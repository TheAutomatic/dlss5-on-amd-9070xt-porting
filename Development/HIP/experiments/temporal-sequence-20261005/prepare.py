"""CPU-only controlled sequence. Not a replay of 111.mp4 or a game capture."""
import argparse, hashlib, json
from pathlib import Path
import numpy as np

def fingerprint(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def make_sequence(out, full=False):
    out.mkdir(parents=True, exist_ok=True)
    frames=[]
    # Small CPU contract cases, not valid full-network performance shapes.
    specs=[(64,40,48,0,True,True), (64,40,48,0,False,True),
           (64,40,48,1,False,True), (64,40,48,2,False,True),
           (64,40,48,2,True,True), (64,40,48,3,False,False),
           (80,48,64,0,False,True), (80,48,64,1,False,True)]
    if full:
        specs=[(1920,1080,1152,o,r,m) for _,_,_,o,r,m in specs[:6]] + [(2560,1440,1472,o,r,m) for _,_,_,o,r,m in specs[6:]]
    for i,(w,h,ph,offset,reset,motion_valid) in enumerate(specs):
        y,x=np.mgrid[:h,:w]
        # Original encoded sRGB-like working-domain input; no linear codec inference.
        rgb=np.empty((h,w,4),np.float32)
        rgb[:,:,0]=.24+.03*((x//8+y//8)%2)
        rgb[:,:,1]=.31+.02*((x//8+y//8)%2)
        rgb[:,:,2]=.37
        rgb[:,:,3]=1
        moving=(x>=20+offset)&(x<32+offset)&(y>=14)&(y<26)
        rgb[moving,:3]=(.65,.55,.4)
        depth=np.full((h,w),.8,np.float32);depth[moving]=.3
        mv=np.zeros((h,w,2),np.float32)
        # Current->previous displacement in valid-network pixels. Object advances +1.
        if i in (2,3,5,7): mv[moving,0]=-1
        idx=np.arange(ph);idx=np.where(idx<h,idx,2*h-idx-2)
        padded=rgb[idx].astype('<f4')
        assets={}
        for name,data in [('encoded.rgba32f',padded),('motion.rg32f',mv),('depth.r32f',depth)]:
            path=out/f'{i:02d}-{name}';data.astype('<f4').tofile(path)
            assets[name]={'path':path.name,'bytes':path.stat().st_size,'sha256':fingerprint(path)}
        frames.append({'frame':i,'valid':[w,h],'processing':[w,ph],
                       'reset':reset,'motion_valid':motion_valid,'frame_seed':i,
                       'fixed_seed':0,'moving_offset':offset,'files':assets})
    manifest={'source':'procedural synthetic; not game data or 111.mp4 input',
              'network_inference_valid_shape':full,
              'color_domain':'encoded sRGB-like working-domain RGB, alpha1; no output decoding',
              'style':1,'style_feature':0.0078125,'passes':1,'skin_protect':0,
              'strength':[1.0,1.0],'jitter':[0.0,0.0],
              'motion':'current-to-previous displacement, valid-network pixels, negative x for right-moving object',
              'motion_conversion':'previous_uv=(pixel_center+motion)/valid_extent',
              'depth':'synthetic linear visibility marker, near=.3/far=.8; not a game depth contract',
              'padding':'bottom mirror index 2*valid_height-y-2, unnormalized stored texels',
              'routes':['spatial','prefix-only','prefix+native-gated-post (gate arithmetic pending oracle)'],
              'seed_variants':['fixed0','counter-reset-on-epoch'],
              'frames':frames}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    return manifest

class HistoryEpoch:
    """Explicit ordered-queue lease model; no GPU execution or approximation math."""
    def __init__(self):
        self.shape=None;self.ready=False;self.generation=0;self.seed=0
        self.pending=None;self.completed=0;self.read=None;self.write=None
    def begin(self,shape,reset,motion_valid,route,seed_mode):
        if self.pending is not None: raise RuntimeError('previous frame not committed')
        changed=shape!=self.shape
        if changed or reset:
            self.shape=shape;self.ready=False;self.generation+=1;self.seed=0
        history=route!='spatial' and self.ready and motion_valid and not reset
        current_seed=0 if seed_mode=='fixed0' else self.seed
        # Both history readers share immutable prior output; scratch warp is separate.
        self.read=self.completed%2 if history else None
        self.write=(self.completed+1)%2
        assert self.read is None or self.read!=self.write
        self.pending=(history,current_seed)
        return history,current_seed
    def commit(self,queue_completed=True):
        if self.pending is None: raise RuntimeError('no frame in flight')
        # CPU publication alone is insufficient to reuse a buffer on another queue.
        if not queue_completed: raise RuntimeError('completion required before cross-queue reuse')
        self.completed+=1;self.ready=True;self.seed+=1;self.pending=None

def check(manifest,out):
    log=[]
    for route in manifest['routes']:
        for seed_mode in ('fixed0','counter-reset-on-epoch'):
            epoch=HistoryEpoch();actual=[]
            for f in manifest['frames']:
                h,seed=epoch.begin(tuple(f['valid']+f['processing']),f['reset'],f['motion_valid'],route,seed_mode)
                actual.append(h);log.append({'route':route,'seed_mode':seed_mode,'frame':f['frame'],
                                            'history':h,'seed':seed,'generation':epoch.generation,
                                            'read_slot':epoch.read,'write_slot':epoch.write})
                epoch.commit()
            expected=[False,True,True,True,False,False,False,True]
            assert actual==([False]*8 if route=='spatial' else expected)
    # Zero motion maps identity, one-pixel object motion has correct sign; padding intact.
    for f in manifest['frames']:
        w,h=f['valid'];_,ph=f['processing']
        color=np.fromfile(out/f['files']['encoded.rgba32f']['path'],'<f4').reshape(ph,w,4)
        assert np.isfinite(color).all()
        assert np.array_equal(color[h:],color[np.arange(h,ph)*-1+2*h-2])
    # Integer-lattice reference only: validate current->previous sign, not native sampler arithmetic.
    second=manifest['frames'][2];w,h=second['valid']
    mv=np.fromfile(out/second['files']['motion.rg32f']['path'],'<f4').reshape(h,w,2)
    x,y=22,18
    previous_pixel=np.array([x+.5,y+.5],np.float32)+mv[y,x]
    assert np.array_equal(previous_pixel,np.array([x-.5,y+.5],np.float32))
    # Rejected asynchronous publication is a tested lifecycle boundary.
    e=HistoryEpoch();e.begin((64,40,64,48),True,True,'prefix-only','fixed0')
    try:e.commit(False)
    except RuntimeError:pass
    else:raise AssertionError('unsafe publication accepted')
    (out/'cpu-state-proof.json').write_text(json.dumps({'pass':True,'scope':'CPU lifecycle/metadata only; no NN or native warp parity claim','timeline':log},indent=2)+'\n')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('out',type=Path);ap.add_argument('--full',action='store_true');args=ap.parse_args()
    m=make_sequence(args.out,args.full);check(m,args.out)
    print('CPU_STATE_PASS: 3 routes x 2 seed policies x 8 frames; reset/resize/missing-motion and lease guards')
