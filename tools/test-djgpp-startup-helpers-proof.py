"""Adversarial tests for executable code embedded in CRT .data."""
from pathlib import Path
import argparse,copy,importlib.util,json,shutil,struct,tempfile
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('helpers',root/'tools/djgpp-startup-helpers-proof.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ['object','archive','djasm','objdump']:
        parser.add_argument('--'+name,type=Path,required=True)
    args=parser.parse_args()
    work=Path(tempfile.mkdtemp(prefix='startup-helpers-regression-',dir=root/'out'))
    native=args.object
    arguments=argparse.Namespace(archive=args.archive,
        object=native,djasm=args.djasm,objdump=args.objdump,
        output=work/'valid',quiet=True)
    record=module.build(arguments)
    verifier=copy.copy(arguments);verifier.verify_proof=arguments.output/'boundary-proof.json'
    module.verify(verifier);checks=['valid rebuild','valid fresh verification']
    def reject(name,call):
        try:call()
        except (ValueError,FileNotFoundError,KeyError,struct.error) as error:
            (work/(name+'.rejection.txt')).write_text(str(error)+'\n',encoding='utf-8');checks.append(name)
        else:raise AssertionError('Invalid embedded-code evidence accepted: '+name)
    blob=native.read_bytes();count=struct.unpack_from('<H',blob,2)[0]
    data_at=None
    for i in range(count):
        at=20+i*40
        if blob[at:at+8].rstrip(b'\0')==b'.data':data_at=struct.unpack_from('<I',blob,at+20)[0]
    assert data_at is not None
    for helper in record['helpers']:
        name=helper['name'];start=data_at+helper['objectStart']
        offsets=[('entry',helper['entry']),('last-byte',helper['loadedBytes']-1)]
        offsets += [('data',r['start']) for r in helper['ranges'] if r['kind']=='data']
        offsets += [('nop-align',s['start']) for s in helper['sourceSites'] if s['source'].startswith('.align') and s['end']>s['start']]
        for label,offset in offsets:
            changed=bytearray(blob);changed[start+offset]^=1
            path=work/(name+'-'+label+'.obj');path.write_bytes(changed)
            case=copy.copy(arguments);case.object=path;case.output=work/(name+'-'+label)
            reject(name+'-'+label,lambda case=case:module.build(case))
    truncated=work/'truncated.obj';truncated.write_bytes(blob[:20])
    case=copy.copy(arguments);case.object=truncated;case.output=work/'truncated'
    reject('truncated-coff',lambda:module.build(case))
    changed_archive=work/'changed-source.zip';changed_archive.write_bytes(arguments.archive.read_bytes()+b'X')
    case=copy.copy(arguments);case.archive=changed_archive;case.output=work/'changed_source'
    reject('changed-primary-source',lambda:module.build(case))
    def forge(name,edit,artifact=None,update_hash=False):
        directory=work/name;shutil.copytree(arguments.output,directory)
        evidence=copy.deepcopy(record)
        if artifact:
            helper=evidence['helpers'][0];path=directory/helper['name']/artifact
            changed=bytearray(path.read_bytes());changed[0]^=1;path.write_bytes(changed)
            if update_hash:helper['artifacts'][artifact]=module.mz.sha(path.read_bytes())
        edit(evidence,directory)
        path=directory/'boundary-proof.json';path.write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
        case=copy.copy(verifier);case.verify_proof=path
        reject(name,lambda:module.verify(case))
    forge('changed-helper-container',lambda r,d:None,'helper-audit.obj')
    forge('changed-helper-image',lambda r,d:None,'helper-image.bin')
    forge('changed-range-artifact',lambda r,d:None,'isa-ranges.json')
    forge('forged-artifact-hash',lambda r,d:None,'helper-image.bin',True)
    forge('forged-code-kind',lambda r,d:next(x for x in r['helpers'][0]['ranges'] if x['kind']=='code').update(kind='data'))
    forge('forged-code-mode',lambda r,d:next(x for x in r['helpers'][0]['ranges'] if x['kind']=='code').update(codeMode=32))
    forge('forged-object-bound',lambda r,d:r['helpers'][0].update(objectStart=0))
    forge('removed-helper',lambda r,d:r['helpers'].pop())
    forge('changed-policy',lambda r,d:r.update(policySha256='0'*64))
    forge('changed-decoder',lambda r,d:r.update(objdumpSha256='0'*64))
    forge('changed-archive-identity',lambda r,d:r.update(primarySourceArchiveSha256='0'*64))
    changed=bytearray(blob);changed[4]^=1
    other=work/'different-complete-object.obj';other.write_bytes(changed)
    case=copy.copy(verifier);case.object=other
    reject('different-complete-object',lambda:module.verify(case))
    (work/'summary.json').write_text(json.dumps(dict(pass_=True,checks=checks,
        helperInstructionRows=sum(h['instructionRows'] for h in record['helpers'])),indent=2)+'\n',encoding='utf-8')
    print(f'Startup helper binding tests PASS: {len(checks)} checks; {work}')
if __name__=='__main__':main()
