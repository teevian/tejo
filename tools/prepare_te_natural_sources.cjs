// Register the complete, repainted poses; retain the approved face pixels.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const DIR=path.resolve(__dirname,'../assets/characters/open_world/sources');
const W=800,H=1120,HEIGHTS=[219,213,212,212,232];
function box(data,w,h,ymax=h){
 let l=w,r=-1,t=h,b=-1;
 for(let y=0;y<ymax;y++)for(let x=0;x<w;x++)if(data[(y*w+x)*4+3]>127){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
 if(r<0)throw Error('Empty sprite');return{left:l,top:t,right:r,bottom:b,width:r-l+1,height:b-t+1,center:(l+r)/2};
}
function largest(mask,w,h){
 const seen=new Uint8Array(mask.length);let best=[];
 for(let p=0;p<mask.length;p++)if(mask[p]&&!seen[p]){
  const stack=[p],part=[];seen[p]=1;
  while(stack.length){const q=stack.pop();part.push(q);const x=q%w,y=Math.floor(q/w);
   for(const [dx,dy] of [[-1,0],[1,0],[0,-1],[0,1]]){const xx=x+dx,yy=y+dy,n=yy*w+xx;
    if(xx>=0&&xx<w&&yy>=0&&yy<h&&mask[n]&&!seen[n]){seen[n]=1;stack.push(n);}
   }
  }
  if(part.length>best.length)best=part;
 }
 const out=new Uint8Array(mask.length);for(const p of best)out[p]=1;return out;
}
function clean(data,w,h){
 for(let i=0;i<data.length;i+=4){const r=data[i],g=data[i+1],b=data[i+2];
  // Matte keys are saturated red/yellow, not the warm shadows on bare limbs.
  if((r>215&&g<60&&b<80)||(r>200&&g>170&&b<65))data.fill(0,i,i+4);
 }
 const mask=largest(Uint8Array.from({length:w*h},(_,p)=>data[p*4+3]>10?1:0),w,h);
 for(let p=0;p<mask.length;p++)if(!mask[p])data.fill(0,p*4,p*4+4);
}
async function main(){
 const input=await sharp(path.join(DIR,'te-natural-body-v9.raw.png')).resize(4000,5600,{fit:'fill'}).ensureAlpha().raw().toBuffer();
 const incoming=await sharp(path.join(DIR,'te-pulled-10593d9.png')).ensureAlpha().raw().toBuffer();
 const atlas=Buffer.alloc(4000*5600*4),report=[];
 for(let row=0;row<5;row++){
  const neutral=Buffer.alloc(W*H*4);
  for(let y=0;y<H;y++)incoming.copy(neutral,y*W*4,((row*H+y)*4000)*4,((row*H+y)*4000+W)*4);
  const neutralTop=(260-HEIGHTS[row])*4;
  const targetHair=box(neutral,W,H,neutralTop+35*4);
  for(let key=0;key<5;key++){
   const cell=Buffer.alloc(W*H*4);
   for(let y=0;y<H;y++)input.copy(cell,y*W*4,((row*H+y)*4000+key*W)*4,((row*H+y)*4000+(key+1)*W)*4);
   clean(cell,W,H);
   const bb=box(cell,W,H),hair=box(cell,W,H,bb.top+35*4),factor=HEIGHTS[row]*4/bb.height;
   const nw=Math.round(bb.width*factor),nh=HEIGHTS[row]*4;
   const trimmed=await sharp(cell,{raw:{width:W,height:H,channels:4}}).extract({left:bb.left,top:bb.top,width:bb.width,height:bb.height}).resize(nw,nh).raw().toBuffer();
   const left=Math.round(targetHair.center-(hair.center-bb.left)*factor);
   if(left<0||left+nw>W)throw Error('Pose outside cell');
   for(let y=0;y<nh;y++)trimmed.copy(atlas,((row*H+neutralTop+y)*4000+key*W+left)*4,y*nw*4,(y+1)*nw*4);
   report.push({row,key,sourceBounds:bb,scale:factor,headCenter:targetHair.center,left,width:nw});
  }
 }
 await sharp(atlas,{raw:{width:4000,height:5600,channels:4}}).png().toFile(path.join(DIR,'te-natural-body-v9.png'));
 const old=await sharp(path.join(DIR,'te-heads-painted-v8.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const generated=await sharp(path.join(DIR,'te-heads-dark-v9.raw.png')).resize(old.info.width,old.info.height,{fit:'fill'}).ensureAlpha().raw().toBuffer();
 const output=Buffer.from(old.data);let replaced=0;
 for(let row=0;row<5;row++){
  const l=Math.round(row*old.info.width/5),r=Math.round((row+1)*old.info.width/5),w=r-l,h=540,mask=new Uint8Array(w*h);
  for(let y=90;y<h;y++)for(let x=0;x<w;x++){
   const i=(y*old.info.width+l+x)*4;
   if(generated[i+3]>32&&generated[i]<125&&generated[i+1]<115&&generated[i+2]<110)mask[y*w+x]=1;
  }
  const hair=largest(mask,w,h);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(hair[y*w+x]){
   // Keep the approved face, including forehead, eyes, brows and stubble.
   const face=row==0?(y>335&&x>100&&x<340):row==1?(y>315&&x>190):row==2?(y>280&&x>268)||(y>420&&x>198):false;
   if(face)continue;
   const i=(y*old.info.width+l+x)*4;if(old.data[i+3]<1)continue;
   for(let c=0;c<3;c++)output[i+c]=generated[i+c];replaced++;
  }
 }
 await sharp(output,{raw:old.info}).png().toFile(path.join(DIR,'te-heads-dark-v9.png'));
 await fs.writeFile(path.join(DIR,'te-natural-v9-registration.json'),JSON.stringify({poses:report,hairPixels:replaced},null,2)+'\n');
 console.log('Registered 25 whole poses at the approved scale and planted-foot baseline; changed only hair in the approved portrait.');
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1;});
module.exports={largest};
