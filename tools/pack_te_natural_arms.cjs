// Register complete painted torso/arm panels by the shirt, so shoulder, upper-arm,
// elbow and wrist motion stay coupled. No elbow pinning or individual limb warps.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {measureArm}=require('./te_depth_arm_measurements.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-natural-arms');
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
const median=a=>a.sort((a,b)=>a-b)[Math.floor(a.length/2)];
function shirt(data){
 const dark=(x,y)=>{const k=(y*290+x)*4;return data[k+3]>127&&data[k]<125&&data[k+1]<125&&data[k+2]<125&&Math.abs(data[k]-data[k+1])<18&&Math.abs(data[k+1]-data[k+2])<18;};
 const centers=[],hems=[];
 for(let y=55;y<90;y++){const xs=[];for(let x=75;x<220;x++)if(dark(x,y))xs.push(x);if(xs.length>65)centers.push((xs[0]+xs.at(-1))/2);}
 for(let x=120;x<160;x++){let last=-1;for(let y=55;y<130;y++)if(dark(x,y))last=y;if(last>=0)hems.push(last);}
 if(centers.length<10||hems.length<30)throw Error('Cannot register the shirt');
 return {x:median(centers),y:median(hems)};
}
function sample(data,x,y){
 const xx=Math.max(0,Math.min(289,Math.round(x))),yy=Math.max(0,Math.min(179,Math.round(y))),k=(yy*290+xx)*4;
 return Array.from(data.subarray(k,k+4));
}
async function main(){
 const source=path.join(root,'assets/characters/open_world/te-south-depth-swing.png');
 const base=await sharp(source).ensureAlpha().raw().toBuffer(),registration=[];
 for(let f=1;f<=4;f++){
  const previous=await sharp(source).extract({left:f*400+55,top:235,width:290,height:180}).ensureAlpha().raw().toBuffer();
  const painted=await sharp(path.join(out,'edited.png')).extract({left:(f-1)%2*290,top:Math.floor((f-1)/2)*180,width:290,height:180}).ensureAlpha().raw().toBuffer();
  const a=shirt(previous),b=shirt(painted),dx=Math.round(a.x-b.x);
  const cuff=(data,shift)=>{
   const ys=[];
   for(const cx of [116,266])for(let x=cx-5;x<=cx+5;x++)for(let y=255;y<315;y++){
    const p=sample(data,x-55-shift,y-235);
    if(p[3]>127&&p[0]>110&&p[0]-p[1]>35&&p[1]-p[2]>18){ys.push(y);break;}
   }
   if(ys.length<10)throw Error('Cannot locate sleeve/arm attachment');
   return median(ys);
  };
  const dy=cuff(previous,0)-cuff(painted,dx);
  if(Math.abs(dx)>40||Math.abs(dy)>15)throw Error('Unexpected panel registration '+JSON.stringify({f,a,b,dx,dy}));
  registration.push({frame:f,translation:[dx,dy],registration:'shirt centre and sleeve attachment',sourceShirt:a,paintedShirt:b});
  const oldFrame=await sharp(source).extract({left:f*400,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer();
  const newFrame=await sharp(painted,{raw:{width:290,height:180,channels:4}}).extend({left:55+dx,right:55-dx,top:235+dy,bottom:145-dy,background:'#00000000'}).raw().toBuffer();
  const oldArms=[0,1].map(side=>measureArm(oldFrame,side,6)),newArms=[0,1].map(side=>measureArm(newFrame,side,4));
  const joins=new Map();
  for(let y=261;y<280;y++){
   const oldXs=[],newXs=[];
   for(let x=55;x<345;x++){
    if(base[(y*2000+f*400+x)*4+3]>127)oldXs.push(x);
    if(sample(painted,x-55-dx,y-235-dy)[3]>127)newXs.push(x);
   }
   if(oldXs.length&&newXs.length){const t=smooth(260,280,y);joins.set(y,[oldXs[0]*(1-t)+newXs[0]*t,oldXs.at(-1)*(1-t)+newXs.at(-1)*t]);}
  }
  for(let y=235;y<410;y++)for(let x=55;x<345;x++){
   const armZone=y<300?Math.max(1-smooth(145,162,x),smooth(222,240,x)):1;
   const w=armZone*smooth(260,280,y)*(1-smooth(387,410,y))*smooth(55,68,x)*(1-smooth(332,345,x));
   if(!w)continue;
   const side=x<200?0:1,om=oldArms[side].mask[y*400+x],nm=newArms[side].mask[y*400+x];
   if(y>=300&&!om&&!nm)continue;
   const p=sample(painted,x-55-dx,y-235-dy),k=(y*2000+f*400+x)*4;
   if(y>=300){
    const skin=q=>q[3]>100&&q[0]-q[1]>25&&q[1]-q[2]>12;
    const old=Array.from(base.subarray(k,k+4));
    const cloth=old[3]>100&&Math.abs(old[0]-old[1])<35&&Math.abs(old[1]-old[2])<40;
    if(!nm){if(cloth&&x>=141&&x<=249)continue;p[3]=0;}
    
   }
   const oa=base[k+3]/255,na=p[3]/255,alpha=oa*(1-w)+na*w;
   for(let c=0;c<3;c++)base[k+c]=alpha?Math.round((base[k+c]*oa*(1-w)+p[c]*na*w)/alpha):0;
   base[k+3]=Math.round(alpha*255);
   // Match the silhouette through the shirt join; the opacity shader must not
   // turn two faint overlapping sleeve edges into two opaque outlines.
   if(joins.has(y)){const [l,r]=joins.get(y);base[k+3]=Math.round(base[k+3]*smooth(l-.5,l+.5,x)*(1-smooth(r-.5,r+.5,x)));}
  }
 }
 const file=path.join(root,'assets/characters/open_world/te-south-natural-arms.png');
 await sharp(base,{raw:{width:2000,height:560,channels:4}}).png().toFile(file);
 const render=Buffer.from(base);for(let k=3;k<render.length;k+=4)render[k]=Math.round(255*smooth(5.1,30.6,render[k]));
 const png=await sharp(render,{raw:{width:2000,height:560,channels:4}}).png().toBuffer();
 await sharp(png).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
 const frames=[],detail=[];
 for(let f=1;f<=4;f++){
  frames.push(await sharp(png).extract({left:f*400,top:0,width:400,height:560}).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
  detail.push(await sharp(png).extract({left:f*400+75,top:250,width:245,height:160}).resize(490,320).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 }
 for(const [name,data,w,h] of [['caminhada.gif',frames,400,560],['bracos.gif',detail,490,320]])await sharp(Buffer.concat(data),{raw:{width:w,height:h*4,channels:3,pageHeight:h}}).gif({loop:0,delay:150}).toFile(path.join(out,name));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({source,wholeArmMotion:true,registration},null,2)+'\n');
}
main().catch(e=>{console.error(e);process.exitCode=1});
