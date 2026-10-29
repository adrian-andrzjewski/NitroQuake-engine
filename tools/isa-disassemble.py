"""Disassemble exact COFF CODE ranges independently of interior symbol labels.

The pinned objdump truncates its raw-byte column at some COFF symbols even with
-D. Extract each proved CODE range into its own raw binary, batch those binaries
across objects through objdump, then attribute whole instructions to the original
symbols. Never decode data ranges.
"""
from __future__ import annotations
import argparse
from bisect import bisect_right
from collections import defaultdict
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile

RELATIVE_PREFIXES={0x26,0x2e,0x36,0x3e,0x64,0x65,0x66,0x67,0xf0,0xf2,0xf3}
DIRECT_TARGET=re.compile(r'0x([0-9a-fA-F]+)$')


def code_section(path: Path, wanted: str):
    blob=path.read_bytes()
    base=0
    if blob[:2]==b'MZ':
        last,pages=struct.unpack_from('<HH',blob,2)
        base=pages*512-(512-last if last else 0)
    if len(blob)<base+20: raise ValueError('Truncated COFF header.')
    machine,count,stamp,symbol_at,symbol_count,optional,flags=struct.unpack_from('<HHIIIHH',blob,base)
    if machine!=0x14c: raise ValueError('The input is not i386 COFF.')
    # COFF file offsets in GO32 executables are relative to the COFF header,
    # after the DOS MZ loader. Objects have base zero.
    symbol_at+=base
    string_at=symbol_at+symbol_count*18
    if symbol_count:
        if string_at+4>len(blob): raise ValueError('Missing COFF string table.')
        string_size=struct.unpack_from('<I',blob,string_at)[0]
        strings=blob[string_at:string_at+string_size]
    else:
        strings=b''
    def name(field: bytes):
        if field[:4]==b'\0'*4:
            at=struct.unpack_from('<I',field,4)[0]
            return strings[at:].split(b'\0',1)[0].decode('ascii')
        if field.startswith(b'/'):
            at=int(field[1:].split(b'\0',1)[0])
            return strings[at:].split(b'\0',1)[0].decode('ascii')
        return field.split(b'\0',1)[0].decode('ascii')
    selected=None
    for index in range(count):
        at=base+20+optional+index*40
        section_name=name(blob[at:at+8])
        physical,vma,size,raw_at=struct.unpack_from('<IIII',blob,at+8)
        section_flags=struct.unpack_from('<I',blob,at+36)[0]
        if section_name==wanted:
            if not section_flags & 0x20: raise ValueError('Requested section is not CODE.')
            if base+raw_at+size>len(blob): raise ValueError('Truncated CODE section.')
            selected=(index+1,vma,blob[base+raw_at:base+raw_at+size])
    if selected is None: raise ValueError('Missing requested CODE section.')
    section_number,vma,data=selected
    symbols=[]; index=0
    while index<symbol_count:
        at=symbol_at+index*18
        value,section,kind,storage,aux=struct.unpack_from('<IhHBB',blob,at+8)
        label=name(blob[at:at+8])
        if section==section_number and not label.startswith('.') and storage in (2,3):
            symbols.append((value if optional else value+vma,label))
        index+=1+aux
    # Deterministic aliases at the same address preserve all public symbols in
    # the separate ownership inventory. One stable name locates an audit site.
    symbols.sort(key=lambda pair:(pair[0],pair[1]))
    return vma,data,symbols


