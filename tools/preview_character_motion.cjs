const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const HEIGHTS=[219,213,212,212,232],LABELS=['Sul','Sudeste','Este','Nordeste','Norte','Noroeste','Oeste','Sudoeste'];
const views=[0,1,2,3,4,3,2,1];
const label=(text,w)=>Buffer.from(`<svg width="${w}" height="28"><text x="${w/2}" y="21" text-anchor="middle" font-family="sans-serif" font-size="17" fill="white">${text}</text></svg>`);
async function saveGif(frames,w,h,file){
  await sharp(Buffer.concat(frames),{raw:{width:w,height:h*frames.length,channels:4,pageHeight:h}})
    .gif({loop:0,delay:100,effort:4}).toFile(path.join(ROOT,'output',file));
}
async function main(){
  const recipe=JSON.parse(await fs.readFile(path.join(DIR,'neck-motion-v14.recipe.json'),'utf8'));
  const comparison=[];
  for(const [kind,who]of ['te','jo'].entries())for(let row=0;row<5;row++)for(let state=0;state<3;state++){
    const pose=recipe.characters[who].poses[row*9],frame=[0,1,5][state];
    const input=await sharp(path.join(DIR,`${who}-walk-${state===0?'v9':'v14'}.png`))
      .extract({left:frame*800+220-(state===0?pose.neutralShift:0),top:row*1120+(260-HEIGHTS[row])*4,width:360,height:300})
      .resize(144,120).png().toBuffer();
    comparison.push({input,left:(kind*3+state)*160+8,top:row*146+30});
  }
  for(let kind=0;kind<2;kind++)for(let state=0;state<3;state++){
    comparison.push({input:label(`${kind?'Jo':'Te'} — ${['original','esquerda','direita'][state]}`,160),left:(kind*3+state)*160,top:0});
  }
  await sharp({create:{width:960,height:760,channels:4,background:'#6f8374'}}).composite(comparison)
    .png().toFile(path.join(ROOT,'output/character-motion-v14-original-faces.png'));
  for(const who of ['te','jo']){
    const pieces=[];
    for(let row=0;row<5;row++)for(let frame=0;frame<9;frame++){
      const input=await sharp(path.join(DIR,`${who}-walk-v14.png`))
        .extract({left:frame*800+200,top:row*1120+(260-HEIGHTS[row])*4-24,width:440,height:456})
        .resize(140,145).png().toBuffer();
      pieces.push({input,left:frame*144,top:row*150});
    }
    await sharp({create:{width:1296,height:750,channels:4,background:'#8a998b'}}).composite(pieces)
      .png().toFile(path.join(ROOT,`output/character-motion-v14-${who}.png`));
  }
  if(process.argv.includes("--stills"))return;
  const frames=[];
  for(let frame=1;frame<=8;frame++){
    const pieces=[];
    for(let d=0;d<8;d++){
      const row=views[d],left=d%4*400,top=Math.floor(d/4)*360;
      pieces.push({input:label(LABELS[d],400),left,top});
      for(let kind=0;kind<2;kind++){
        const who=kind?'jo':'te',scale=(kind?153:156)/(HEIGHTS[row]*4)*1.5;
        const w=Math.round(800*scale),h=Math.round(1120*scale),trim=Math.max(0,Math.ceil((w-200)/2));
        const scaled=await sharp(path.join(DIR,`${who}-walk-v14.png`))
          .extract({left:frame*800,top:row*1120,width:800,height:1120})
          .resize(w,h,{fit:'fill'}).png().toBuffer();
        let input=sharp(scaled);
        if(d>4)input=input.flop();
        const painted=await input.extract({left:trim,top:0,width:w-trim*2,height:h}).png().toBuffer();
        pieces.push({input:painted,left:left+kind*200+Math.round((200-w+trim*2)/2),top:top+328-Math.round(1040*scale)});
      }
    }
    frames.push(await sharp({create:{width:1600,height:720,channels:4,background:'#586d60'}}).composite(pieces).raw().toBuffer());
  }
  await saveGif(frames,1600,720,'character-motion-v14-walk.gif');
  if(process.argv.includes('--scene')){
    const game=[],turns=[],south=[];
    for(let phase=0;phase<8;phase++){
      const pieces=[];
      for(let d=0;d<8;d++){
        const input=await sharp(`/tmp/tejo-motion-v14/d${d}-p${phase}.png`)
          .extract({left:440,top:160,width:400,height:360}).resize(320,288).png().toBuffer();
        const left=d%4*320,top=Math.floor(d/4)*316;
        pieces.push({input,left,top:top+28},{input:label(LABELS[d],320),left,top});
      }
      game.push(await sharp({create:{width:1280,height:632,channels:4,background:'#25372e'}}).composite(pieces).raw().toBuffer());
      const d=[3,4,5,4,3,4,5,4][phase];
      const input=await sharp(`/tmp/tejo-motion-v14/d${d}-p${phase}.png`)
        .extract({left:440,top:160,width:400,height:360}).resize(600,540).png().toBuffer();
      turns.push(await sharp({create:{width:600,height:568,channels:4,background:'#25372e'}})
        .composite([{input,left:0,top:28},{input:label(LABELS[d],600),left:0,top:0}]).raw().toBuffer());
      const front=await sharp(`/tmp/tejo-motion-v14/d0-p${phase}.png`)
        .extract({left:440,top:160,width:400,height:360}).resize(600,540).png().toBuffer();
      south.push(await sharp({create:{width:600,height:568,channels:4,background:'#25372e'}})
        .composite([{input:front,left:0,top:28},{input:label('Caminhada para sul',600),left:0,top:0}]).raw().toBuffer());
    }
    await saveGif(game,1280,632,'character-motion-v14-game.gif');
    await saveGif(turns,600,568,'character-motion-v14-turns.gif');
    await saveGif(south,600,568,'character-motion-v14-south.gif');
  }
  console.log('Saved original-face previews: two head states reused across eight body phases, at uniform directional heights.');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
