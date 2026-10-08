"""Map verified source CODE boundaries onto the actual linked instruction bytes.

Every linked contribution needs a current exact native/source proof. The result
is fed to isa-audit.ps1 for independent decoding of the relocated executable,
including operands and ModRM bytes rather than only input opcode comparisons.
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
    proofs={}
    for name in index['proofs']:
        proof=load(Path(name));key=Path(proof['object']).name.lower()
        if key in proofs:raise ValueError('Ambiguous duplicate native object proof: '+key)
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
    ranges=[];bound=[]
    for item in report['textContributions']:
        key=item['object'].lower();size=int(item['size'],0);address=int(item['address'],0)
        if key not in proofs:raise ValueError('Linked object lacks a source CODE boundary proof: '+key)
        proof=proofs[key]
        native=inputs.get(key,Path(proof['object']))
        if sha(native)!=proof['objectSha256']:raise ValueError('Source boundaries belong to a different audited native object: '+key)
        sections,_=coff.coff(native)
        if item['section'] not in sections or sections[item['section']]['size']!=size:
            raise ValueError('Mapped contribution size differs from the proved native section.')
        classified=sorted([x for x in proof['ranges'] if x['section']==item['section']],key=lambda x:x['start'])
        cursor=0
        for source in classified:
            if source['start']!=cursor or source['end']<=cursor or source['end']>size:
                raise ValueError('Source boundaries do not continuously cover a mapped section: '+key)
            cursor=source['end']
            if source['kind']=='code':
                ranges.append(dict(start=address+source['start'],end=address+source['end'],
                    codeMode=source['codeMode'],label=key+':'+item['section'],object=item['object'],
                    sourceProofObjectSha256=proof['objectSha256']))
            elif source['kind']!='data':raise ValueError('Unrecognized source boundary kind.')
        if cursor!=size:raise ValueError('Unproved bytes in a linked input section: '+key)
        bound.append(dict(object=item['object'],section=item['section'],address=address,size=size,objectSha256=proof['objectSha256']))
    ranges.sort(key=lambda x:(x['start'],x['end']))
    for left,right in zip(ranges,ranges[1:]):
        if left['end']>right['start']:raise ValueError('Mapped final CODE ranges overlap.')
    args.output.mkdir(parents=True,exist_ok=False)
    (args.output/'isa-ranges.json').write_text(json.dumps(ranges,indent=2)+'\n',encoding='utf-8')
    (args.output/'range-proof.json').write_text(json.dumps(dict(schemaVersion=1,executable=str(exe),executableSha256=sha(exe),
        linkerMapSha256=sha(mapping),linkedReport=str(args.linked_report.resolve()),linkedReportSha256=sha(args.linked_report),
        proofIndexSha256=sha(args.proof_index),sourceBoundContributions=bound,codeRanges=len(ranges),
        codeBytes=sum(x['end']-x['start'] for x in ranges),isaAuditRequired=True,policySha256=sha(Path(__file__))),indent=2)+'\n',encoding='utf-8')
    print(f'Final CODE mapping PASS: {len(bound)} source-bound contributions; {len(ranges)} ranges require relocated-byte ISA auditing.')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('linked-report','proof-index','output'):parser.add_argument('--'+name,type=Path,required=True)
    build(parser.parse_args())


if __name__=='__main__':main()
