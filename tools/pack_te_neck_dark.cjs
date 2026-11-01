// Uniformly register the complete idle painting to the completed walk's stature.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,bounds}=require('./pack_te_rpg_v17.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-neck-dark'),dir=path.join(root,'assets/characters/open_world');
async function main(){
 let target=0;
 for(let f=0;f<4;f++){
  const data=await sharp(path.join(out,'te-sul-proposta.png')).extract({left:f*400,top:0,width:400,height:560}).raw().toBuffer();
  target+=bounds(data,400,560).height/4;
 }
 const p=(await readFigures(path.join(out,'idle.raw.png'),1))[0],bb=bounds(p.data,p.width,p.height),scale=target/bb.height;
 const width=Math.round(p.width*scale),height=Math.round(p.height*scale);
 const data=await sharp(p.data,{raw:{width:p.width,height:p.height,channels:4}}).resize(width,height).raw().toBuffer();
 const body=bounds(data,width,height),crown=bounds(data,width,height,Math.round(height*.16));
 const left=Math.round(200-crown.left-crown.width/2),top=520-body.top-body.height;
 await sharp({create:{width:400,height:560,channels:4,background:'#00000000'}}).composite([{input:data,raw:{width,height,channels:4},left,top}]).png().toFile(path.join(dir,'te-down-idle-neck-dark.png'));
 await fs.copyFile(path.join(out,'te-sul-proposta.png'),path.join(dir,'te-south-neck-dark.png'));
 console.log('Complete sprites registered; mean walking height',target,'idle height',body.height);
}
main().catch(e=>{console.error(e);process.exitCode=1});
