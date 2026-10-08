"""Adversarial checks for exact-byte COFF code/data boundary evidence."""
from __future__ import annotations
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('code_data',ROOT/'tools/coff-code-data.py')
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def main():
    manifest=json.loads((ROOT/'tools/dos-toolchain.json').read_text(encoding='utf-8'))
    tool_root=Path(os.environ['LOCALAPPDATA'])/'486quake/tools'
    compiler=tool_root/manifest['djgpp']['installDirectory']/manifest['djgpp']['compiler']
    work=Path(tempfile.mkdtemp(prefix='coff-code-data-regression-',dir=ROOT/'out'))
    prefix='.text\n.globl _fixture\n.def _fixture; .scl 2; .type 32; .endef\n_fixture:\n'
    cases={
        'anonymous_leading_pointer':('/APP\n.long _external\n/NO_APP\n'+prefix+'ret\n',True),
        'leading_numeric_encoding':('/APP\n.long 0x00c0450f\n/NO_APP\n'+prefix+'ret\n',True),
        'literal_after_return':(prefix+'movl .Lconstant,%eax\nret\n.Lconstant:\n.long 0xdeadbeef\n',True),
        'switch_destinations':(prefix+'jmp *.Ltable(,%eax,4)\n.Ltable:\n.long .L1\n.L1:\nret\n',True),
        'inline_forbidden_bytes':(prefix+'#APP\n.byte 0x0f,0x45,0xc0\n#NO_APP\nret\n',True),
        'djgpp_inline_forbidden_bytes':(prefix+'/APP\n.byte 0x0f,0x45,0xc0\n/NO_APP\nret\n',True),
        'djgpp_fs_prefix':(prefix+'/APP\n.byte 0x64\nmovl (%eax),%eax\n/NO_APP\nret\n',True),
        'djgpp_switch_destinations':(prefix+'jmp *Ltable(,%eax,4)\nLtable:\n.long L1\nL1:\nret\n',True),
        'djgpp_switch_into_data':(prefix+'jmp *Ltable(,%eax,4)\nLtable:\n.long L1\nL1:\n.long 1\n',False),
        'terminating_exit_abi':(prefix+'call _exit\n.Lliteral:\n.long 1\n',True),
        'ordinary_call_fallthrough':(prefix+'call _external\n.Lliteral:\n.long 1\n',False),
        'cold_section_does_not_change_main_return':(prefix+'ret\n.section .text.unlikely,"x"\ncall _external\n.p2align 4\n.section .text\n.p2align 2\n.Lliteral:\n.long 1\n',True),
        'cold_return_cannot_hide_main_fallthrough':(prefix+'call _external\n.section .text.unlikely,"x"\nret\n.p2align 4\n.section .text\n.p2align 2\n.Lliteral:\n.long 1\n',False),
        'invalid_local_fatal_contract':(prefix+'call _Sys_Error\nret\n.globl _Sys_Error\n_Sys_Error:\nret\n',False),
        'inline_ret_local_fatal_contract':(prefix+'call _Sys_Error\nret\n.globl _Sys_Error\n_Sys_Error:\n/APP\n.byte 0xc3\n/NO_APP\ncall _exit\n',False),
        'semicolon_ret_local_fatal_contract':(prefix+'call _Sys_Error\nret\n.globl _Sys_Error\n_Sys_Error:\nnop; ret\ncall _exit\n',False),
        'prefix_local_fatal_contract':(prefix+'call _Sys_Error\nret\n.globl _Sys_Error\n_Sys_Error:\n/APP\n.byte 0x65\nmovl (%eax),%eax\n/NO_APP\ncall _exit\n',True),
        'external_jump_local_fatal_contract':(prefix+'call _Sys_Error\nret\n.globl _Sys_Error\n_Sys_Error:\njmp _returning\ncall _exit\n.globl _returning\n_returning:\nret\n',False),
        'external_conditional_local_fatal_contract':(prefix+'call _Sys_Error\nret\n.globl _Sys_Error\n_Sys_Error:\nje _returning\ncall _exit\n.globl _returning\n_returning:\nret\n',False),
        'indirect_jump_local_fatal_contract':(prefix+'call _Sys_Error\nret\n.globl _Sys_Error\n_Sys_Error:\njmp *%eax\ncall _exit\n',False),
        'default_gas_text_section':('.globl _fixture\n.def _fixture; .scl 2; .type 32; .endef\n_fixture:\nret\n',True),
        'function_entry_data':(prefix+'.byte 0x0f,0x45,0xc0\nret\n',False),
        'branch_into_data':(prefix+'jmp .Lliteral\n.Lliteral:\n.long 0xdeadbeef\n',False),
        'call_into_data':(prefix+'call .Lliteral\nret\n.Lliteral:\n.long 0xdeadbeef\n',False),
        'switch_into_data':(prefix+'jmp *.Ltable(,%eax,4)\n.Ltable:\n.long .L1\n.L1:\n.long 0xdeadbeef\n',False),
        'fallthrough_into_data':(prefix+'nop\n.Lliteral:\n.long 0xdeadbeef\n',False),
        'relocation_control':(prefix+'call _external\nret\n',True),
        'repeated_gas_macro':('.macro increment\nincl %eax\n.endm\n'+prefix+'increment\nincrement\nret\n',True),
        'encoded_gas_macro_is_code':('.macro encoded\n.byte 0x0f,0x45,0xc0\n.endm\n'+prefix+'encoded\nret\n',True),
        'gas_macro_cannot_hide_data_target':('.macro transfer\njmp .Lliteral\n.endm\n'+prefix+'transfer\nret\n.Lliteral:\n.long 1\n',False),
        'gas_macro_mode_change_rejected':('.macro switchmode\n.code16\nnop\n.code32\n.endm\n'+prefix+'switchmode\nret\n',False),
        'gas_macro_section_change_rejected':('.macro switchsection\n.data\n.byte 1\n.text\n.endm\n'+prefix+'switchsection\nret\n',False),
    }
    passed=0;records={}
    for name,(source,expected) in cases.items():
        directory=work/name;directory.mkdir()
        assembly=directory/'native.s';native=directory/'native.obj'
        c_source=directory/'original.c';c_source.write_text('void fixture(void) {}\n',encoding='ascii')
        marked_asm=directory/'annotated.s';marked=directory/'annotated.obj'
        assembly.write_text(source,encoding='ascii')
        subprocess.run([str(compiler),'-c','-x','assembler',str(assembly),'-o',str(native)],capture_output=True,check=True)
        try:
            marked_asm.write_text(module.annotate(source),encoding='ascii')
            subprocess.run([str(compiler),'-c','-x','assembler',str(marked_asm),'-o',str(marked)],capture_output=True,check=True)
            record=module.prove(native,marked,assembly,marked_asm,c_source)
            actual=True;records[name]=record
        except ValueError as error:
            actual=False
            (directory/'rejection.txt').write_text(str(error),encoding='utf-8')
        assert actual==expected,(name,actual,expected)
        passed+=1

    assert records['anonymous_leading_pointer']['ranges'][0]['kind']=='data'
    assert records['leading_numeric_encoding']['ranges'][0]['kind']=='code'

    reference=records['literal_after_return']
    native=Path(reference['object']);marked=Path(reference['annotatedObject'])
    assembly=Path(reference['compilerAssembly']);annotated=Path(reference['annotatedAssembly'])
    damaged=work/'damaged-code.obj';blob=bytearray(marked.read_bytes())
    raw_at=struct.unpack_from('<I',blob,20+20)[0]
    blob[raw_at]^=1;damaged.write_bytes(blob)
    try: module.prove(native,damaged,assembly,annotated,Path(reference['source']))
    except ValueError: passed+=1
    else: raise AssertionError('Changed allocated CODE bytes were accepted.')
    reloc=records['relocation_control'];native=Path(reloc['object']);marked=Path(reloc['annotatedObject'])
    blob=bytearray(marked.read_bytes());reloc_at=struct.unpack_from('<I',blob,20+24)[0]
    struct.pack_into('<H',blob,reloc_at+8,0x0006)
    damaged=work/'damaged-relocation.obj';damaged.write_bytes(blob)
    try: module.prove(native,damaged,Path(reloc['compilerAssembly']),Path(reloc['annotatedAssembly']),Path(reloc['source']))
    except ValueError: passed+=1
    else: raise AssertionError('Changed relocation semantics were accepted.')

    # A different build-directory string in non-allocated DWARF is legitimate.
    # Executable or initialized-data flags must never be accepted as debug data.
    directory=work/'nonallocated_debug';directory.mkdir()
    assembly=directory/'native.s';native=directory/'native.obj'
    annotated=directory/'annotated.s';marked=directory/'annotated.obj'
    c_source=directory/'original.c';c_source.write_text('void fixture(void) {}\n',encoding='ascii')
    text=prefix+'ret\n.section .debug_info\n.byte 1,2,3,4\n'
    assembly.write_text(text,encoding='ascii')
    subprocess.run([str(compiler),'-c','-x','assembler',str(assembly),'-o',str(native)],capture_output=True,check=True)
    annotated.write_text(module.annotate(text).replace('.byte 1,2,3,4','.byte 5,6,7,8'),encoding='ascii')
    subprocess.run([str(compiler),'-c','-x','assembler',str(annotated),'-o',str(marked)],capture_output=True,check=True)
    debug=module.prove(native,marked,assembly,annotated,c_source)
    assert '.debug_info' not in debug['allocatedSectionsCompared'];passed+=1
    blob=bytearray(marked.read_bytes());count=struct.unpack_from('<H',blob,2)[0]
    for i in range(count):
        at=20+40*i
        if blob[at:at+8].startswith(b'/') or blob[at:at+8].startswith(b'.debug'):
            flags=struct.unpack_from('<I',blob,at+36)[0]
            struct.pack_into('<I',blob,at+36,flags|0x20)
            break
    damaged=directory/'allocated-debug.obj';damaged.write_bytes(blob)
    try:module.prove(native,damaged,assembly,annotated,c_source)
    except ValueError:passed+=1
    else:raise AssertionError('Debug bytes promoted to executable CODE were accepted.')

    # Verify that proof metadata cannot change a range kind or source snapshot.
    proof=work/'verification-proof.json';index=work/'verification-index.json'
    source=Path(reference['source'])
    record=dict(reference)
    proof.write_text(json.dumps(record),encoding='utf-8')
    index.write_text(json.dumps({'pass':True,'failures':[],'proofs':[str(proof)]}),encoding='utf-8')
    command=[shutil.which('python'),'tools/coff-code-data.py','--verify-proof-index',str(index)]
    subprocess.run(command,cwd=ROOT,capture_output=True,check=True)
    passed+=1

    for c_source,handwritten in [(None,False),(source,True)]:
        try: module.prove(Path(reference['object']),Path(reference['annotatedObject']),Path(reference['compilerAssembly']),Path(reference['annotatedAssembly']),c_source,handwritten)
        except ValueError: passed+=1
        else: raise AssertionError('Missing or ambiguous source kind was accepted.')

    # Real GO32 function definitions often have COFF type zero. The original
    # C source must still prevent their entry bytes being waived as DATA.
    directory=work/'untyped_function';directory.mkdir()
    c_source=directory/'original.c';c_source.write_text('void fixture(void) {}\n',encoding='ascii')
    assembly=directory/'native.s';assembly.write_text('.text\n.globl _fixture\n_fixture:\n.byte 0x0f,0x45,0xc0\nret\n',encoding='ascii')
    native=directory/'native.obj';annotated=directory/'annotated.s';marked=directory/'annotated.obj'
    subprocess.run([str(compiler),'-c','-x','assembler',str(assembly),'-o',str(native)],capture_output=True,check=True)
    annotated.write_text(module.annotate(assembly.read_text(encoding='ascii')),encoding='ascii')
    subprocess.run([str(compiler),'-c','-x','assembler',str(annotated),'-o',str(marked)],capture_output=True,check=True)
    try: module.prove(native,marked,assembly,annotated,c_source)
    except ValueError: passed+=1
    else: raise AssertionError('A type-zero C function entry was waived as DATA.')
    tampered=json.loads(json.dumps(record));tampered['ranges'][0]['kind']='data'
    proof.write_text(json.dumps(tampered),encoding='utf-8')
    assert subprocess.run(command,cwd=ROOT,capture_output=True).returncode!=0
    passed+=1
    proof.write_text(json.dumps(record),encoding='utf-8');source.write_text('int different;\n',encoding='ascii')
    assert subprocess.run(command,cwd=ROOT,capture_output=True).returncode!=0
    passed+=1

    inline=records['inline_forbidden_bytes']
    inline_proof=work/'inline-proof.json';inline_proof.write_text(json.dumps(inline),encoding='utf-8')
    inline_index=work/'inline-index.json'
    inline_index.write_text(json.dumps({'pass':True,'failures':[],'proofs':[str(inline_proof)]}),encoding='utf-8')
    audit=work/'inline-audit.json'
    run=subprocess.run([shutil.which('pwsh'),'-NoProfile','-File',str(ROOT/'tools/isa-audit.ps1'),
        '-BuildRoot',str(work),'-ObjectRoot',str(Path(inline['object']).parent),'-SkipExecutable',
        '-MaxIsa','i486','-FailOnViolation','-ObjectCodeDataProofJson',str(inline_index),
        '-OutputJson',str(audit)],capture_output=True,text=True)
    (work/'inline-audit-output.txt').write_text(run.stdout+run.stderr,encoding='utf-8')
    assert run.returncode!=0 and audit.is_file(),'Inline CMOV audit did not reject with a report.'
    report=json.loads(audit.read_text(encoding='utf-8-sig'))
    assert report['violations'],'Inline .byte CMOV was hidden as data.'
    passed+=1
    print(f'PASS: {passed} exact boundary, control-flow and adversarial proof checks; {work}')


if __name__=='__main__': main()
