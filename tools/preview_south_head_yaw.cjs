const sharp=require('sharp'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..');
(async()=>{
 const frames=[];
 for(let phase=0;phase<8;phase++)frames.push(await sharp(`/tmp/tejo-motion-v14/d0-p${phase}.png`).extract({left:440,top:160,width:400,height:360}).resize(600,540).ensureAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:600,height:540*8,channels:4,pageHeight:540}}).gif({loop:0,delay:100,effort:4}).toFile(path.join(ROOT,'output/character-motion-v14-south.gif'));
 console.log('Saved frontal walking preview with fixed heads and subtle facial yaw.');
})().catch(e=>{console.error(e);process.exitCode=1;});
