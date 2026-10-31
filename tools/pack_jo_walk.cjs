// Jo's painted identity and authored neck/collar, baked into complete poses.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {largest}=require('./prepare_te_natural_sources.cjs');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const F=4,W=800,H=1120,HEIGHTS=[219,213,212,212,232];
const HEAD_HEIGHTS=[73,72,70,68,68],REPAIRS=[84,84,88,84,84],BLENDS=[68,64,61,60,64];
function bounds(data,w,h,ymax=h){
 let l=w,r=-1,t=h,b=-1;
 for(let y=0;y<ymax;y++)for(let x=0;x<w;x++)if(data[(y*w+x)*4+3]>127){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
 if(r<0)throw Error('Empty head/body');return{left:l,top:t,right:r,bottom:b,width:r-l+1,height:b-t+1,center:(l+r)/2};
}
function clean(data,w,h){
 for(let i=0;i<data.length;i+=4){const r=data[i],g=data[i+1],b=data[i+2];
  if(data[i+3]<128||(r>215&&g<60&&b<80)||(r>200&&g>170&&b<70))data.fill(0,i,i+4);
 }
 for(let y=2;y<h-2;y++)for(let x=2;x<w-2;x++){
  const i=(y*w+x)*4,r=data[i],g=data[i+1],b=data[i+2];
  if(!((r>150&&g>110&&b<85)||(r>170&&g<70&&b<90)))continue;
  let edge=false;for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++)if(data[((y+dy)*w+x+dx)*4+3]<10)edge=true;
  if(edge)data.fill(0,i,i+4);
 }
 const mask=largest(Uint8Array.from({length:w*h},(_,p)=>data[p*4+3]>10?1:0),w,h);
 for(let p=0;p<mask.length;p++)if(!mask[p])data.fill(0,p*4,p*4+4);
}
// Burgundy has blue above green. Brown jaw/neck shadows have green above blue
// and must remain part of the identity, even where they meet the source collar.
function maroon(d,i){return d[i+3]>24&&d[i]>d[i+1]*1.2&&d[i+2]>d[i+1]+1&&d[i+1]<135;}
function clothMask(d,w,h,minY,loose=false){
 const m=new Uint8Array(w*h);
 for(let y=minY;y<h;y++)for(let x=0;x<w;x++)if(maroon(d,(y*w+x)*4)||(loose&&d[(y*w+x)*4+3]>24&&d[(y*w+x)*4]>d[(y*w+x)*4+1]*1.2&&d[(y*w+x)*4+2]>d[(y*w+x)*4+1]*.86&&d[(y*w+x)*4+1]<135))m[y*w+x]=1;
 return largest(m,w,h);
}
function clothEnvelope(d,w,h,minY,loose=false){
 const core=clothMask(d,w,h,minY,loose),mask=new Uint8Array(w*h),first=new Int32Array(w).fill(h);
 for(let x=0;x<w;x++)for(let y=minY;y<h;y++)if(core[y*w+x]){first[x]=y;break;}
 for(let x=0;x<w;x++)for(let y=first[x];y<h;y++)if(d[(y*w+x)*4+3]>24)mask[y*w+x]=1;
 if(!loose)for(let x=1;x<w-1;x++)for(let y=Math.max(minY,first[x]-F);y<first[x];y++){
  const i=(y*w+x)*4;if(d[i+3]>10&&!skin(d,i)&&(first[x-1]<=y+F||first[x+1]<=y+F))mask[y*w+x]=1;
 }
 if(loose)for(let x=0;x<w;x++)for(let y=first[x];y<h;y++)mask[y*w+x]=1;
 return{mask,first};
}
function smooth(t){t=Math.max(0,Math.min(1,t));return t*t*(3-2*t);}
function skin(d,i){return d[i+3]>127&&d[i]>105&&d[i]>d[i+1]*1.12&&d[i+1]>d[i+2]*1.07;}
function over(d,i,head,a){
 const b=d[i+3]/255,alpha=a+b*(1-a);if(!alpha){d.fill(0,i,i+4);return;}
 for(let c=0;c<3;c++)d[i+c]=Math.round((head[i+c]*a+d[i+c]*b*(1-a))/alpha);
 d[i+3]=Math.round(alpha*255);
}
async function headFor(raw,row,target){
 const left=Math.round(row*raw.info.width/5),right=Math.round((row+1)*raw.info.width/5),w=right-left,h=raw.info.height;
 const data=Buffer.alloc(w*h*4);
 for(let y=0;y<h;y++)raw.data.copy(data,y*w*4,(y*raw.info.width+left)*4,(y*raw.info.width+right)*4);
 clean(data,w,h);
 const bb=bounds(data,w,h),sh=bb.height;
 const source=Buffer.from(data.subarray(bb.top*w*4,(bb.bottom+1)*w*4));
 const hair=bounds(source,w,sh,Math.round(sh*.5));
 let neckBottom=0;
 for(let y=Math.round(sh*.55);y<sh;y++)for(let x=0;x<w;x++)if(skin(source,(y*w+x)*4))neckBottom=Math.max(neckBottom,y);
 const rw=Math.round(w*target.width*F/hair.width),rh=Math.round(sh*HEAD_HEIGHTS[row]*F/(neckBottom+1));
 const small=await sharp(source,{raw:{width:w,height:sh,channels:4}}).resize(Math.round(rw/F),Math.round(rh/F),{fit:'fill'}).png().toBuffer();
 const projected=await sharp(small).resize(rw,rh,{fit:'fill',kernel:'linear'}).raw().toBuffer();
 const ox=Math.round(target.center*F-hair.center*rw/w),oy=target.top*F;
 const head=Buffer.alloc(W*REPAIRS[row]*F*4),foreground=new Uint8Array(W*REPAIRS[row]*F);
 for(let y=0;y<rh;y++)for(let x=0;x<rw;x++){
  const xx=x+ox,yy=y+oy;if(xx<0||xx>=W||yy>=REPAIRS[row]*F)continue;
  const i=(yy*W+xx)*4,j=(y*rw+x)*4;projected.copy(head,i,j,j+4);
  if(yy<(target.top+BLENDS[row])*F&&head[i+3]>0)foreground[yy*W+xx]=1;
 }
 const blend=(target.top+BLENDS[row])*F;
 let neckLeft=W,neckRight=0,lastNeck=0;
 for(let y=Math.max(0,blend-6*F);y<Math.min(REPAIRS[row]*F,blend+6*F);y++){
  let l=W,r=0;for(let x=0;x<W;x++)if(skin(head,(y*W+x)*4)){l=Math.min(l,x);r=Math.max(r,x);}
  if(r-l>6*F)lastNeck=y;
 }
 for(let y=Math.max(0,lastNeck-2*F);y<=lastNeck;y++)for(let x=0;x<W;x++){
  if(skin(head,(y*W+x)*4)){neckLeft=Math.min(neckLeft,x);neckRight=Math.max(neckRight,x);}
 }
 return{head,foreground,blend,neckLeft,neckRight,lastNeck,cleaned:data,width:w,height:h,left};
}
function moveHead(head,dx){
 const pixels=Buffer.alloc(head.head.length),foreground=new Uint8Array(head.foreground.length);
 for(let p=0;p<head.foreground.length;p++){
  const x=p%W,nx=x+dx;if(nx<0||nx>=W)continue;
  const q=p+dx;head.head.copy(pixels,q*4,p*4,p*4+4);foreground[q]=head.foreground[p];
 }
 return{...head,head:pixels,foreground,neckLeft:head.neckLeft+dx,neckRight:head.neckRight+dx};
}
async function packJo(){
 const raw=await sharp(path.join(DIR,'sources/jo-busts-v9.raw.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const cleanStrip=Buffer.alloc(raw.data.length),atlas=Buffer.alloc(4000*5600*4),identityMask=Buffer.alloc(800*5600*4),regions=[],anchors=[],report=[],headOffsets=[];
 for(let row=0;row<5;row++){
  const top=260-HEIGHTS[row],height=HEIGHTS[row]*F,repair=REPAIRS[row]*F;
  const neutral=await sharp(path.join(DIR,'sources/jo-body-v8.png')).extract({left:0,top:row*H+top*F,width:W,height}).raw().toBuffer();
  const native=await sharp(neutral,{raw:{width:W,height,channels:4}}).resize(200,HEIGHTS[row]).raw().toBuffer();
  const target=bounds(native,200,HEIGHTS[row],35),prototype=await headFor(raw,row,target);
  // Test-only mask: opaque portrait pixels, excluding antialiased silhouette
  // edges whose background legitimately changes with the moving garment.
  const identityCloth=clothEnvelope(prototype.head,W,repair,[60,54,53,54,57][row]*F,true).mask;
  for(let y=0;y<=[63,63,63,57,58][row]*F;y++)for(let x=0;x<W;x++)if(prototype.head[(y*W+x)*4+3]===255&&!identityCloth[y*W+x]){
   const i=((row*H+top*F+y)*W+x)*4;identityMask.fill(255,i,i+4);
  }
  for(let y=0;y<raw.info.height;y++)prototype.cleaned.copy(cleanStrip,(y*raw.info.width+prototype.left)*4,y*prototype.width*4,(y+1)*prototype.width*4);
  for(let key=0;key<5;key++){
   const body=await sharp(path.join(DIR,'sources/jo-body-v8.png')).extract({left:key*W,top:row*H+top*F,width:W,height}).raw().toBuffer();
   const poseNative=await sharp(body,{raw:{width:W,height,channels:4}}).resize(200,HEIGHTS[row]).raw().toBuffer();
   const poseHair=bounds(poseNative,200,HEIGHTS[row],35),dx=Math.round((poseHair.center-target.center)*F);
   const replacement=moveHead(prototype,dx);
   headOffsets.push(dx);
   const paint=Buffer.from(body),cloth=clothEnvelope(body,W,height,50*F).mask;
   const patch=clothEnvelope(replacement.head,W,repair,[60,54,53,54,57][row]*F,true);
   const fabricWeight=x=>smooth((x-replacement.neckLeft+7*F)/(4*F))*smooth((replacement.neckRight+7*F-x)/(4*F));
   let oldNeckEnd=0;
   for(let y=50*F;y<Math.min(repair,[78,78,80,78,78][row]*F);y++)for(let x=Math.max(0,replacement.neckLeft-2*F);x<Math.min(W,replacement.neckRight+2*F);x++){
    const i=(y*W+x)*4;if(skin(body,i)&&body[i+1]>body[i+2]*1.18)oldNeckEnd=Math.max(oldNeckEnd,y);
   }
   const fabric=await sharp(body,{raw:{width:W,height,channels:4}}).blur(2*F).raw().toBuffer();
   for(let y=0;y<repair;y++)for(let x=0;x<W;x++){
    const p=y*W+x,i=p*4;
    if(!cloth[p]&&y<[84,80,76,76,78][row]*F)paint.fill(0,i,i+4);
    if(patch.mask[p]&&body[i+3]>127&&fabricWeight(x)>0){
     const q=((repair+5*F)*W+x)*4;
     const old=cloth[p]&&!skin(body,i)?smooth((y-Math.max(oldNeckEnd+2*F,patch.first[x]+4*F))/(4*F)):0;
     const weight=fabricWeight(x);
     for(let c=0;c<3;c++)paint[i+c]=Math.round(cloth[p]?body[i+c]*(1-weight*(1-old))+fabric[q+c]*weight*(1-old):fabric[q+c]);
     paint[i+3]=body[i+3];
    }
   }
   // The painted head, neck and complete curved collar are authored together.
   // Only the fabric beyond that collar blends into each moving shirt pose.
   for(let y=0;y<repair;y++)for(let x=0;x<W;x++){
    const p=y*W+x,i=p*4;let fade=1;
    if(y>=[64,63,64,58,60][row]*F&&fabricWeight(x)===0)continue;
    if(patch.mask[p]){
     if(body[i+3]<128)continue;
     fade=(1-smooth((y-patch.first[x]-.75*F)/(4*F)))*fabricWeight(x);
    }
    over(paint,i,replacement.head,replacement.head[i+3]/255*fade);
   }
   // The profile's bust shoulder must stop at the neck's front edge. The
   // torso beneath follows the original shirt outline in each leaning pose.
   if(row===2)for(let y=(HEAD_HEIGHTS[row]-6)*F;y<80*F;y++)for(let x=replacement.neckRight+F;x<W;x++){
    const p=y*W+x,i=p*4;if(!cloth[p]&&(!skin(replacement.head,i)||y>(HEAD_HEIGHTS[row]+1)*F))paint.fill(0,i,i+4);
   }
   // Close small bounded gaps within the collar, without touching the outer
   // silhouette or any open space between the limbs.
   for(let y=[64,60,63,59,61][row]*F;y<Math.min(repair,(HEAD_HEIGHTS[row]+6)*F);y++)for(let x=Math.max(F,replacement.neckLeft-12*F);x<Math.min(W-F,replacement.neckRight+12*F);x++){
    const i=(y*W+x)*4;if(paint[i+3]>32||paint[i-1]<128)continue;
    let end=x;while(end<W-F&&paint[(y*W+end)*4+3]<33)end++;
    if(end-x<=3*F&&paint[(y*W+end)*4+3]>127){
     const a=(y*W+x-1)*4,b=(y*W+end)*4;
     for(let xx=x;xx<end;xx++){const t=(xx-x+1)/(end-x+1),j=(y*W+xx)*4;
      for(let c=0;c<3;c++)paint[j+c]=Math.round(paint[a+c]*(1-t)+paint[b+c]*t);paint[j+3]=255;
     }
    }
    x=end;
   }
   // The older body atlas contains a few opaque chroma-key contour flecks.
   // Remove only those boundary colours in the replaced head/neck region.
   for(let y=F;y<repair-F;y++)for(let x=F;x<W-F;x++){
    const i=(y*W+x)*4,r=paint[i],g=paint[i+1],b=paint[i+2];
    const key=(r>140&&r>g*2.4&&r>b*2)||(g>95&&r>140&&g>b*2.25&&r<g*1.65)||(g>110&&g>r*1.25&&g>b*1.6);
    if(!key)continue;
    let edge=false;for(let dy=-F;dy<=F;dy++)for(let dx=-F;dx<=F;dx++)if(paint[((y+dy)*W+x+dx)*4+3]<10)edge=true;
    if(edge)paint.fill(0,i,i+4);
   }
   const connected=largest(Uint8Array.from({length:W*HEIGHTS[row]*F},(_,p)=>paint[p*4+3]>10?1:0),W,HEIGHTS[row]*F);
   for(let p=0;p<repair*W;p++)if(!connected[p])paint.fill(0,p*4,p*4+4);
   if(!paint.subarray(repair*W*4).equals(body.subarray(repair*W*4)))throw Error('Jo body changed below neck');
   let min=W,max=0;for(let p=0;p<paint.length/4;p++)if(paint[p*4+3]>10){min=Math.min(min,p%W);max=Math.max(max,p%W);}
   regions.push([key*W+min,row*H+top*F,max-min+1,height]);anchors.push([400-min,height]);
   for(let y=0;y<height;y++)paint.copy(atlas,((row*H+top*F+y)*4000+key*W)*4,y*W*4,(y+1)*W*4);
  }
  report.push({view:row,cranialWidth:target.width,headHeight:HEAD_HEIGHTS[row],repairEnd:REPAIRS[row],neckBase:prototype.lastNeck/F,neckSpan:[prototype.neckLeft/F,prototype.neckRight/F]});
 }
 await sharp(cleanStrip,{raw:raw.info}).png().toFile(path.join(DIR,'sources/jo-heads-v9.png'));
 await sharp(identityMask,{raw:{width:800,height:5600,channels:4}}).png().toFile(path.join(DIR,'sources/jo-identity-mask-v9.png'));
 await sharp(atlas,{raw:{width:4000,height:5600,channels:4}}).png().toFile(path.join(DIR,'jo-walk-v9.png'));
 const cycle=[0,1,1,2,2,3,3,4,4],rows=(list,type)=>Array.from({length:5},(_,r)=>'\t'+cycle.map(k=>type+'('+list[r*5+k].join(',')+')').join(',')).join(',\n');
 let art=await fs.readFile(path.join(ROOT,'scripts/open_world_art.gd'),'utf8');
 art=art.replace(/open_world\/jo-walk-v\d+\.png/,'open_world/jo-walk-v9.png');
 const start=art.indexOf('const JO:'),end=art.indexOf('static func direction_row',start);
 art=art.slice(0,start)+'const JO: Array[Rect2] = [\n'+rows(regions,'Rect2')+']\nconst JO_ANCHORS: Array[Vector2] = [\n'+rows(anchors,'Vector2')+']\n\n'+art.slice(end);
 art=art.replace(/var scale_value: float =[^\n]+/,'var scale_value: float = HEIGHTS[kind]/876.0');
 art=art.replace(/var anchor := TE_ANCHORS[^\n]+/,'var anchor := TE_ANCHORS[row*9+frame] if kind==0 else JO_ANCHORS[row*9+frame]');
 await fs.writeFile(path.join(ROOT,'scripts/open_world_art.gd'),art);
 await fs.writeFile(path.join(DIR,'jo-walk-v9.recipe.json'),JSON.stringify({body:'sources/jo-body-v8.png',head:'sources/jo-heads-v9.png',factor:F,repairs:REPAIRS,headOffsets,views:report},null,2)+'\n');
 console.log('Baked 25 complete Jo sprites with a painted identity and authored continuous neck/collar transitions.');
}
if(require.main===module)packJo().catch(e=>{console.error(e);process.exitCode=1;});
module.exports={packJo};
