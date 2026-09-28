import json
count=0;shapes=0
for tokens in range(16,4097,16):
 nt=(tokens+31)//32
 for cols in [8,24]:
  old={(b//cols*32,b%cols*64) for b in range(nt*cols)}
  new={(b%nt*32,b//nt*64) for b in range(nt*cols)}
  assert old==new and len(new)==nt*cols
  count+=nt*cols;shapes+=1
print(json.dumps({'geometries':shapes,'group_coordinate_pairs':count,'same_coordinates':True,'scope':'Only workgroup order changes. Each output owns the entire original K sequence, including 16-token tails.'},indent=2))
