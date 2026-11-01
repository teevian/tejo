// Package whole approved Te drawings. Only trim transparent padding and uniformly
// resize complete poses; never stretch bodies or replace heads/busts/limbs.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const W=400,H=560,HEIGHT=480,FLOOR=520,COLS=7;
function groups(data,width,height){
 const seen=new Uint8Array(width*height),queue=new Int32Array(width*height),found=[];
 for(let p=0;p<width*height;p++)if(!seen[p]&&data[p*4+3]>=24){
  let n=0,len=1,l=width,r=0,t=height,b=0;const pixels=[];seen[p]=1;queue[0]=p;
  while(n<len){const a=queue[n++],x=a%width,y=Math.floor(a/width);pixels.push(a);l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);for(const k of [x>0?a-1:-1,x<width-1?a+1:-1,y>0?a-width:-1,y<height-1?a+width:-1])if(k>=0&&!seen[k]&&data[k*4+3]>=24){seen[k]=1;queue[len++]=k;}}
  if(pixels.length>2000)found.push({pixels,left:l,top:t,width:r-l+1,height:b-t+1});
 }
 return found;
}
async function readFigures(file,count){
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const figures=groups(data,info.width,info.height).sort((a,b)=>b.pixels.length-a.pixels.length).slice(0,count);
 if(figures.length!==count)throw Error(`Expected ${count} intact figures in ${file}, found ${figures.length}`);
 const extracted=[];
 for(const g of figures){const left=Math.max(0,g.left-2),top=Math.max(0,g.top-2),width=Math.min(info.width-left,g.width+4),height=Math.min(info.height-top,g.height+4),out=Buffer.alloc(width*height*4),keep=new Uint8Array(width*height);
  for(const p of g.pixels){const x=p%info.width-left,y=Math.floor(p/info.width)-top;for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const xx=x+dx,yy=y+dy;if(xx>=0&&xx<width&&yy>=0&&yy<height)keep[yy*width+xx]=1;}}
  for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(keep[y*width+x]){const i=((top+y)*info.width+left+x)*4;data.copy(out,(y*width+x)*4,i,i+4);}
  extracted.push({data:out,width,height,source:{left,top,width,height},centre:[g.left+g.width/2,g.top+g.height/2]});
 }
 return extracted;
}
function bounds(data,width,height,yEnd=height){let l=width,r=-1,t=height,b=-1;for(let y=0;y<yEnd;y++)for(let x=0;x<width;x++)if(data[(y*width+x)*4+3]>127){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}return{left:l,top:t,width:r-l+1,height:b-t+1};}
async function packagePose(pose,scale){
 const width=Math.round(pose.width*scale),height=Math.round(pose.height*scale),data=await sharp(pose.data,{raw:{width:pose.width,height:pose.height,channels:4}}).resize(width,height,{fit:'fill'}).raw().toBuffer();
 const bb=bounds(data,width,height),crown=bounds(data,width,height,Math.min(height,Math.ceil(height*.105))),left=Math.round(200-crown.left-(crown.width-1)/2),top=FLOOR-bb.top-bb.height;
 if(left<0||left+width>W||top<0||top+height>H)throw Error('Whole pose exceeds packing cell');
 const out=Buffer.alloc(W*H*4);for(let y=0;y<height;y++)data.copy(out,((top+y)*W+left)*4,y*width*4,(y+1)*width*4);
 return {data:out,source:pose.source,scale,placement:[left,top],bounds:bounds(out,W,H)};
}
async function main(){
 const walk=await readFigures(path.join(DIR,'sources/te-rpg-v17-walk.raw.png'),12),idle=(await readFigures(path.join(DIR,'sources/te-rpg-v17-idle.raw.png'),2)).sort((a,b)=>a.centre[0]-b.centre[0]);
 walk.sort((a,b)=>a.centre[1]-b.centre[1]);const rows=[walk.slice(0,6),walk.slice(6)];for(const r of rows)r.sort((a,b)=>a.centre[0]-b.centre[0]);
 const atlas=Buffer.alloc(W*COLS*H*2*4),recipe={version:17,character:'Te',approvedPreview:'output/te-propostas-rpg/te-escolhido-antebracos-laterais-v2.png',cell:[W,H],columns:COLS,walkFrames:6,sourceHeight:HEIGHT,ground:[200,FLOOR],directions:['down','right (mirror for left)'],wholePaintings:true,poses:[]};
 for(let row=0;row<2;row++){
  const heights=rows[row].map(p=>p.height-4).sort((a,b)=>a-b),height=(heights[2]+heights[3])/2,scale=HEIGHT/height;
  for(let frame=0;frame<COLS;frame++){
   const p=frame===0?idle[row]:rows[row][frame-1],pose=await packagePose(p,frame===0?HEIGHT/(p.height-4):scale);
   for(let y=0;y<H;y++)pose.data.copy(atlas,((row*H+y)*W*COLS+frame*W)*4,y*W*4,(y+1)*W*4);
   recipe.poses.push({row,frame,...pose,data:undefined});
  }
 }
 await sharp(atlas,{raw:{width:W*COLS,height:H*2,channels:4}}).png().toFile(path.join(DIR,'te-rpg-v17.png'));
 await fs.writeFile(path.join(DIR,'te-rpg-v17.recipe.json'),JSON.stringify(recipe,null,2)+'\n');
 const preview=[];for(let row=0;row<2;row++)for(let f=0;f<COLS;f++)preview.push({input:await sharp(atlas,{raw:{width:W*COLS,height:H*2,channels:4}}).extract({left:f*W,top:row*H,width:W,height:H}).resize(200,280).png().toBuffer(),left:f*200,top:row*280});
 await sharp({create:{width:1400,height:560,channels:4,background:'#a7b29b'}}).composite(preview).png().toFile(path.join(ROOT,'output/te-propostas-rpg/te-no-jogo-v17-poses.png'));
 console.log('Packed 14 complete Te poses: idle + 6 walking keys in down/right. Uniform scaling only, no fixed bust, common floor.');
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1});
module.exports={readFigures,packagePose,bounds,W,H,HEIGHT,FLOOR};
