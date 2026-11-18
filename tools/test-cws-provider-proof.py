"""Reject unreviewed providers and changed source/control/mode evidence."""
from pathlib import Path
import copy,importlib.util,json,os,shutil,struct,tempfile
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('provider_test',ROOT/'tools/cws-provider-proof.py')
tool=importlib.util.module_from_spec(spec);spec.loader.exec_module(tool)

def main():
    work=Path(tempfile.mkdtemp(prefix='provider-proof-regression-',dir=ROOT/'out'))
    bundle=work/'bundle';shutil.copytree(ROOT/'tools/isa-provider-reference',bundle)
    config=tool.load(ROOT/'tools/dos-toolchain.json')
    compiler=Path(os.environ['LOCALAPPDATA'])/'486quake/tools'/config['djgpp']['installDirectory']/config['djgpp']['compiler']
    native=bundle/'original-cwsdpmi.exe';blob=native.read_bytes();header=struct.unpack_from('<14H',blob);base=header[4]*16
    # Use the independently maintained patch to create the exact candidate.
    import subprocess
    patch=work/'patch.obj';subprocess.run([str(compiler),'-c','-x','assembler',str(bundle/'cpu486-and-hex.s'),'-o',str(patch)],capture_output=True,check=True)
    coff=tool.module('provider_test_coff',ROOT/'tools/coff-code-data.py');sections,_=coff.coff(patch)
    candidate=bytearray(blob);candidate[base+0x2d67:base+0x2d8d]=sections['.text']['bytes'][:38]
    candidate[base+0x5358:base+0x535c]=b'\xe8'+struct.pack('<h',0x2d6a-(0x5358+3))+b'\x90'
    executable=work/'cwsdpmi486.exe';executable.write_bytes(candidate)
    accepted=tool.build(executable,compiler,bundle,work/'valid')
    assert accepted['passed'] and accepted['instructionCount']==9207 and accepted['runtimeVariantInstructions']==1
    rejected=[]
    def reject(name,call):
        try:call()
        except (ValueError,OSError,KeyError):rejected.append(name)
        else:raise AssertionError('Invalid provider proof accepted: '+name)
    reject('original_contains_cpuid',lambda:tool.build(native,compiler,bundle,work/'original'))
    for name,offset in [('post486_code',base),('entry_header',20),('relocation_table',header[12]),('data_byte',base+0x235)]:
        altered=bytearray(candidate);altered[offset]^=1;path=work/(name+'.exe');path.write_bytes(altered)
        reject(name,lambda path=path,name=name:tool.build(path,compiler,bundle,work/name))
    for name in ['primary/MSWITCH.ASM','primary/COPYING','primary/COPYING.CWS','cpu486-and-hex.s','original-cwsdpmi.exe','boundaries.json','control-review.json']:
        path=bundle/name;original=path.read_bytes();path.write_bytes(original+b'X')
        try:reject('changed_'+name,lambda:tool.validate_bundle(bundle))
        finally:path.write_bytes(original)
    manifest=bundle/'manifest.json';original=manifest.read_bytes()
    for name,edit in [('unknown_provider_policy',lambda r:r.update(unknownProviderPolicy='decode-anything')),
                     ('duplicate_input',lambda r:r['files'].append(r['files'][0])),
                     ('forged_input_hash',lambda r:r['files'][0].update(sha256='0'*64))]:
        forged=json.loads(original);edit(forged);tool.save(manifest,forged)
        try:reject(name,lambda:tool.validate_bundle(bundle))
        finally:manifest.write_bytes(original)
    sites=[json.loads(line) for line in (work/'valid/provider-instructions.jsonl').read_text(encoding='utf-8-sig').splitlines()]
    typed=tool.load(bundle/'boundaries.json');review=tool.load(bundle/'control-review.json');image=bytes(candidate[base:])
    first=next(i for i,s in enumerate(sites) if s['decoded'].strip().startswith('call ') and '*' not in s['decoded'])
    for name,decoded in [('direct_to_data','call 0x235'),('direct_to_interior','call 0x1'),('unparsed_control','jmp nonsense')]:
        altered=copy.deepcopy(sites);altered[first]['decoded']=decoded
        reject(name,lambda altered=altered:tool.controls(image,bytes(candidate),header,typed,review,altered,bundle))
    altered=copy.deepcopy(sites);next(s for s in altered if s['address']==0x122)['address']=0x123
    reject('unreviewed_near_site',lambda:tool.controls(image,bytes(candidate),header,typed,review,altered,bundle))
    changed=bytearray(image);changed[0x69d]=1
    reject('own_code_dbit_contract',lambda:tool.controls(bytes(changed),bytes(candidate),header,typed,review,sites,bundle))
    changed=bytearray(image);changed[0x1e7]=0x75
    reject('unreviewed_runtime_opcode',lambda:tool.controls(bytes(changed),bytes(candidate),header,typed,review,sites,bundle))
    altered=copy.deepcopy(sites);altered[0]['bytes'][0]='0f'
    reject('relocation_changes_opcode',lambda:tool.controls(image,bytes(candidate),header,typed,review,altered,bundle))
    tool.save(work/'results.json',dict(passed=True,valid=1,adversarialRejections=len(rejected),rejected=rejected))
    print(f'PASS: exact source-maintained provider and {len(rejected)} adversarial rejections; {work}')
if __name__=='__main__':main()
