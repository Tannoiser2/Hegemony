import sys,os,re
from PIL import Image
sheet,nw,nh,out,pref=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),sys.argv[4],sys.argv[5]
n=int(sys.argv[6]) if len(sys.argv)>6 else nw*nh
os.makedirs(out,exist_ok=True)
im=Image.open(sheet).convert('RGB'); W,H=im.size; cw,ch=W/nw,H/nh
for i in range(n):
    x,y=i%nw,i//nw
    c=im.crop((round(x*cw),round(y*ch),round((x+1)*cw),round((y+1)*ch)))
    c.save(os.path.join(out,f'{pref}{i:02d}.png'))
