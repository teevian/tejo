const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,bounds}=require('./pack_te_rpg_v17.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/south-arms'),dir=path.join(root,'assets/characters/open_world');
async function main(){
 const figures=await readFigures(path.join(out,'edited.raw.png'),8);figures.sort((a,b)=>a.centre[1]-b.centre[1]);
 const layers=[],frames=[[],[]];
 for(let row=0;row<2;row++){
  const poses=figures.slice(row*4,row*4+4).sort((a,b)=>a.centre[0]-b.centre[0]);
  const scale=426/(poses.reduce((n,p)=>n+p.height-4,0)/4);
  for(let f=0;f<4;f++){
   const p=poses[f],w=Math.round(p.width*scale),h=Math.round(p.height*scale);
   const data=await sharp(p.data,{raw:{width:p.width,height:p.height,channels:4}}).resize(w,h).raw().toBuffer();
   const bb=bounds(data,w,h),head=bounds(data,w,h,Math.round(h*.19));
   const left=Math.round(200-head.left-head.width/2),top=520-bb.top-bb.height;
   const cell=await sharp({create:{width:400,height:560,channels:4,background:'#00000000'}}).composite([{input:data,raw:{width:w,height:h,channels:4},left,top}]).png().toBuffer();
   frames[row].push(cell);layers.push({input:cell,left:f*400,top:row*560});
  }
 }
 await sharp({create:{width:1600,height:1120,channels:4,background:'#00000000'}}).composite(layers).png().toFile(path.join(dir,'te-jo-down-arms-v23.png'));
 const idlePose=(await readFigures(path.join(out,'idle.raw.png'),1))[0];
 const ref=await sharp(frames[0][0]).raw().toBuffer();
 const target=bounds(ref,400,560).height;
 const src=bounds(idlePose.data,idlePose.width,idlePose.height);
 const factor=target/src.height,w=Math.round(idlePose.width*factor),h=Math.round(idlePose.height*factor);
 const data=await sharp(idlePose.data,{raw:{width:idlePose.width,height:idlePose.height,channels:4}}).resize(w,h).raw().toBuffer();
 const ib=bounds(data,w,h),head=bounds(data,w,h,Math.round(h*.19));
 await sharp({create:{width:400,height:560,channels:4,background:'#00000000'}}).composite([{input:data,raw:{width:w,height:h,channels:4},left:Math.round(200-head.left-head.width/2),top:520-ib.top-ib.height}]).png().toFile(path.join(dir,'te-down-idle-v23.png'));
 console.log('Te source height: walking',target,'idle',ib.height);
 const gif=[];for(let f=0;f<4;f++)gif.push(await sharp(await sharp({create:{width:800,height:560,channels:4,background:'#a7b29b'}}).composite([{input:frames[0][f],left:0,top:0},{input:frames[1][f],left:400,top:0}]).png().toBuffer()).resize(400,280).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(gif),{raw:{width:400,height:1120,channels:3,pageHeight:280}}).gif({loop:0,delay:120}).toFile(path.join(out,'caminhar-baixo.gif'));
 await sharp(path.join(dir,'te-jo-down-arms-v23.png')).resize(800,560).flatten({background:'#a7b29b'}).toFile(path.join(out,'proposta.png'));
}
main().catch(e=>{console.error(e);process.exitCode=1});
