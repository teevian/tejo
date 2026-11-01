// Bake the painted lower-arm poses around one shared, stationary elbow painting.
// Runtime still draws complete sprites, without an articulated rig.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {arm}=require('./check_te_forearm_balance.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-anchored-arms');
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
const skin=p=>p[3]>100&&p[0]-p[1]>25&&p[1]-p[2]>12;
function mix(data,k,p,w){
 const a=data[k+3]/255,b=p[3]/255,alpha=a*(1-w)+b*w;
 for(let c=0;c<3;c++)data[k+c]=alpha?Math.round((data[k+c]*a*(1-w)+p[c]*b*w)/alpha):0;
 data[k+3]=Math.round(alpha*255);
}
function sample(data,x,y){
 let a=0,rgb=[0,0,0];const ix=Math.floor(x),iy=Math.floor(y);
 for(let dy=0;dy<=1;dy++)for(let dx=0;dx<=1;dx++){
  const xx=Math.max(0,Math.min(399,ix+dx)),yy=Math.max(0,Math.min(559,iy+dy));
  const k=(yy*400+xx)*4,w=(dx?x-ix:1-x+ix)*(dy?y-iy:1-y+iy)*data[k+3]/255;
  a+=w;for(let c=0;c<3;c++)rgb[c]+=data[k+c]*w;
 }
 return rgb.map(c=>a?c/a:0).concat(a*255);
}
async function main(){
 const source=path.join(root,'assets/characters/open_world/te-south-forearm-balance.png');
 const base=await sharp(source).ensureAlpha().raw().toBuffer();
 const idle=await sharp(source).extract({left:0,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer();
 const pivots=[arm(idle,0).elbowX,arm(idle,1).elbowX];
 const targets=[[385,367],[379,379],[367,385],[379,379]],registration=[];
 for(let f=1;f<=4;f++){
  const paint=await sharp(path.join(out,'edited.png')).extract({left:(f-1)%2*270,top:Math.floor((f-1)/2)*200,width:270,height:200}).extend({left:65,right:65,top:240,bottom:120,background:'#00000000'}).ensureAlpha().raw().toBuffer();
  const shifts=[0,1].map(s=>{const a=arm(paint,s);return [pivots[s]-a.elbowX,targets[f-1][s]-a.handBottom]});
  registration.push({frame:f,shifts,handTargets:targets[f-1]});
  for(let y=210;y<405;y++)for(let x=75;x<320;x++){
   const side=x<200?0:1;
   const zone=side?smooth(222,232,x)*(1-smooth(300,312,x)):smooth(75,85,x)*(1-smooth(145,156,x));
   if(!zone)continue;
   const k=(y*2000+f*400+x)*4,j=(y*400+x)*4;
   // Every pose uses identical proximal-arm and elbow pixels at rows 298–326.
   const fixed=zone*smooth(210,225,y)*(1-smooth(328,336,y));
   if(fixed)mix(base,k,Array.from(idle.subarray(j,j+4)),fixed);
   const weight=zone*smooth(326,332,y)*(1-smooth(394,405,y));
   if(!weight)continue;
   const [dx,dy]=shifts[side],px=x-dx,py=y-dy*smooth(320,350,y),p=sample(paint,px,py);
   const old=Array.from(base.subarray(k,k+4));
   const cloth=old[3]>100&&Math.abs(old[0]-old[1])<35&&Math.abs(old[1]-old[2])<40;
   if(cloth&&!skin(p)){
    let outline=false;
    if(p[3]>30&&p[0]<140)for(let yy=-2;yy<=2;yy++)for(let xx=-2;xx<=2;xx++)if(skin(sample(paint,px+xx,py+yy)))outline=true;
    if(!outline)continue;
   }
   mix(base,k,p,weight);
  }
 }
 const file=path.join(root,'assets/characters/open_world/te-south-anchored-arms.png');
 await sharp(base,{raw:{width:2000,height:560,channels:4}}).png().toFile(file);
 await sharp(file).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
 const frames=[];
 for(let f=1;f<=4;f++)frames.push(await sharp(file).extract({left:f*400,top:0,width:400,height:560}).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:400,height:560*4,channels:3,pageHeight:560}}).gif({loop:0,delay:160}).toFile(path.join(out,'caminhada.gif'));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({source,commonElbowSource:0,elbowPivots:pivots,stationaryRows:[225,326],registration},null,2)+'\n');
}
main().catch(e=>{console.error(e);process.exitCode=1});
