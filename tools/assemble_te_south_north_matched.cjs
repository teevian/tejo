// Compose complete authored poses only. No limb or face masks.
const sharp=require('sharp'),path=require('node:path');
const out=path.resolve(__dirname,'../output/te-south-north-matched');
async function main(){
 const layers=[];
 for(let f=0;f<3;f++)layers.push({input:await sharp(path.join(out,'top-source-atlas.png')).extract({left:f*400,top:0,width:400,height:560}).png().toBuffer(),left:f*400,top:0});
 const bottom=await sharp(path.join(out,'bottom-edited.raw.png')).metadata();
 if(Math.abs(bottom.width/bottom.height-800/560)>.03)throw Error('Bottom canvas aspect ratio changed');
 layers.push({input:await sharp(path.join(out,'bottom-edited.raw.png')).resize(800,560,{fit:'contain',background:'#00000000'}).png().toBuffer(),left:0,top:560});
 await sharp({create:{width:1200,height:1120,channels:4,background:'#00000000'}}).composite(layers).png().toFile(path.join(out,'edited.raw.png'));
 console.log('Assembled five complete poses; first three retained, opposite arm half-cycle edited as a pair');
}
main().catch(error=>{console.error(error);process.exitCode=1});
