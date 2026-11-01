// Recolour the existing RGB pixels only. Never resample or change alpha/geometry.
const sharp = require('sharp');
const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'output/te-all-directions-colours');
const source = path.join(root, 'assets/characters/open_world/te-walk-v14.png');
const destination = path.join(root, 'assets/characters/open_world/te-walk-v14-palette.png');
const L = (r,g,b) => .2126*r+.7152*g+.0722*b;
const median = a => a.sort((a,b)=>a-b)[Math.floor(a.length/2)];
const smooth = x => { const t=Math.max(0,Math.min(1,(x-5.1)/25.5));return t*t*(3-2*t); };
const hash = d => crypto.createHash('sha256').update(d).digest('hex');

function components(mask,w,h) {
  const seen=new Uint8Array(mask.length), groups=[];
  for(let start=0;start<mask.length;start++) {
    if(!mask[start]||seen[start])continue;
    seen[start]=1;const g=[start];
    for(let q=0;q<g.length;q++) {
      const i=g[q],x=i%w,y=Math.floor(i/w);
      for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
        const xx=x+dx,yy=y+dy,k=yy*w+xx;
        if(xx<0||xx>=w||yy<0||yy>=h||seen[k]||!mask[k])continue;
        seen[k]=1;g.push(k);
      }
    }
    groups.push(g);
  }
  return groups.sort((a,b)=>b.length-a.length);
}
function dilate(mask,w,h,r) {
  const expanded=new Uint8Array(mask);
  for(let i=0;i<mask.length;i++)if(mask[i]) {
    const x=i%w,y=Math.floor(i/w);
    for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++) {
      const xx=x+dx,yy=y+dy;
      if(xx>=0&&xx<w&&yy>=0&&yy<h)expanded[yy*w+xx]=1;
    }
  }
  return expanded;
}
function fillSmallHoles(mask,w,h,d) {
  const inverse=new Uint8Array(mask.map(v=>!v));
  for(const g of components(inverse,w,h)) {
    if(g.length>w*h*.008||g.some(i=>i%w===0||i%w===w-1||i<w||i>=w*(h-1)))continue;
    // Enclosed warm stitching belongs to the cloth; keep warm skin untouched.
    if(g.some(i=>d[i*4]-d[i*4+1]>48&&d[i*4+1]-d[i*4+2]>20))continue;
    for(const i of g)if(d[i*4+3]>4)mask[i]=1;
  }
}
function inPolygon(x,y,points) {
  let inside=false;
  for(let i=0,j=points.length-1;i<points.length;j=i++) {
    const a=points[i],b=points[j];
    if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])inside=!inside;
  }
  return inside;
}
function materialMasks(d,w,h,row,frame) {
  const n=w*h,skin=new Uint8Array(n),warmSkin=new Uint8Array(n),shirtCandidates=new Uint8Array(n),shortsCandidates=new Uint8Array(n);
  const l=new Float32Array(n),chroma=new Uint8Array(n);
  for(let i=0;i<n;i++) {
    const k=i*4,r=d[k],g=d[k+1],b=d[k+2];
    l[i]=L(r,g,b);chroma[i]=Math.max(r,g,b)-Math.min(r,g,b);
    if(d[k+3]>8&&r>80&&r-g>32&&g-b>15)skin[i]=1;
    if(d[k+3]>8&&r>80&&r-g>44&&g-b>20)warmSkin[i]=1;
  }
  const protectedSkin=dilate(skin,w,h,3),shortsSkin=dilate(warmSkin,w,h,2),raisedShoe=new Uint8Array(n);
  // In this authored pose, the lifted shoe overlaps the shorts vertically.
  // Its material guide only disambiguates colours; no pixel is moved.
  if(row===3&&frame>=7)for(let i=0;i<n;i++)if(inPolygon(i%w,Math.floor(i/w),[[326,538],[365,541],[390,572],[390,622],[350,657],[313,684],[263,680],[263,648],[282,626],[301,607],[314,573]]))raisedShoe[i]=1;
  for(let i=0;i<n;i++) {
    const k=i*4,y=Math.floor(i/w)/h,r=d[k],g=d[k+1],b=d[k+2];
    if(d[k+3]<=4)continue;
    if(!protectedSkin[i]&&y>.265&&y<.655&&l[i]<145&&chroma[i]<40&&r-g<26&&g-b<24)shirtCandidates[i]=1;
    if(!shortsSkin[i]&&y>.535&&y<.80&&!raisedShoe[i]&&l[i]>55&&chroma[i]<79&&r-g<44&&g-b<35&&!(y<.60&&l[i]<115))shortsCandidates[i]=1;
  }
  const shirt=new Uint8Array(n),shorts=new Uint8Array(n),shoes=new Uint8Array(n),soles=new Uint8Array(n);
  const shirtGroups=components(shirtCandidates,w,h);
  const torso=shirtGroups.find(g=>g.some(i=>Math.floor(i/w)>.40*h&&Math.floor(i/w)<.54*h));
  if(!torso)throw Error('Missing shirt');
  for(const i of torso)shirt[i]=1;
  const shortsGroups=components(shortsCandidates,w,h);
  const fabric=shortsGroups.find(g=>g.length>n*.015&&g.some(i=>Math.floor(i/w)<h*.65&&l[i]>150));
  if(!fabric)throw Error('Missing shorts');
  for(const i of fabric)shorts[i]=1;
  // Main shorts panels may be separated by an outline or by an overlapping arm.
  for(const g of shortsGroups)if(g!==fabric&&g.length>fabric.length*.12&&g.some(i=>Math.floor(i/w)<h*.66))for(const i of g)shorts[i]=1;
  fillSmallHoles(shorts,w,h,d);
  const shoesCandidates=new Uint8Array(n);
  for(let i=0;i<n;i++) {
    const k=i*4,y=Math.floor(i/w)/h;
    if((y>.66||raisedShoe[i])&&d[k+3]>4&&!protectedSkin[i]&&!shorts[i]&&chroma[i]<75&&d[k]-d[k+1]<45&&d[k+1]-d[k+2]<35)shoesCandidates[i]=1;
  }
  for(const g of components(shoesCandidates,w,h)) {
    if(g.length<n*.001||!g.some(i=>Math.floor(i/w)>h*.73))continue;
    for(const i of g)shoes[i]=1;
  }
  const bright=new Uint8Array(n);
  for(let i=0;i<n;i++)if(shoes[i]&&l[i]>80)bright[i]=1;
  for(const g of components(bright,w,h)) {
    if(g.length<8||!g.some(i=>l[i]>150))continue;
    for(const i of g)soles[i]=1;
  }
  // Preserve dark tread lines, while recolouring the bright trim around them.
  for(let i=0;i<n;i++)if(shorts[i])shirt[i]=0;
  return {shirt,shorts,shoes,soles,protectedSkin,l};
}
function materialMedian(d,mask,lo=0,hi=255) {
  const a=[];
  for(let i=0;i<mask.length;i++)if(mask[i]&&d[i*4+3]>127) {
    const v=L(d[i*4],d[i*4+1],d[i*4+2]);if(v>lo&&v<hi)a.push(v);
  }
  if(!a.length)throw Error('Empty material sample');
  return median(a);
}
function tint(d,i,target,ratio,chroma) {
  const k=i*4,old=[d[k],d[k+1],d[k+2]],l=L(...old),t=L(...target);
  for(let c=0;c<3;c++)d[k+c]=Math.max(0,Math.min(255,Math.round(l*ratio+target[c]-t+(old[c]-l)*chroma)));
}
async function normalise(d,w,h,anchor,shader=true) {
  const p=Buffer.from(d);
  if(shader)for(let k=3;k<p.length;k+=4)p[k]=Math.round(255*smooth(p[k]));
  const scale=438/h,rw=Math.round(w*scale);
  const sprite=await sharp(p,{raw:{width:w,height:h,channels:4}}).resize(rw,438).png().toBuffer();
  return sharp({create:{width:400,height:560,channels:4,background:'#00000000'}}).composite([{input:sprite,left:Math.round(200-anchor[0]*scale),top:82}]).png().toBuffer();
}
async function main() {
  await fs.mkdir(out,{recursive:true});
  const regions=JSON.parse(await fs.readFile(path.join(out,'source-regions.json')));
  const palette=JSON.parse(await fs.readFile(path.join(root,'output/te-south-final-details/recipe.json')));
  const shirtTarget=palette.shirtAndSoleTarget,shortsTarget=palette.shortsTarget;
  const {data:original,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const atlas=Buffer.from(original),union=new Uint8Array(info.width*info.height),frames=[],samples=[];
  for(let row=1;row<5;row++)for(let f=0;f<9;f++) {
    const index=row*9+f,[x,y,w,h]=regions.rects[index],d=Buffer.alloc(w*h*4);
    for(let yy=0;yy<h;yy++)original.copy(d,yy*w*4,((y+yy)*info.width+x)*4,((y+yy)*info.width+x+w)*4);
    const masks=materialMasks(d,w,h,row,f);
    if(f===0) {
      const upper=new Uint8Array(masks.shoes.map((v,i)=>v&&!masks.soles[i]?1:0));
      samples[row]={shirt:materialMedian(d,masks.shirt,25,130),shorts:materialMedian(d,masks.shorts,100),shoes:materialMedian(d,upper,25,115),soles:materialMedian(d,masks.soles,100)};
    }
    const painted=Buffer.from(d),s=samples[row],counts={shirt:0,shorts:0,shoes:0,soles:0},shortsRatio=L(...shortsTarget)/s.shorts;
    for(let i=0;i<w*h;i++) {
      let material=null;
      if(masks.shirt[i]){tint(painted,i,shirtTarget,L(...shirtTarget)/s.shirt,.08);material='shirt';}
      if(masks.shorts[i]){tint(painted,i,shortsTarget,shortsRatio,.08);material='shorts';}
      if(masks.shoes[i]){tint(painted,i,shirtTarget,L(...shirtTarget)/(masks.soles[i]?s.soles:s.shoes),.03);material=masks.soles[i]?'soles':'shoes';}
      if(material){counts[material]++;union[(y+Math.floor(i/w))*info.width+x+i%w]=1;}
    }
    for(let yy=0;yy<h;yy++)painted.copy(atlas,((y+yy)*info.width+x)*4,yy*w*4,(yy+1)*w*4);
    const maskRGB=Buffer.from(d);
    for(let i=0;i<w*h;i++) {
      const color=masks.shirt[i]?[70,150,255]:masks.shorts[i]?[80,235,110]:masks.shoes[i]?[255,80,180]:null;
      if(color)for(let c=0;c<3;c++)maskRGB[i*4+c]=color[c];
    }
    frames.push({row,frame:f,index,counts,before:await normalise(d,w,h,regions.anchors[index]),after:await normalise(painted,w,h,regions.anchors[index]),mask:await normalise(maskRGB,w,h,regions.anchors[index])});
  }
  await sharp(atlas,{raw:{width:info.width,height:info.height,channels:4}}).png().toFile(destination);
  let alphaChanges=0,outsideChanges=0,changedPixels=0;
  for(let i=0;i<union.length;i++) {
    const k=i*4,changed=original[k]!==atlas[k]||original[k+1]!==atlas[k+1]||original[k+2]!==atlas[k+2];
    if(original[k+3]!==atlas[k+3])alphaChanges++;
    if(changed){changedPixels++;if(!union[i])outsideChanges++;}
  }
  if(alphaChanges||outsideChanges)throw Error('Recolouring changed protected pixels');
  for(const kind of ['after','mask']) {
    const overlays=[];
    for(const f of frames)overlays.push({input:await sharp(f[kind]).resize(200,280).png().toBuffer(),left:f.frame*200,top:(f.row-1)*300+20});
    await sharp({create:{width:1800,height:1200,channels:3,background:'#a7b29b'}}).composite(overlays).png().toFile(path.join(out,`${kind}-all-poses.png`));
  }
  const comparison=[];
  for(let row=1;row<5;row++) {
    const f=frames.find(f=>f.row===row&&f.frame===1);
    comparison.push({input:f.before,left:(row-1)*400,top:0},{input:f.after,left:(row-1)*400,top:560});
  }
  await sharp({create:{width:1600,height:1120,channels:3,background:'#a7b29b'}}).composite(comparison).png().toFile(path.join(out,'before-after.png'));
  const report={source,destination,dimensions:[info.width,info.height],shirtAndShoeTarget:shirtTarget,shortsTarget,samples,verification:{alphaChanges,outsideMaterialRGBChanges:outsideChanges,changedPixels,sourceSHA256:hash(original),outputSHA256:hash(atlas)},frames:frames.map(({row,frame,index,counts})=>({row,frame,index,counts}))};
  await fs.writeFile(path.join(out,'verification.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report,null,2));
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1});
module.exports={materialMasks};
