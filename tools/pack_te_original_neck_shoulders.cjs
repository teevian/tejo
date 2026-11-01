// Bake the image-generated neck/collar/shoulder corrections into COMPLETE original
// sprites. Preserve the original face, hair, arms below sleeves, legs and footwear.
// Runtime renders a single whole texture per frame, with no articulated parts.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {readFigures,bounds}=require('./pack_te_rpg_v17.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-original-neck-shoulders'),dir=path.join(root,'assets/characters/open_world');
const W=400,H=560,originalKeys=[0,1,3,5,7];
const clamp=v=>Math.max(0,Math.min(1,v));
const smooth=v=>{v=clamp(v);return v*v*(3-2*v)};
function rectangle(x,y,l,t,r,b,feather=5){return smooth(Math.min(x-l,r-x,y-t,b-y)/feather)}
function editMask(x,y,moving){
 let a=rectangle(x,y,145,195,254,252,5);
 if(moving){a=Math.max(a,rectangle(x,y,98,210,293,291,8),rectangle(x,y,133,252,267,325,12));}
 // Keep the original entire face and jaw, including its two authored head turns.
 if(y<195)return 0;
 if(y<224){const d=y-195,left=163+d*.78,right=237-d*.78;
  if(x>left&&x<right)return 0;
  a*=smooth((x<=left?left-x:x-right)/3);
 }
 return a;
}
async function main(){
 const originals=[];
 for(let f=0;f<9;f++)originals.push(await sharp(path.join(dir,'te-walk-v14.png')).extract({left:f*800,top:0,width:800,height:1120}).resize(W,H).ensureAlpha().raw().toBuffer());
 const figures=await readFigures(path.join(out,'edited.raw.png'),5);figures.sort((a,b)=>a.centre[1]-b.centre[1]);
 const poses=[...figures.slice(0,3).sort((a,b)=>a.centre[0]-b.centre[0]),...figures.slice(3).sort((a,b)=>a.centre[0]-b.centre[0])];
 const scale=438/(poses.reduce((s,p)=>s+p.height-4,0)/5),corrections=[];
 for(let i=0;i<5;i++){
  const p=poses[i],width=Math.round(p.width*scale),height=Math.round(p.height*scale);
  const data=await sharp(p.data,{raw:{width:p.width,height:p.height,channels:4}}).resize(width,height).raw().toBuffer();
  const bb=bounds(data,width,height),crown=bounds(data,width,height,Math.round(height*.15));
  const orig=originals[originalKeys[i]],ob=bounds(orig,W,H),oc=bounds(orig,W,H,ob.top+Math.round(ob.height*.15));
  const left=Math.round(oc.left+oc.width/2-crown.left-crown.width/2),top=520-bb.top-bb.height;
  corrections.push(await sharp({create:{width:W,height:H,channels:4,background:'#00000000'}}).composite([{input:data,raw:{width,height,channels:4},left,top}]).raw().toBuffer());
 }
 const baked=[],recipe={base:'te-walk-v14.png',cell:[W,H],ground:[200,520],height:438,wholeSprites:true,source:'output/te-original-neck-shoulders/edited.raw.png',frames:[]};
 for(let f=0;f<9;f++){
  const original=originals[f],edit=corrections[f===0?0:1+Math.floor((f-1)/2)],data=Buffer.from(original);let changed=0;
  for(let y=0;y<H;y++)for(let x=0;x<W;x++){
   const weight=editMask(x,y,f>0);if(weight<=0)continue;
   const k=(y*W+x)*4,oa=original[k+3]/255,ea=edit[k+3]/255,alpha=oa*(1-weight)+ea*weight;
   for(let c=0;c<3;c++)data[k+c]=alpha>0?Math.round((original[k+c]*oa*(1-weight)+edit[k+c]*ea*weight)/alpha):0;
   data[k+3]=Math.round(alpha*255);changed++;
  }
  // Source invariants: all pixels in hair/eyes/nose and below the edit remain exact.
  if(!data.subarray(0,195*W*4).equals(original.subarray(0,195*W*4)))throw Error('Face changed');
  if(!data.subarray(326*W*4).equals(original.subarray(326*W*4)))throw Error('Lower body changed');
  baked.push(await sharp(data,{raw:{width:W,height:H,channels:4}}).png().toBuffer());recipe.frames.push({frame:f,editedPixels:changed});
 }
 await sharp({create:{width:W*9,height:H,channels:4,background:'#00000000'}}).composite(baked.map((input,f)=>({input,left:f*W,top:0}))).png().toFile(path.join(dir,'te-original-south-neck-shoulders.png'));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify(recipe,null,2)+'\n');
 await sharp({create:{width:W*5,height:H,channels:4,background:'#a7b29b'}}).composite(originalKeys.map((f,i)=>({input:baked[f],left:i*W,top:0}))).png().toFile(path.join(out,'sequencia.png'));
 const previews=[];for(let f of [1,3,5,7])previews.push(await sharp(baked[f]).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(previews),{raw:{width:W,height:H*4,channels:3,pageHeight:H}}).gif({loop:0,delay:120}).toFile(path.join(out,'caminhada.gif'));
 console.log('Packed 9 complete original-based sprites. Original face/hair and lower body pixels preserved.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
