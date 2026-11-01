// First run tests/side_walk_motion_test.gd with Godot graphics enabled.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const OUT=path.resolve(__dirname,'../output/side-walk');
const text=(value,x,y)=>`<text x="${x}" y="${y}" text-anchor="middle" font-family="sans-serif" font-size="18" fill="#2d483b">${value}</text>`;
async function main(){
 await fs.mkdir(OUT,{recursive:true});
 const comparison=[],current=[];
 for(let frame=0;frame<32;frame+=2){
  const input=await fs.readFile(`/tmp/tejo-side-walk/${String(frame).padStart(2,'0')}.png`);
  let labels='<svg width="1040" height="680">';
  let shadows='<svg width="1040" height="680">';
  for(let row=0;row<2;row++)for(const col of [0,2])shadows+=`<ellipse cx="${col*260+130}" cy="${row*340+307}" rx="37.5" ry="14.25" fill="#142921" opacity=".27"/>`;
  shadows+='</svg>';
  for(let row=0;row<2;row++)for(let col=0;col<4;col++)labels+=text(`${col<2?'Te':'Jo'} · ${col%2?'agora':'antes'} ${row?'←':'→'}`,col*260+130,row*340+28);
  for(let row=0;row<2;row++)labels+=`<line x1="0" y1="${row*340+310}" x2="1040" y2="${row*340+310}" stroke="#718469" opacity=".3"/>`;
  labels+='</svg>';
  const painted=await sharp({create:{width:1040,height:680,channels:4,background:'#a7b29b'}}).composite([{input:Buffer.from(shadows),left:0,top:0},{input,left:0,top:0},{input:Buffer.from(labels),left:0,top:0}]).png().toBuffer();
  comparison.push(await sharp(painted).raw().toBuffer());
  const pieces=[];
  for(let row=0;row<2;row++)for(let kind=0;kind<2;kind++)pieces.push({input:await sharp(painted).extract({left:(kind*2+1)*260,top:row*340,width:260,height:340}).png().toBuffer(),left:kind*260,top:row*340});
  current.push(await sharp({create:{width:520,height:680,channels:4,background:'#a7b29b'}}).composite(pieces).raw().toBuffer());
  if(frame===8)await sharp(painted).png().toFile(path.join(OUT,'comparacao.png'));
 }
 for(const [frames,width,name]of [[comparison,1040,'comparacao.gif'],[current,520,'caminhada-lateral.gif']])await sharp(Buffer.concat(frames),{raw:{width,height:680*frames.length,channels:4,pageHeight:680}}).gif({loop:0,delay:30,effort:4}).toFile(path.join(OUT,name));
 console.log('Saved lateral before/after comparison and the current Te/Jo walks in both directions.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
