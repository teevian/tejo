// Tiny local finish on the approved gait: a horizontal tuck of the advancing
// elbow and a faint painted sleeve response. Heights and physical widths stay fixed.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-subtle-shoulder');
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
function sample(data,f,x,y){
 const lo=Math.max(0,Math.min(399,Math.floor(x))),hi=Math.min(399,lo+1),t=x-Math.floor(x),a=(y*2000+f*400+lo)*4,b=(y*2000+f*400+hi)*4;
 const alpha=data[a+3]*(1-t)+data[b+3]*t;
 return [0,1,2].map(c=>alpha?(data[a+c]*data[a+3]*(1-t)+data[b+c]*data[b+3]*t)/alpha:0).concat(alpha);
}
async function main(){
 const source=path.join(root,'assets/characters/open_world/te-south-proportions.png');
 const original=await sharp(source).ensureAlpha().raw().toBuffer(),atlas=Buffer.from(original);
 const paint=await sharp(path.join(out,'edited.raw.png')).resize(256,276,{fit:'fill'}).ensureAlpha().raw().toBuffer();
 const amplitudes=[0,-3,1.25,3,-1.25];
 for(let f=1;f<=4;f++){
  const right=f===1||f===4,phase=Math.abs(amplitudes[f])/3;
  for(let y=236;y<343;y++)for(let x=right?210:72;x<(right?320:182);x++){
   const zone=right?smooth(212,232,x)*(1-smooth(300,320,x)):smooth(72,92,x)*(1-smooth(160,182,x));
   const dx=amplitudes[f]*smooth(235,290,y)*(1-smooth(311,343,y))*zone;
   if(!dx)continue;
   const p=sample(original,f,x-dx,y),k=(y*2000+f*400+x)*4;
   for(let c=0;c<4;c++)atlas[k+c]=Math.round(p[c]);
   // A bounded colour-only sleeve retouch cannot alter the accepted silhouette
   // or anatomy. It only suggests the slight additional shoulder rotation.
   const fold=phase*.14*smooth(244,250,y)*(1-smooth(274,281,y))*(right?smooth(242,248,x)*(1-smooth(268,274,x)):smooth(112,118,x)*(1-smooth(140,146,x)));
   if(!fold)continue;
   const px=(f-1)%2*136+x-(right?205:75),py=Math.floor((f-1)/2)*146+y-215,j=(py*256+px)*4;
   const grey=(r,g,b)=>r<125&&g<125&&b<125&&Math.abs(r-g)<16&&Math.abs(g-b)<16;
   if(atlas[k+3]>245&&paint[j+3]>245&&grey(atlas[k],atlas[k+1],atlas[k+2])&&grey(paint[j],paint[j+1],paint[j+2])&&[0,1,2].every(c=>Math.abs(atlas[k+c]-paint[j+c])<24))for(let c=0;c<3;c++)atlas[k+c]=Math.round(atlas[k+c]*(1-fold)+paint[j+c]*fold);
  }
 }
 const file=path.join(root,'assets/characters/open_world/te-south-subtle-shoulder.png');
 await sharp(atlas,{raw:{width:2000,height:560,channels:4}}).png().toFile(file);
 const render=Buffer.from(atlas);for(let k=3;k<render.length;k+=4)render[k]=Math.round(255*smooth(5.1,30.6,render[k]));
 const png=await sharp(render,{raw:{width:2000,height:560,channels:4}}).png().toBuffer();
 await sharp(png).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
 const frames=[];
 for(let f=1;f<=4;f++)frames.push(await sharp(png).extract({left:f*400,top:0,width:400,height:560}).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:400,height:560*4,channels:3,pageHeight:560}}).gif({loop:0,delay:150}).toFile(path.join(out,'caminhada.gif'));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({source,elbowHorizontalOffsets:amplitudes.slice(1),verticalDisplacement:0,geometry:'local horizontal translation; no limb scaling',preservedBelowRow:343,sleeveRetouchMaximumBlend:.14},null,2)+'\n');
}
main().catch(e=>{console.error(e);process.exitCode=1});
