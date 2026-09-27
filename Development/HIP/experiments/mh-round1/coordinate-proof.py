import json
count=0
for W,H in ((512,512),(1280,768),(1600,960),(1600,1024),(1920,1152)):
 for div in (4,8,16):
  w,h=W//div,H//div
  for sx in (0,4):
   for sy in (0,4):
    ww,hh=(w+sx+7)&~7,(h+sy+7)&~7
    for win in range((ww//8)*(hh//8)):
     for t in range(64):
      x=(win%(ww//8))*8+t%8;y=(win//(ww//8))*8+t//8;p=y*ww+x
      assert 0<=p<2**32 and (p%ww,p//ww)==(x,y)
      assert ((p%ww-sx>=0 and p//ww-sy>=0 and p%ww-sx<w and p//ww-sy<h)==(sx<=x<sx+w and sy<=y<sy+h))
      count+=1
print(json.dumps({'supported_geometries':5,'channel_families':3,'shifts':4,'checked_coordinates':count,'mismatches':0}))
