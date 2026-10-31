const sharp=require('sharp'),fs=require('node:fs'),{ARMS}=require('./pack_character_necks.cjs');
const dir='assets/characters/open_world/',recipe=JSON.parse(fs.readFileSync(dir+'neck-motion-v14.recipe.json'));
(async()=>{let before=0,after=0,count=0,changed=0;
for(const who of ['te','jo']){
 const neutral=await sharp(dir+recipe.characters[who].body).ensureAlpha().raw().toBuffer();
 const source=await sharp(dir+who+'-walk-v9.png').ensureAlpha().raw().toBuffer();
 const final=await sharp(dir+who+'-walk-v14.png').ensureAlpha().raw().toBuffer();
 const width=(data,stride,x0,y,l,r)=>{let min=Infinity,max=-1;for(let x=l;x<r;x++){const i=(y*stride+x0+x)*4;if(data[i+3]>128&&data[i]>105&&data[i]>data[i+1]*1.28&&data[i+1]>data[i+2]*1.08){min=Math.min(min,x);max=x;}}return max<0?0:max-min+1;};
 for(let row=0;row<5;row++)for(let frame=1;frame<9;frame++){
  if(who==='jo'&&row===0)continue; // This direction uses a separately corrected gait source.
  const pose=recipe.characters[who].poses[row*9+frame],top=(260-[219,213,212,212,232][row])*4;
  for(const [l,r,start]of ARMS[who][row])for(let y=top+(start+12)*4;y<top+130*4;y+=4){
   const target=width(neutral,4000,0,row*1120+y,l*4,r*4);
   const old=width(source,4000,pose.key*800-pose.sourceShift+pose.neutralShift,row*1120+y,l*4,r*4);
   const actual=width(final,7200,frame*800+pose.neutralShift,row*1120+y,l*4,r*4);
   if(Math.min(target,old,actual)<12)continue;
   before+=Math.abs(old-target);after+=Math.abs(actual-target);count++;if(actual!==old)changed++;
  }
 }
}
if(count<500||changed<100||after>before){console.error({before,after,count,changed});process.exitCode=1;}
else console.log(`PASS: ${count} arm cross-sections; deviation from neutral width reduced from ${(before/count).toFixed(2)} to ${(after/count).toFixed(2)} pixels (${changed} adjusted)`);
})();
