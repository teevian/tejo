// Preview-only complete paintings. No runtime assets or character logic are changed.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,bounds}=require('./pack_te_rpg_v17.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,process.argv[2]||'output/te-south-counterbalance');
async function main(){
 const poses=await readFigures(path.join(out,'edited.raw.png'),4);
 poses.sort((a,b)=>a.centre[1]-b.centre[1]);
 const ordered=[...poses.slice(0,2).sort((a,b)=>a.centre[0]-b.centre[0]),...poses.slice(2).sort((a,b)=>a.centre[0]-b.centre[0])];
 const scale=426/(ordered.reduce((n,p)=>n+p.height-4,0)/4),cells=[];
 for(const p of ordered){
  const width=Math.round(p.width*scale),height=Math.round(p.height*scale);
  const data=await sharp(p.data,{raw:{width:p.width,height:p.height,channels:4}}).resize(width,height).raw().toBuffer();
  const bb=bounds(data,width,height),crown=bounds(data,width,height,Math.round(height*.16));
  const left=Math.round(200-crown.left-crown.width/2),top=520-bb.top-bb.height;
  cells.push(await sharp({create:{width:400,height:560,channels:4,background:'#00000000'}}).composite([{input:data,raw:{width,height,channels:4},left,top}]).png().toBuffer());
 }
 await sharp({create:{width:1600,height:560,channels:4,background:'#00000000'}}).composite(cells.map((input,i)=>({input,left:i*400,top:0}))).png().toFile(path.join(out,'te-sul-proposta.png'));
 await sharp({create:{width:1600,height:560,channels:4,background:'#a7b29b'}}).composite(cells.map((input,i)=>({input,left:i*400,top:0}))).png().toFile(path.join(out,'sequencia.png'));
 const frames=[];
 for(const cell of cells)frames.push(await sharp(cell).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:400,height:560*4,channels:3,pageHeight:560}}).gif({loop:0,delay:120}).toFile(path.join(out,'te-sul-proposta.gif'));
 console.log('Preview saved; runtime unchanged. Complete paintings use common scale',scale);
}
main().catch(e=>{console.error(e);process.exitCode=1});
