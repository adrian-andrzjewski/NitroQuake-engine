"""Map verified source CODE and DATA boundaries onto the linked .text image.

Every linked contribution needs a current exact native/source proof. The result
is fed to isa-audit.ps1 for independent decoding of the relocated executable,
including operands and ModRM bytes rather than only input opcode comparisons.
Proved non-code sections mapped into output .text are byte-bound separately and
never enter the CODE range list.
"""
from __future__ import annotations
import argparse,gzip,hashlib,importlib.util,json,subprocess,sys
from pathlib import Path


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def build(args):
    tool=Path(__file__).with_name('coff-code-data.py')
    subprocess.run([sys.executable,str(tool),'--verify-proof-index',str(args.proof_index)],check=True)
    load=lambda path:json.loads(path.read_text(encoding='utf-8-sig'))
    report=load(args.linked_report);index=load(args.proof_index)
    if not report.get('pass') or not report.get('sourceBoundCodeData'):
        raise ValueError('Independent linked decoding requires a passing source-bound linked audit.')
    exe=Path(report['executable']);mapping=Path(report['linkerMap'])
    if sha(exe)!=report['executableSha256'] or sha(mapping)!=report['linkerMapSha256']:
        raise ValueError('The executable or map changed after its linked audit.')
    coverage=report.get('linkedTextCoverage',{})
    if coverage.get('continuous') is not True:
        raise ValueError('The linked audit did not prove continuous output .text coverage.')
    text_vma,text_bytes,_=load_module('final_ranges_disassembler',Path(__file__).with_name('isa-disassemble.py')).code_section(exe,'.text')
    executable_text=report.get('executableText',{})
    if int(executable_text.get('address','-1'),0)!=text_vma or int(executable_text.get('size','-1'),0)!=len(text_bytes):
        raise ValueError('The linked report .text bounds do not match the executable CODE section.')
    if int(coverage.get('bytes',-1))!=len(text_bytes):
        raise ValueError('The linked report .text coverage byte count does not match the executable.')
    proofs={}
    for name in index['proofs']:
        proof=load(Path(name));key=Path(proof['object']).name.lower()
        if key in proofs:raise ValueError('Ambiguous duplicate native object proof: '+key)
        if proof.get('allocatedBytesAndRelocationsMatch') is not True:
            raise ValueError('Source proof does not bind allocated bytes and relocations: '+key)
        proofs[key]=proof
    inputs={}
    details=Path(report['instructionAudit']['inputInstructionDetailsJsonl'])
    if details.suffix.lower()=='.gz':
        detail_file=gzip.open(details,'rt',encoding='utf-8-sig')
    else:
        detail_file=details.open('r',encoding='utf-8-sig')
    with detail_file:
        for line in detail_file:
            item=json.loads(line);key=item['object'].lower();path=Path(item['path'])
            if key in inputs and inputs[key]!=path:raise ValueError('Ambiguous audited native object path.')
            inputs[key]=path
    spec=importlib.util.spec_from_file_location('final_ranges_coff',tool)
    coff=importlib.util.module_from_spec(spec);spec.loader.exec_module(coff)
    object_sections={};external_symbols={}
    contribution_objects={item['object'].lower() for item in report['textContributions']}
    for key in contribution_objects:
        if key not in proofs:raise ValueError('Linked object lacks a source CODE boundary proof: '+key)
        native=inputs.get(key,Path(proofs[key]['object']))
        if sha(native)!=proofs[key]['objectSha256']:
            raise ValueError('Source boundaries belong to a different audited native object: '+key)
        sections,symbols=coff.coff(native)
        section_name_by_number={value['number']:name for name,value in sections.items()}
        object_sections[key]=(native,sections,section_name_by_number)
        for symbol in symbols:
            # COFF external definitions are the only cross-object relocation
            # targets resolved here. Undefined, absolute, weak, or ambiguous
            # targets still fail closed below.
            if symbol['storage']==2 and symbol['section']>0:
                section_name=section_name_by_number.get(symbol['section'])
                if section_name is not None:
                    external_symbols.setdefault(symbol['name'],[]).append(
                        (key,section_name,symbol['value']))
    ranges=[];data_ranges=[];bound=[];mapped={};contribution_spans=[]
    for item in report['textContributions']:
        key=item['object'].lower();section_name=item['section'];contribution_key=(key,section_name)
        if contribution_key in mapped:raise ValueError('Duplicate mapped input section: '+key+':'+section_name)
        mapped[contribution_key]=dict(item,address=int(item['address'],0),size=int(item['size'],0))
    for item in report['textContributions']:
        key=item['object'].lower();size=int(item['size'],0);address=int(item['address'],0)
        if size<=0 or address<text_vma or address+size>text_vma+len(text_bytes):
            raise ValueError('Linked input contribution falls outside executable .text: '+key+':'+item['section'])
        if key not in proofs:raise ValueError('Linked object lacks a source CODE boundary proof: '+key)
        proof=proofs[key]
        native,sections,section_name_by_number=object_sections[key]
        if item['section'] not in sections or sections[item['section']]['size']!=size:
            raise ValueError('Mapped contribution size differs from the proved native section.')
        section_name=item['section'];section=sections[section_name]
        if section_name not in proof.get('allocatedSectionsCompared',[]):
            raise ValueError('Mapped section is absent from the source proof allocated-section set: '+key+':'+section_name)
        contribution_spans.append((address,address+size,key+':'+section_name))
        classified=sorted([x for x in proof['ranges'] if x['section']==item['section']],key=lambda x:x['start'])
        section_class=section['flags']&0xe0
        if section_name.startswith('.text'):
            if section_class!=0x20:
                raise ValueError('A proved CODE section lacks COFF STYP_TEXT characteristics: '+key+':'+section_name)
            cursor=0
            for source in classified:
                if source['start']!=cursor or source['end']<=cursor or source['end']>size:
                    raise ValueError('Source boundaries do not continuously cover a mapped section: '+key)
                cursor=source['end']
                if source['kind']=='code':
                    ranges.append(dict(start=address+source['start'],end=address+source['end'],
                        codeMode=source['codeMode'],label=key+':'+section_name,object=item['object'],
                        sourceProofObjectSha256=proof['objectSha256']))
                elif source['kind']!='data':raise ValueError('Unrecognized source boundary kind.')
            if cursor!=size:raise ValueError('Unproved bytes in a linked input section: '+key)
            bound.append(dict(kind='code-section',object=item['object'],section=section_name,address=address,size=size,
                objectSha256=proof['objectSha256'],sectionFlags=hex(section['flags'])))
            continue

        # A non-.text contribution is accepted only as initialized COFF DATA.
        # The verified proof binds its allocated bytes and relocations even
        # though it intentionally emits no instruction-boundary ranges for it.
        if section_class!=0x40 or len(section['bytes'])!=size:
            raise ValueError('A non-CODE contribution must be a complete initialized STYP_DATA section: '+key+':'+section_name)
        if classified:
            raise ValueError('A non-CODE contribution must not carry instruction-boundary ranges: '+key+':'+section_name)
        text_offset=address-text_vma
        linked_slice=text_bytes[text_offset:text_offset+size]
        expected=bytearray(section['bytes']);relocation_bytes=set()
        for offset,relocation_type,target_name,target_value,target_section_number in section['relocations']:
            # DATA pointers in the supported GO32 objects use DIR32 (IMAGE_REL_I386_DIR32).
            # Resolve local section symbols directly and external symbols only
            # through one unique, source-proved global definition. Other
            # relocation forms fail closed.
            if relocation_type!=6 or offset<0 or offset+4>size:
                raise ValueError('Unsupported or out-of-range relocation in mapped DATA section: '+key+':'+section_name)
            target_section=section_name_by_number.get(target_section_number)
            target_key=key
            resolved_value=target_value
            if target_section_number==0:
                definitions=external_symbols.get(target_name,[])
                if len(definitions)!=1:
                    reason='unresolved' if not definitions else 'ambiguous'
                    raise ValueError(reason+' external DATA relocation target: '+key+':'+str(target_name))
                target_key,target_section,symbol_value=definitions[0]
                resolved_value=symbol_value+target_value
            elif target_section_number<0:
                target_section=None
            target_contribution=mapped.get((target_key,target_section)) if target_section else None
            if target_contribution is None:
                raise ValueError('DATA relocation target has no exact linked section mapping: '+key+':'+str(target_name))
            if resolved_value<0 or resolved_value>target_contribution['size']:
                raise ValueError('DATA relocation target offset exceeds its mapped section: '+key+':'+str(target_name))
            width_offsets=set(range(offset,offset+4))
            if relocation_bytes & width_offsets:
                raise ValueError('Overlapping DATA relocation fields: '+key+':'+section_name)
            relocation_bytes.update(width_offsets)
            addend=int.from_bytes(section['bytes'][offset:offset+4],'little',signed=False)
            relocated=(target_contribution['address']+resolved_value+addend)&0xffffffff
            expected[offset:offset+4]=relocated.to_bytes(4,'little')
            actual=int.from_bytes(linked_slice[offset:offset+4],'little',signed=False)
            if actual!=relocated:
                raise ValueError('Linked DATA relocation bytes do not match the proved target mapping: '+key+':'+section_name)
        if any(expected[i]!=linked_slice[i] for i in range(size) if i not in relocation_bytes):
            raise ValueError('Linked DATA bytes differ from the proved source section: '+key+':'+section_name)
        source_digest=hashlib.sha256(section['bytes']).hexdigest().upper()
        linked_digest=hashlib.sha256(linked_slice).hexdigest().upper()
        data_ranges.append(dict(start=address,end=address+size,label=key+':'+section_name,object=item['object'],
            section=section_name,sectionFlags=hex(section['flags']),sourceBytesSha256=source_digest,
            linkedBytesSha256=linked_digest,relocationsValidated=len(section['relocations'])))
        bound.append(dict(kind='data-section',object=item['object'],section=section_name,address=address,size=size,
            objectSha256=proof['objectSha256'],sectionFlags=hex(section['flags']),sourceBytesSha256=source_digest,
            linkedBytesSha256=linked_digest,relocationsValidated=len(section['relocations'])))
    contribution_spans.sort()
    for left,right in zip(contribution_spans,contribution_spans[1:]):
        if left[1]>right[0]:raise ValueError('Mapped linked input contributions overlap: '+left[2]+' / '+right[2])
    ranges.sort(key=lambda x:(x['start'],x['end']))
    for left,right in zip(ranges,ranges[1:]):
        if left['end']>right['start']:raise ValueError('Mapped final CODE ranges overlap.')
    args.output.mkdir(parents=True,exist_ok=False)
    code_range_path=args.output/'isa-ranges.json';data_range_path=args.output/'data-ranges.json'
    code_range_path.write_text(json.dumps(ranges,indent=2)+'\n',encoding='utf-8')
    data_range_path.write_text(json.dumps(data_ranges,indent=2)+'\n',encoding='utf-8')
    (args.output/'range-proof.json').write_text(json.dumps(dict(schemaVersion=2,executable=str(exe),executableSha256=sha(exe),
        linkerMapSha256=sha(mapping),linkedReport=str(args.linked_report.resolve()),linkedReportSha256=sha(args.linked_report),
        proofIndexSha256=sha(args.proof_index),sourceBoundContributions=bound,codeRanges=len(ranges),
        codeBytes=sum(x['end']-x['start'] for x in ranges),dataRanges=len(data_ranges),
        dataBytes=sum(x['end']-x['start'] for x in data_ranges),dataRangeFile='data-ranges.json',
        codeRangesSha256=sha(code_range_path),dataRangesSha256=sha(data_range_path),
        isaAuditRequired=True,policySha256=sha(Path(__file__))),indent=2)+'\n',encoding='utf-8')
    print(f'Final mapping PASS: {len(bound)} source-bound contributions; {len(ranges)} CODE ranges and {len(data_ranges)} DATA ranges; only CODE ranges require ISA decoding.')


def load_module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    if spec is None or spec.loader is None:raise ValueError('Unable to load verification helper: '+str(path))
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('linked-report','proof-index','output'):parser.add_argument('--'+name,type=Path,required=True)
    build(parser.parse_args())


if __name__=='__main__':main()
