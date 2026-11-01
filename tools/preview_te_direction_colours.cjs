const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'output/te-all-directions-colours');
const smooth=x=>{const t=Math.max(0,Math.min(1,(x-5.1)/25.5));return t*t*(3-2*t)};
async function shader(png){const {data,info}=await sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject:true});for(let k=3;k<data.length;k+=4)data[k]=Math.round(255*smooth(data[k]));return sharp(data,{raw:{width:info.width,height:info.height,channels:4}}).png().toBuffer();}
async function main(){
 const {rects,anchors}=JSON.parse(await fs.readFile(path.join(out,'source-regions.json'))),atlas=path.join(root,'assets/characters/open_world/te-walk-v14-palette.png'),south=path.join(root,'assets/characters/open_world/te-south-final-details.png');
 const directions=[['NO',3,true],['N',4,false],['NE',3,false],['O',2,true],['Te',0,false],['E',2,false],['SO',1,true],['S',0,false],['SE',1,false]],frames=[];
 for(let tick=0;tick<4;tick++){
  const overlays=[];
  for(let pos=0;pos<directions.length;pos++){
   const [label,row,mirror]=directions[pos],idle=pos===4,f=idle?0:1+tick*2;let png;
   if(row===0){png=await sharp(south).extract({left:(idle?0:1+tick)*400,top:0,width:400,height:560}).png().toBuffer();png=await shader(png);}
   else {
    const index=row*9+f,[x,y,w,h]=rects[index],scale=438/h;
    const crop=await shader(await sharp(atlas).extract({left:x,top:y,width:w,height:h}).png().toBuffer());
    const figure=await sharp(crop).resize(Math.round(w*scale),438).png().toBuffer();
    png=await sharp({create:{width:400,height:560,channels:4,background:'#00000000'}}).composite([{input:figure,left:Math.round(200-anchors[index][0]*scale),top:82}]).png().toBuffer();
   }
   if(mirror)png=await sharp(png).flop().png().toBuffer();
   const left=(pos%3)*240,top=Math.floor(pos/3)*310;
   overlays.push({input:await sharp(png).resize(200,280).png().toBuffer(),left:left+20,top:top+25});
   overlays.push({input:Buffer.from(`<svg width="240" height="30"><text x="120" y="24" font-family="Arial" font-size="17" text-anchor="middle" fill="#294238">${label}</text></svg>`),left,top});
  }
  const frame=await sharp({create:{width:720,height:930,channels:3,background:'#a7b29b'}}).composite(overlays).removeAlpha().raw().toBuffer();frames.push(frame);
  if(tick===0)await sharp(frame,{raw:{width:720,height:930,channels:3}}).png().toFile(path.join(out,'oito-direcoes.png'));
 }
 await sharp(Buffer.concat(frames),{raw:{width:720,height:930*4,channels:3,pageHeight:930}}).gif({loop:0,delay:[150,150,150,150]}).toFile(path.join(out,'oito-direcoes.gif'));
 console.log('Saved eight-direction previews. Display alpha matches the game shader.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
