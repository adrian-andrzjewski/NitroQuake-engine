"""Rebuild and locate every DJGPP 16-bit startup instruction in the final EXE.

The primary loader and CRT helper sources must reproduce every loaded byte.
The linker map only supplies locations; exact final-byte equality verifies them.
The generated containers require the same strict ISA audit as renderer objects.
"""
from __future__ import annotations
import argparse,importlib.util,json,re,struct
from pathlib import Path


def module(name,filename):
    spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(filename))
    result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result


def initialized_data(executable:Path):
    blob=executable.read_bytes()
    if blob[:2]!=b'MZ':raise ValueError('Expected the complete GO32 executable with its DOS loader.')
    last,pages=struct.unpack_from('<HH',blob,2);base=pages*512-(512-last if last else 0)
    machine,count,stamp,symbol_at,symbol_count,optional,flags=struct.unpack_from('<HHIIIHH',blob,base)
    if machine!=0x14c or not optional:raise ValueError('Expected an i386 COFF executable.')
    result=[]
    for index in range(count):
        at=base+20+optional+40*index
        name=blob[at:at+8].split(b'\0',1)[0].decode('ascii')
        physical,address,size,raw=struct.unpack_from('<IIII',blob,at+8)
        section_flags=struct.unpack_from('<I',blob,at+36)[0]
        if name=='.data':
            if section_flags&0x20 or not section_flags&0x40 or base+raw+size>len(blob):
                raise ValueError('Invalid initialized-data section.')
            result.append((address,blob[base+raw:base+raw+size]))
    if len(result)!=1:raise ValueError('The final executable must have one initialized-data section.')
    return result[0]


def build(args):
    mz=module('startup_linked_mz','mz-loader-proof.py')
    helper=module('startup_linked_helper','djgpp-startup-helpers-proof.py')
    coff=module('startup_linked_coff','coff-code-data.py')
    args.output.mkdir(parents=True,exist_ok=False)
    loader=mz.build(argparse.Namespace(archive=args.archive,executable=args.executable,
        djasm=args.djasm,objdump=args.objdump,output=args.output/'loader',quiet=True))
    helpers=helper.build(argparse.Namespace(archive=args.archive,object=args.crt_object,
        djasm=args.djasm,objdump=args.objdump,output=args.output/'crt-helpers',quiet=True))
    sections,_=coff.coff(args.crt_object);native=sections['.data']
    contributions=[]
    for line in args.map.read_text(encoding='latin1').splitlines():
        match=re.match(r'^\s+\.data\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)\s+(.+)$',line)
        if match and re.search(r'(?:[/\\])crt0\.o$',match[3],re.I):
            contributions.append(dict(address=int(match[1],16),size=int(match[2],16),origin=match[3]))
    if len(contributions)!=1 or contributions[0]['size']!=native['size']:
        raise ValueError('The map must locate exactly one full CRT initialized-data contribution.')
    contribution=contributions[0];base,image=initialized_data(args.executable)
    relative=contribution['address']-base
    if relative<0 or relative+native['size']>len(image):raise ValueError('Mapped CRT data is outside the executable.')
    located=[]
    for item in helpers['helpers']:
        begin,end=item['objectStart'],item['objectEnd']
        linked=image[relative+begin:relative+end]
        if linked!=native['bytes'][begin:end]:raise ValueError('Final executable helper bytes differ: '+item['name'])
        located.append(dict(name=item['name'],linkedStart=contribution['address']+begin,
            linkedEnd=contribution['address']+end,linkedEntry=contribution['address']+begin+item['entry'],
            loadedBytes=len(linked),imageSha256=mz.sha(linked),allCodeAndDataBytesMatch=True))
    report=dict(schemaVersion=1,executable=str(args.executable.resolve()),executableSha256=mz.sha(args.executable.read_bytes()),
        linkerMap=str(args.map.resolve()),linkerMapSha256=mz.sha(args.map.read_bytes()),crtObject=str(args.crt_object.resolve()),
        crtObjectSha256=mz.sha(args.crt_object.read_bytes()),loaderProof=str(args.output/'loader/boundary-proof.json'),
        helperProof=str(args.output/'crt-helpers/boundary-proof.json'),crtContribution=contribution,helpers=located,
        loadedStartupBytesProved=loader['loadedBytes']+sum(item['loadedBytes'] for item in located),
        instructionRows=loader['instructionRows']+sum(item['instructionRows'] for item in helpers['helpers']),
        exactPrimarySourcesAndFinalBytes=True,isaAuditRequired=True,policySha256=mz.sha(Path(__file__).read_bytes()))
    (args.output/'startup-linked-proof.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(f"Startup final-byte proof PASS: {report['loadedStartupBytesProved']} loaded bytes; {report['instructionRows']} CODE rows require strict ISA auditing.")
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('archive','executable','map','crt-object','djasm','objdump','output'):
        parser.add_argument('--'+name,type=Path,required=True)
    build(parser.parse_args())


if __name__=='__main__':main()
