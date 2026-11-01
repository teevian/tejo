// Check the user's requested motion in painted pixels: two alternating hands,
// stable upper arms, and level shoulders. This does not infer motion from code.
const sharp=require('sharp'),path=require('node:path');
const median=a=>a.slice().sort((a,b)=>a-b)[Math.floor(a.length/2)];
function arm(data,side){
 const x0=side?225:75,x1=side?325:165,y0=270,y1=400,w=x1-x0,h=y1-y0;
 const mask=new Uint8Array(w*h),seen=new Uint8Array(w*h),groups=[];
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const k=((y+y0)*400+x+x0)*4;
  mask[y*w+x]=data[k+3]>127&&data[k]>70&&data[k]-data[k+1]>20&&data[k+1]-data[k+2]>10;
 }
 for(let start=0;start<mask.length;start++)if(mask[start]&&!seen[start]){
  const pixels=[start];seen[start]=1;
  for(let q=0;q<pixels.length;q++){
   const p=pixels[q],x=p%w,y=Math.floor(p/w);
   for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){
    const xx=x+dx,yy=y+dy,k=yy*w+xx;
    if(xx>=0&&xx<w&&yy>=0&&yy<h&&mask[k]&&!seen[k]){seen[k]=1;pixels.push(k);}
   }
  }
  if(pixels.some(p=>Math.floor(p/w)+y0<305))groups.push(pixels);
 }
 groups.sort((a,b)=>b.length-a.length);
 if(!groups.length)throw Error('Cannot find an intact arm');
 const pixels=groups[0].map(p=>[p%w+x0,Math.floor(p/w)+y0]);
 const elbows=[];
 for(let y=305;y<325;y++){
  const xs=pixels.filter(p=>p[1]===y).map(p=>p[0]);
  if(xs.length)elbows.push((Math.min(...xs)+Math.max(...xs))/2);
 }
 const elbowX=median(elbows),distal=[];let gaps=0;
 // A fist can touch the thigh. Follow the arm's narrow vertical lane instead
 // of mistaking connected leg skin for the bottom of the hand.
 for(let y=330;y<400;y++){
  const xs=pixels.filter(p=>p[1]===y).map(p=>p[0]).sort((a,b)=>a-b),runs=[];
  for(const x of xs){if(!runs.length||x>runs.at(-1).at(-1)+1)runs.push([x]);else runs.at(-1).push(x);}
  const valid=runs.filter(r=>r.length>=3&&Math.abs((r[0]+r.at(-1))/2-elbowX)<=14).sort((a,b)=>Math.abs((a[0]+a.at(-1))/2-elbowX)-Math.abs((b[0]+b.at(-1))/2-elbowX));
  if(valid.length){gaps=0;for(const x of valid[0])distal.push([x,y]);}
  else if(y>345&&++gaps>=2)break;
 }
 if(!distal.length)throw Error('Cannot track a hand below its elbow');
 const bottom=Math.max(...distal.map(p=>p[1])),hand=distal.filter(p=>p[1]>=bottom-20);
 return {handBottom:bottom,handX:median(hand.map(p=>p[0])),elbowX};
}
function shoulder(data,side){
 const ys=[];
 for(let x=side?238:130;x<(side?256:148);x++)for(let y=210;y<260;y++){
  const k=(y*400+x)*4,r=data[k],g=data[k+1],b=data[k+2];
  if(data[k+3]>127&&r<100&&g<100&&b<100&&Math.abs(r-g)<8&&Math.abs(g-b)<8){ys.push(y);break;}
 }
 if(ys.length<10)throw Error('Cannot measure the shirt shoulder');
 return median(ys);
}
const span=a=>Math.max(...a)-Math.min(...a);
async function main(){
 const file=path.resolve(process.argv[2]||'assets/characters/open_world/te-south-forearm-balance.png'),frames=[],contours=[];
 for(let f=1;f<=4;f++){
  const data=await sharp(file).extract({left:f*400,top:0,width:400,height:560}).ensureAlpha().raw().toBuffer();
  frames.push({frame:f,shoulders:[shoulder(data,0),shoulder(data,1)],arms:[arm(data,0),arm(data,1)]});
  contours.push([0,1].map(s=>Array.from({length:27},(_,i)=>{
   const xs=[];
   for(let x=s?225:75;x<(s?325:165);x++){
    const k=((300+i)*400+x)*4;
    if(data[k+3]>127&&data[k]-data[k+1]>25&&data[k+1]-data[k+2]>12)xs.push(x);
   }
   if(!xs.length)throw Error('Cannot measure the elbow contour');
   return [xs[0],xs.at(-1)];
  })));
 }
 const handRanges=[0,1].map(s=>span(frames.map(f=>f.arms[s].handBottom))),elbowRanges=[0,1].map(s=>span(frames.map(f=>f.arms[s].elbowX)));
 const elbowContourDrift=[0,1].map(s=>Math.max(...Array.from({length:27},(_,y)=>Math.max(...[0,1].map(e=>span(contours.map(c=>c[s][y][e])))))));
 console.log(JSON.stringify({file,handRanges,elbowRanges,elbowContourDrift,frames},null,2));
 if(handRanges.some(r=>r<10||r>24))throw Error('Each forearm must swing visibly but subtly; neither hand may stay parked');
 if(Math.max(...handRanges)/Math.min(...handRanges)>1.25)throw Error('Forearm swing amplitudes are unbalanced');
 // The skin/cloth edge is a pixel proxy, with about one pixel of uncertainty.
 if(elbowRanges.some(r=>r>(process.argv.includes('--anchored')?1:5)))throw Error('Elbows move sideways instead of staying under the shoulders');
 if(process.argv.includes('--anchored')&&elbowContourDrift.some(r=>r>1))throw Error('Elbow silhouettes change shape between poses');
 if(frames.some(f=>Math.abs(f.shoulders[0]-f.shoulders[1])>3)||[0,1].some(s=>span(frames.map(f=>f.shoulders[s]))>4))throw Error('Shoulders hike or tilt instead of staying almost level');
 const a=frames[0].arms,c=frames[2].arms;
 if(a[0].handBottom-a[1].handBottom<8||c[1].handBottom-c[0].handBottom<8)throw Error('The two forearms do not take turns advancing');
 for(const s of [0,1])for(const f of [1,3]){
  const lo=Math.min(a[s].handBottom,c[s].handBottom),hi=Math.max(a[s].handBottom,c[s].handBottom);
  if(frames[f].arms[s].handBottom<lo||frames[f].arms[s].handBottom>hi)throw Error('Passing hand is not between the forward and rear positions');
 }
 console.log('PASS: both forearms alternate through passing poses, shoulders level and elbows stable');
}
module.exports={arm};
if(require.main===module)main().catch(error=>{console.error(error.message);process.exitCode=1});
