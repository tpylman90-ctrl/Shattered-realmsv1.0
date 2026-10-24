"""Convert a supplied video for Godot's built-in Theora playback."""
import argparse, subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('output',type=Path)
a=p.parse_args()
if not a.source.is_file(): p.error('Source file does not exist')
if a.output.suffix.lower()!='.ogv': p.error('Output must end in .ogv')
a.output.parent.mkdir(parents=True,exist_ok=True)
subprocess.run(['ffmpeg','-n','-i',str(a.source),'-vf',"scale='min(1280,iw)':-2",'-c:v','libtheora','-q:v','7','-c:a','libvorbis','-q:a','5',str(a.output)],check=True)
