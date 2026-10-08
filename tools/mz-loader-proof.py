"""Bind DJGPP's source-rebuilt MZ loader to exact, source-typed ISA ranges.

The MZ loaded image must match a fresh DJASM assembly of the pinned primary
source. Every byte is CODE or a verified data directive/alignment byte. Decode
16-bit CODE continuously and verify direct targets, including the deliberate
TEST-AX/REPNE-SCASB overlap. The synthetic COFF file is only an audit container;
its .text bytes are identical to the loaded MZ image, never a replacement loader.
"""
from __future__ import annotations
import argparse
import ast
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import zipfile

ARCHIVE_SHA='80690B6E44FF8BC6C6081FCA1F4FAEBA1591C4490B76EF0EC8B35847BAA5DEEA'
SOURCE_SHA='EB3AEDE63C1F01D09F4956FFB95D7145EC7C9BEB52B9E97470CEF47B12AFC035'

def sha(data: bytes): return hashlib.sha256(data).hexdigest().upper()

def mz_image(blob: bytes):
    if len(blob)<28: raise ValueError('Truncated MZ header.')
    fields=struct.unpack_from('<14H',blob)
    if fields[0]!=0x5a4d or fields[3]!=0 or fields[11]!=0:
        raise ValueError('Only the original relocation-free DJGPP MZ layout is supported.')
    length=fields[2]*512-(512-fields[1] if fields[1] else 0)
    header=fields[4]*16
    if not 28<=header<length<=len(blob): raise ValueError('Invalid MZ image bounds.')
    return fields,blob[header:length]

def coff_container(image: bytes,labels: dict[str,int]):
    strings=bytearray(b'\0'*4); symbols=bytearray()
    for name,offset in sorted(labels.items(),key=lambda item:(item[1],item[0])):
        encoded=name.encode('ascii')
        if len(encoded)<=8: field=encoded.ljust(8,b'\0')
        else:
            field=struct.pack('<II',0,len(strings));strings.extend(encoded+b'\0')
        symbols.extend(field+struct.pack('<IhHBB',offset,1,0,2,0))
    struct.pack_into('<I',strings,0,len(strings))
    header=struct.pack('<HHIIIHH',0x14c,1,0,60+len(image),len(labels),0,0)
    section=b'.text\0\0\0'+struct.pack('<IIIIIIHHI',0,0,len(image),60,0,0,0,0,0x20)
    return header+section+image+symbols+strings

