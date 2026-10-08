"""Exercise exact proof identity and complete, non-overlapping final mappings."""
from pathlib import Path
import argparse,contextlib,copy,gzip,hashlib,importlib.util,io,json,os,shutil,subprocess,tempfile

ROOT=Path(__file__).resolve().parents[1]
def load_module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def save(path,value):path.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')

def main():
    manifest=json.loads((ROOT/'tools/dos-toolchain.json').read_text(encoding='utf-8'))
    compiler=Path(os.environ['LOCALAPPDATA'])/'486quake/tools'/manifest['djgpp']['installDirectory']/manifest['djgpp']['compiler']
    work=Path(tempfile.mkdtemp(prefix='final-ranges-regression-',dir=ROOT/'out'))
    boundary=load_module('range_test_boundary',ROOT/'tools/coff-code-data.py')
    tool=load_module('range_test_tool',ROOT/'tools/final-executable-isa-ranges.py')
    assembly=work/'fixture.s';annotated=work/'annotated.s';native=work/'fixture.obj';marked=work/'annotated.obj'
    assembly.write_text('.text\n.globl _fixture\n_fixture:\nmovl $7,%eax\nret\n.p2align 2\nLconstant:\n.long 0xdeadbeef\n',encoding='ascii')
    annotated.write_text(boundary.annotate(assembly.read_text(encoding='ascii')),encoding='ascii')
    for source,target in [(assembly,native),(annotated,marked)]:
        subprocess.run([str(compiler),'-c','-x','assembler',str(source),'-o',str(target)],capture_output=True,check=True)
    c_source=work/'original.c';c_source.write_text('int fixture(void) { return 7; }\n',encoding='ascii')
    proof=boundary.prove(native,marked,assembly,annotated,c_source)
    proof_path=work/'proof.json';index_path=work/'index.json';report_path=work/'linked.json'
    save(proof_path,proof);index={'pass':True,'failures':[],'proofs':[str(proof_path)]};save(index_path,index)
    exe=work/'fixture.exe';exe.write_bytes(b'executable byte identity for mapping test')
    mapping=work/'fixture.map';mapping.write_text('unit mapping fixture\n',encoding='ascii')
    detail_line=json.dumps(dict(object=native.name,path=str(native)))+'\n'
    details=work/'inputs.jsonl';details.write_text(detail_line,encoding='utf-8')
    compressed_details=work/'inputs.jsonl.gz'
    with gzip.open(compressed_details,'wt',encoding='utf-8') as stream:stream.write(detail_line)
    sections,_=boundary.coff(native);size=sections['.text']['size']
    report={'pass':True,'sourceBoundCodeData':True,'executable':str(exe),'executableSha256':sha(exe),
            'linkerMap':str(mapping),'linkerMapSha256':sha(mapping),'instructionAudit':{'inputInstructionDetailsJsonl':str(details)},
            'textContributions':[dict(object=native.name,section='.text',address='0x1000',size=hex(size))]}
    save(report_path,report)
    def check(name,record=report,proof_index=index,proof_record=proof):
        save(report_path,record);save(index_path,proof_index);save(proof_path,proof_record)
        args=argparse.Namespace(linked_report=report_path,proof_index=index_path,output=work/name)
        with contextlib.redirect_stdout(io.StringIO()):tool.build(args)
        return json.loads((args.output/'range-proof.json').read_text(encoding='utf-8'))
    valid=check('valid');assert valid['codeRanges']>=1 and valid['isaAuditRequired']
    compressed_report=copy.deepcopy(report)
    compressed_report['instructionAudit']['inputInstructionDetailsJsonl']=str(compressed_details)
    valid_compressed=check('valid_compressed_details',record=compressed_report)
    assert valid_compressed['codeRanges']==valid['codeRanges'] and valid_compressed['isaAuditRequired']
    cases={}
    def changed(name,mutate):
        item=copy.deepcopy(report);mutate(item);cases[name]=(item,index,proof)
    changed('failed_linked_report',lambda item:item.update({'pass':False}))
    changed('unbound_linked_report',lambda item:item.update(sourceBoundCodeData=False))
    changed('changed_executable_identity',lambda item:item.update(executableSha256='0'*64))
    changed('changed_map_identity',lambda item:item.update(linkerMapSha256='0'*64))
    changed('missing_object_proof',lambda item:item['textContributions'][0].update(object='unknown.obj'))
    changed('wrong_section',lambda item:item['textContributions'][0].update(section='.missing'))
    changed('wrong_section_size',lambda item:item['textContributions'][0].update(size=hex(size+1)))
    changed('duplicated_contribution',lambda item:item['textContributions'].append(copy.deepcopy(item['textContributions'][0])))
    changed('overlapping_contributions',lambda item:item['textContributions'].append(dict(item['textContributions'][0],address='0x1001')))
    cases['duplicate_proof']=(report,dict(index,proofs=[str(proof_path),str(proof_path)]),proof)
    cases['incomplete_proof_index']=(report,dict(index,**{'pass':False}),proof)
    for name,field,value in [('forged_boundary_kind','kind','data'),('forged_boundary_mode','codeMode',16),('forged_boundary_gap','start',1)]:
        forged=copy.deepcopy(proof);forged['ranges'][0][field]=value;cases[name]=(report,index,forged)
    rejected=[]
    for name,(record,proof_index,proof_record) in cases.items():
        try:check(name,record,proof_index,proof_record)
        except (ValueError,subprocess.CalledProcessError) as error:rejected.append(dict(name=name,reason=str(error)))
        else:raise AssertionError('Invalid final boundary evidence was accepted: '+name)
    save(work/'results.json',dict(passed=True,valid=2,rejected=rejected))
    shutil.rmtree(work)
    print(f'PASS: plain and gzip final boundary mappings plus {len(rejected)} adversarial rejections')
if __name__=='__main__':main()
