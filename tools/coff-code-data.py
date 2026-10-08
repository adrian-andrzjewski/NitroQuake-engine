"""Prove compiler-emitted text data without exempting instructions or functions.

Reassemble the original compiler assembly with zero-byte boundary symbols. The
native and annotated objects must have identical allocated bytes and equivalent
relocations. Only literal-data directives outside inline-assembly blocks become
data ranges, apart from anonymous symbolic pointer records before any text
label or instruction. Inline encoded instruction bytes always remain code.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

LITERAL = re.compile(r'^\s*\.(?:byte|value|word|short|long|int|quad|ascii|asciz|string|float|single|double|zero|space|skip|fill)\b')
ALIGN = re.compile(r'^\s*\.(?:align|balign|p2align)(?:[wl])?\b')
LABEL = re.compile(r'^\s*([A-Za-z_.$][A-Za-z_0-9.$]*):\s*(?:[#/].*)?$')
DIRECT_TRANSFER = re.compile(r'^\s*(?:j[a-z]+|call[lw]?)\s+([A-Za-z_.$][A-Za-z_0-9.$]*)\s*(?:[#/].*)?$')
# ISO C exit does not return. DJGPP 2.05 stdlib.h declares noreturn, and its
# primary exit.c ends in _exit. This is a control-flow ABI contract, never an
# instruction exemption: exit and its runtime closure still need ISA auditing.
# Quake declares Sys_Error noreturn in sys.h; when its definition is present,
# the native compiler listing below must prove it terminates through exit.
# DJGPP's _exit/__exit exit boundaries and ISO longjmp also cannot resume the
# caller's next instruction. The private fault-message boundary is declared
# noreturn in DJGPP 2.05 dpmiexcp.c and terminates through _exit. These contracts
# affect only fallthrough checks; every provider instruction remains audited.
TERMINATING_C_ABI = frozenset({'_exit','__exit','___exit','_longjmp',
                              '_Sys_Error','_do_faulting_finish_message'})

def c_functions(path: Path):
    # GO32 GCC often emits type zero even for a defined function. Bind the
    # original C definitions as well as COFF function types, rather than relying
    # on ELF-style function metadata which this toolchain does not provide.
    source=path.read_text(encoding='latin1')
    source=re.sub(r'/\*.*?\*/|//[^\n]*',' ',source,flags=re.S)
    source=re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'','""',source)
    source=re.sub(r'^\s*#[^\n]*','',source,flags=re.M)
    names=set()
    for match in re.finditer(r'\b(\w+)\s*\(',source):
        if match[1] in {'if','while','for','switch','sizeof','__attribute__'}: continue
        depth=1;end=match.end()
        while end<len(source) and depth:
            depth+=(source[end]=='(')-(source[end]==')');end+=1
        if not depth and source[end:].lstrip().startswith('{'): names.add(match[1])
    return names

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()

def coff(path: Path):
    blob=path.read_bytes()
    machine,count,stamp,symbol_at,symbol_count,optional,flags=struct.unpack_from('<HHIIIHH',blob)
    if machine!=0x14c or optional: raise ValueError(f'Not an i386 relocatable COFF object: {path}')
    string_at=symbol_at+symbol_count*18
    string_size=struct.unpack_from('<I',blob,string_at)[0]
    strings=blob[string_at:string_at+string_size]
    def name(field):
        if field[:4]==b'\0'*4:
            at=struct.unpack_from('<I',field,4)[0]
            return strings[at:].split(b'\0',1)[0].decode('ascii')
        if field.startswith(b'/'):
            at=int(field[1:].split(b'\0',1)[0])
            return strings[at:].split(b'\0',1)[0].decode('ascii')
        return field.split(b'\0',1)[0].decode('ascii')
    symbols={};index=0
    while index<symbol_count:
        at=symbol_at+index*18
        value,section,kind,storage,aux=struct.unpack_from('<IhHBB',blob,at+8)
        symbols[index]={'name':name(blob[at:at+8]),'value':value,'section':section,'type':kind,'storage':storage}
        index+=1+aux
    sections={}
    for index in range(count):
        at=20+index*40
        size,raw_at,reloc_at,line_at,nreloc,nline,section_flags=struct.unpack_from('<IIIIHHI',blob,at+16)
        section_name=name(blob[at:at+8])
        relocs=[]
        for i in range(nreloc):
            offset,symbol,kind=struct.unpack_from('<IIH',blob,reloc_at+i*10)
            target=symbols[symbol]
            relocs.append((offset,kind,target['name'],target['value'],target['section']))
        sections[section_name]={'number':index+1,'size':size,'flags':section_flags,
            'bytes':blob[raw_at:raw_at+size] if raw_at else b'', 'relocations':sorted(relocs)}
    return sections,list(symbols.values())

def annotate(source: str,handwritten: bool=False):
    # GAS begins in .text even when a handwritten source has no .text directive.
    output=[]; section='.text'; inline=False; active=None; ordinal=0; mode=32
    label_ordinal=0; last_operation=None; section_operations={};macro_depth=0
    def close():
        nonlocal active
        if active:
            label=active+'_end';output.extend([f'.globl {label}',label+':']);active=None
    for line in source.splitlines():
        stripped=line.strip()
        if re.match(r'^\s*\.macro\b',line):macro_depth+=1
        if macro_depth:
            # A GAS definition emits no bytes until invocation. Inserting
            # global markers inside it duplicates them at every expansion.
            # Invocations are conservatively CODE, including encoded bytes.
            # Section/mode changes inside macros would invalidate that rule.
            if re.match(r'^\s*\.(?:text|data|bss|section|pushsection|popsection|previous|code16|code16gcc|code32)\b',line):
                raise ValueError('GAS macros may not change section or instruction mode in a boundary proof.')
            output.append(line)
            if re.match(r'^\s*\.endm\b',line):macro_depth-=1
            continue
        if stripped in ('#APP','/APP'): inline=True
        if stripped in ('#NO_APP','/NO_APP'): inline=False
        match=re.match(r'^\s*\.(text|data|bss)\s*(?:#.*)?$',line)
        named=re.match(r'^\s*\.section\s+([^,\s]+)',line)
        if match or named:
            section_operations[section]=last_operation
            close();section='.'+match[1] if match else named[1]
            last_operation=section_operations.get(section)
        if re.match(r'^\s*\.code16(?:gcc)?\b',line): mode=16
        if re.match(r'^\s*\.code32\b',line): mode=32
        kind=None
        if section and section.startswith('.text'):
            label=LABEL.match(line)
            if label:
                alias=f'__isa_source_label_{label_ordinal:06d}';label_ordinal+=1
                output.extend([f'.globl {alias}',alias+':'])
            if LITERAL.match(line):
                # Preprocessed handwritten runtime assembly spells segment
                # prefixes and patched INT bytes with .byte. Conservatively
                # decode all such bytes; this rule never waives their ISA.
                # DJGPP's stdio header forces an archive member into the link
                # with an anonymous .long symbol before any function. This is
                # a pointer record, never an executable entry or numeric byte
                # encoding. Entry/direct-target/fallthrough checks below still
                # reject any attempt to execute a proposed DATA range.
                leading_pointer=(not handwritten and label_ordinal==0 and last_operation is None and
                    re.fullmatch(r'\s*\.long\s+[A-Za-z_.$][A-Za-z_0-9.$]*(?:\s*,\s*[A-Za-z_.$][A-Za-z_0-9.$]*)*\s*(?:[#/].*)?',line))
                kind='data' if leading_pointer else 'code' if inline or (handwritten and re.match(r'^\s*\.byte\b',line)) else 'data'
            elif ALIGN.match(line): kind='code'
            elif stripped and not stripped.startswith(('#','.','/')) and not stripped.endswith(':'):
                kind='code'
                last_operation=stripped.split()[0].lower()
                transfer=DIRECT_TRANSFER.match(line)
                if last_operation in ('call','calll','callw') and transfer and transfer[1] in TERMINATING_C_ABI:
                    last_operation='terminating-c-abi'
            if kind=='data' and active and '_code' in active and last_operation is not None:
                if last_operation not in ('ret','retl','retw','lret','lretl','lretw',
                                           'iret','iretl','iretw','jmp','jmpl','jmpw','ud2','terminating-c-abi'):
                    raise ValueError(f'CODE operation {last_operation} can fall through into proposed DATA: {line.strip()}')
                last_operation=None
        if kind and (active is None or f'_{kind}{mode}_' not in active):
            close();active=f'__isa_boundary_{kind}{mode}_{ordinal:06d}';ordinal+=1
            label=active+'_begin';output.extend([f'.globl {label}',label+':'])
        output.append(line)
    if macro_depth:raise ValueError('Unterminated GAS macro definition.')
    close()
    return '\n'.join(output)+'\n'

def prove(native: Path,marked: Path,source_assembly: Path,annotated_assembly: Path,c_source: Path|None=None,handwritten: bool=False):
    if c_source is None and not handwritten:
        raise ValueError('Compiler literal boundaries require the original C source; otherwise use explicit handwritten assembly rules.')
    if c_source is not None and handwritten:
        raise ValueError('A boundary proof must have one source kind: C compiler output or handwritten assembly.')
    original,native_symbols=coff(native); observed,symbols=coff(marked)
    # DJGPP loads STYP_TEXT/DATA/BSS contributions. Non-allocated DWARF and
    # comment records are not part of the executable instruction/data image;
    # their source-directory strings can differ in a primary-source rebuild.
    allocated=lambda sections:{name for name,item in sections.items() if item['flags']&0xe0}
    if allocated(original)!=allocated(observed): raise ValueError('Annotation changed the allocated section set.')
    for name in allocated(original):
        for field in ('size','flags','bytes','relocations'):
            if original[name][field]!=observed[name][field]:
                raise ValueError(f'Annotation changed {name} {field}; no data exemption can be issued.')
    by_name={entry['name']:entry for entry in symbols}
    assembly_text=source_assembly.read_text(encoding='utf-8')
    local_termination=[]
    source_functions=c_functions(c_source) if c_source else set()
    for symbol in sorted(TERMINATING_C_ABI):
        fatal=re.search(r'^'+re.escape(symbol)+r':\s*$',assembly_text,flags=re.M)
        if not fatal or (symbol!='_Sys_Error' and symbol[1:] not in source_functions):continue
        remainder=assembly_text[fatal.end():]
        following=re.search(r'^\s*\.cfi_endproc\b',remainder,flags=re.M)
        if following is None:following=re.search(r'^\s*\.globl\b',remainder,flags=re.M)
        body=remainder[:following.start()] if following else remainder
        operations=[line.strip() for line in body.splitlines() if line.strip() and
                    not line.strip().startswith(('#','/','.')) and not LABEL.match(line)]
        if re.search(r'(?:^|[;:])\s*(?:l?ret|iret)[lw]?\b',body,re.M) or not operations:
            raise ValueError(f'Local {symbol} definition violates its terminating ABI contract.')
        for literal in re.finditer(r'^\s*\.(byte|word|short|long|int|quad)\s+([^\n]+)',body,re.M):
            # libc/farptrgs.h emits an explicit GS prefix. Prefix-only bytes
            # cannot conceal a RET; ISA validation still checks the resulting
            # complete prefixed instruction. Reject every other opaque form.
            try:values=[int(value.strip(),0) for value in literal[2].split(',')]
            except ValueError:values=[]
            if literal[1]!='byte' or not values or any(value not in
                    {0x26,0x2e,0x36,0x3e,0x64,0x65,0x66,0x67,0xf0,0xf2,0xf3} for value in values):
                raise ValueError(f'Opaque encoded operations in local terminating definition {symbol}.')
        last=DIRECT_TRANSFER.match(operations[-1])
        labels={m[1] for line in body.splitlines() if (m:=LABEL.match(line))}
        for line in operations:
            transfer=DIRECT_TRANSFER.match(line)
            if re.match(r'^j[a-z]+\b',line):
                if not transfer or transfer[1] not in labels | TERMINATING_C_ABI:
                    raise ValueError(f'Local {symbol} branches outside its proved terminating body.')
        if symbol=='_Sys_Error' and (not last or last[1]!='_exit'):
            raise ValueError('Local Sys_Error termination through exit was not proved.')
        if symbol!='_Sys_Error':
            transfers=[DIRECT_TRANSFER.match(line) for line in operations]
            if not any(t and t[1] in TERMINATING_C_ABI-{symbol} for t in transfers):
                raise ValueError(f'Local {symbol} termination through a checked ABI boundary was not proved.')
            if not last or last[1] not in TERMINATING_C_ABI | labels:
                raise ValueError(f'Local {symbol} can fall out of its function body.')
        local_termination.append(symbol)
    ranges=[]
    for entry in symbols:
        match=re.fullmatch(r'__isa_boundary_(code|data)(16|32)_(\d+)_begin',entry['name'])
        if not match: continue
        end=by_name[entry['name'].removesuffix('_begin')+'_end']
        if entry['section']!=end['section']: raise ValueError('Boundary spans sections.')
        section=next((name for name,item in original.items() if item['number']==entry['section']),None)
        start=entry['value'];stop=end['value']
        if stop<start: raise ValueError('Invalid annotation extent.')
        if stop==start: continue
        ranges.append({'section':section,'start':start,'end':stop,'kind':match[1],'codeMode':int(match[2]),
            'sha256':sha(original[section]['bytes'][start:stop]),'proof':'byte-identical compiler assembly directive boundaries'})
    ranges.sort(key=lambda item:(item['section'],item['start']))
    for section,item in original.items():
        if not section.startswith('.text') or not item['bytes']: continue
        cursor=0
        for span in (span for span in ranges if span['section']==section):
            if span['start']!=cursor: raise ValueError(f'Unproved or overlapping {section} range at {cursor:x}.')
            cursor=span['end']
        if cursor!=len(item['bytes']):
            padding=item['bytes'][cursor:]
            # DJGPP COFF pads raw section storage to 16 bytes after the
            # assembler's last symbol. These bytes do not encode source code.
            if len(padding)>=16 or len(item['bytes'])%16:
                raise ValueError(f'Unproved {section} tail at {cursor:x}.')
            ranges.append({'section':section,'start':cursor,'end':len(item['bytes']),
                'kind':'code' if any(padding) else 'data','codeMode':32,'sha256':sha(padding),
                'proof':'byte-identical COFF trailing alignment after final assembler boundary; nonzero padding remains ISA-audited'})
    def is_code(section_number,offset):
        section=next((name for name,item in original.items() if item['number']==section_number),None)
        return any(span['section']==section and span['kind']=='code' and
                   span['start']<=offset<span['end'] for span in ranges)
    # A DATA directive cannot waive a function entry. COFF records C function
    # types independently of directive annotation, including static functions.
    for symbol in native_symbols:
        source_name=symbol['name'][1:] if symbol['name'].startswith('_') else symbol['name']
        is_function=symbol['type'] & 0x30 == 0x20 or source_name.split('.')[0] in source_functions
        if symbol['section']>0 and is_function:
            if not is_code(symbol['section'],symbol['value']):
                raise ValueError(f"Function entry {symbol['name']} lies in proposed DATA.")
    # Preserve local labels with zero-byte aliases, then verify every direct
    # control-flow target and compiler jump-table destination is still CODE.
    aliases={};section='.text';ordinal=0;targets=set();macro_depth=0
    for line in source_assembly.read_text(encoding='utf-8').splitlines():
        if re.match(r'^\s*\.macro\b',line):macro_depth+=1
        if macro_depth:
            transfer=DIRECT_TRANSFER.match(line)
            if transfer:targets.add(transfer[1])
            if re.match(r'^\s*\.endm\b',line):macro_depth-=1
            continue
        match=re.match(r'^\s*\.(text|data|bss)\s*(?:#.*)?$',line)
        named=re.match(r'^\s*\.section\s+([^,\s]+)',line)
        if match or named: section='.'+match[1] if match else named[1]
        if not section or not section.startswith('.text'): continue
        label=LABEL.match(line)
        if label:
            alias=by_name[f'__isa_source_label_{ordinal:06d}'];ordinal+=1
            aliases[label[1]]=alias
        transfer=DIRECT_TRANSFER.match(line)
        table=re.match(r'^\s*\.(?:long|int)\s+(\.?L[0-9]+)\s*(?:[#/].*)?$',line)
        if transfer: targets.add(transfer[1])
        if table: targets.add(table[1])
    for target in targets:
        symbol=aliases.get(target)
        if symbol is not None and not is_code(symbol['section'],symbol['value']):
            raise ValueError(f'Control-flow target {target} lies in proposed DATA.')
    record={'schemaVersion':2,'object':str(native.resolve()),'objectSha256':sha(native.read_bytes()),
        'compilerAssembly':str(source_assembly.resolve()),'compilerAssemblySha256':sha(source_assembly.read_bytes()),
        'annotatedAssembly':str(annotated_assembly.resolve()),'annotatedAssemblySha256':sha(annotated_assembly.read_bytes()),
        'annotatedObject':str(marked.resolve()),'annotatedObjectSha256':sha(marked.read_bytes()),
        'allocatedBytesAndRelocationsMatch':True,'functionEntriesAndDirectTargetsAreCode':True,
        'allocatedSectionsCompared':sorted(allocated(original)),
        'terminatingCAbiContracts':sorted(TERMINATING_C_ABI),
        'locallyProvedTerminatingSymbols':local_termination,
        'annotationPolicySha256':sha(Path(__file__).read_bytes()),
        'handwrittenAssembly':handwritten,'ranges':ranges}
    if c_source:
        record.update(source=str(c_source.resolve()),sourceSha256=sha(c_source.read_bytes()),
                      cFunctionDefinitions=sorted(source_functions))
    return record

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assembly',type=Path)
    parser.add_argument('--native-object',type=Path)
    parser.add_argument('--compiler',type=Path)
    parser.add_argument('--output-root',type=Path)
    parser.add_argument('--c-source',type=Path)
    parser.add_argument('--handwritten-assembly',action='store_true')
    parser.add_argument('--verify-proof-index',type=Path)
    args=parser.parse_args()
    if args.verify_proof_index:
        index=json.loads(args.verify_proof_index.read_text(encoding='utf-8-sig'))
        if not index['pass'] or index.get('failures'): raise ValueError('Incomplete code/data proof index.')
        for filename in index['proofs']:
            record=json.loads(Path(filename).read_text(encoding='utf-8-sig'))
            original=Path(record['object']);assembly=Path(record['compilerAssembly'])
            marked=Path(record['annotatedObject']);annotated=Path(record['annotatedAssembly'])
            handwritten=record.get('handwrittenAssembly',False)
            if annotate(assembly.read_text(encoding='utf-8'),handwritten)!=annotated.read_text(encoding='utf-8'): raise ValueError('Boundary annotation differs from the checked annotation rules.')
            actual=prove(original,marked,assembly,annotated,Path(record['source']) if 'source' in record else None,handwritten)
            for field in actual:
                if actual[field]!=record[field]: raise ValueError(f'Changed code/data proof field: {field}')
            if 'source' in record and sha(Path(record['source']).read_bytes())!=record['sourceSha256']:
                raise ValueError('Compiler code/data proof belongs to a different source snapshot.')
        print(f'Verified {len(index["proofs"])} exact native/annotated object proofs.')
        return
    if not all((args.assembly,args.native_object,args.compiler,args.output_root)):
        parser.error('Assembly, native object, compiler and output root are required to issue a proof.')
    args.output_root.mkdir(parents=True,exist_ok=True)
    marked_asm=args.output_root/'annotated.s';marked_obj=args.output_root/'annotated.obj'
    marked_asm.write_text(annotate(args.assembly.read_text(encoding='utf-8'),args.handwritten_assembly),encoding='utf-8',newline='\n')
    subprocess.run([str(args.compiler),'-c','-x','assembler',str(marked_asm),'-o',str(marked_obj)],check=True)
    report=prove(args.native_object,marked_obj,args.assembly,marked_asm,args.c_source,args.handwritten_assembly)
    path=args.output_root/'code-data-proof.json';path.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(f'Code/data proof PASS: {len(report["ranges"])} byte-identical ranges; {path}')

if __name__=='__main__': main()
