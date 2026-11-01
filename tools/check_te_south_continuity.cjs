// Regression check for the visible "inflating forearms" defect in the actual atlas.
// Compare skin cross-sections in the same forearm band, across authored key poses.
const sharp=require('sharp'),path=require('node:path');
const {bounds}=require('./pack_te_rpg_v17.cjs');
const median=a=>a.slice().sort((a,b)=>a-b)[Math.floor(a.length/2)];
function elbowEnvelope(data){
 const left=[],right=[];
 for(let y=300;y<330;y++){
  let l=400,r=-1;
  for(let x=60;x<340;x++){
   const k=(y*400+x)*4;
   if(data[k+3]>127&&data[k]-data[k+1]>25&&data[k+1]-data[k+2]>12){l=Math.min(l,x);r=Math.max(r,x);}
  }
  if(r>l){left.push(l);right.push(r);}
 }
 if(left.length<20)throw Error('Cannot measure elbow envelope');
 return [median(left),median(right)];
}
async function main(){
 const level=process.argv.includes('--level');
 const tucked=process.argv.includes('--tucked-elbows');
 const file=path.resolve(process.argv[2]||path.join(__dirname,'../assets/characters/open_world/te-south-continuous.png'));
 const meta=await sharp(file).metadata(),keys=meta.width===3600?[1,3,5,7]:[1,2,3,4],measurements=[];
 const idle=await sharp(file).extract({left:0,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer(),idleElbows=elbowEnvelope(idle);
 for(const f of keys){
  const data=await sharp(file).extract({left:f*400,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer(),bb=bounds(data,400,560),arms=[];
  for(let side=0;side<2;side++){
   const widths=[];
   for(let y=300;y<330;y++){
    let l=400,r=-1;
    for(let x=side?225:75;x<(side?325:175);x++){
     const k=(y*400+x)*4;
     if(data[k+3]>127&&data[k]-data[k+1]>25&&data[k+1]-data[k+2]>12){l=Math.min(l,x);r=Math.max(r,x);}
    }
    if(r>l)widths.push(r-l+1);
   }
   if(widths.length<20)throw Error('Forearm cannot be measured in frame '+f);
   arms.push(median(widths));
  }
  const head=bounds(data,400,560,bb.top+Math.round(bb.height*.23));
  measurements.push({frame:f,arms,elbowEnvelope:elbowEnvelope(data),crown:bb.top,ground:bb.top+bb.height,headCenter:head.left+head.width/2,headWidth:head.width});
 }
 const ratios=[0,1].map(side=>{const a=measurements.map(m=>m.arms[side]);return Math.max(...a)/Math.min(...a)});
 console.log(JSON.stringify({file,forearmWidthRatios:ratios,idleElbows,measurements},null,2));
 if(tucked&&measurements.some(m=>m.elbowEnvelope[0]<idleElbows[0]-4||m.elbowEnvelope[1]>idleElbows[1]+4))throw Error('Elbows flare sideways beyond the relaxed idle silhouette');
 if(ratios.some(r=>r>1.20))throw Error('Forearm cross-section changes by more than 20% across the walk');
 const centers=measurements.map(m=>m.headCenter),widths=measurements.map(m=>m.headWidth),span=Math.max(...centers)-Math.min(...centers);
 if((!level&&span<.4)||span>4)throw Error('Head must follow the chest subtly instead of remaining pinned or swaying excessively');
 const crowns=measurements.map(m=>m.crown);
 if(level&&Math.max(...crowns)-Math.min(...crowns)>2)throw Error('The head drops between steps instead of staying almost level');
 if(Math.max(...widths)/Math.min(...widths)>1.06)throw Error('Head/hair size changes across the walk');
 if(measurements.some(m=>level?Math.abs(m.ground-520)>6:m.ground!==520))throw Error('Foot depth exceeds the allowed front-view stride');
 console.log(level?'PASS: level head, consistent forearms and head size, bounded foot stride depth':'PASS: bounded forearm cross-sections, subtle unpinned head response, steady head size and planted-foot baseline');
}
main().catch(e=>{console.error(e.message);process.exitCode=1});
