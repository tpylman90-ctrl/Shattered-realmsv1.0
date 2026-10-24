"""Install only the required addon directories from immutable upstream revisions."""
import io, json, shutil, urllib.request, zipfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
for name, dep in json.loads((ROOT/'tools/dependencies.json').read_text()).items():
    dest = ROOT/'game'/dep['directory']
    marker = dest/'.upstream-revision'
    if marker.exists() and marker.read_text() == dep['commit']:
        print(f'{name}: already installed'); continue
    url = f"https://codeload.github.com/{dep['repo']}/zip/{dep['commit']}"
    with urllib.request.urlopen(url, timeout=120) as response:
        archive = zipfile.ZipFile(io.BytesIO(response.read()))
    prefix = archive.namelist()[0].split('/')[0]+'/'
    addon_prefix = prefix+dep['directory']+'/'
    members = [m for m in archive.namelist() if m.startswith(addon_prefix) and not m.endswith('/')]
    if not members: raise RuntimeError(f'Missing addon in {url}')
    if dest.exists(): shutil.rmtree(dest)
    for member in members:
        target = dest/member[len(addon_prefix):]
        if not target.resolve().is_relative_to(dest.resolve()): raise ValueError('Unsafe path')
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(archive.read(member))
    for member in archive.namelist():
        relative = member[len(prefix):]
        if '/' not in relative and relative.lower().startswith(('license','copying')) and not member.endswith('/'):
            (dest/Path(relative).name).write_bytes(archive.read(member))
    marker.write_text(dep['commit'])
    print(f"{name}: {dep['commit']}")
