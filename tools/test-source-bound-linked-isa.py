"""Test the linked ISA gate with genuine minimal GO32 binaries and bad inputs."""
from pathlib import Path
import atexit
import hashlib,importlib.util,json,os,re,struct,subprocess,tempfile
import shutil

ROOT=Path(__file__).resolve().parents[1]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def main():
    config=json.loads((ROOT/'tools/dos-toolchain.json').read_text(encoding='utf-8'))
    compiler=Path(os.environ['LOCALAPPDATA'])/'486quake/tools'/config['djgpp']['installDirectory']/config['djgpp']['compiler']
    spec=importlib.util.spec_from_file_location('linked_boundary_test',ROOT/'tools/coff-code-data.py')
    boundary=importlib.util.module_from_spec(spec);spec.loader.exec_module(boundary)
    work=Path(tempfile.mkdtemp(prefix='source-linked-regression-',dir=ROOT/'out'))
    retained_run_ids=set()
    def cleanup_work():
        output_root=(ROOT/'out').resolve()
        if (work.exists() and not work.is_symlink() and work.name.startswith('source-linked-regression-')
                and work.resolve().parent==output_root):
            shutil.rmtree(work)
    atexit.register(cleanup_work)
    def fixture(name,instructions,cold_instructions=None):
        directory=work/name;directory.mkdir()
        native=directory/'fixture.obj';assembly=directory/'fixture.s';annotated=directory/'annotated.s';marked=directory/'annotated.obj'
        source=directory/'original.c';source.write_text('int fixture(void) { return 7; }\nint cold_fixture(void) { return 9; }\n',encoding='ascii')
        cold=''
        if cold_instructions is not None:
            cold=('.section .text.unlikely,"ax"\n.p2align 4\n.globl _cold_fixture\n'
                  '_cold_fixture:\n'+cold_instructions+'\nret\n')
        assembly.write_text('.text\n.globl _fixture\n_fixture:\n'+instructions+'\nret\n.p2align 2\nLliteral:\n.long 0x00c0450f\n'+cold,encoding='ascii')
        annotated.write_text(boundary.annotate(assembly.read_text(encoding='ascii')),encoding='ascii')
        for a,b in [(assembly,native),(annotated,marked)]:
            subprocess.run([str(compiler),'-c','-x','assembler',str(a),'-o',str(b)],capture_output=True,check=True)
        proof=boundary.prove(native,marked,assembly,annotated,source)
        proof_path=directory/'proof.json';proof_path.write_text(json.dumps(proof),encoding='utf-8')
        index=directory/'proof-index.json';index.write_text(json.dumps({'pass':True,'failures':[],'proofs':[str(proof_path)]}),encoding='utf-8')
        exe=directory/'fixture.exe';mapping=directory/'fixture.exe.map'
        subprocess.run([str(compiler),'-nostdlib','-Wl,-e,_fixture','-Wl,-Map='+str(mapping),str(native),'-o',str(exe)],capture_output=True,check=True)
        return directory,native,index,exe,mapping
    good=fixture('good','movl $7,%eax\nbswap %eax','movl $9,%eax')
    bad=fixture('post486','cmovz %ebx,%eax')
    cold_bad=fixture('cold_post486','movl $7,%eax','cmovz %ebx,%eax')
    encoded=fixture('encoded_post486','#APP\n.byte 0x0f,0x45,0xc3\n#NO_APP')
    records=[]
    def audit(name,inputs,expected,extra=(),failure_contains=None,hold_report_lock=False,expect_rejected_details=False):
        directory,native,index,exe,mapping=inputs;report=work/('audit-'+name)
        lock_handle=None
        if hold_report_lock:
            report.mkdir(parents=True,exist_ok=True)
            lock_handle=(report/'.isa-audit-linked.lock').open('a+b')
        command=['pwsh','-NoProfile','-File',str(ROOT/'tools/isa-audit-linked.ps1'),'-BuildRoot',str(directory),
                 '-ExecutableName',exe.name,'-MapPath',str(mapping),'-ObjectRoot',str(directory),'-ObjectNames',native.name,
                 '-ObjectCodeDataProofJson',str(index),'-ReportRoot',str(report),'-ScratchRoot',str(work/'audit-scratch'),*extra]
        try:
            process=subprocess.run(command,capture_output=True,text=True)
        finally:
            if lock_handle is not None:lock_handle.close()
        combined=process.stdout+process.stderr
        (work/(name+'.txt')).write_text(combined,encoding='utf-8')
        assert (process.returncode==0)==expected,(name,process.stdout[-1500:],process.stderr[-1500:])
        scratch=work/'audit-scratch'
        assert not list(scratch.glob('isa-archive-extract-*')),(name,'linked ISA audit left archive extraction data')
        assert not list(scratch.glob('isa-linked-inputs-*')),(name,'linked ISA audit left retained proof inputs in transient scratch')
        input_roots=list(report.glob('isa-linked-inputs-*'))
        if hold_report_lock:
            assert not input_roots,(name,'locked report root was modified before the audit failed',input_roots)
        else:
            assert len(input_roots)==1 and input_roots[0].is_dir(),(name,'linked ISA audit did not retain its report-bound input objects',input_roots)
            input_root=input_roots[0].resolve()
            match=re.fullmatch(r'isa-linked-inputs-\d{8}-\d{9}-([0-9a-f]{32})',input_roots[0].name)
            assert match,(name,'linked ISA input directory lacks a GUID-unique run id',input_roots[0].name)
            assert match.group(1) not in retained_run_ids,(name,'linked ISA run id collided',match.group(1))
            retained_run_ids.add(match.group(1))
            assert list(input_root.glob('*.obj')),(name,'linked ISA report retained no copied input objects')
        if failure_contains is not None:
            assert failure_contains in combined,(name,'missing expected diagnostic',failure_contains,combined[-2000:])
        if expected:
            result=json.loads((report/'isa-audit-linked.json').read_text(encoding='utf-8-sig'))
            assert result['sourceBoundCodeData'] and not result['instructionAudit']['inputExempted']
            assert result['instructionAudit']['linkedInstructionsVerified']>0
            assert result['linkedTextCoverage']['continuous']
            assert result['linkedTextCoverage']['bytes']==int(result['executableText']['size'],16)
            object_audit=Path(result['instructionAudit']['inputObjectAudit'])
            detail_path=Path(result['instructionAudit']['inputInstructionDetailsJsonl'])
            assert object_audit.is_file() and detail_path.is_file(),(name,'linked ISA report points to missing audit artifacts',object_audit,detail_path)
            details=[json.loads(line) for line in detail_path.read_text(encoding='utf-8').splitlines() if line]
            assert details,(name,'passing linked ISA report has no per-instruction evidence')
            for detail in details:
                object_path=Path(detail['path'])
                assert object_path.is_file(),(name,'per-instruction evidence references a missing object',object_path)
                assert object_path.resolve().is_relative_to(input_root),(name,'per-instruction object is outside retained report inputs',object_path,input_root)
        elif not hold_report_lock:
            # Rejected ISA audits also persist their disassembly before raising.
            # Validate every path they wrote instead of checking only PASS runs.
            detail_path=report/'isa-audit-linked-instructions.jsonl'
            if detail_path.is_file():
                details=[json.loads(line) for line in detail_path.read_text(encoding='utf-8').splitlines() if line]
                for detail in details:
                    object_path=Path(detail['path'])
                    assert object_path.is_file(),(name,'rejected audit evidence references a missing object',object_path)
                    assert object_path.resolve().is_relative_to(input_root),(name,'rejected audit object is outside retained report inputs',object_path,input_root)
                if expect_rejected_details:
                    assert details,(name,'rejected linked ISA audit emitted an empty instruction evidence file')
            elif expect_rejected_details:
                raise AssertionError((name,'rejected linked ISA audit did not persist its instruction evidence file',detail_path))
        records.append(dict(name=name,passed=expected,rejected=not expected))
    audit('exact_i486_and_literal_data',good,True)
    good_report=json.loads((work/'audit-exact_i486_and_literal_data'/'isa-audit-linked.json').read_text(encoding='utf-8-sig'))
    assert any(item['section']=='.text.unlikely' for item in good_report['textContributions'])
    assert good_report['textFillSpans']
    audit('post486_object',bad,False,expect_rejected_details=True)
    audit('post486_wrapped_text_unlikely',cold_bad,False)
    audit('post486_inline_bytes',encoded,False)
    audit('instruction_exemption_forbidden',good,False,['-Exempt','fixture.obj:_fixture:1'])
    audit('range_exemption_forbidden',good,False,['-ExemptRange','fixture.obj:.text:0:1'])
    audit('report_root_locked',good,False,failure_contains='Another linked ISA audit is using ReportRoot',hold_report_lock=True)
    directory,native,index,exe,mapping=good
    original_exe=exe.read_bytes();original_map=mapping.read_text(encoding='latin1');original_object=native.read_bytes()
    last,pages=struct.unpack_from('<HH',original_exe,2);base=pages*512-(512-last if last else 0)
    count=struct.unpack_from('<H',original_exe,base+2)[0];optional=struct.unpack_from('<H',original_exe,base+16)[0]
    match=re.search(r'^\s+\.text\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s+[^\n]*fixture\.obj\s*$',original_map,re.M);assert match
    output_text=re.search(r'^\.text\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s*$',original_map,re.M);assert output_text
    output_start=int(output_text[1],16);output_end=output_start+int(output_text[2],16)
    fills=[]
    for fill in re.finditer(r'^\s+\*fill\*\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s*$',original_map,re.M):
        address,size=int(fill[1],16),int(fill[2],16)
        if size>=3 and output_start<=address and address+size<=output_end:
            fills.append((address,size,fill[0]))
    assert fills, 'fixture must produce at least three linker-fill bytes inside output .text'
    text_offset=None
    for i in range(count):
        at=base+20+optional+40*i
        if original_exe[at:at+8].split(b'\0',1)[0]==b'.text':
            text_offset=base+struct.unpack_from('<I',original_exe,at+20)[0]+int(match[1],16)-struct.unpack_from('<I',original_exe,at+12)[0]
    assert text_offset is not None
    blob=bytearray(original_exe);blob[text_offset]^=1;exe.write_bytes(blob)
    audit('linked_opcode_changed',good,False);exe.write_bytes(original_exe)
    line=match[0]
    mapping.write_text(original_map.replace(line,line+'\n'+line,1),encoding='latin1',newline='')
    audit('duplicate_map_contribution',good,False);mapping.write_text(original_map,encoding='latin1',newline='')
    mapping.write_text(original_map.replace(line,line.replace('0x'+match[2],'0x'+f'{int(match[2],16)+1:x}',1),1),encoding='latin1',newline='')
    audit('wrong_map_contribution_size',good,False);mapping.write_text(original_map,encoding='latin1',newline='')
    fill_address,fill_size,fill_line=fills[0]
    blob=bytearray(original_exe)
    fill_offset=None
    for i in range(count):
        at=base+20+optional+40*i
        if original_exe[at:at+8].split(b'\0',1)[0]==b'.text':
            fill_offset=(base+struct.unpack_from('<I',original_exe,at+20)[0]
                         +fill_address-struct.unpack_from('<I',original_exe,at+12)[0])
    assert fill_offset is not None and fill_offset+3<=len(blob)
    blob[fill_offset:fill_offset+3]=bytes.fromhex('0f45c3');exe.write_bytes(blob)
    audit('forbidden_opcode_in_linker_fill',good,False,failure_contains='outside the documented 486-safe 66 90 policy')
    exe.write_bytes(original_exe)
    mapping.write_text(original_map.replace(fill_line,'',1),encoding='latin1',newline='')
    audit('missing_linker_fill_map_span',good,False,failure_contains='Unmapped executable .text')
    mapping.write_text(original_map,encoding='latin1',newline='')
    blob=bytearray(original_object);sections,_=boundary.coff(native)
    raw=struct.unpack_from('<I',blob,20+20)[0];blob[raw]^=1;native.write_bytes(blob)
    audit('changed_native_object',good,False);native.write_bytes(original_object)
    assert exe.read_bytes()==original_exe and mapping.read_text(encoding='latin1')==original_map and native.read_bytes()==original_object
    (work/'results.json').write_text(json.dumps(dict(passed=True,tests=records),indent=2)+'\n',encoding='utf-8')
    print(f'PASS: {len(records)} source-bound linked binary checks; temporary fixture removed at exit')
if __name__=='__main__':main()
