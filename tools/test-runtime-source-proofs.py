"""Adversarial checks for pinned runtime input/source identity and completeness."""
from pathlib import Path
import copy,importlib.util,json,shutil,tempfile

spec=importlib.util.spec_from_file_location('runtime_proofs',Path(__file__).with_name('runtime-source-proofs.py'))
runtime=importlib.util.module_from_spec(spec);spec.loader.exec_module(runtime)
source=Path(__file__).with_name('isa-runtime-reference')
root=Path(tempfile.mkdtemp(prefix='runtime-source-regression-',dir=Path(__file__).resolve().parents[1]/'out'))
bundle=root/'bundle';shutil.copytree(source,bundle)
original=runtime.load(bundle/'manifest.json');assert len(runtime.validate_bundle(bundle))==235
failures=[];rejections=0
def reject(name,change):
    global rejections
    index=copy.deepcopy(original);change(index)
    (bundle/'manifest.json').write_text(json.dumps(index),encoding='utf-8')
    try:runtime.validate_bundle(bundle)
    except (ValueError,OSError,KeyError):rejections+=1
    else:failures.append(name)
reject('duplicate file',lambda i:i['files'].append(i['files'][0]))
reject('duplicate runtime identity',lambda i:i['entries'].append(i['entries'][0]))
reject('escaped path',lambda i:i['files'][0].update(path='../manifest.json'))
reject('changed file identity',lambda i:i['files'][0].update(sha256='0'*64))
reject('changed file length',lambda i:i['files'][0].update(bytes=i['files'][0]['bytes']+1))
reject('listing identity',lambda i:i['entries'][0].update(assemblySha256='0'*64))
reject('primary C identity',lambda i:i['entries'][0].update(primarySourceSha256='0'*64))
reject('missing primary C source',lambda i:i['entries'][0].pop('cSource'))
reject('conflicting source kind',lambda i:i['entries'][0].update(handwrittenAssembly=True))
reject('permissive unknown policy',lambda i:i.update(unknownRuntimeObjectPolicy='raw-decode'))
reject('runtime replacement policy',lambda i:i.update(replacesRuntimeObjects=True))
(bundle/'manifest.json').write_text(json.dumps(original),encoding='utf-8')
inputs=[dict(object='not-reviewed.obj',sha256='0'*64)]
try:runtime.build(bundle,root,inputs,root/'unused-compiler',root/'unused-output')
except ValueError:rejections+=1
else:failures.append('unknown runtime member')
inputs=[dict(object=original['entries'][0]['object'],sha256=original['entries'][0]['objectSha256'])]
(root/inputs[0]['object']).write_bytes(b'changed native object')
try:runtime.build(bundle,root,inputs,root/'unused-compiler',root/'unused-output')
except ValueError:rejections+=1
else:failures.append('changed native object')
report=dict(passed=not failures,pinnedObjects=235,adversarialRejections=rejections,failures=failures)
(root/'result.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report));assert not failures
