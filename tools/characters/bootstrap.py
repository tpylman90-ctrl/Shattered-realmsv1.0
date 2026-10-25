"""Install the pinned MPFB authoring extension, preserving upstream licenses.
Blender's bundled Rigify is enabled by rig_starters.py. Neither runs on Android.
"""
from pathlib import Path
import hashlib,io,json,shutil,urllib.request,zipfile
ROOT=Path(__file__).resolve().parents[2]
REVISION='d0a32e57a7f915cb2f2b95410e2117648c7bbb7e'
DEST=ROOT/'.tools/character-extensions/mpfb'
marker=DEST/'.upstream-revision'
if marker.exists() and marker.read_text().strip()==REVISION:
 print('MPFB 2.0.18 already installed');raise SystemExit(0)
url=f'https://codeload.github.com/makehumancommunity/mpfb2/zip/{REVISION}'
with urllib.request.urlopen(url,timeout=120) as response:data=response.read()
assert hashlib.sha256(data).hexdigest()=='b50c69cea33cce250ca49d838079904da7fb84a21943f3cb7fc5a9bb3e0165f8', 'MPFB source archive hash mismatch'
z=zipfile.ZipFile(io.BytesIO(data));prefix=z.namelist()[0].split('/')[0]+'/'
if DEST.exists():shutil.rmtree(DEST)
for entry in z.namelist():
 if entry.startswith(prefix+'src/mpfb/') and not entry.endswith('/'):
  relative=entry[len(prefix+'src/mpfb/'):];target=DEST/relative
  if not target.resolve().is_relative_to(DEST.resolve()):raise ValueError('Unsafe archive path')
  target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(entry))
for name in ['LICENSE.md','LICENSE.CODE.md','LICENSE.ASSETS.md']: (DEST/name).write_bytes(z.read(prefix+name))
marker.write_text(REVISION)
print(json.dumps({'mpfb':'2.0.18','revision':REVISION,'archive_sha256':hashlib.sha256(data).hexdigest(),'destination':str(DEST)}))
