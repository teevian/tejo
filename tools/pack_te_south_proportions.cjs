// Package complete authored paintings at a uniform aspect ratio. No separately
// scaled limbs or shirt joins: the shoulders and forearms retain one coherent build.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,bounds}=require('./pack_te_rpg_v17.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-proportions');
const W=400,H=560,median=a=>a.slice().sort((a,b)=>a-b)[Math.floor(a.length/2)];
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
function shoulder(data){
 const spans=[];
 for(let y=242;y<262;y++){
  const xs=[];
  for(let x=75;x<325;x++){const k=(y*W+x)*4;if(data[k+3]>127)xs.push(x);}
  if(xs.length)spans.push(xs.at(-1)-xs[0]+1);
 }
 return median(spans);
}
async function main(){
 const source=path.join(root,'assets/characters/open_world/te-south-natural-arms.png');
 const oldAtlas=await sharp(source).ensureAlpha().raw().toBuffer();
 const atlas=Buffer.from(oldAtlas),figures=await readFigures(path.join(out,'edited.raw.png'),4);
 figures.sort((a,b)=>a.centre[1]-b.centre[1]);
 const poses=[...figures.slice(0,2).sort((a,b)=>a.centre[0]-b.centre[0]),...figures.slice(2).sort((a,b)=>a.centre[0]-b.centre[0])],recipe=[];
 const previous=[];
 for(let f=1;f<=4;f++){
  const old=await sharp(source).extract({left:f*W,top:0,width:W,height:H}).ensureAlpha().raw().toBuffer(),target=bounds(old,W,H),oldHead=bounds(old,W,H,target.top+Math.round(target.height*.28));
  const pose=poses[f-1],bb=bounds(pose.data,pose.width,pose.height),scale=target.height/bb.height;
  const width=Math.round(pose.width*scale),height=Math.round(pose.height*scale);
  const data=await sharp(pose.data,{raw:{width:pose.width,height:pose.height,channels:4}}).resize(width,height).raw().toBuffer();
  const resized=bounds(data,width,height),head=bounds(data,width,height,resized.top+Math.round(resized.height*.28));
  const left=Math.round(oldHead.left+oldHead.width/2-head.left-head.width/2),top=target.top-resized.top;
  if(left<0||top<0||left+width>W||top+height>H)throw Error('Whole painting exceeds its cell');
  const cell=Buffer.alloc(W*H*4);
  for(let y=0;y<height;y++)data.copy(cell,((top+y)*W+left)*4,y*width*4,(y+1)*width*4);
  // Keep the established facial identity and hair scale. The painted shoulder
  // silhouette stays free to narrow below the neck, without limb/body splices.
  for(let y=0;y<236;y++)for(let x=0;x<W;x++){
   const mask=y<205?1:(1-smooth(205,236,y))*smooth(132,145,x)*(1-smooth(255,270,x));
   if(!mask)continue;
   const k=(y*W+x)*4,oa=cell[k+3]/255,na=old[k+3]/255,alpha=oa*(1-mask)+na*mask;
   for(let c=0;c<3;c++)cell[k+c]=alpha?Math.round((cell[k+c]*oa*(1-mask)+old[k+c]*na*mask)/alpha):0;
   cell[k+3]=Math.round(alpha*255);
  }
  for(let y=0;y<H;y++)cell.copy(atlas,(y*W*5+f*W)*4,y*W*4,(y+1)*W*4);
  recipe.push({frame:f,uniformScale:scale,placement:[left,top],wholePose:true,oldShoulderSpan:shoulder(old),newShoulderSpan:shoulder(cell),headWidth:bounds(cell,W,H,target.top+Math.round(target.height*.28)).width});
  previous.push(old);
 }
 const file=path.join(root,'assets/characters/open_world/te-south-proportions.png');
 await sharp(atlas,{raw:{width:W*5,height:H,channels:4}}).png().toFile(file);
 const render=Buffer.from(atlas);for(let k=3;k<render.length;k+=4)render[k]=Math.round(255*smooth(5.1,30.6,render[k]));
 const png=await sharp(render,{raw:{width:W*5,height:H,channels:4}}).png().toBuffer();
 await sharp(png).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
 const gif=[],compare=[];
 for(let f=1;f<=4;f++){
  const cell=await sharp(png).extract({left:f*W,top:0,width:W,height:H}).png().toBuffer();
  gif.push(await sharp(cell).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
  const before=Buffer.from(previous[f-1]);for(let k=3;k<before.length;k+=4)before[k]=Math.round(255*smooth(5.1,30.6,before[k]));
  const old=await sharp(before,{raw:{width:W,height:H,channels:4}}).png().toBuffer();
  compare.push(await sharp({create:{width:W*2,height:H,channels:3,background:'#a7b29b'}}).composite([{input:old,left:0,top:0},{input:cell,left:W,top:0}]).raw().toBuffer());
 }
 for(const [name,data,w] of [['caminhada.gif',gif,W],['antes-depois.gif',compare,W*2]])await sharp(Buffer.concat(data),{raw:{width:w,height:H*4,channels:3,pageHeight:H}}).gif({loop:0,delay:150}).toFile(path.join(out,name));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({source,canvas:[2000,560],completePaintings:true,registration:'whole-pose height and head centre; uniform scaling only',frames:recipe},null,2)+'\n');
 console.log(JSON.stringify(recipe,null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1});
