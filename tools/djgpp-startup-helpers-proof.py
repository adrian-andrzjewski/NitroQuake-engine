"""Prove the 16-bit executable helpers embedded in DJGPP CRT .data.

Reassemble pinned primary DJASM sources, compare every byte with the linked
CRT object, classify source CODE/DATA and verify continuous 16-bit decoding.
Audit containers preserve the exact helper bytes; they never replace runtime
code. The ISA classifier must separately audit the generated CODE ranges.
"""
from __future__ import annotations
import argparse,importlib.util,json,re,subprocess,tempfile,zipfile
from pathlib import Path

def module(name,filename):
    spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(filename))
    result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result
mz=module('startup_mz','mz-loader-proof.py')
coff=module('startup_coff','coff-code-data.py')
SOURCE_HASHES={'sbrk16':'37671B26D663981AAF7D69E5DFD18580C9B81FFD2C97D7057FD616FF3F082D17',
               'exit16':'6BF0A35B331E1179A5796B067EA09A9FCA7526877E9A2C1DA94F6DE7C103E495'}

def build(args):
    if mz.sha(args.archive.read_bytes())!=mz.ARCHIVE_SHA:raise ValueError('Primary source archive changed.')
    sections,symbols=coff.coff(args.object)
    by_name={s['name']:s for s in symbols}
    if '.data' not in sections:raise ValueError('The CRT has no .data section.')
    data=sections['.data'];outcomes=[]
    args.output.mkdir(parents=True,exist_ok=False)
    with zipfile.ZipFile(args.archive) as package:
        for name,source_sha in SOURCE_HASHES.items():
            source=package.read('src/libc/crt0/'+name+'.asm')
            if mz.sha(source)!=source_sha:raise ValueError('Primary helper source changed: '+name)
            first=by_name[name+'_first_byte'];last=by_name[name+'_last_byte']
            if first['section']!=data['number'] or last['section']!=data['number']:
                raise ValueError('Helper bounds are outside CRT .data.')
            begin,end=first['value'],last['value']
            if not 0<=begin<end<=data['size']:raise ValueError('Invalid CRT helper bounds.')
            if any(begin<=r[0]<end for r in data['relocations']):
                raise ValueError('The embedded helper contains an unexpected relocation.')
            native=data['bytes'][begin:end]
            with tempfile.TemporaryDirectory(prefix='djgpp-helper-rebuild-') as temporary:
                work=Path(temporary);(work/(name+'.asm')).write_bytes(source)
                run=subprocess.run([str(args.djasm.resolve()),name+'.asm',name+'.bin',name+'.map'],
                    cwd=work,capture_output=True,text=True,check=True)
                rebuilt=(work/(name+'.bin')).read_bytes()
                mapping=(work/(name+'.map')).read_text(encoding='ascii')
            if rebuilt!=native:raise ValueError('Embedded helper bytes differ from primary source: '+name)
            lines=source.decode('latin1').splitlines()
            labels={label:int(address,16) for address,label,kind in
                re.findall(r'^0000:([0-9A-F]+)\s+(\S+)\s+\(([ADT?])\)',mapping,re.M)}
            at=mapping.index('Line numbers for ('+name+'.asm)')
            emissions=[(int(number),int(address,16)) for number,address in
                re.findall(r'(\d+)\s+0000:([0-9A-F]+)',mapping[at:])]
            classification=[None]*len(native);sites=[]
            for i,(number,offset) in enumerate(emissions):
                if offset>=len(native):continue # Primary BSS stack is allocated, not copied.
                stop=min(emissions[i+1][1] if i+1<len(emissions) else len(native),len(native))
                if stop<offset:raise ValueError('Nonmonotonic helper source map.')
                operation=lines[number-1].split(';',1)[0].strip()
                if operation.startswith(('.db','.dw','.dd')):
                    kind='data'
                    if mz.data_bytes(operation,labels)!=native[offset:stop]:
                        raise ValueError('Source DATA directive differs from embedded bytes.')
                elif operation.startswith('.align'):
                    kind='code';alignment=int(operation.split()[1],0)
                    if stop!=(offset+alignment-1)//alignment*alignment or native[offset:stop]!=b'\x90'*(stop-offset):
                        raise ValueError('Source NOP alignment differs from embedded bytes.')
                elif operation.startswith('.') and operation not in ('.opsize','.addrsize'):
                    raise ValueError('Unknown emitting helper directive: '+operation)
                else:kind='code'
                for position in range(offset,stop):
                    if classification[position] is not None:raise ValueError('Overlapping helper source emissions.')
                    classification[position]=kind
                sites.append(dict(line=number,start=offset,end=stop,kind=kind,source=operation))
            if any(kind is None for kind in classification):raise ValueError('Unclassified embedded helper bytes.')
            ranges=[];start=0
            for stop in range(1,len(native)+1):
                if stop==len(native) or classification[stop]!=classification[start]:
                    ranges.append(dict(start=start,end=stop,kind=classification[start],codeMode=16,
                                       section='.text',label='primary-'+name));start=stop
            entry=labels['sbrk_16_helper'] if name=='sbrk16' else 0
            if name=='sbrk16' and int.from_bytes(native[:2],'little')!=entry:
                raise ValueError('The embedded API header points to a different entry.')
            directory=args.output/name;directory.mkdir()
            raw=directory/'helper-image.bin';raw.write_bytes(native)
            rows=[]
            for item in ranges:
                if item['kind']=='code':rows+=mz.decode(args.objdump,raw,item['start'],item['end'])
            starts={offset for offset,_,_ in rows};coverage=set()
            for offset,encoded,mnemonic in rows:
                if encoded!=native[offset:offset+len(encoded)] or any(classification[p]!='code' for p in range(offset,offset+len(encoded))):
                    raise ValueError('A helper instruction crosses a source DATA boundary.')
                coverage.update(range(offset,offset+len(encoded)))
                target=re.match(r'^(?:j[a-z]+|call|loop[a-z]*|jcxz)\s+0x([0-9a-f]+)\b',mnemonic)
                if target and int(target[1],16) not in starts:raise ValueError('Helper direct target has no CODE entry.')
            if entry not in starts or coverage!={p for p,k in enumerate(classification) if k=='code'}:
                raise ValueError('Helper entry or continuous CODE coverage failed.')
            (directory/'primary.asm').write_bytes(source)
            (directory/'rebuilt.bin').write_bytes(rebuilt)
            (directory/'rebuilt.map').write_text(mapping,encoding='ascii')
            (directory/'helper-audit.obj').write_bytes(mz.coff_container(native,{k:v for k,v in labels.items() if v<len(native)}))
            (directory/'isa-ranges.json').write_text(json.dumps([r for r in ranges if r['kind']=='code'],indent=2)+'\n',encoding='utf-8')
            artifacts={filename:mz.sha((directory/filename).read_bytes()) for filename in
                ('primary.asm','rebuilt.bin','rebuilt.map','helper-image.bin','helper-audit.obj','isa-ranges.json')}
            outcomes.append(dict(name=name,section='.data',objectStart=begin,objectEnd=end,entry=entry,
                imageSha256=mz.sha(native),sourceSha256=source_sha,loadedBytes=len(native),codeBytes=len(coverage),
                ranges=ranges,sourceSites=sites,instructionRows=len(rows),directTargetsAreCode=True,artifacts=artifacts))
    record=dict(schemaVersion=1,object=str(args.object.resolve()),objectSha256=mz.sha(args.object.read_bytes()),
        primarySourceArchiveSha256=mz.ARCHIVE_SHA,djasmSha256=mz.sha(args.djasm.read_bytes()),
        objdumpSha256=mz.sha(args.objdump.read_bytes()),policySha256=mz.sha(Path(__file__).read_bytes()),
        mzPolicySha256=mz.sha(Path(__file__).with_name('mz-loader-proof.py').read_bytes()),
        coffPolicySha256=mz.sha(Path(__file__).with_name('coff-code-data.py').read_bytes()),
        exactPrimarySourceBytes=True,replacesRuntimeObjects=False,isaAuditRequired=True,helpers=outcomes)
    (args.output/'boundary-proof.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    if not getattr(args,'quiet',False):print('Startup helper boundary proof PASS: '+', '.join(
        f'{r["name"]}: {r["loadedBytes"]} identical bytes, {r["instructionRows"]} instruction rows' for r in outcomes))
    return record

