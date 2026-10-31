const sharp=require('sharp'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const HEIGHTS=[219,213,212,212,232];
async function main(){
  const pieces=[];
  for(let kind=0;kind<2;kind++)for(let row=0;row<5;row++)for(let key=0;key<5;key++){
    const input=await sharp(path.join(DIR,`${kind?'jo':'te'}-walk-v10.png`))
      .extract({left:key*800+200,top:row*1120+(260-HEIGHTS[row])*4-20,width:440,height:448})
      .resize(220,224).png().toBuffer();
    pieces.push({input,left:kind*1120+key*224,top:row*228});
  }
  await sharp({create:{width:2240,height:1140,channels:4,background:'#8a998b'}})
    .composite(pieces).png().toFile(path.join(ROOT,'output/character-neck-v10-review.png'));
  const frames=[];
  const views=[0,1,2,3,4,3,2,1],labels=['Sul','Sudeste','Este','Nordeste','Norte','Noroeste','Oeste','Sudoeste'];
  for(let key=1;key<=4;key++){
    const tiles=[];
    for(let direction=0;direction<8;direction++){
      const row=views[direction],left=direction%4*280,top=Math.floor(direction/4)*342;
      const label=Buffer.from(`<svg width="280" height="28"><text x="140" y="21" text-anchor="middle" font-family="sans-serif" font-size="17" fill="#f5f2e8">${labels[direction]}</text></svg>`);
      tiles.push({input:label,left,top});
      for(let kind=0;kind<2;kind++){
        let sprite=sharp(path.join(DIR,`${kind?'jo':'te'}-walk-v10.png`))
          .extract({left:key*800+120,top:row*1120,width:560,height:1120});
        if(direction>4)sprite=sprite.flop();
        tiles.push({input:await sprite.resize(140,280).png().toBuffer(),left:left+kind*140,top:top+34});
      }
    }
    frames.push(await sharp({create:{width:1120,height:684,channels:4,background:'#586d60'}}).composite(tiles).raw().toBuffer());
  }
  await sharp(Buffer.concat(frames),{raw:{width:1120,height:684*4,channels:4,pageHeight:684}})
    .gif({loop:0,delay:180,effort:4}).toFile(path.join(ROOT,'output/character-neck-v10-walk.gif'));
  if(process.argv.includes('--scene')) {
    const game=[];
    for(let phase=0;phase<4;phase++) {
      const tiles=[];
      for(let direction=0;direction<8;direction++) {
        const left=direction%4*320,top=Math.floor(direction/4)*316;
        const input=await sharp(`/tmp/tejo-neck-game/d${direction}-p${phase}.png`)
          .extract({left:440,top:160,width:400,height:360}).resize(320,288).png().toBuffer();
        const label=Buffer.from(`<svg width="320" height="28"><text x="160" y="21" text-anchor="middle" font-family="sans-serif" font-size="17" fill="white">${labels[direction]}</text></svg>`);
        tiles.push({input,left,top:top+28},{input:label,left,top});
      }
      game.push(await sharp({create:{width:1280,height:632,channels:4,background:'#25372e'}}).composite(tiles).raw().toBuffer());
    }
    await sharp(Buffer.concat(game),{raw:{width:1280,height:632*4,channels:4,pageHeight:632}})
      .gif({loop:0,delay:180,effort:4}).toFile(path.join(ROOT,'output/character-neck-v10-game.gif'));
  }
  console.log('Saved all 50 upper-body poses and an eight-direction animated review.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
