// Check depth rotation, rather than treating changing vertical length as swing.
const sharp=require('sharp'),path=require('node:path');
const {measureArm}=require('./te_depth_arm_measurements.cjs');
const span=a=>Math.max(...a)-Math.min(...a);
async function main(){
 const file=path.resolve(process.argv[2]||'assets/characters/open_world/te-south-depth-swing.png'),frames=[];
 for(let f=1;f<=4;f++){
  const data=await sharp(file).extract({left:f*400,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer();
  frames.push([0,1].map(s=>measureArm(data,s)));
 }
 const elbowDrift=[0,1].map(s=>span(frames.map(a=>a[s].elbowX)));
 const contourDrift=[0,1].map(s=>Math.max(...Array.from({length:13},(_,y)=>Math.max(...[0,1].map(e=>span(frames.map(a=>a[s].contour[y][e])))))));
 const forward=[frames[2][0],frames[0][1]],rear=[frames[0][0],frames[2][1]],passing=[0,1].map(s=>(frames[1][s].forearmWidth+frames[3][s].forearmWidth)/2);
 const result={file,elbowDrift,contourDrift,forwardInwardOffsets:forward.map(a=>a.inwardOffset),forwardProjectedAngles:forward.map(a=>a.projectedAngle),rearWidths:rear.map(a=>a.forearmWidth),passingWidths:passing,frames:frames.map(a=>a.map(({mask,contour,...m})=>m))};
 console.log(JSON.stringify(result,null,2));
 if(elbowDrift.some(v=>v>1)||contourDrift.some(v=>v>1))throw Error('Proximal elbow anchors change between poses');
 if(forward.some(a=>a.inwardOffset<12||a.projectedAngle<17))throw Error('Forward forearms stay vertical instead of rotating toward the waist');
 if(forward.some((a,s)=>a.handY>rear[s].handY-7))throw Error('Forward hand does not approach the waist');
 if(rear.some(a=>Math.abs(a.inwardOffset)>8))throw Error('Rear arm bends inward like the advancing arm');
 if(rear.some((a,s)=>a.forearmWidth>=passing[s]))throw Error('Receding forearm does not narrow in perspective');
 for(let s=0;s<2;s++)for(let f of [1,3])if(frames[f][s].inwardOffset>=forward[s].inwardOffset-4)throw Error('Passing wrist is not between the two depth angles');
 console.log('PASS: fixed elbows, angled inward forward wrists, narrower receding forearms and intermediate angles');
}
main().catch(e=>{console.error(e.message);process.exitCode=1});
