const sharp=require('sharp'),path=require('node:path'),fs=require('node:fs/promises');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world'),OUT=path.join(ROOT,'output/sprites-v15');
const dirs=['Baixo','Diagonal baixo','Direita','Diagonal cima','Cima'];
const label=(s,w)=>Buffer.from(`<svg width="${w}" height="28"><text x="${w/2}" y="20" text-anchor="middle" font-family="sans-serif" font-size="15" fill="#e7ece8">${s}</text></svg>`);
async function scenePreview(){
 const frames=[];
 for(let phase=0;phase<8;phase++){
  const pieces=[];
  for(let d=0;d<8;d++){
   const input=await sharp(`/tmp/tejo-motion-v15/d${d}-p${phase}.png`).extract({left:440,top:140,width:400,height:380}).resize(280,266).png().toBuffer();
   pieces.push({input,left:d%4*280,top:Math.floor(d/4)*266});
  }
  frames.push(await sharp({create:{width:1120,height:532,channels:4,background:'#25372e'}}).composite(pieces).raw().toBuffer());
 }
 await sharp(Buffer.concat(frames),{raw:{width:1120,height:532*8,channels:4,pageHeight:532}}).gif({loop:0,delay:60,effort:4}).toFile(path.join(OUT,'caminhada-no-jogo.gif'));
}
async function main(){await fs.mkdir(OUT,{recursive:true});if(process.argv.includes("--scene")){await scenePreview();return;}for(const who of ['te','jo']){const c=[];for(let r=0;r<5;r++)for(let f=0;f<9;f++){const b=await sharp(path.join(DIR,`${who}-walk-v15.png`)).extract({left:f*400,top:r*560+24,width:400,height:512}).resize(200,256).png().toBuffer();c.push({input:b,left:f*205,top:r*262});}await sharp({create:{width:1845,height:1310,channels:4,background:'#8f9d90'}}).composite(c).png().toFile(path.join(OUT,`${who}-poses.png`));}
 const frames=[];for(let f=1;f<=8;f++){const pieces=[];for(let r=0;r<5;r++){pieces.push({input:label(dirs[r],400),left:r*400,top:8});for(let k=0;k<2;k++){const b=await sharp(path.join(DIR,`${k?'jo':'te'}-walk-v15.png`)).extract({left:f*400+10,top:r*560+20,width:380,height:520}).resize(190,260).png().toBuffer();pieces.push({input:b,left:r*400+k*195+5,top:38});}}frames.push(await sharp({create:{width:2000,height:310,channels:4,background:'#607969'}}).composite(pieces).raw().toBuffer());}
 await sharp(Buffer.concat(frames),{raw:{width:2000,height:310*8,channels:4,pageHeight:310}}).gif({loop:0,delay:85,effort:4}).toFile(path.join(OUT,'caminhada.gif'));
 // Close-up of the new neck/collar connection and the preserved faces, all angles.
 const detail=[];for(let k=0;k<2;k++)for(let r=0;r<5;r++){const b=await sharp(path.join(DIR,`${k?'jo':'te'}-walk-v15.png`)).extract({left:110,top:r*560+32,width:180,height:170}).resize(252,238).png().toBuffer();detail.push({input:b,left:r*260,top:k*250});}await sharp({create:{width:1300,height:500,channels:4,background:'#8f9d90'}}).composite(detail).png().toFile(path.join(OUT,'rostos-e-golas.png'));
}
main().catch(e=>{console.error(e);process.exitCode=1});
