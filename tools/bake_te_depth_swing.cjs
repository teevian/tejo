// Paint authored forearm rotation into complete sprites. Registration is a rigid
// horizontal translation only: the angled wrist, fist and volume are never warped.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const {measureArm}=require('./te_depth_arm_measurements.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-depth-swing');
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
const skin=p=>p[3]>100&&p[0]-p[1]>25&&p[1]-p[2]>12;
function sample(data,x,y){
 const lo=Math.max(0,Math.min(399,Math.floor(x))),hi=Math.min(399,lo+1),t=x-Math.floor(x),a=(y*400+lo)*4,b=(y*400+hi)*4;
 const alpha=data[a+3]*(1-t)+data[b+3]*t;
 return [0,1,2].map(c=>alpha?(data[a+c]*data[a+3]*(1-t)+data[b+c]*data[b+3]*t)/alpha:0).concat(alpha);
}
function mix(data,k,p,w){
 const a=data[k+3]/255,b=p[3]/255,alpha=a*(1-w)+b*w;
 for(let c=0;c<3;c++)data[k+c]=alpha?Math.round((data[k+c]*a*(1-w)+p[c]*b*w)/alpha):0;
 data[k+3]=Math.round(alpha*255);
}
async function main(){
 const source=path.join(root,'assets/characters/open_world/te-south-anchored-arms.png');
 const base=await sharp(source).ensureAlpha().raw().toBuffer();
 const reference=await sharp(source).extract({left:400,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer();
 const pivots=[0,1].map(s=>measureArm(reference,s).elbowX),registration=[];
 for(let f=1;f<=4;f++){
  const paint=await sharp(path.join(out,'edited.png')).extract({left:(f-1)%2*270,top:Math.floor((f-1)/2)*200,width:270,height:200}).extend({left:65,right:65,top:240,bottom:120,background:'#00000000'}).ensureAlpha().raw().toBuffer();
  const sourceFrame=await sharp(source).extract({left:f*400,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer();
  const newArms=[0,1].map(s=>measureArm(paint,s,true)),oldArms=[0,1].map(s=>measureArm(sourceFrame,s,6));
  const dx=newArms.map((a,s)=>pivots[s]-a.elbowX);
  registration.push({frame:f,horizontalTranslation:dx,verticalTranslation:0,scale:1});
  for(let y=310;y<405;y++)for(let x=72;x<322;x++){
   const side=x<200?0:1;
   // Include the waist, so a rotated hand can overlap the shirt and shorts.
   const zone=side?smooth(202,214,x)*(1-smooth(310,322,x)):smooth(72,82,x)*(1-smooth(174,186,x));
   const weight=zone*smooth(310,316,y)*(1-smooth(394,405,y));
   if(!weight)continue;
   const px=x-dx[side],oldMask=oldArms[side].mask[y*400+x],newMask=newArms[side].mask[y*400+Math.max(0,Math.min(399,Math.round(px)))];
   if(!oldMask&&!newMask)continue;
   const k=(y*2000+f*400+x)*4,p=sample(paint,px,y),old=Array.from(base.subarray(k,k+4));
   const cloth=old[3]>100&&Math.abs(old[0]-old[1])<35&&Math.abs(old[1]-old[2])<40;
   if(!newMask){
    if(!(cloth&&x>=141&&x<=249))mix(base,k,[0,0,0,0],weight);
    continue;
   }
   if(cloth&&!skin(p)){
    let outline=false;
    if(p[3]>30&&p[0]<140)for(let yy=-2;yy<=2;yy++)for(let xx=-2;xx<=2;xx++)if(skin(sample(paint,px+xx,y+yy)))outline=true;
    if(!outline)continue;
   }
   mix(base,k,p,weight);
  }
 }
 // Remove isolated remnants left behind by the old arm silhouette. Match the
 // game's alpha threshold when identifying the main connected painting.
 for(let f=1;f<=4;f++){
  const seen=new Uint8Array(400*560),groups=[];
  for(let start=0;start<seen.length;start++){
   const a=(Math.floor(start/400)*2000+f*400+start%400)*4+3;
   if(seen[start]||base[a]<=5)continue;
   const group=[start];seen[start]=1;
   for(let q=0;q<group.length;q++){
    const p=group[q],x=p%400,y=Math.floor(p/400);
    for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){
     const xx=x+dx,yy=y+dy,k=yy*400+xx;
     if(xx>=0&&xx<400&&yy>=0&&yy<560&&!seen[k]&&base[(yy*2000+f*400+xx)*4+3]>5){seen[k]=1;group.push(k);}
    }
   }
   groups.push(group);
  }
  groups.sort((a,b)=>b.length-a.length);
  for(const group of groups.slice(1))for(const p of group){const x=p%400,y=Math.floor(p/400);if(y>=310&&y<405&&(x<185||x>210))base[(y*2000+f*400+x)*4+3]=0;}
 }
 const file=path.join(root,'assets/characters/open_world/te-south-depth-swing.png');
 await sharp(base,{raw:{width:2000,height:560,channels:4}}).png().toFile(file);
 await sharp(file).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
 const frames=[],comparison=[],details=[];
 const rendered=await sharp(file).ensureAlpha().raw().toBuffer();
 for(let k=3;k<rendered.length;k+=4)rendered[k]=Math.round(255*smooth(.02*255,.12*255,rendered[k]));
 const render=await sharp(rendered,{raw:{width:2000,height:560,channels:4}}).png().toBuffer();
 await sharp(render).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia-no-jogo.png'));
 for(let f=1;f<=4;f++){
  const south=await sharp(render).extract({left:f*400,top:0,width:400,height:560}).png().toBuffer();
  frames.push(await sharp(south).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
  details.push(await sharp(south).extract({left:75,top:275,width:245,height:135}).resize(490,270).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
  const north=await sharp(path.join(root,'output/te-south-north-matched/north-four-reference.png')).extract({left:(f-1)%2*400,top:Math.floor((f-1)/2)*560,width:400,height:560}).png().toBuffer();
  comparison.push(await sharp({create:{width:800,height:560,channels:3,background:'#a7b29b'}}).composite([{input:south,left:0,top:0},{input:north,left:400,top:0}]).raw().toBuffer());
 }
 for(const [name,data,w,h] of [['caminhada.gif',frames,400,560],['sul-norte.gif',comparison,800,560],['antebracos.gif',details,490,270]])await sharp(Buffer.concat(data),{raw:{width:w,height:h*4,channels:3,pageHeight:h}}).gif({loop:0,delay:150}).toFile(path.join(out,name));
 await fs.writeFile(path.join(out,'recipe.json'),JSON.stringify({source,elbowPivots:pivots,preservedThroughRow:310,authoredPerspective:true,runtimeWholeSprites:true,registration},null,2)+'\n');
}
main().catch(e=>{console.error(e);process.exitCode=1});
