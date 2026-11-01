// Capture first with tests/te_side_rig_test.gd and Godot graphics enabled.
const sharp=require('sharp'),path=require('node:path');
const OUT=path.resolve(__dirname,'../output/te-propostas-rpg');
async function main(){
 const frames=[];for(let f=0;f<32;f++)frames.push(await sharp(`/tmp/tejo-v19-side/${String(f).padStart(2,'0')}.png`).flatten({background:'#a7b29b'}).raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:600,height:400*32,channels:3,pageHeight:400}}).gif({loop:0,delay:20,effort:4}).toFile(path.join(OUT,'te-v19-lateral.gif'));
 await sharp('/tmp/tejo-v19-side/12.png').flatten({background:'#a7b29b'}).png().toFile(path.join(OUT,'te-v19-lateral.png'));
}
main().catch(e=>{console.error(e);process.exitCode=1});
