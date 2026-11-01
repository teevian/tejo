// Prepare one immutable underpainting for rigid skeletal animation.
// The approved original remains the head and arm texture; only occluded cloth
// and the leg texture use the arm-free underpainting generated once.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,packagePose}=require('./pack_te_rpg_v17.cjs');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
async function main(){
 const original=await sharp(path.join(DIR,'te-rpg-v17.png')).extract({left:0,top:560,width:400,height:560}).png().toBuffer();
 await fs.writeFile(path.join(DIR,'te-side-rig-v19-original.png'),original);
 const [figure]=await readFigures(path.join(DIR,'sources/te-side-rig-v19-clean.raw.png'),1),pose=await packagePose(figure,480/(figure.height-4));
 await sharp(pose.data,{raw:{width:400,height:560,channels:4}}).png().toFile(path.join(DIR,'te-side-rig-v19-body.png'));
 await fs.writeFile(path.join(DIR,'te-side-rig-v19.recipe.json'),JSON.stringify({version:19,original:'te-rpg-v17.png row 1 idle',underpainting:pose.source,scale:pose.scale,placement:pose.placement,geometry:'Rigid bone transforms: no scale, no independently generated walking frames'},null,2)+'\n');
}
main().catch(e=>{console.error(e);process.exitCode=1});
