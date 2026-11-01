// Pack complete paintings with one shared scale. Never replace or deform body parts.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,packagePose}=require('./pack_te_rpg_v17.cjs');
const root=path.resolve(__dirname,'..'),dir=path.join(root,'assets/characters/open_world'),out=path.join(root,'output/te-propostas-rpg');
async function main(){
 const poses=await readFigures(path.join(dir,'sources/te-side-v20.raw.png'),8);
 poses.sort((a,b)=>a.centre[1]-b.centre[1]);const ordered=[];
 for(let row=0;row<2;row++)ordered.push(...poses.slice(row*4,row*4+4).sort((a,b)=>a.centre[0]-b.centre[0]));
 const heights=ordered.map(p=>p.height-4).sort((a,b)=>a-b),scale=480/((heights[3]+heights[4])/2);
 const selected=[0,1,2,4,5,6].map(i=>ordered[i]);
 const packed=[];for(const p of selected)packed.push(await packagePose(p,scale));
 const layers=packed.map((p,i)=>({input:p.data,raw:{width:400,height:560,channels:4},left:i*400,top:0}));
 await sharp({create:{width:2400,height:560,channels:4,background:'#00000000'}}).composite(layers).png().toFile(path.join(dir,'te-side-v20.png'));
 const frames=[];for(const p of packed)frames.push(await sharp(p.data,{raw:{width:400,height:560,channels:4}}).resize(200,280).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:200,height:280*6,channels:3,pageHeight:280}}).gif({loop:0,delay:110}).toFile(path.join(out,'te-v20-lateral.gif'));
 await sharp({create:{width:600,height:560,channels:4,background:'#a7b29b'}}).composite(await Promise.all(packed.map(async(p,i)=>({input:await sharp(p.data,{raw:{width:400,height:560,channels:4}}).resize(200,280).png().toBuffer(),left:i%3*200,top:Math.floor(i/3)*280})))).png().toFile(path.join(out,'te-v20-sequencia.png'));
 await fs.writeFile(path.join(dir,'te-side-v20.recipe.json'),JSON.stringify({wholePaintings:true,sharedScale:scale,frames:packed.map(({data,...p})=>p)},null,2));
 console.log('Packed 6 complete paintings',packed.map(p=>p.bounds));
}
main().catch(e=>{console.error(e);process.exitCode=1});