def verify(args):
    record=json.loads(args.verify_proof.read_text(encoding='utf-8'))
    if record.get('schemaVersion')!=1:raise ValueError('Unsupported startup helper proof.')
    for helper in record['helpers']:
        if helper['name'] not in SOURCE_HASHES:raise ValueError('Unknown saved helper.')
        for name,expected in helper['artifacts'].items():
            if Path(name).name!=name:raise ValueError('Invalid helper artifact name.')
            if mz.sha((args.verify_proof.parent/helper['name']/name).read_bytes())!=expected:
                raise ValueError('Startup helper proof artifact changed: '+name)
    with tempfile.TemporaryDirectory(prefix='djgpp-helper-verify-') as temporary:
        actual=build(argparse.Namespace(archive=args.archive,object=args.object,djasm=args.djasm,
                                      objdump=args.objdump,output=Path(temporary)/'fresh',quiet=True))
    if actual!=record:raise ValueError('Helper proof differs from fresh primary-source evidence.')
    print('Startup helper proof verified against the complete CRT object and fresh primary-source rebuild.')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('archive','object','djasm','objdump'):parser.add_argument('--'+name,type=Path,required=True)
    parser.add_argument('--output',type=Path);parser.add_argument('--verify-proof',type=Path)
    args=parser.parse_args()
    if bool(args.output)==bool(args.verify_proof):parser.error('Exactly one output or verify-proof is required.')
    if args.verify_proof:verify(args)
    else:build(args)
if __name__=='__main__':main()