def data_bytes(operation: str,labels: dict[str,int]):
    match=re.fullmatch(r'\.(db|dw|dd)\s+(.+)',operation)
    if not match: raise ValueError(f'Unsupported source data operation: {operation}')
    width={'db':1,'dw':2,'dd':4}[match[1]]
    content=match[2].strip()
    duplicate=re.fullmatch(r'(\d+)\s+\.dup\s+(.+)',content)
    if duplicate: return data_bytes('.'+match[1]+' '+duplicate[2],labels)*int(duplicate[1])
    result=bytearray()
    parts=re.findall(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[^,]+',content)
    for part in parts:
        part=part.strip()
        if part.startswith(('"',"'")):
            value=ast.literal_eval(part)
            if part.startswith('"'):
                if width!=1: raise ValueError('Unexpected wide string directive.')
                result.extend(value.encode('latin1'));continue
            number=ord(value)
        else: number=labels[part] if part in labels else int(part,0)
        result.extend(number.to_bytes(width,'little',signed=False))
    return bytes(result)

def decode(objdump: Path,raw: Path,start: int,end: int):
    run=subprocess.run([str(objdump),'-D','-z','-b','binary','-mi8086','--insn-width=16',
        f'--start-address={start}',f'--stop-address={end}',str(raw)],
        capture_output=True,text=True,check=True)
    rows=[]
    for line in run.stdout.splitlines():
        match=re.match(r'^\s*([0-9a-f]+):\t((?:[0-9a-f]{2} )*[0-9a-f]{2})\s*\t(.+)$',line)
        if match: rows.append((int(match[1],16),bytes.fromhex(match[2]),match[3]))
        elif re.match(r'^\s*[0-9a-f]+:\t',line): raise ValueError('Unparsed instruction: '+line)
    return rows

def build(args):
    archive=args.archive.read_bytes()
    if sha(archive)!=ARCHIVE_SHA: raise ValueError('Primary source archive hash changed.')
    with zipfile.ZipFile(args.archive) as package: source=package.read('src/stub/stub.asm')
    if sha(source)!=SOURCE_SHA: raise ValueError('Primary loader source hash changed.')
    fields,image=mz_image(args.executable.read_bytes())
    with tempfile.TemporaryDirectory(prefix='djgpp-loader-proof-') as directory:
        work=Path(directory);(work/'stub.asm').write_bytes(source)
        run=subprocess.run([str(args.djasm.resolve()),'stub.asm','stub.exe','stub.map'],
            cwd=work,capture_output=True,text=True,check=True)
        rebuilt=(work/'stub.exe').read_bytes();mapping=(work/'stub.map').read_text(encoding='ascii')
    rebuilt_fields,rebuilt_image=mz_image(rebuilt)
    if fields!=rebuilt_fields or image!=rebuilt_image:
        raise ValueError('Executable MZ header or loaded bytes differ from the source rebuild.')
    lines=source.decode('latin1').splitlines()
    labels={name:int(address,16) for address,name,kind in
        re.findall(r'^0000:([0-9A-F]+)\s+(\S+)\s+\(([ADT?])\)',mapping,re.M)}
    start=mapping.index('Line numbers for (stub.asm)')
    emissions=[(int(number),int(address,16)) for number,address in
        re.findall(r'(\d+)\s+0000:([0-9A-F]+)',mapping[start:])]
    classification=[None]*len(image); source_sites=[]
    for index,(number,offset) in enumerate(emissions):
        if offset>=len(image): continue
        end=emissions[index+1][1] if index+1<len(emissions) else len(image)
        end=min(end,len(image))
        if end<offset: raise ValueError('Nonmonotonic DJASM source map.')
        operation=lines[number-1].split(';',1)[0].strip()
        if operation.startswith(('.db','.dw','.dd')):
            if operation=='.db\t0xa9' or re.fullmatch(r'\.db\s+0xa9',operation):
                if offset!=0xa6 or image[offset:end]!=b'\xa9': raise ValueError('Changed overlap opcode.')
                kind='code'
            else:
                kind='data'
                if data_bytes(operation,labels)!=image[offset:end]:
                    raise ValueError(f'Data directive bytes differ at source line {number}.')
        elif operation.startswith('.align'):
            # DJASM's default alignment emits 90 NOP, not zero DATA. Audit it.
            kind='code'
            boundary=int(operation.split()[1],0)
            if end!=(offset+boundary-1)//boundary*boundary or image[offset:end]!=b'\x90'*(end-offset):
                raise ValueError('Incorrectly sized or changed source NOP alignment.')
        elif operation.startswith('.') and operation not in ('.opsize','.addrsize'):
            raise ValueError(f'Unknown emitting directive at line {number}: {operation}')
        else: kind='code'
        for at in range(offset,end):
            if classification[at] is not None: raise ValueError('Overlapping source byte classifications.')
            classification[at]=kind
        source_sites.append({'line':number,'start':offset,'end':end,'kind':kind,'source':operation})
    if any(kind is None for kind in classification): raise ValueError('Unclassified loaded byte.')
    ranges=[];begin=0
    for end in range(1,len(image)+1):
        if end==len(image) or classification[end]!=classification[begin]:
            ranges.append({'start':begin,'end':end,'kind':classification[begin],
                'codeMode':16,'section':'.text','label':'source-typed-loader'});begin=end
    if fields[9]!=0 or fields[10]>=len(image) or classification[fields[10]]!='code':
        raise ValueError('The MZ entry does not point to proved CODE.')
    args.output.mkdir(parents=True,exist_ok=False)
    raw=args.output/'loaded-image.bin';raw.write_bytes(image)
    all_rows=[]
    for item in ranges:
        if item['kind']=='code': all_rows.extend(decode(args.objdump,raw,item['start'],item['end']))
    # The intentional TEST AX immediate consumes REPNE/SCASB on one path;
    # scan_environment enters the second path at REPNE, never at a naked suffix.
    overlap=decode(args.objdump,raw,labels['scan_environment'],0xa9)
    if len(overlap)!=1 or overlap[0][0]!=0xa7 or overlap[0][1]!=b'\xf2\xae':
        raise ValueError('The alternate overlap path did not decode exactly.')
    all_rows+=overlap
    starts={offset for offset,data,mnemonic in all_rows}
    coverage=set()
    for offset,data,mnemonic in all_rows:
        if image[offset:offset+len(data)]!=data or any(classification[at]!='code' for at in range(offset,offset+len(data))):
            raise ValueError('Instruction crosses a source DATA boundary.')
        coverage.update(range(offset,offset+len(data)))
        target=re.match(r'^(?:j[a-z]+|call|loop[a-z]*|jcxz)\s+0x([0-9a-f]+)\b',mnemonic)
        if target and int(target[1],16) not in starts: raise ValueError('Direct transfer has no proved CODE entry: '+mnemonic)
    if coverage!={at for at,kind in enumerate(classification) if kind=='code'}:
        raise ValueError('Decoded instructions do not cover every CODE byte.')
    if fields[10] not in starts: raise ValueError('Entry inside an instruction.')
    (args.output/'primary-stub.asm').write_bytes(source)
    (args.output/'rebuilt-stub.exe').write_bytes(rebuilt)
    (args.output/'rebuilt-stub.map').write_text(mapping,encoding='ascii')
    container=args.output/'loader-audit.obj'
    container.write_bytes(coff_container(image,{name:offset for name,offset in labels.items() if offset<len(image)}))
    audit_ranges=[item for item in ranges if item['kind']=='code']
    audit_ranges.append({'start':0xa7,'end':0xa9,'codeMode':16,'section':'.text','label':'alternate-repne-scasb-entry'})
    (args.output/'isa-ranges.json').write_text(json.dumps(audit_ranges,indent=2)+'\n',encoding='utf-8')
    artifact_names=('primary-stub.asm','rebuilt-stub.exe','rebuilt-stub.map',
                    'loaded-image.bin','loader-audit.obj','isa-ranges.json')
    record={'schema':2,'executable':str(args.executable.resolve()),'executableSha256':sha(args.executable.read_bytes()),
        'primaryArchiveSha256':ARCHIVE_SHA,'primarySourceSha256':SOURCE_SHA,
        'djasmSha256':sha(args.djasm.read_bytes()),'objdumpSha256':sha(args.objdump.read_bytes()),
        'policySha256':sha(Path(__file__).read_bytes()),
        'mzHeaderFields':list(fields),'loadedImageSha256':sha(image),'loadedBytes':len(image),
        'sourceRebuildLoadedBytesEqual':True,'sourceTypedRanges':ranges,'sourceSites':source_sites,
        'instructionRows':len(all_rows),'codeBytes':len(coverage),'directTargetsAreCode':True,
        'overlappingEntries':[0xa6,0xa7],'containerSha256':sha(container.read_bytes()),
        'executionMode':'16-bit real or protected CS; explicit operand/address prefixes; far transfer into 32-bit client',
        'isaAuditRequired':True,
        'artifacts':{name:sha((args.output/name).read_bytes()) for name in artifact_names}}
    (args.output/'boundary-proof.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    if not getattr(args,'quiet',False):
        print(f'Loader boundary proof PASS: {len(image)} identical loaded bytes, {len(coverage)} CODE bytes, {len(all_rows)} decoded rows.')
    return record

def verify(args):
    record=json.loads(args.verify_proof.read_text(encoding='utf-8'))
    if record.get('schema')!=2: raise ValueError('Unsupported or incomplete loader boundary proof.')
    if sha(args.executable.read_bytes())!=record['executableSha256']:
        raise ValueError('Loader proof belongs to a different complete executable.')
    for name,expected in record['artifacts'].items():
        if Path(name).name!=name: raise ValueError('Invalid proof artifact name.')
        if sha((args.verify_proof.parent/name).read_bytes())!=expected:
            raise ValueError('Loader proof artifact changed: '+name)
    # Fresh primary-source assembly and continuous decode recompute every range;
    # a saved range list or altered proof JSON cannot waive executable bytes.
    with tempfile.TemporaryDirectory(prefix='djgpp-loader-verify-') as directory:
        fresh=argparse.Namespace(archive=args.archive,executable=args.executable,
            djasm=args.djasm,objdump=args.objdump,output=Path(directory)/'fresh',quiet=True)
        actual=build(fresh)
        # DJASM writes current-time/copyright text into the unloaded header.
        # The saved artifact is fully hash-bound above; fresh equality concerns
        # every header field and loaded byte, exactly as for the executable.
        saved_rebuild=mz_image((args.verify_proof.parent/'rebuilt-stub.exe').read_bytes())
        fresh_rebuild=mz_image((fresh.output/'rebuilt-stub.exe').read_bytes())
        if saved_rebuild!=fresh_rebuild:
            raise ValueError('Saved and freshly rebuilt loader images differ.')
        actual['artifacts']['rebuilt-stub.exe']=record['artifacts']['rebuilt-stub.exe']
    if actual!=record:
        fields=[key for key in actual if actual[key]!=record.get(key)]
        raise ValueError('Loader proof differs from recomputed primary-source evidence: '+', '.join(fields))
    print('Loader boundary proof verified against the complete executable and fresh primary-source rebuild.')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for argument in ('archive','executable','djasm','objdump'):
        parser.add_argument('--'+argument,type=Path,required=True)
    parser.add_argument('--output',type=Path)
    parser.add_argument('--verify-proof',type=Path)
    args=parser.parse_args()
    if bool(args.output)==bool(args.verify_proof):
        parser.error('Exactly one of output or verify-proof is required.')
    if args.verify_proof: verify(args)
    else: build(args)

if __name__=='__main__': main()
