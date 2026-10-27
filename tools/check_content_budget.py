"""Cap shipped content at 3 GB, preserving 0.5 GB for runtime/user data."""
import json,sys,zipfile
from pathlib import Path
LIMIT=3_000_000_000
if len(sys.argv)>1:
 p=Path(sys.argv[1])
 with zipfile.ZipFile(p) as archive: size=sum(i.file_size for i in archive.infolist())
else:
 size=sum(p.stat().st_size for p in Path('game/assets').rglob('*') if p.is_file() and p.suffix!='.import')
print(json.dumps({'content_bytes':size,'content_ceiling_bytes':LIMIT,'total_target_bytes':3_500_000_000,'within_budget':size<=LIMIT}))
if size>LIMIT: raise SystemExit('Content budget exceeded')
