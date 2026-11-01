// Bake the painted forearm retouch into complete sprites. The original heads,
// shoulders, upper arms and legs remain in the atlas; runtime has no part rig.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-forearm-balance');
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
function samplePanel(data,x,y){
 const lo=Math.max(0,Math.min(299,Math.floor(y))),hi=Math.min(299,lo+1),t=y-Math.floor(y),a=(lo*540+x)*4,b=(hi*540+x)*4;
 const alpha=data[a+3]*(1-t)+data[b+3]*t;
 return [0,1,2].map(c=>alpha?(data[a+c]*data[a+3]*(1-t)+data[b+c]*data[b+3]*t)/alpha:0).concat(alpha);
}
async function main(){
 const meta=await sharp(path.join(out,'forearm-panels-edited.raw.png')).metadata();
 if(Math.abs(meta.width/meta.height-540/300)>.03)throw Error('Forearm panel layout changed');
 const panels=await sharp(path.join(out,'forearm-panels-edited.raw.png')).resize(540,300,{fit:'contain',background:'#00000000'}).ensureAlpha().raw().toBuffer();
 const atlas=await sharp(path.join(out,'first-pass-atlas.png')).ensureAlpha().raw().toBuffer();
 for(const f of [2,3]){
  const panelX=(f-1)%2*270,panelY=Math.floor((f-1)/2)*150;
  for(let y=0;y<150;y++)for(let x=0;x<270;x++){
   const gx=x+65,gy=y+280;
   if(gy>400)continue;
   const left=f===2?smooth(72,88,gx)*(1-smooth(152,168,gx)):0;
   const right=smooth(222,238,gx)*(1-smooth(307,323,gx));
   const mask=Math.max(left,right)*smooth(304,324,gy)*(1-smooth(403,419,gy));
   if(mask===0)continue;
   // Register the retouch to the requested hand levels while keeping its elbow
   // anchor fixed. Hands translate intact; only the forearm's depth projection
   // changes. This is baked once, not an articulated animation at runtime.
   const correction=f===2?(gx<195?7:4):4;
   let low=gy-correction,high=gy;
   for(let i=0;i<12;i++){const mid=(low+high)/2;if(mid+correction*smooth(320,350,mid)<gy)low=mid;else high=mid;}
   const paint=samplePanel(panels,panelX+x,panelY+(low+high)/2-280),plain=samplePanel(panels,panelX+x,panelY+y);
   const shorts=p=>p[3]>127&&p[0]>130&&p[1]>120&&Math.abs(p[0]-p[1])<35&&Math.abs(p[1]-p[2])<40;
   const skin=p=>p[3]>127&&p[0]-p[1]>35&&p[1]-p[2]>15;
   if(shorts(plain)&&!skin(paint))for(let c=0;c<4;c++)paint[c]=plain[c];
   const a=(gy*2000+f*400+gx)*4,original=[atlas[a],atlas[a+1],atlas[a+2],atlas[a+3]];
   const bodyCloth=shorts(original)||(gx>143&&gx<247&&original[3]>127&&!skin(original));
   if(bodyCloth&&!skin(paint)){
    let outline=false;
    if(paint[3]>10&&Math.max(...paint.slice(0,3))<130){
     for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++)if(skin(samplePanel(panels,panelX+x+dx,panelY+(low+high)/2-280+dy)))outline=true;
    }
    // Keep the original shirt/shorts instead of retouching clothing beneath a
    // moving hand. Only painted arm skin and its thin outline may occlude it.
    if(!outline)continue;
   }
   const oldAlpha=atlas[a+3]/255,newAlpha=paint[3]/255,alpha=oldAlpha*(1-mask)+newAlpha*mask;
   for(let c=0;c<3;c++)atlas[a+c]=alpha?Math.round((atlas[a+c]*oldAlpha*(1-mask)+paint[c]*newAlpha*mask)/alpha):0;
   atlas[a+3]=Math.round(alpha*255);
  }
 }
 const file=path.join(root,'assets/characters/open_world/te-south-forearm-balance.png');
 await sharp(atlas,{raw:{width:2000,height:560,channels:4}}).png().toFile(file);
 await sharp(atlas,{raw:{width:2000,height:560,channels:4}}).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
 const frames=[];
 for(let f=1;f<=4;f++)frames.push(await sharp(file).extract({left:f*400,top:0,width:400,height:560}).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:400,height:560*4,channels:3,pageHeight:560}}).gif({loop:0,delay:120}).toFile(path.join(out,'caminhada.gif'));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({sourceWholeAtlas:'first-pass-atlas.png',paintedRetouch:'forearm-panels-edited.raw.png',columns:5,cell:[400,560],retouchedPoses:[2,3],untouchedCompletePoses:[0,1,4],preservedAboveRow:304,retouchRegistration:{pose2:[7,4],pose3:[0,4],anchorRows:[320,350]},runtimeWholeSprites:true,softBoundaryRows:[304,324,403,419]},null,2)+'\n');
 console.log('Baked forearm paint into complete sprites; upper body and existing gait preserved');
}
main().catch(error=>{console.error(error);process.exitCode=1});
