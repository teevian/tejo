// Surface/material finishing of the approved atlas. Limb pixels keep their exact
// coordinates: only the neck and the receding shoulder have tiny shape changes.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-final-details'),W=400,H=560;
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
const median=a=>a.slice().sort((a,b)=>a-b)[Math.floor(a.length/2)];
const lum=p=>.2126*p[0]+.7152*p[1]+.0722*p[2];
const skin=p=>p[3]>20&&p[0]>100&&p[0]-p[1]>38&&p[1]-p[2]>18;
const pixel=(d,x,y)=>Array.from(d.subarray((y*W+x)*4,(y*W+x)*4+4));
function sample(d,x,y){
 const lo=Math.max(0,Math.min(W-1,Math.floor(x))),hi=Math.min(W-1,lo+1),t=x-Math.floor(x),a=(y*W+lo)*4,b=(y*W+hi)*4;
 const alpha=d[a+3]*(1-t)+d[b+3]*t;
 return [0,1,2].map(c=>alpha?(d[a+c]*d[a+3]*(1-t)+d[b+c]*d[b+3]*t)/alpha:0).concat(alpha);
}
function groups(d,box,eligible){
 const [x0,y0,x1,y1]=box,seen=new Uint8Array(W*H),result=[];
 for(let y=y0;y<y1;y++)for(let x=x0;x<x1;x++){
  const start=y*W+x;if(seen[start])continue;seen[start]=1;
  if(!eligible(pixel(d,x,y),x,y))continue;
  const group=[start];
  for(let q=0;q<group.length;q++){
   const i=group[q],gx=i%W,gy=Math.floor(i/W);
   for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){
    const xx=gx+dx,yy=gy+dy,k=yy*W+xx;
    if(xx<x0||xx>=x1||yy<y0||yy>=y1||seen[k])continue;
    seen[k]=1;if(eligible(pixel(d,xx,yy),xx,yy))group.push(k);
   }
  }
  result.push(group);
 }
 return result;
}
function edges(d){
 const left=[],right=[];
 for(let y=242;y<262;y++){const xs=[];for(let x=75;x<325;x++)if(d[(y*W+x)*4+3]>127)xs.push(x);left.push(xs[0]);right.push(xs.at(-1));}
 return [median(left),median(right)];
}
function colourMedian(d,box,filter=()=>true){
 const p=[];for(let y=box[1];y<box[3];y++)for(let x=box[0];x<box[2];x++){const a=pixel(d,x,y);if(a[3]>127&&filter(a))p.push(a);}
 if(p.length<10)throw Error('Cannot sample material colour');
 return [0,1,2].map(c=>median(p.map(a=>a[c])));
}
function tint(d,k,target,ratio,chroma=.08){
 const old=[d[k],d[k+1],d[k+2]],l=lum(old),t=lum(target),value=l*ratio;
 for(let c=0;c<3;c++)d[k+c]=Math.max(0,Math.min(255,Math.round(value+(target[c]-t)+(old[c]-l)*chroma)));
}
async function main(){
 const source=path.join(root,'assets/characters/open_world/te-south-subtle-shoulder.png');
 const original=await sharp(source).ensureAlpha().raw().toBuffer(),atlas=Buffer.from(original),frames=[];
 for(let f=0;f<5;f++)frames.push(await sharp(source).extract({left:f*W,top:0,width:W,height:H}).ensureAlpha().raw().toBuffer());
 const reference=await sharp(path.join(out,'colour-reference.png')).ensureAlpha().raw().toBuffer();
 const shirtTarget=colourMedian(frames[0],[137,482,177,506],p=>Math.max(...p.slice(0,3))-Math.min(...p.slice(0,3))<30);
 const refShorts=colourMedian(reference,[155,360,225,390],p=>Math.max(...p.slice(0,3))-Math.min(...p.slice(0,3))<45);
 const shortsTarget=refShorts.map(c=>Math.round(c+192-lum(refShorts)));
 const oldShirt=colourMedian(frames[0],[155,250,235,330],p=>Math.max(...p.slice(0,3))-Math.min(...p.slice(0,3))<30);
 const idleEdges=edges(frames[0]),recipe=[];
 for(let f=0;f<5;f++){
  const d=frames[f],geometry=Buffer.from(d),beforeEdges=edges(d),backSide=(f===1||f===4)?0:1;
  const rearRestore=f===0?0:(backSide===0?-Math.max(0,beforeEdges[0]-idleEdges[0]):Math.max(0,idleEdges[1]-beforeEdges[1]))*.8;
  for(let y=215;y<278;y++)for(let x=75;x<325;x++){
   const neck=.05*smooth(226,233,y)*(1-smooth(239,245,y))*smooth(151,164,x)*(1-smooth(236,249,x));
   let sx=200+(x-200)/(1-neck);
   if(rearRestore){
    const zone=backSide===0?smooth(76,94,x)*(1-smooth(137,159,x)):smooth(228,249,x)*(1-smooth(298,319,x));
    const dx=rearRestore*zone*smooth(215,239,y)*(1-smooth(258,278,y));
    if(dx&&!skin(pixel(d,x,y))&&!skin(sample(d,sx-dx,y)))sx-=dx;
   }
   if(Math.abs(sx-x)<1e-9)continue;
   const p=sample(d,sx,y),k=(y*W+x)*4;for(let c=0;c<4;c++)geometry[k+c]=Math.round(p[c]);
  }
  const painted=Buffer.from(geometry),protectedSkin=new Uint8Array(W*H);
  for(let y=246;y<430;y++)for(let x=70;x<330;x++)if(skin(pixel(geometry,x,y)))for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++)protectedSkin[(y+dy)*W+x+dx]=1;
  const shortsMask=new Uint8Array(W*H),shirtMask=new Uint8Array(W*H),soleMask=new Uint8Array(W*H);
  const clothGroups=groups(geometry,[118,335,283,423],(p,x,y)=>p[3]>16&&lum(p)>65&&Math.max(...p.slice(0,3))-Math.min(...p.slice(0,3))<58&&p[0]-p[1]<35&&p[1]-p[2]<30&&!(y<354&&lum(p)<110));
  for(const g of clothGroups)if(g.filter(i=>{const p=pixel(geometry,i%W,Math.floor(i/W));return lum(p)>150&&Math.floor(i/W)<400;}).length>35)for(const i of g)shortsMask[i]=1;
  const shirtGroups=groups(geometry,[90,213,296,358],p=>p[3]>10&&lum(p)<135&&Math.max(...p.slice(0,3))-Math.min(...p.slice(0,3))<35);
  for(const g of shirtGroups)if(g.some(i=>i%W>170&&i%W<220&&Math.floor(i/W)>265&&Math.floor(i/W)<310))for(const i of g)if(!shortsMask[i]&&!protectedSkin[i])shirtMask[i]=1;
  const brightShoe=groups(geometry,[85,385,300,546],(p,x,y)=>p[3]>8&&lum(p)>80&&Math.max(...p.slice(0,3))-Math.min(...p.slice(0,3))<68&&p[0]-p[1]<45&&p[1]-p[2]<35&&!shortsMask[y*W+x]&&!protectedSkin[y*W+x]);
  for(const g of brightShoe){
   if(g.length<4||!g.some(i=>lum(pixel(geometry,i%W,Math.floor(i/W)))>155))continue;
   const atEdge=g.some(i=>{const x=i%W,y=Math.floor(i/W);for(const [dx,dy] of [[6,0],[-6,0],[0,6],[0,-6],[4,4],[-4,4],[4,-4],[-4,-4]]){const xx=x+dx,yy=y+dy;if(xx>=0&&xx<W&&yy>=0&&yy<H&&geometry[(yy*W+xx)*4+3]<16)return true;}return false;});
   if(atEdge)for(const i of g)soleMask[i]=1;
  }
  const shortsL=[],soleL=[];
  for(let i=0;i<W*H;i++){const p=pixel(geometry,i%W,Math.floor(i/W));if(shortsMask[i])shortsL.push(lum(p));if(soleMask[i])soleL.push(lum(p));}
  if(shortsL.length<1000||soleL.length<20)throw Error('Incomplete material mask in frame '+f);
  const shortsRatio=lum(shortsTarget)/median(shortsL),soleRatio=lum(shirtTarget)/median(soleL);
  for(let i=0;i<W*H;i++){
   if(shirtMask[i])tint(painted,i*4,shirtTarget,lum(shirtTarget)/lum(oldShirt));
   if(shortsMask[i]&&!protectedSkin[i])tint(painted,i*4,shortsTarget,shortsRatio);
   if(soleMask[i])tint(painted,i*4,shirtTarget,soleRatio,.03);
  }
  for(let y=0;y<H;y++)painted.copy(atlas,(y*2000+f*W)*4,y*W*4,(y+1)*W*4);
  recipe.push({frame:f,recedingShoulderSide:f===0?null:backSide,recedingShoulderHorizontalCorrection:rearRestore,beforeShoulderEdges:beforeEdges,afterShoulderEdges:edges(geometry),materialPixels:{shirt:shirtMask.reduce((a,b)=>a+b,0),shorts:shortsL.length,soles:soleL.length}});
  for(const [name,mask] of [['shirt',shirtMask],['shorts',shortsMask],['soles',soleMask]])await sharp(Buffer.from(mask.map(a=>a*255)),{raw:{width:W,height:H,channels:1}}).png().toFile(path.join(out,`mask-${f}-${name}.png`));
 }
 const file=path.join(root,'assets/characters/open_world/te-south-final-details.png');
 await sharp(atlas,{raw:{width:2000,height:H,channels:4}}).png().toFile(file);
 const rendered=Buffer.from(atlas);for(let k=3;k<rendered.length;k+=4)rendered[k]=Math.round(255*smooth(5.1,30.6,rendered[k]));
 const png=await sharp(rendered,{raw:{width:2000,height:H,channels:4}}).png().toBuffer();
 await sharp(png).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
 const animation=[],comparison=[],labels=Buffer.from('<svg width="800" height="34"><g fill="#294238" font-family="Arial" font-size="18" text-anchor="middle"><text x="200" y="25">Parado</text><text x="600" y="25">A caminhar</text></g></svg>');
 const idle=await sharp(png).extract({left:0,top:0,width:W,height:H}).png().toBuffer();
 for(let f=1;f<=4;f++){
  const frame=await sharp(png).extract({left:f*W,top:0,width:W,height:H}).png().toBuffer();
  animation.push(await sharp(frame).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
  comparison.push(await sharp({create:{width:800,height:594,channels:3,background:'#a7b29b'}}).composite([{input:labels,left:0,top:0},{input:idle,left:0,top:34},{input:frame,left:400,top:34}]).raw().toBuffer());
 }
 for(const [name,data,w,h] of [['caminhada.gif',animation,W,H],['parado-e-caminhar.gif',comparison,800,594]])await sharp(Buffer.concat(data),{raw:{width:w,height:h*4,channels:3,pageHeight:h}}).gif({loop:0,delay:150}).toFile(path.join(out,name));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({source,shirtAndSoleTarget:shirtTarget,shortsTarget,neckMaximumWidthScale:.95,limbPositionsPreserved:true,frames:recipe},null,2)+'\n');
 console.log(JSON.stringify({shirtTarget,shortsTarget,frames:recipe},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1});
