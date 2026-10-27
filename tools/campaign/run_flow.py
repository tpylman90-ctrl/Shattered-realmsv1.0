"""Exercise real scene callbacks in an isolated disposable Godot user profile."""
import argparse,os,shutil,subprocess,tempfile
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--godot',default='godot');args=parser.parse_args()
root=Path(__file__).resolve().parents[2];godot=shutil.which(args.godot) or args.godot
with tempfile.TemporaryDirectory(prefix='shattered-realms-flow-') as profile:
 env=os.environ.copy();env['XDG_DATA_HOME']=profile
 run=subprocess.run([godot,'--headless','--audio-driver','Dummy','--path',str(root/'game'),'-s',str(root/'tools/campaign/smoke_flow.gd')],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
 output=run.stdout
 (root/'.build').mkdir(exist_ok=True);(root/'.build/campaign-flow.log').write_text(output)
 print(output)
 if run.returncode or 'FLOW PASSED' not in output or 'FLOW FAILED' in output or 'SCRIPT ERROR' in output:raise SystemExit('Campaign scene-flow check failed')
