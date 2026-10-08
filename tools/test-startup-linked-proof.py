"""Reject changed final loader/helper bytes and incorrect linker locations."""
from pathlib import Path
import argparse,contextlib,hashlib,importlib.util,io,json,re,struct,tempfile


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('archive','executable','map','crt-object','djasm','objdump'):
        parser.add_argument('--'+name,type=Path,required=True)
    args=parser.parse_args();root=Path(__file__).resolve().parents[1]
    spec=importlib.util.spec_from_file_location('startup_test',Path(__file__).with_name('startup-linked-proof.py'))
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    work=Path(tempfile.mkdtemp(prefix='startup-linked-regression-',dir=root/'out'))
    original={name:hashlib.sha256(getattr(args,name).read_bytes()).hexdigest() for name in ['archive','executable','map','crt_object','djasm','objdump']}
    args.output=work/'valid'
    with contextlib.redirect_stdout(io.StringIO()):valid=module.build(args)
    assert valid['exactPrimarySourcesAndFinalBytes'] and valid['instructionRows']==529 and valid['isaAuditRequired']
    exe=args.executable.read_bytes();mapping=args.map.read_text(encoding='latin1')
    last,pages=struct.unpack_from('<HH',exe,2);base=pages*512-(512-last if last else 0)
    count=struct.unpack_from('<H',exe,base+2)[0];optional=struct.unpack_from('<H',exe,base+16)[0]
    data=None
    for i in range(count):
        at=base+20+optional+40*i
        if exe[at:at+8].split(b'\0',1)[0]==b'.data':
            address,size,raw=struct.unpack_from('<III',exe,at+12);data=(address,size,base+raw)
    assert data
    located={x['name']:x for x in valid['helpers']}
    crt=re.search(r'^\s+\.data\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)\s+([^\n]*[/\\]crt0\.o)\s*$',mapping,re.M)
    assert crt
    cases={}
    def altered(name,offset,value):
        blob=bytearray(exe);blob[offset]=value;cases[name]=(bytes(blob),mapping)
    header_paragraphs=struct.unpack_from('<H',exe,8)[0]
    altered('loader_instruction',header_paragraphs*16+84,exe[header_paragraphs*16+84]^1)
    altered('loader_entry',20,83)
    for name,offset in [('helper_instruction',located['sbrk16']['linkedEntry']),('helper_api_data',located['sbrk16']['linkedStart']),('exit_instruction',located['exit16']['linkedEntry'])]:
        raw=data[2]+offset-data[0];altered(name,raw,exe[raw]^1)
    line=crt[0]
    cases['map_address']=(exe,mapping.replace(line,line.replace(crt[1],f'{int(crt[1],16)+1:08x}',1),1))
    cases['map_size']=(exe,mapping.replace(line,line.replace('0x'+crt[2],'0x'+f'{int(crt[2],16)+1:x}',1),1))
    cases['map_missing']=(exe,mapping.replace(line,'',1))
    cases['map_duplicate']=(exe,mapping.replace(line,line+'\n'+line,1))
    rejected=[]
    for name,(blob,text) in cases.items():
        directory=work/name;directory.mkdir();executable=directory/'quake.exe';mapfile=directory/'quake.exe.map'
        executable.write_bytes(blob);mapfile.write_text(text,encoding='latin1',newline='')
        fixture=argparse.Namespace(**vars(args));fixture.executable=executable;fixture.map=mapfile;fixture.output=directory/'proof'
        try:
            with contextlib.redirect_stdout(io.StringIO()):module.build(fixture)
        except ValueError as error:rejected.append(dict(name=name,reason=str(error)))
        else:raise AssertionError('Changed final startup evidence was accepted: '+name)
    for name,expected in original.items():assert hashlib.sha256(getattr(args,name).read_bytes()).hexdigest()==expected
    (work/'results.json').write_text(json.dumps(dict(pass_=True,valid=1,rejected=rejected),indent=2)+'\n',encoding='utf-8')
    print(f'PASS: one exact final-byte mapping and {len(rejected)} adversarial rejections; {work}')


if __name__=='__main__':main()
