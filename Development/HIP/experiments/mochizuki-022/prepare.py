from pathlib import Path
import shutil,tarfile
root=Path(__file__).resolve().parents[4];here=Path(__file__).resolve().parent;out=Path('/tmp/mochizuki-022');out.mkdir(exist_ok=True)
shutil.copytree(root/'hip',out/'hip',dirs_exist_ok=True,ignore=shutil.ignore_patterns('modules','*.exe','*.hsaco','__pycache__'))
for n in ['regression.ps1','collect.ps1','collect-adaptive.ps1']:
 s=(here.parent/'c512-round1'/n).read_text().replace('c512-round1','mochizuki-022');(here/n).write_text(s);(out/n).write_text(s)
for p in here.glob('*.ps1'):shutil.copy2(p,out/p.name)
with tarfile.open('/tmp/mochizuki-022.tar.gz','w:gz') as t:t.add(out,arcname='mochizuki-022')
