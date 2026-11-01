const sharp=require('sharp'),path=require('node:path');
const out=process.argv[2]?path.resolve(process.argv[2]):path.resolve(__dirname,'../output/te-south-north-matched');
async function main(){
 const frames=[],contact=[],detail=[];
 const labels=Buffer.from('<svg width="840" height="38"><rect width="840" height="38" fill="#a7b29b"/><g fill="#2c4d42" font-family="Arial" font-size="18" text-anchor="middle"><text x="140" y="26">Sul · parado</text><text x="420" y="26">Sul · caminhar</text><text x="700" y="26">Norte · referência</text></g></svg>');
 for(let i=0;i<8;i++){
  const src=path.join(out,`motor-${i}.png`);
  frames.push(await sharp({create:{width:840,height:438,channels:3,background:'#a7b29b'}}).composite([{input:labels,top:0,left:0},{input:src,top:38,left:0}]).removeAlpha().raw().toBuffer());
  const body=await sharp(src).extract({left:320,top:55,width:200,height:320}).resize(300,480).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer();
  detail.push(body);
  if(i%2===0)contact.push({input:body,raw:{width:300,height:480,channels:3},left:i/2*300,top:0});
 }
 await sharp(Buffer.concat(frames),{raw:{width:840,height:438*8,channels:3,pageHeight:438}}).gif({loop:0,delay:60}).toFile(path.join(out,'sul-norte-no-jogo.gif'));
 await sharp(Buffer.concat(detail),{raw:{width:300,height:480*8,channels:3,pageHeight:480}}).gif({loop:0,delay:100}).toFile(path.join(out,'sul-lento.gif'));
 await sharp({create:{width:1200,height:480,channels:3,background:'#a7b29b'}}).composite(contact).png().toFile(path.join(out,'quatro-fases-no-jogo.png'));
 console.log('Saved south/north comparison captured in the game');
}
main().catch(error=>{console.error(error);process.exitCode=1});
