// Run the Godot scene preview with -- --all-directions first. Requires sharp.
const sharp=require('sharp');
const path=require('node:path');
const fs=require('node:fs/promises');
const ROOT=path.resolve(__dirname,'..');
const OUT=path.join(ROOT,'output');
const DIRS=['Frente','Diagonal direita','Direita','Costas / direita','Costas','Costas / esquerda','Esquerda','Diagonal esquerda'];
async function main() {
  const pieces=[];
  for(let kind=0;kind<2;kind++) for(let row=0;row<5;row++) for(let col=0;col<5;col++) {
    const crop={left:col*800+220,top:row*1120+[41,47,48,48,28][row]*4,width:400,height:440};
    const input=await sharp(path.join(ROOT,'assets/characters/open_world',kind?'jo-walk-v9.png':'te-walk-v9.png'))
      .extract(crop).resize(100,110).png().toBuffer();
    pieces.push({input,left:col*110+kind*560,top:row*120});
  }
  const sheet=await sharp({create:{width:1120,height:600,channels:4,background:'#8a998b'}}).composite(pieces).png().toBuffer();
  await sharp(sheet).resize(1680,900).png().toFile(path.join(OUT,'character-neck-review.png'));
  const frames=[],review=[];
  for(let direction=0;direction<8;direction++) {
    const phaseImages=[];
    for(let phase=0;phase<4;phase++) {
      const crop=await sharp('/tmp/tejo-neck-game/d'+direction+'-p'+phase+'.png')
        .extract({left:440,top:160,width:400,height:360}).png().toBuffer();
      review.push({input:crop,left:direction%4*400,top:(phase*2+Math.floor(direction/4))*360});
      const view=await sharp(crop).resize(800,720).png().toBuffer();
      const title=Buffer.from('<svg width="800" height="32"><rect width="800" height="32" fill="#25372e"/><text x="16" y="23" font-size="19" font-family="sans-serif" fill="white">'+DIRS[direction]+' · Te / Jo</text></svg>');
      phaseImages.push(await sharp({create:{width:800,height:752,channels:4,background:'#25372e'}})
        .composite([{input:title,left:0,top:0},{input:view,left:0,top:32}]).raw().toBuffer());
    }
    for(const phase of [0,1,2,3]) frames.push(phaseImages[phase]);
  }
  await sharp({create:{width:1600,height:2880,channels:4,background:'#25372e'}}).composite(review)
    .png().toFile(path.join(OUT,'character-neck-scene-review.png'));
  await sharp(Buffer.concat(frames),{raw:{width:800,height:752*frames.length,channels:4,pageHeight:752}})
    .gif({loop:0,delay:frames.map((_,index)=>index%4===3?450:250),effort:4}).toFile(path.join(OUT,'character-neck-walk.gif'));
  // Keep the two reported Jo joins visible side by side in an actual game loop.
  const joins=[];
  for(let phase=0;phase<4;phase++){
    const pieces=[];
    for(const [column,direction] of [4,0].entries()){
      const input=await sharp(frames[direction*4+phase],{raw:{width:800,height:752,channels:4}})
        .extract({left:400,top:32,width:400,height:720}).resize(300,540).png().toBuffer();
      const title=Buffer.from('<svg width="300" height="36"><rect width="300" height="36" fill="#25372e"/><text x="150" y="25" text-anchor="middle" font-size="21" font-family="sans-serif" fill="white">Jo · '+(direction===4?'Norte':'Sul')+'</text></svg>');
      pieces.push({input,left:column*300,top:36},{input:title,left:column*300,top:0});
    }
    joins.push(await sharp({create:{width:600,height:576,channels:4,background:'#25372e'}}).composite(pieces).raw().toBuffer());
  }
  await sharp(Buffer.concat(joins),{raw:{width:600,height:576*4,channels:4,pageHeight:576}})
    .gif({loop:0,delay:220,effort:4}).toFile(path.join(OUT,'jo-neck-north-south-v9.gif'));
  await sharp(joins[0],{raw:{width:600,height:576,channels:4}}).png().toFile(path.join(OUT,'jo-neck-north-south-v9.png'));
  await fs.copyFile(path.join(ROOT,'assets/characters/open_world/sources/jo-heads-v9.png'),path.join(OUT,'jo-heads-v9.png'));
  // Keep the troublesome directions visible together for a continuous loop.
  const focused=[],directions=[1,2,3,6],labels=['Diagonal frente','Direita','Diagonal costas','Esquerda'];
  for(let phase=0;phase<4;phase++){
    const pieces=[];
    for(let column=0;column<directions.length;column++){
      const input=await sharp('/tmp/tejo-neck-game/d'+directions[column]+'-p'+phase+'.png')
        .extract({left:440,top:160,width:200,height:360}).png().toBuffer();
      pieces.push({input,left:column*200,top:32});
      const label=Buffer.from('<svg width="200" height="32"><rect width="200" height="32" fill="#25372e"/><text x="12" y="22" font-size="17" font-family="sans-serif" fill="white">'+labels[column]+'</text></svg>');
      pieces.push({input:label,left:column*200,top:0});
    }
    focused.push(await sharp({create:{width:800,height:392,channels:4,background:'#25372e'}}).composite(pieces).raw().toBuffer());
  }
  await sharp(Buffer.concat(focused),{raw:{width:800,height:392*4,channels:4,pageHeight:392}})
    .gif({loop:0,delay:300,effort:4}).toFile(path.join(OUT,'te-natural-walk-v9.gif'));
  console.log('Reviewed 50 baked head/torso joins and 64 rendered game poses; saved static and animated neck previews.');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
