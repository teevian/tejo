const sharp=require('sharp'),assert=require('node:assert/strict');
const recipe=require('../assets/characters/open_world/neck-motion-v14.recipe.json');
(async()=>{for(const who of ['te','jo']){
 const atlas=await sharp(`assets/characters/open_world/${who}-walk-v14.png`).ensureAlpha().raw().toBuffer();
 const pose=recipe.characters[who].poses[0],top=164,cx=pose.pivot[0],eye=who==='te'?40:34;
 const pixel=(frame,x,y,c)=>atlas[((top+y)*7200+frame*800+x)*4+c];
 for(let frame=1;frame<=8;frame++)for(let y=0;y<pose.headEnd*4;y++)for(let x=200;x<600;x++){
  assert.equal(pixel(frame,x,y,3),pixel(0,x,y,3),'Head outline translated');
  if(y<80||x<78*4+pose.neutralShift||x>=122*4+pose.neutralShift)
   for(let c=0;c<3;c++)assert.equal(pixel(frame,x,y,c),pixel(0,x,y,c),'Hair or outer head moved');
 }
 // Locate the original nose/eye texture independently by patch matching.
 const shift=(frame,yy)=>{let best=Infinity,delta=0;for(let dx=-8;dx<=8;dx++){
  let error=0;for(let y=yy*4-8;y<=yy*4+8;y++)for(let x=cx-12;x<=cx+12;x++)for(let c=0;c<3;c++)error+=Math.abs(pixel(frame,x+dx,y,c)-pixel(0,x,y,c));
  if(error<best){best=error;delta=dx;}
 }return delta;};
 const nose=[1,5].map(f=>shift(f,eye+10)),eyes=[1,5].map(f=>shift(f,eye));
 assert(nose[0]<0&&nose[1]>0,'Nose must turn both ways');
 assert(nose.every((v,i)=>Math.abs(v)>Math.abs(eyes[i])),'Face must change perspective, not shift as one piece');
 assert(nose.every(v=>Math.abs(v)<=5),'Yaw must stay subtle');
 console.log(`PASS ${who}: head contour/hair fixed in all 8 steps; nose ${nose} px, eyes ${eyes} px at 4x resolution`);
}})().catch(e=>{console.error(e);process.exitCode=1});
