"""Exercise exact proof identity and complete, non-overlapping final mappings."""
from pathlib import Path
import argparse,atexit,contextlib,copy,gzip,hashlib,importlib.util,io,json,os,re,shutil,subprocess,tempfile

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
    def cleanup_work():
        output_root=(ROOT/'out').resolve()
        if (work.exists() and not work.is_symlink() and work.name.startswith('final-ranges-regression-')
                and work.resolve().parent==output_root):
            shutil.rmtree(work)
    atexit.register(cleanup_work)
    boundary=load_module('range_test_boundary',ROOT/'tools/coff-code-data.py')
    tool=load_module('range_test_tool',ROOT/'tools/final-executable-isa-ranges.py')
    assembly=work/'fixture.s';annotated=work/'annotated.s';native=work/'fixture.obj';marked=work/'annotated.obj'
    assembly.write_text('.text\n.globl _fixture\n_fixture:\nmovl $7,%eax\nret\n.p2align 2\nLconstant:\n.long 0xdeadbeef\n.section .rodata\nLrodata:\n.long 0x11223344\n.long Lconstant\n.long _external_target\n',encoding='ascii')
    annotated.write_text(boundary.annotate(assembly.read_text(encoding='ascii')),encoding='ascii')
    target_assembly=work/'target.s';target_annotated=work/'target-annotated.s'
    target_native=work/'target.obj';target_marked=work/'target-annotated.obj'
    target_assembly.write_text('.text\n.globl _external_target\n_external_target:\nmovl $1,%eax\nret\n',encoding='ascii')
    target_annotated.write_text(boundary.annotate(target_assembly.read_text(encoding='ascii')),encoding='ascii')
    for source,target in [(assembly,native),(annotated,marked),
                          (target_assembly,target_native),(target_annotated,target_marked)]:
        subprocess.run([str(compiler),'-c','-x','assembler',str(source),'-o',str(target)],capture_output=True,check=True)
    c_source=work/'original.c';c_source.write_text('int fixture(void) { return 7; }\n',encoding='ascii')
    proof=boundary.prove(native,marked,assembly,annotated,c_source)
    target_c_source=work/'target-original.c';target_c_source.write_text('int external_target(void) { return 1; }\n',encoding='ascii')
    target_proof=boundary.prove(target_native,target_marked,target_assembly,target_annotated,target_c_source)
    duplicate_native=work/'target-duplicate.obj';shutil.copyfile(target_native,duplicate_native)
    duplicate_proof=copy.deepcopy(target_proof);duplicate_proof['object']=str(duplicate_native.resolve())
    duplicate_proof_path=work/'target-duplicate-proof.json'
    proof_path=work/'proof.json';target_proof_path=work/'target-proof.json'
    index_path=work/'index.json';report_path=work/'linked.json'
    save(proof_path,proof);save(target_proof_path,target_proof)
    index={'pass':True,'failures':[],'proofs':[str(proof_path),str(target_proof_path)]};save(index_path,index)
    exe=work/'fixture.exe';mapping=work/'fixture.exe.map'
    subprocess.run([str(compiler),'-nostdlib','-Wl,-e,_fixture','-Wl,-Map='+str(mapping),
                    str(native),str(target_native),'-o',str(exe)],capture_output=True,check=True)
    detail_lines=''.join(json.dumps(dict(object=path.name,path=str(path)))+'\n'
                         for path in (native,target_native))
    details=work/'inputs.jsonl';details.write_text(detail_lines,encoding='utf-8')
    compressed_details=work/'inputs.jsonl.gz'
    with gzip.open(compressed_details,'wt',encoding='utf-8') as stream:stream.write(detail_lines)
    sections,_=boundary.coff(native)
    disassembler=load_module('range_test_disassembler',ROOT/'tools/isa-disassemble.py')
    map_text=mapping.read_text(encoding='latin1')
    output_text=re.search(r'^\.text\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s*$',map_text,re.M)
    assert output_text,'fixture link must expose its output .text bounds'
    def map_contribution(section_name,object_path):
        match=re.search(r'^\s+'+re.escape(section_name)+r'\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s+[^\n]*'+re.escape(object_path.name)+r'\s*$',map_text,re.M)
        assert match,'fixture link must map '+section_name+' from '+object_path.name
        return dict(object=object_path.name,section=section_name,address='0x'+match[1],size='0x'+match[2])
    contributions=[map_contribution('.text',native),map_contribution('.text',target_native),
                   map_contribution('.rodata',native)]
    text_address=int(output_text[1],16);text_size=int(output_text[2],16)
    rodata_contribution=next(item for item in contributions if item['section']=='.rodata')
    assert text_address<=int(contributions[0]['address'],16)<int(contributions[1]['address'],16)
    assert int(rodata_contribution['address'],16)+int(rodata_contribution['size'],16)<=text_address+text_size
    report={'pass':True,'sourceBoundCodeData':True,'executable':str(exe),'executableSha256':sha(exe),
            'linkerMap':str(mapping),'linkerMapSha256':sha(mapping),'executableFormat':'coff-go32',
            'executableText':{'address':'0x%x'%text_address,'size':'0x%x'%text_size},
            'linkedTextCoverage':{'continuous':True,'bytes':text_size},
            'instructionAudit':{'inputInstructionDetailsJsonl':str(details)},'textContributions':contributions}
    save(report_path,report)
    def check(name,record=report,proof_index=index,proof_record=proof,target_proof_record=target_proof):
        save(report_path,record);save(index_path,proof_index)
        save(proof_path,proof_record);save(target_proof_path,target_proof_record)
        save(duplicate_proof_path,duplicate_proof)
        args=argparse.Namespace(linked_report=report_path,proof_index=index_path,output=work/name)
        with contextlib.redirect_stdout(io.StringIO()):tool.build(args)
        return json.loads((args.output/'range-proof.json').read_text(encoding='utf-8'))
    valid=check('valid');assert valid['codeRanges']>=1 and valid['isaAuditRequired']
    valid_ranges=json.loads((work/'valid'/'isa-ranges.json').read_text(encoding='utf-8'))
    valid_data=json.loads((work/'valid'/'data-ranges.json').read_text(encoding='utf-8'))
    assert valid['dataRanges']==1 and valid['dataBytes']==sections['.rodata']['size']
    assert len(valid_data)==1 and valid_data[0]['section']=='.rodata'
    assert valid_data[0]['relocationsValidated']==len(sections['.rodata']['relocations'])==2
    assert valid_data[0]['sectionFlags']=='0x40'
    image_vma,image_bytes,_=disassembler.code_section(exe,'.text')
    image_offset=int(valid_data[0]['start'])-image_vma
    assert hashlib.sha256(image_bytes[image_offset:image_offset+valid_data[0]['end']-valid_data[0]['start']]).hexdigest().upper()==valid_data[0]['linkedBytesSha256']
    assert valid['codeRangesSha256']==sha(work/'valid'/'isa-ranges.json')
    assert valid['dataRangesSha256']==sha(work/'valid'/'data-ranges.json')
    rodata_start=int(rodata_contribution['address'],16);rodata_end=rodata_start+int(rodata_contribution['size'],16)
    assert all(item['end']<=rodata_start or item['start']>=rodata_end for item in valid_ranges)
    assert {item['kind'] for item in valid['sourceBoundContributions']}=={'code-section','data-section'}
    compressed_report=copy.deepcopy(report)
    compressed_report['instructionAudit']['inputInstructionDetailsJsonl']=str(compressed_details)
    valid_compressed=check('valid_compressed_details',record=compressed_report)
    assert valid_compressed['codeRanges']==valid['codeRanges'] and valid_compressed['isaAuditRequired']
    cases={}
    def changed(name,mutate):
        item=copy.deepcopy(report);mutate(item);cases[name]=(item,index,proof,target_proof)
    changed('failed_linked_report',lambda item:item.update({'pass':False}))
    changed('unbound_linked_report',lambda item:item.update(sourceBoundCodeData=False))
    changed('changed_executable_identity',lambda item:item.update(executableSha256='0'*64))
    changed('changed_map_identity',lambda item:item.update(linkerMapSha256='0'*64))
    changed('missing_object_proof',lambda item:item['textContributions'][0].update(object='unknown.obj'))
    changed('wrong_section',lambda item:item['textContributions'][0].update(section='.missing'))
    changed('wrong_section_size',lambda item:item['textContributions'][0].update(size=hex(sections['.text']['size']+1)))
    changed('wrong_data_address',lambda item:next(section for section in item['textContributions'] if section['section']=='.rodata').update(address=hex(int(next(section for section in item['textContributions'] if section['section']=='.rodata')['address'],0)+1)))
    changed('external_relocation_mapping_mismatch',lambda item:next(section for section in item['textContributions'] if section['object']==target_native.name and section['section']=='.text').update(address=hex(int(next(section for section in item['textContributions'] if section['object']==target_native.name and section['section']=='.text')['address'],0)+1)))
    changed('missing_external_target_mapping',lambda item:item.update(textContributions=[section for section in item['textContributions'] if not (section['object']==target_native.name and section['section']=='.text')]))
    changed('duplicated_contribution',lambda item:item['textContributions'].append(copy.deepcopy(item['textContributions'][0])))
    changed('overlapping_contributions',lambda item:item['textContributions'].append(dict(item['textContributions'][0],address='0x1001')))
    cases['duplicate_proof']=(report,dict(index,proofs=[str(proof_path),str(proof_path)]),proof,target_proof)
    cases['incomplete_proof_index']=(report,dict(index,**{'pass':False}),proof,target_proof)
    ambiguous_report=copy.deepcopy(report)
    ambiguous_report['textContributions'].append(dict(next(section for section in contributions if section['object']==target_native.name),object=duplicate_native.name))
    ambiguous_index=dict(index,proofs=[*index['proofs'],str(duplicate_proof_path)])
    cases['ambiguous_external_target']=(ambiguous_report,ambiguous_index,proof,target_proof)
    missing_rodata=copy.deepcopy(proof);missing_rodata['allocatedSectionsCompared'].remove('.rodata')
    cases['unproved_rodata_section']=(report,index,missing_rodata,target_proof)
    for name,field,value in [('forged_boundary_kind','kind','data'),('forged_boundary_mode','codeMode',16),('forged_boundary_gap','start',1)]:
        forged=copy.deepcopy(proof);forged['ranges'][0][field]=value;cases[name]=(report,index,forged,target_proof)
    rejected=[]
    expected_reasons={
        'ambiguous_external_target':'ambiguous external DATA relocation target',
        'external_relocation_mapping_mismatch':'Linked DATA relocation bytes do not match',
        'missing_external_target_mapping':'unresolved external DATA relocation target'}
    for name,(record,proof_index,proof_record,target_record) in cases.items():
        try:check(name,record,proof_index,proof_record,target_record)
        except (ValueError,subprocess.CalledProcessError) as error:
            reason=str(error)
            if name in expected_reasons and expected_reasons[name] not in reason:
                raise AssertionError('Wrong rejection for '+name+': '+reason)
            rejected.append(dict(name=name,reason=reason))
        else:raise AssertionError('Invalid final boundary evidence was accepted: '+name)
    save(work/'results.json',dict(passed=True,valid=2,rejected=rejected))
    shutil.rmtree(work)
    print(f'PASS: plain and gzip final boundary mappings plus {len(rejected)} adversarial rejections')
if __name__=='__main__':main()
