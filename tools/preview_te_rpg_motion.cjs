// Run tests/te_rpg_integration_test.gd with graphics first.
const sharp=require('sharp'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),OUT=path.join(ROOT,'output/te-propostas-rpg');
const label=(v,x)=>`<text x="${x}" y="25" text-anchor="middle" font-family="sans-serif" font-size="18" fill="#2d483b">${v}</text>`;
async function main(){
 const frames=[];
 for(let frame=1;frame<=6;frame++){
  const pieces=[];for(let row=0;row<3;row++)pieces.push({input:await sharp(path.join(OUT,'te-v18-no-motor.png')).extract({left:frame*200,top:row*230,width:200,height:230}).resize(300,345).png().toBuffer(),left:row*300,top:35});
  const svg='<svg width="900" height="380">'+['Baixo','Direita','Esquerda'].map((v,i)=>label(v,i*300+150)).join('')+'</svg>';
  pieces.push({input:Buffer.from(svg),left:0,top:0});
  frames.push(await sharp({create:{width:900,height:380,channels:4,background:'#a7b29b'}}).composite(pieces).raw().toBuffer());
 }
 await sharp(Buffer.concat(frames),{raw:{width:900,height:380*6,channels:4,pageHeight:380}}).gif({loop:0,delay:80,effort:4}).toFile(path.join(OUT,'te-v18-caminhada.gif'));
 console.log('Saved native-rendered Te down/right/left walking preview.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