def restore_relative_target(line: str, item) -> str:
    """Translate a direct relative branch target from range-local to section VMA."""
    separator=line.rfind('\t')
    if separator<0: return line
    decoded=line[separator+1:].strip()
    mnemonic=decoded.split(None,1)[0] if decoded else ''
    if mnemonic!='call' and not mnemonic.startswith(('j','loop')): return line
    target_match=DIRECT_TARGET.search(decoded)
    if not target_match: return line
    columns=line.split('\t')
    if len(columns)<3: return line
    try: encoded=[int(value,16) for value in columns[1].split()]
    except ValueError: return line
    index=0; operand_override=False
    while index<len(encoded) and encoded[index] in RELATIVE_PREFIXES:
        operand_override|=encoded[index]==0x66
        index+=1
    if index>=len(encoded): return line
    opcode=encoded[index]
    short_relative=(0x70<=opcode<=0x7f) or (0xe0<=opcode<=0xe3) or opcode==0xeb
    near_relative=opcode in (0xe8,0xe9) or (
        opcode==0x0f and index+1<len(encoded) and 0x80<=encoded[index+1]<=0x8f)
    if not (short_relative or near_relative): return line
    width=16 if item['mode']==16 else 32
    if near_relative and operand_override: width=32 if width==16 else 16
    target=(int(target_match[1],16)+item['start'])&((1<<width)-1)
    decoded=decoded[:target_match.start()]+f'0x{target:x}'
    return line[:separator+1]+decoded


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target',type=Path)
    parser.add_argument('--section',default='.text')
    parser.add_argument('--start',type=lambda n:int(n,0))
    parser.add_argument('--end',type=lambda n:int(n,0))
    parser.add_argument('--mode',type=int,choices=(16,32),default=32)
    parser.add_argument('--ranges-json',type=Path)
    parser.add_argument('--batch-manifest',type=Path,
        help='JSON object containing targetIndex, path and ranges entries for multiple objects.')
    parser.add_argument('--batch-output-directory',type=Path,
        help='Write bounded per-target disassembly files for a multi-target batch.')
    parser.add_argument('--objdump',type=Path,required=True)
    args=parser.parse_args()

    if args.batch_manifest is None and args.batch_output_directory is not None:
        parser.error('--batch-output-directory requires --batch-manifest')
    multi_target=False
    if args.batch_manifest is not None:
        if args.target is not None or args.ranges_json is not None or args.start is not None or args.end is not None:
            parser.error('--batch-manifest cannot be combined with single-target range arguments')
        if args.batch_output_directory is None:
            parser.error('--batch-output-directory is required with --batch-manifest')
        manifest=json.loads(args.batch_manifest.read_text(encoding='utf-8-sig'))
        target_groups=manifest.get('targets') if isinstance(manifest,dict) else None
        if not isinstance(target_groups,list) or not target_groups:
            raise ValueError('Batch manifest must contain a nonempty targets array.')
        multi_target=True
        range_markers=True
        pending=[]
        for group in target_groups:
            target_index=int(group['targetIndex'])
            target=Path(group['path'])
            ranges=group.get('ranges')
            if not isinstance(ranges,list) or not ranges:
                raise ValueError(f'Target {target_index} has no CODE ranges.')
            for range_index,item in enumerate(ranges):
                pending.append((target,target_index,range_index,item))
    elif args.ranges_json is None:
        if args.target is None:
            parser.error('--target is required without --batch-manifest')
        if args.start is None or args.end is None:
            parser.error('--start and --end are required without --ranges-json')
        ranges=[dict(section=args.section,start=args.start,end=args.end,codeMode=args.mode)]
        range_markers=False
        pending=[(args.target,0,index,item) for index,item in enumerate(ranges)]
    else:
        if args.target is None:
            parser.error('--target is required with --ranges-json')
        if args.start is not None or args.end is not None:
            parser.error('--start/--end cannot be combined with --ranges-json')
        ranges=json.loads(args.ranges_json.read_text(encoding='utf-8-sig'))
        if isinstance(ranges,dict): ranges=[ranges]
        if not isinstance(ranges,list) or not ranges:
            raise ValueError('Range manifest must be a nonempty JSON array.')
        range_markers=True
        pending=[(args.target,0,index,item) for index,item in enumerate(ranges)]

    section_cache={}
    normalized=[]
    def address(value):
        return int(value,0) if isinstance(value,str) else int(value)
    for index,(target,target_index,range_index,item) in enumerate(pending):
        section=str(item.get('section','.text'))
        start=address(item['start']); end=address(item['end'])
        mode=int(item.get('codeMode',32))
        if mode not in (16,32): raise ValueError(f'Unsupported code mode {mode}.')
        cache_key=(str(target.resolve()),section)
        if cache_key not in section_cache:
            section_cache[cache_key]=code_section(target,section)
        vma,data,symbols=section_cache[cache_key]
        if not vma<=start<end<=vma+len(data): raise ValueError(f'Range {index} outside CODE bytes.')
        normalized.append(dict(index=index,target=target,targetIndex=target_index,rangeIndex=range_index,
            section=section,start=start,end=end,mode=mode,
            vma=vma,data=data,symbols=symbols,offsets=[pair[0] for pair in symbols]))

    with tempfile.TemporaryDirectory(prefix='isa-raw-') as directory:
        root=Path(directory)
        by_mode=defaultdict(list)
        for item in normalized:
            raw=root/f'range-{item["index"]:05d}.bin'
            item['raw']=raw
            item['decoded']=root/f'range-{item["index"]:05d}.txt'
            by_mode[item['mode']].append(item)

        file_pattern=re.compile(r'(?P<name>range-(?P<index>\d{5})\.bin):\s+file format binary\s*$')
        address_pattern=re.compile(r'^(?P<indent>\s*)(?P<address>[0-9a-fA-F]+):(?P<rest>\t.*)$')
        old_batches_by_target=defaultdict(lambda:defaultdict(int))
        for item in normalized:
            old_batches_by_target[item['targetIndex']][item['mode']]+=1
        old_objdump_runs=sum((count+31)//32 for modes in old_batches_by_target.values() for count in modes.values())
        objdump_runs=sum((len(items)+31)//32 for items in by_mode.values())
        for mode,items in by_mode.items():
            # Keep command lines below Windows' native limit with long temp paths.
            for batch_start in range(0,len(items),32):
                batch=items[batch_start:batch_start+32]
                for item in batch:
                    code=item['data'][item['start']-item['vma']:item['end']-item['vma']]
                    item['raw'].write_bytes(code)
                command=[str(args.objdump),'-D','-z','-b','binary',
                    '-mi8086' if mode==16 else '-mi386','--insn-width=16']
                command.extend(item['raw'].name for item in batch)
                run=subprocess.run(command,cwd=directory,capture_output=True,text=True)
                if run.returncode:
                    raise RuntimeError(f"objdump failed for '{batch[0]['target']}': {run.stderr.strip()}")
                item_by_index={item['index']:item for item in batch}
                current=None; active=None; seen=set(); outputs={}
                try:
                    for line in run.stdout.splitlines():
                        file_match=file_pattern.search(line)
                        if file_match:
                            index=int(file_match['index'])
                            current=item_by_index.get(index)
                            if current is None: raise ValueError(f'Unexpected batched objdump input {index}.')
                            if current['index'] in seen: raise ValueError(f'Duplicate batched objdump input {index}.')
                            seen.add(current['index']); active=None
                            output=current['decoded'].open('w',encoding='ascii',newline='\n')
                            outputs[current['index']]=output
                            if multi_target:
                                output.write(f"@@ISA-TARGET {current['targetIndex']} RANGE {current['rangeIndex']}@@\n")
                            elif range_markers:
                                output.write(f'@@ISA-RANGE {index}@@\n')
                            output.write(f"Disassembly of section {current['section']}:\n")
                            continue
                        if current is None: continue
                        match=address_pattern.match(line)
                        if not match: continue
                        range_offset=int(match['address'],16)
                        original_address=current['start']+range_offset
                        position=bisect_right(current['offsets'],original_address)-1
                        label=current['symbols'][position][1] if position>=0 else '<none>'
                        output=outputs[current['index']]
                        if label!=active:
                            output.write(f'{original_address:08x} <{label}>:\n')
                            active=label
                        absolute_line=f"{match['indent']}{original_address:08x}:{match['rest']}"
                        output.write(restore_relative_target(absolute_line,current)+'\n')
                finally:
                    for output in outputs.values(): output.close()
                if seen!={item['index'] for item in batch}:
                    raise ValueError('Batched objdump output omitted one or more input ranges.')

        if multi_target:
            output_root=args.batch_output_directory
            if output_root.exists() and any(output_root.iterdir()):
                raise ValueError(f'Batch output directory is not empty: {output_root}')
            output_root.mkdir(parents=True,exist_ok=True)
            outputs={}
            try:
                for item in normalized:
                    target_index=item['targetIndex']
                    if target_index not in outputs:
                        output_path=output_root/f'target-{target_index:05d}.txt'
                        outputs[target_index]=output_path.open('w',encoding='ascii',newline='\n')
                    output=outputs[target_index]
                    with item['decoded'].open('r',encoding='ascii',newline='') as decoded:
                        expected=f"@@ISA-TARGET {target_index} RANGE {item['rangeIndex']}@@\n"
                        if decoded.readline()!=expected:
                            raise ValueError('Decoded range target marker does not match its manifest.')
                        output.write(f"@@ISA-RANGE {item['rangeIndex']}@@\n")
                        shutil.copyfileobj(decoded,output)
            finally:
                for output in outputs.values(): output.close()
            print(f'Cross-object ISA batch: {len(normalized)} ranges across {len(outputs)} targets; '
                f'{objdump_runs} objdump processes versus {old_objdump_runs} per-target batches.')
        else:
            for item in normalized:
                for line in item['decoded'].read_text(encoding='ascii').splitlines():
                    print(line)


if __name__=='__main__': main()
