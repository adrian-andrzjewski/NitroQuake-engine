"""Adversarial binding tests for the source-rebuilt 16-bit DJGPP loader."""
from pathlib import Path
import argparse
import copy
import importlib.util
import json
import shutil
import struct
import tempfile

root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('mzproof',root/'tools/mz-loader-proof.py')
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--executable',type=Path,required=True)
    parser.add_argument('--archive',type=Path,required=True)
    parser.add_argument('--djasm',type=Path,required=True)
    parser.add_argument('--objdump',type=Path,required=True)
    args=parser.parse_args()
    work=Path(tempfile.mkdtemp(prefix='mz-loader-regression-',dir=root/'out'))
    archive=args.archive;djasm=args.djasm;objdump=args.objdump
    original=args.executable.read_bytes()
    fields,image=module.mz_image(original)
    header=fields[4]*16
    valid=argparse.Namespace(archive=archive,executable=args.executable,djasm=djasm,
                             objdump=objdump,output=work/'valid',quiet=True)
    record=module.build(valid)
    verify_args=argparse.Namespace(archive=archive,executable=args.executable,djasm=djasm,
                                  objdump=objdump,verify_proof=valid.output/'boundary-proof.json')
    module.verify(verify_args)
    checks=['valid source rebuild','valid regenerated proof']

    def reject(name,call):
        try:call()
        except (ValueError,FileNotFoundError,KeyError) as error:
            (work/(name+'.rejection.txt')).write_text(str(error)+'\n',encoding='utf-8')
            checks.append(name)
        else:raise AssertionError('Invalid loader evidence accepted: '+name)

    mutations={
        'entry_opcode':(header+fields[10],original[header+fields[10]]^1),
        'overlap_opcode':(header+0xa6,0x90),
        'overlap_prefix':(header+0xa7,0x90),
        'source_data_byte':(header+next(r['start'] for r in record['sourceTypedRanges'] if r['kind']=='data'),0x5a),
        'source_nop_alignment':(header+next(r['start'] for r in record['sourceSites'] if r['source'].startswith('.align') and r['end']>r['start']),0),
    }
    for name,(offset,value) in mutations.items():
        modified=bytearray(original);modified[offset]=value
        executable=work/(name+'.exe');executable.write_bytes(modified)
        case=copy.copy(valid);case.executable=executable;case.output=work/name
        reject(name,lambda case=case:module.build(case))
    for name,offset,value in [('header_entry',20,fields[10]+1),('header_relocations',6,1),
                             ('bypass_cpu_guard',20,0x54),
                             ('header_code_segment',22,1),('header_image_size',4,fields[2]+1)]:
        modified=bytearray(original);struct.pack_into('<H',modified,offset,value)
        executable=work/(name+'.exe');executable.write_bytes(modified)
        case=copy.copy(valid);case.executable=executable;case.output=work/name
        reject(name,lambda case=case:module.build(case))
    truncated=work/'truncated.exe';truncated.write_bytes(original[:20])
    case=copy.copy(valid);case.executable=truncated;case.output=work/'truncated'
    reject('truncated_header',lambda:module.build(case))
    changed_archive=work/'changed-source.zip';changed_archive.write_bytes(archive.read_bytes()+b'X')
    case=copy.copy(valid);case.archive=changed_archive;case.output=work/'changed_source'
    reject('changed_primary_archive',lambda:module.build(case))

    # Installing the guard only changes the MZ loader. The exact linked COFF
    # image (including all engine/runtime instructions and data) must survive.
    pristine=module.guard.assemble(archive,djasm,work/'original-loader',guarded=False)
    installable=work/'installable.exe'
    coff=original[module.guard.mz_length(original):]
    installable.write_bytes(pristine+coff)
    module.guard.install(archive,djasm,installable)
    installed=installable.read_bytes()
    assert installed[module.guard.mz_length(installed):]==coff
    assert module.mz_image(installed)==module.mz_image(original)
    checks.append('guard installation preserves exact COFF image')
    reject('install_over_unknown_loader',lambda:module.guard.install(archive,djasm,installable))

    def forged(name,edit,artifact=None):
        directory=work/name;shutil.copytree(valid.output,directory)
        evidence=copy.deepcopy(record)
        if artifact:
            path=directory/artifact
            changed=bytearray(path.read_bytes());changed[0]^=1;path.write_bytes(changed)
        edit(evidence,directory)
        path=directory/'boundary-proof.json'
        path.write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
        case=copy.copy(verify_args);case.verify_proof=path
        reject(name,lambda:module.verify(case))
    forged('saved_loaded_bytes',lambda r,d:None,'loaded-image.bin')
    forged('saved_container_bytes',lambda r,d:None,'loader-audit.obj')
    forged('forged_code_range',lambda r,d:next(s for s in r['sourceTypedRanges'] if s['kind']=='code').update(kind='data'))
    forged('removed_alternate_entry',lambda r,d:r.update(overlappingEntries=[0xa6]))
    forged('changed_annotation_policy',lambda r,d:r.update(policySha256='0'*64))
    forged('changed_decoder_identity',lambda r,d:r.update(objdumpSha256='0'*64))
    def range_artifact(record,directory):
        path=directory/'isa-ranges.json'
        ranges=json.loads(path.read_text(encoding='utf-8'));ranges.pop()
        path.write_text(json.dumps(ranges,indent=2)+'\n',encoding='utf-8')
        record['artifacts']['isa-ranges.json']=module.sha(path.read_bytes())
    forged('forged_range_artifact_and_hash',range_artifact)
    # Header metadata is not loaded, but an existing proof still binds the full
    # executable, rather than being transferable to a differently hashed file.
    changed=bytearray(original);changed[70]^=1
    metadata=work/'header_metadata.exe';metadata.write_bytes(changed)
    case=copy.copy(verify_args);case.executable=metadata
    reject('different_complete_executable',lambda:module.verify(case))
    (work/'summary.json').write_text(json.dumps({'pass':True,'checks':checks,
        'loaderInstructions':record['instructionRows'],'codeBytes':record['codeBytes']},indent=2)+'\n',encoding='utf-8')
    print(f'MZ loader binding tests PASS: {len(checks)} checks; {work}')

if __name__=='__main__':main()
