"""Disassemble exact COFF CODE bytes independently of interior symbol labels.

The pinned objdump truncates its raw-byte column at some COFF symbols even with
-D. Extract a section into a raw binary, decode continuously, then attribute
whole instructions to the original symbols. Never decode data sections.
"""
from __future__ import annotations
import argparse
from bisect import bisect_right
from pathlib import Path
import re
import struct
import subprocess
import tempfile


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


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target',type=Path,required=True)
    parser.add_argument('--section',required=True)
    parser.add_argument('--start',type=lambda n:int(n,0),required=True)
    parser.add_argument('--end',type=lambda n:int(n,0),required=True)
    parser.add_argument('--mode',type=int,choices=(16,32),required=True)
    parser.add_argument('--objdump',type=Path,required=True)
    args=parser.parse_args()
    vma,data,symbols=code_section(args.target,args.section)
    if not vma<=args.start<args.end<=vma+len(data): raise ValueError('Range outside CODE bytes.')
    offsets=[pair[0] for pair in symbols]
    with tempfile.TemporaryDirectory(prefix='isa-raw-') as directory:
        raw=Path(directory)/'code.bin'
        raw.write_bytes(data[args.start-vma:args.end-vma])
        run=subprocess.run([str(args.objdump),'-D','-z','-b','binary',
            '-mi8086' if args.mode==16 else '-mi386','--insn-width=16',
            f'--adjust-vma=0x{args.start:x}',str(raw)],capture_output=True,text=True,check=True)
    print(f'Disassembly of section {args.section}:')
    active=None
    for line in run.stdout.splitlines():
        match=re.match(r'^\s*([0-9a-fA-F]+):\t',line)
        if not match: continue
        address=int(match[1],16)
        position=bisect_right(offsets,address)-1
        label=symbols[position][1] if position>=0 else '<none>'
        if label!=active:
            print(f'{address:08x} <{label}>:')
            active=label
        print(line)


if __name__=='__main__': main()
