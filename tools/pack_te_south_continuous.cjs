// Package complete paintings without masks, body-part joins or independent head
// registration. A single shared scale and the shorts/pelvis register each figure.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,bounds}=require('./pack_te_rpg_v17.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,process.argv[2]||'output/te-south-continuous'),dir=path.join(root,'assets/characters/open_world');
const W=400,H=560,FLOOR=520;
const level=process.argv.includes('--level');
const idleSource=process.argv.find(arg=>arg.startsWith('--idle-from='))?.slice('--idle-from='.length);
const paintedHeight=Number(process.argv.find(arg=>arg.startsWith('--painted-height='))?.slice('--painted-height='.length)||438);
if(!Number.isFinite(paintedHeight)||paintedHeight<=0)throw Error('Invalid painted height');
const median=a=>a.slice().sort((x,y)=>x-y)[Math.floor(a.length/2)];
function pelvis(data,width,height,bb){
 // Register the lower shirt/waist center. The center of all shorts pixels shifts
 // with the forward leg and would introduce an artificial side-to-side sway.
 const centers=[];
 for(let y=Math.floor(bb.top+bb.height*.52);y<bb.top+bb.height*.59;y++){
  const runs=[];let start=-1;
  for(let x=0;x<=width;x++){
   const k=(y*width+x)*4,r=data[k],g=data[k+1],b=data[k+2];
   const cloth=x<width&&data[k+3]>127&&r<130&&g<130&&b<130&&Math.abs(r-g)<20&&Math.abs(g-b)<20;
   if(cloth&&start<0)start=x;
   if(!cloth&&start>=0){runs.push([start,x]);start=-1;}
  }
  runs.sort((a,b)=>(b[1]-b[0])-(a[1]-a[0]));
  if(runs.length&&runs[0][1]-runs[0][0]>bb.width*.3)centers.push((runs[0][0]+runs[0][1])/2);
 }
 if(centers.length<5)throw Error('Cannot register lower shirt/waist');
 return median(centers);
}

async function main(){
 const reference=await sharp(path.join(dir,'te-walk-v14.png')).extract({left:0,top:0,width:800,height:1120}).resize(W,H).raw().toBuffer();
 const referenceBounds=bounds(reference,W,H),waistTarget=pelvis(reference,W,H,referenceBounds),crownTarget=referenceBounds.top;
 const figures=await readFigures(path.join(out,'edited.raw.png'),5);figures.sort((a,b)=>a.centre[1]-b.centre[1]);
 const poses=[...figures.slice(0,3).sort((a,b)=>a.centre[0]-b.centre[0]),...figures.slice(3).sort((a,b)=>a.centre[0]-b.centre[0])];
 const heights=poses.map(p=>bounds(p.data,p.width,p.height).height),scale=paintedHeight/median(heights),layers=[],frames=[],meta=[];
 for(let f=0;f<5;f++){
  if(f===0&&idleSource){
   const cell=await sharp(path.resolve(root,idleSource)).extract({left:0,top:0,width:W,height:H}).png().toBuffer();
   layers.push({input:cell,left:0,top:0});frames.push(cell);meta.push({frame:0,unchangedWholePose:idleSource});
   continue;
  }
  const p=poses[f],width=Math.round(p.width*scale),height=Math.round(p.height*scale);
  const data=await sharp(p.data,{raw:{width:p.width,height:p.height,channels:4}}).resize(width,height).raw().toBuffer();
  const bb=bounds(data,width,height),hip=pelvis(data,width,height,bb),left=Math.round(waistTarget-hip),top=level?crownTarget-bb.top:FLOOR-bb.top-bb.height;
  if(left<0||top<0||left+width>W||top+height>H)throw Error('Complete sprite exceeds cell');
  const cell=await sharp({create:{width:W,height:H,channels:4,background:'#00000000'}}).composite([{input:data,raw:{width,height,channels:4},left,top}]).png().toBuffer();
  layers.push({input:cell,left:f*W,top:0});frames.push(cell);meta.push({frame:f,scale,placement:[left,top],bounds:bb,pelvis:hip});
 }
 const atlas=await sharp({create:{width:W*5,height:H,channels:4,background:'#00000000'}}).composite(layers).raw().toBuffer();
 if(idleSource){
  // Copy raw pixels after compositing to avoid rounding translucent edge colors.
  const idle=await sharp(path.resolve(root,idleSource)).extract({left:0,top:0,width:W,height:H}).ensureAlpha().raw().toBuffer();
  for(let y=0;y<H;y++)idle.copy(atlas,y*W*5*4,y*W*4,(y+1)*W*4);
 }
 await sharp(atlas,{raw:{width:W*5,height:H,channels:4}}).png().toFile(path.join(dir,process.argv[3]||'te-south-continuous.png'));
 await sharp({create:{width:W*5,height:H,channels:4,background:'#a7b29b'}}).composite(layers).png().toFile(path.join(out,'sequencia.png'));
 const gif=[];for(let f=1;f<=4;f++)gif.push(await sharp(frames[f]).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(gif),{raw:{width:W,height:H*4,channels:3,pageHeight:H}}).gif({loop:0,delay:120}).toFile(path.join(out,'caminhada.gif'));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({wholePaintings:true,registration:level?'whole-pose level crown and original waist; projected feet retain stride depth':'lower shirt/waist and ground; head remains coupled to torso',columns:5,sourceHeight:paintedHeight,waistTarget,crownTarget,frames:meta},null,2)+'\n');
 console.log('Packed complete idle + 4 walking paintings; original waist registration',waistTarget);
}
main().catch(e=>{console.error(e);process.exitCode=1});
