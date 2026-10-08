"""Prove the exact maintained CWSDPMI provider, its ISA and control targets."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,re,struct,subprocess

TOOLS=Path(__file__).resolve().parent
BUNDLE_SHA256='43564D410A58E4C6DCD8A0AB5EEDAF4FD6004C12194A70A5AAB18CF9526C7CAD'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def load(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def save(path,record):path.write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value);return value

def validate_bundle(bundle):
    if sha(bundle/'manifest.json')!=BUNDLE_SHA256:raise ValueError('Changed provider source/boundary manifest.')
    record=load(bundle/'manifest.json');seen=set()
    if record['unknownProviderPolicy']!='reject':raise ValueError('Unknown providers must fail.')
    for item in record['files']:
        name=item['path'];path=(bundle/name).resolve()
        if name in seen or not path.is_relative_to(bundle.resolve()):raise ValueError('Duplicate or escaping provider input.')
        seen.add(name)
        if path.stat().st_size!=item['bytes'] or sha(path)!=item['sha256']:raise ValueError('Changed provider input: '+name)
    if len(seen)!=43:raise ValueError('Incomplete provider inputs.')
    return record

def exact(image,start,value):
    if image[start:start+len(bytes.fromhex(value))]!=bytes.fromhex(value):raise ValueError('Provider control bytes changed at '+hex(start))

def audit(output,name,image,ranges,tool_root=None):
    loader=module('provider_container',TOOLS/'mz-loader-proof.py')
    container=output/(name+'.obj');container.write_bytes(loader.coff_container(image,{'_cwsdpmi_entry':0}))
    range_path=output/(name+'-ranges.json');save(range_path,ranges)
    report=output/(name+'-isa.json');details=output/(name+'-instructions.jsonl')
    command=['pwsh','-NoProfile','-File',str(TOOLS/'isa-audit.ps1'),'-BuildRoot',str(output),'-ExeName',container.name,
        '-ExecutableOnly','-AddressRangesJson',str(range_path),'-MaxIsa','i486','-FailOnViolation',
        '-OutputJson',str(report),'-InstructionDetailsJsonl',str(details)]
    if tool_root:command+=['-ToolRoot',str(tool_root)]
    result=subprocess.run(command,capture_output=True,text=True)
    (output/(name+'-audit.txt')).write_text(result.stdout+result.stderr,encoding='utf-8')
    if result.returncode:raise ValueError('Provider instruction audit failed: '+result.stdout[-2000:]+result.stderr[-1000:])
    summary=load(report)
    if summary['result']!='PASS' or summary['continuationLineCount'] or summary['unclassifiedCount'] or summary['exemptedCount']:
        raise ValueError('Provider instruction audit was not strict.')
    sites=[json.loads(line) for line in details.read_text(encoding='utf-8-sig').splitlines()]
    return summary,sites,report

def controls(image,blob,header,typed,review,sites,bundle):
    starts={site['address']:site for site in sites};direct=[];near=[];far=[]
    for site in sites:
        text=site['decoded'].strip();op,_,operands=text.partition(' ')
        if op in ('ljmp','ljmpw','ljmpl','lcall','lcallw','lcalll'):far.append(site['address'])
        elif op in ('call','callw','calll','jmp','jmpw','jmpl') or op.startswith('j') or op.startswith('loop'):
            if '*' in operands:near.append(site['address']);continue
            match=re.match(r'\s*(?:0x)?([0-9a-f]+)(?:\s|$)',operands)
            if not match:raise ValueError('Unparsed provider control instruction: '+text)
            target=int(match[1],16)
            if target not in starts:raise ValueError('Provider transfer enters DATA or an instruction interior: '+hex(target))
            direct.append(dict(site=site['address'],target=target))
    expected_near={item['site']:item['targets'] for item in review['nearTransfers']}
    if set(near)!=set(expected_near) or set(far)!={int(key) for key in review['farTransfers']}:
        raise ValueError('Changed provider indirect/far control sites.')
    known=[0,0x2d3a,0x2d6a]+typed['interruptStubEntries']+typed['exceptionTableEntries']
    for item in typed['dataRecords']:
        known+=item.get('entries',[])
        for key in ['nearTarget','farEntryTarget']:
            if key in item:known.append(item[key])
    for targets in expected_near.values():known+=targets
    if any(entry not in starts for entry in known):raise ValueError('A provider table entry is not canonical CODE.')
    if len(direct)!=1751 or len(set(known))!=337:raise ValueError('Provider control coverage changed.')
    control=(bundle/'primary/CONTROL.C').read_text(encoding='latin1');gdt=(bundle/'primary/GDT.H').read_text(encoding='latin1')
    for text in ['fill_desc(&gdt[g_rcode], 0xffff, (word32)_CS*16L, 0x9a, 0);',
                 'fill_desc(&gdt[g_pcode], 0xffff, (word32)_CS*16L, SEL_PRV | 0x9a, 0);',
                 'g->lim1 |= G * 0x40;','t->tss_cs = g_rcode*8;']:
        if text not in control:raise ValueError('Changed primary provider code-mode contract.')
    if not re.search(r'#define\s+g_rcode\s+3\b',gdt) or not re.search(r'#define\s+g_pcode\s+5\b',gdt):
        raise ValueError('Changed provider GDT selectors.')
    for start,value in [(0x69c,'6a00689a008cc833d2b104e87b5252506a006aff681807e89afb83c40e'),
            (0x703,'6a0068fa008cc833d2b104e8145252506a006aff682807e833fb83c40e'),
            (0x29c,'8a44068a5610c0e2060ac2884406'),(0x2c0,'c7444c18008b4606894420'),
            (0x631,'c7068007e510c70682071800c6068507ec'),(0x4ebc,'c706be040650'),
            (0x4a4d,'b8944c50ff7604ff76068d460850e80b09'),(0xfef,'669a000000000000'),
            (0xf12,'662ea3f10f'),(0xf1b,'2ea3f50f'),(0xf0,'2ec606e70172'),(0xf6,'2ec606d60100'),
            (0x1d5,'b4ff'),(0x1e7,'7705')]:exact(image,start,value)
    for start,storage,entry in review['taskEntries']:
        exact(image,start,'68'+struct.pack('<H',entry).hex()+'68'+struct.pack('<H',storage).hex())
        if starts[entry]['codeMode']!=16:raise ValueError('Wrong provider task code mode.')
    if list(struct.unpack_from('<3H',image,0x5c40+0x4be))!=[0x496e]*3:raise ValueError('Changed provider stream hooks.')
    if struct.unpack_from('<H',image,0x5c40+0x4bc)[0] or any(item['target']==0x494a for item in direct):
        raise ValueError('Provider atexit table no longer has the reviewed empty target set.')
    if [item['site'] for item in direct if item['target']==0x5369]!=[0x4a5b]:raise ValueError('New provider formatter caller.')
    relocations=[]
    for index in range(header[3]):
        offset,segment=struct.unpack_from('<HH',blob,header[12]+index*4);address=segment*16+offset
        site=next((item for item in sites if item['address']<=address<item['address']+len(item['bytes'])),None)
        if site:
            encoded=bytes.fromhex(''.join(site['bytes']));at=address-site['address']
            # Native MZ relocations alter only a two-byte immediate, never an opcode.
            valid=(encoded[0] in [0xb8,0xba,0xbb,0x68] and at==1 and len(encoded)==3) or \
                (encoded[:2]==b'\x66\xb8' and at==2 and len(encoded)==6) or \
                (encoded[0]==0xea and at==3 and len(encoded)==5)
            if not valid:raise ValueError('MZ relocation would change provider instruction encoding.')
            relocations.append(dict(address=address,kind='instruction immediate only'))
        else:
            if not (address>=0x5c40 or any(r['start']<=address and address+2<=r['end'] for r in typed['dataRecords'])):
                raise ValueError('Unreviewed provider MZ relocation.')
            relocations.append(dict(address=address,kind='typed data'))
    return dict(directBranches=len(direct),nearTransfers=len(near),farTransfers=len(far),
        typedEntries=len(set(known)),codeMode=16,ownDescriptorDbit=0,mzRelocations=relocations,
        externalBoundary=review['externalExecutionBoundary'])

def build(executable,compiler,bundle,output,tool_root=None):
    manifest=validate_bundle(bundle)
    if sha(executable)!=manifest['candidateSha256']:raise ValueError('Unreviewed or changed DPMI provider: '+str(executable))
    output.mkdir(parents=True,exist_ok=False)
    original=(bundle/'original-cwsdpmi.exe').read_bytes();blob=executable.read_bytes();header=struct.unpack_from('<14H',blob)
    base=header[4]*16;size=header[2]*512-(512-header[1] if header[1] else 0)
    if base!=512 or size!=len(blob) or header[3]!=25 or header[10:12]!=(0,0):raise ValueError('Changed provider MZ layout.')
    if blob[:base]!=original[:base]:raise ValueError('The provider patch changed MZ header or relocations.')
    patch=output/'patch.obj';result=subprocess.run([str(compiler),'-c','-x','assembler',str(bundle/'cpu486-and-hex.s'),'-o',str(patch)],capture_output=True,text=True)
    if result.returncode:raise ValueError('Maintained provider patch did not assemble: '+result.stderr)
    boundary=module('provider_coff',TOOLS/'coff-code-data.py');sections,symbols=boundary.coff(patch)
    values={item['name']:item['value'] for item in symbols}
    if values['_hex_nibbles']!=3 or values['_cpu486_patch_end']!=38 or sections['.text']['relocations']:
        raise ValueError('Changed maintained provider patch layout.')
    rebuilt=bytearray(original);rebuilt[base+0x2d67:base+0x2d8d]=sections['.text']['bytes'][:38]
    rebuilt[base+0x5358:base+0x535c]=b'\xe8'+struct.pack('<h',0x2d6a-(0x5358+3))+b'\x90'
    if bytes(rebuilt)!=blob:raise ValueError('The provider does not match the original plus maintained assembly patch.')
    changed=[i-base for i,(a,b) in enumerate(zip(original,blob)) if a!=b]
    if len(changed)!=36 or any(not any(start<=i<end for start,end in manifest['patchLoadRanges']) for i in changed):
        raise ValueError('Unbounded provider changes.')
    image=blob[base:size];typed=load(bundle/'boundaries.json');review=load(bundle/'control-review.json');ranges=[];cursor=0
    for item in typed['dataRecords']:
        if not cursor<=item['start']<item['end']<=manifest['codeEnd']:raise ValueError('Overlapping provider DATA.')
        if 'literalHex' in item:exact(image,item['start'],item['literalHex'])
        if item['kind'].startswith('zero') and any(image[item['start']:item['end']]):raise ValueError('Nonzero provider alignment DATA.')
        if cursor<item['start']:ranges.append(dict(start=cursor,end=item['start'],codeMode=16,label='CWSDPMI typed CODE'))
        cursor=item['end']
    if cursor<manifest['codeEnd']:ranges.append(dict(start=cursor,end=manifest['codeEnd'],codeMode=16,label='CWSDPMI typed CODE'))
    summary,sites,report=audit(output,'provider',image[:manifest['codeEnd']],ranges,tool_root)
    if summary['instructionCount']!=9207 or len(ranges)!=10 or len(typed['dataRecords'])!=15:raise ValueError('Provider coverage changed.')
    flow=controls(image,blob,header,typed,review,sites,bundle)
    variant=bytearray(image[:manifest['codeEnd']]);variant[0x1e7]=0x72
    alternate,alternate_sites,alternate_report=audit(output,'patched-ja-to-jb',bytes(variant),
        [dict(start=0x1e7,end=0x1e9,codeMode=16,label='Reviewed runtime JA to JB patch')],tool_root)
    if alternate['instructionCount']!=1 or not alternate_sites[0]['decoded'].strip().startswith('jb '):raise ValueError('Wrong provider runtime branch variant.')
    record=dict(schemaVersion=1,passed=True,executable=str(executable.resolve()),executableSha256=sha(executable),
        sourceManifestSha256=BUNDLE_SHA256,policySha256=sha(Path(__file__)),
        exactOriginalPlusMaintainedAssembly=True,changedBytes=36,instructionCount=9207,runtimeVariantInstructions=1,
        instructionExemptions=0,unknownEncodings=0,codeRanges=10,typedDataRecords=15,loadedBytes=len(image),
        control=flow,strictReport=str(report.resolve()),strictReportSha256=sha(report),
        runtimeVariantReport=str(alternate_report.resolve()),runtimeVariantReportSha256=sha(alternate_report))
    save(output/'provider-proof.json',record);return record

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--executable',type=Path,required=True);p.add_argument('--compiler',type=Path,required=True)
    p.add_argument('--bundle',type=Path,default=TOOLS/'isa-provider-reference');p.add_argument('--output',type=Path,required=True)
    p.add_argument('--tool-root',type=Path)
    args=p.parse_args();record=build(args.executable,args.compiler,args.bundle,args.output,args.tool_root)
    print(f"Provider ISA proof PASS: {record['instructionCount']} instructions, one runtime branch variant, zero exemptions.")
if __name__=='__main__':main()
