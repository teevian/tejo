// Genuine contact -> passing -> reaching cycles from complete painted sprites.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,packagePose,bounds,W,H,HEIGHT,FLOOR}=require('./pack_te_rpg_v17.cjs');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world'),OUT=path.join(ROOT,'output/te-propostas-rpg');
const COLS=7;
async function pair(name){return (await readFigures(path.join(DIR,`sources/te-rpg-v18-${name}.raw.png`),2)).sort((a,b)=>a.centre[0]-b.centre[0]);}
async function main(){
 const old=await sharp(path.join(DIR,'te-rpg-v17.png')).ensureAlpha().raw().toBuffer();
 const pairs={};for(const name of ['down-pass','side-pass','down-reach','side-reach'])pairs[name]=await pair(name);
 const atlas=Buffer.alloc(W*COLS*H*2*4),recipe={version:18,character:'Te',cell:[W,H],columns:COLS,walkFrames:6,sourceHeight:HEIGHT,ground:[200,FLOOR],directions:['down','right (mirror for left)'],phases:['idle','contact_a','passing_a','reaching_b','contact_b','passing_b','reaching_a'],poses:[]};
 const mappings=[
  [0,1,['down-pass',0],['down-reach',0,true],3,['down-pass',1],['down-reach',1]],
  [0,1,['side-pass',1],['side-reach',0],4,['side-pass',0],['side-reach',1]]
 ];
 for(let row=0;row<2;row++)for(let frame=0;frame<COLS;frame++){
  const item=mappings[row][frame];let pose;
  if(typeof item==='number'){
   const data=Buffer.alloc(W*H*4);for(let y=0;y<H;y++)old.copy(data,y*W*4,((row*H+y)*W*COLS+item*W)*4,((row*H+y)*W*COLS+(item+1)*W)*4);
   pose={data,bounds:bounds(data,W,H),source:{atlas:'te-rpg-v17.png',row,frame:item},preserved:true};
  }else{
   let raw=pairs[item[0]][item[1]];
   if(item[2])raw={...raw,data:await sharp(raw.data,{raw:{width:raw.width,height:raw.height,channels:4}}).flop().raw().toBuffer()};
   pose=await packagePose(raw,HEIGHT/(raw.height-4));pose.source={file:`te-rpg-v18-${item[0]}.raw.png`,...raw.source,figure:item[1],mirrored:!!item[2]};
  }
  for(let y=0;y<H;y++)pose.data.copy(atlas,((row*H+y)*W*COLS+frame*W)*4,y*W*4,(y+1)*W*4);
  recipe.poses.push({row,frame,phase:recipe.phases[frame],...pose,data:undefined});
 }
 await sharp(atlas,{raw:{width:W*COLS,height:H*2,channels:4}}).png().toFile(path.join(DIR,'te-rpg-v18.png'));
 await fs.writeFile(path.join(DIR,'te-rpg-v18.recipe.json'),JSON.stringify(recipe,null,2)+'\n');
 const tiles=[];for(let row=0;row<2;row++)for(let f=0;f<COLS;f++)tiles.push({input:await sharp(atlas,{raw:{width:W*COLS,height:H*2,channels:4}}).extract({left:f*W,top:row*H,width:W,height:H}).resize(200,280).png().toBuffer(),left:f*200,top:row*280});
 await sharp({create:{width:1400,height:560,channels:4,background:'#a7b29b'}}).composite(tiles).png().toFile(path.join(OUT,'te-v18-sequencia.png'));
 console.log('Packed Te contact / passing / reaching phases; preserved original idle and opposite contacts.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
