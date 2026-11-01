// Integrate the image-tool forearm retouch; preserve every pixel outside arms.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-south-fine-arms');
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
async function main(){
 const source=path.join(root,'assets/characters/open_world/te-south-forearm-balance.png');
 const base=await sharp(source).ensureAlpha().raw().toBuffer();
 const paint=await sharp(path.join(out,'edited.png')).resize(540,300,{fit:'fill'}).ensureAlpha().raw().toBuffer();
 for(let f=1;f<=4;f++)for(let y=0;y<150;y++)for(let x=0;x<270;x++){
  const gx=x+65,gy=y+280;
  const side=Math.max(smooth(72,88,gx)*(1-smooth(140,158,gx)),smooth(236,250,gx)*(1-smooth(313,329,gx)));
  const weight=side*smooth(324,340,gy)*(1-smooth(392,404,gy));
  if(!weight)continue;
  const shifts=[[[ -1,7],[0,5]],[[-7,0],[-8,-1]],[[-1,2],[0,5]],[[-9,3],[-8,2]]];
  const [dx,dy]=shifts[f-1][gx<200?0:1];
  const center=(gx<200?117:268)-65-dx;
  const widthScale=1+.10*smooth(325,336,gy)*(1-smooth(346,362,gy));
  const px=Math.max(0,Math.min(269,Math.round(center+(x-dx-center)/widthScale))),py=Math.max(0,Math.min(149,Math.round(y-dy*smooth(320,350,gy))));
  const a=(gy*2000+f*400+gx)*4,b=((Math.floor((f-1)/2)*150+py)*540+(f-1)%2*270+px)*4;
  const skin=k=>paint[k+3]>100&&paint[k]-paint[k+1]>25&&paint[k+1]-paint[k+2]>12;
  const cloth=base[a+3]>100&&Math.abs(base[a]-base[a+1])<35&&Math.abs(base[a+1]-base[a+2])<40;
  if(cloth&&!skin(b)){
   let edge=false;
   if(paint[b+3]>100&&paint[b]<130)for(let yy=-2;yy<=2;yy++)for(let xx=-2;xx<=2;xx++)if(skin(b+(yy*540+xx)*4))edge=true;
   if(!edge)continue;
  }
  const oa=base[a+3]/255,na=paint[b+3]/255,alpha=oa*(1-weight)+na*weight;
  for(let c=0;c<3;c++)base[a+c]=alpha?Math.round((base[a+c]*oa*(1-weight)+paint[b+c]*na*weight)/alpha):0;
  base[a+3]=Math.round(alpha*255);
 }
 const file=path.join(root,'assets/characters/open_world/te-south-fine-arms.png');
 await sharp(base,{raw:{width:2000,height:560,channels:4}}).png().toFile(file);
 const frames=[];
 for(let f=1;f<=4;f++)frames.push(await sharp(file).extract({left:f*400,top:0,width:400,height:560}).flatten({background:'#a7b29b'}).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:400,height:560*4,channels:3,pageHeight:560}}).gif({loop:0,delay:120}).toFile(path.join(out,'caminhada.gif'));
 await sharp(file).flatten({background:'#a7b29b'}).png().toFile(path.join(out,'sequencia.png'));
}
main().catch(e=>{console.error(e);process.exitCode=1});
