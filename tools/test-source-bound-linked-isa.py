"""Test the linked ISA gate with genuine minimal GO32 binaries and bad inputs."""
from pathlib import Path
import hashlib,importlib.util,json,os,re,struct,subprocess,tempfile

ROOT=Path(__file__).resolve().parents[1]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def main():
    config=json.loads((ROOT/'tools/dos-toolchain.json').read_text(encoding='utf-8'))
    compiler=Path(os.environ['LOCALAPPDATA'])/'486quake/tools'/config['djgpp']['installDirectory']/config['djgpp']['compiler']
    spec=importlib.util.spec_from_file_location('linked_boundary_test',ROOT/'tools/coff-code-data.py')
    boundary=importlib.util.module_from_spec(spec);spec.loader.exec_module(boundary)
    work=Path(tempfile.mkdtemp(prefix='source-linked-regression-',dir=ROOT/'out'))
    def fixture(name,instructions):
        directory=work/name;directory.mkdir()
        native=directory/'fixture.obj';assembly=directory/'fixture.s';annotated=directory/'annotated.s';marked=directory/'annotated.obj'
        source=directory/'original.c';source.write_text('int fixture(void) { return 7; }\n',encoding='ascii')
        assembly.write_text('.text\n.globl _fixture\n_fixture:\n'+instructions+'\nret\n.p2align 2\nLliteral:\n.long 0x00c0450f\n',encoding='ascii')
        annotated.write_text(boundary.annotate(assembly.read_text(encoding='ascii')),encoding='ascii')
        for a,b in [(assembly,native),(annotated,marked)]:
            subprocess.run([str(compiler),'-c','-x','assembler',str(a),'-o',str(b)],capture_output=True,check=True)
        proof=boundary.prove(native,marked,assembly,annotated,source)
        proof_path=directory/'proof.json';proof_path.write_text(json.dumps(proof),encoding='utf-8')
        index=directory/'proof-index.json';index.write_text(json.dumps({'pass':True,'failures':[],'proofs':[str(proof_path)]}),encoding='utf-8')
        exe=directory/'fixture.exe';mapping=directory/'fixture.exe.map'
        subprocess.run([str(compiler),'-nostdlib','-Wl,-e,_fixture','-Wl,-Map='+str(mapping),str(native),'-o',str(exe)],capture_output=True,check=True)
        return directory,native,index,exe,mapping
    good=fixture('good','movl $7,%eax\nbswap %eax')
    bad=fixture('post486','cmovz %ebx,%eax')
    encoded=fixture('encoded_post486','#APP\n.byte 0x0f,0x45,0xc3\n#NO_APP')
    records=[]
    def audit(name,inputs,expected,extra=()):
        directory,native,index,exe,mapping=inputs;report=work/('audit-'+name)
        command=['pwsh','-NoProfile','-File',str(ROOT/'tools/isa-audit-linked.ps1'),'-BuildRoot',str(directory),
                 '-ExecutableName',exe.name,'-MapPath',str(mapping),'-ObjectRoot',str(directory),'-ObjectNames',native.name,
                 '-ObjectCodeDataProofJson',str(index),'-ReportRoot',str(report),*extra]
        process=subprocess.run(command,capture_output=True,text=True)
        (work/(name+'.txt')).write_text(process.stdout+process.stderr,encoding='utf-8')
        assert (process.returncode==0)==expected,(name,process.stdout[-1500:],process.stderr[-1500:])
        if expected:
            result=json.loads((report/'isa-audit-linked.json').read_text(encoding='utf-8-sig'))
            assert result['sourceBoundCodeData'] and not result['instructionAudit']['inputExempted']
            assert result['instructionAudit']['linkedInstructionsVerified']>0
        records.append(dict(name=name,passed=expected,rejected=not expected))
    audit('exact_i486_and_literal_data',good,True)
    audit('post486_object',bad,False)
    audit('post486_inline_bytes',encoded,False)
    audit('instruction_exemption_forbidden',good,False,['-Exempt','fixture.obj:_fixture:1'])
    audit('range_exemption_forbidden',good,False,['-ExemptRange','fixture.obj:.text:0:1'])
    directory,native,index,exe,mapping=good
    original_exe=exe.read_bytes();original_map=mapping.read_text(encoding='latin1');original_object=native.read_bytes()
    last,pages=struct.unpack_from('<HH',original_exe,2);base=pages*512-(512-last if last else 0)
    count=struct.unpack_from('<H',original_exe,base+2)[0];optional=struct.unpack_from('<H',original_exe,base+16)[0]
    match=re.search(r'^\s+\.text\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s+[^\n]*fixture\.obj\s*$',original_map,re.M);assert match
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
    blob=bytearray(original_object);sections,_=boundary.coff(native)
    raw=struct.unpack_from('<I',blob,20+20)[0];blob[raw]^=1;native.write_bytes(blob)
    audit('changed_native_object',good,False);native.write_bytes(original_object)
    assert exe.read_bytes()==original_exe and mapping.read_text(encoding='latin1')==original_map and native.read_bytes()==original_object
    (work/'results.json').write_text(json.dumps(dict(passed=True,tests=records),indent=2)+'\n',encoding='utf-8')
    print(f'PASS: {len(records)} source-bound linked binary checks; {work}')
if __name__=='__main__':main()
