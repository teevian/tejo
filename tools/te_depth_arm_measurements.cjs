// Follow the complete connected arm, including a hand moving inward over clothing.
// A fixed vertical lane cannot measure a foreshortened, diagonally angled forearm.
const median=a=>a.slice().sort((a,b)=>a-b)[Math.floor(a.length/2)];
function measureArm(data,side,includeMask=false){
 const x0=side?210:75,x1=side?325:185,y0=270,y1=402,w=x1-x0,h=y1-y0,mask=new Uint8Array(w*h),seen=new Uint8Array(w*h),groups=[];
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const k=((y+y0)*400+x+x0)*4;
  mask[y*w+x]=data[k+3]>127&&data[k]>110&&data[k]-data[k+1]>35&&data[k+1]-data[k+2]>18;
 }
 for(let p=0;p<mask.length;p++)if(mask[p]&&!seen[p]){
  const pixels=[p];seen[p]=1;
  for(let q=0;q<pixels.length;q++){
   const k=pixels[q],x=k%w,y=Math.floor(k/w);
   for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){
    const xx=x+dx,yy=y+dy,n=yy*w+xx;
    if(xx>=0&&xx<w&&yy>=0&&yy<h&&mask[n]&&!seen[n]){seen[n]=1;pixels.push(n);}
   }
  }
  if(pixels.some(k=>Math.floor(k/w)+y0<295))groups.push(pixels);
 }
 groups.sort((a,b)=>b.length-a.length);
 if(!groups.length)throw Error('Cannot trace an arm');
 const pixels=groups[0].map(k=>[k%w+x0,Math.floor(k/w)+y0]),elbow=[],contour=[];
 for(let y=298;y<=310;y++){
  const xs=pixels.filter(p=>p[1]===y).map(p=>p[0]).sort((a,b)=>a-b);
  if(!xs.length)throw Error('Cannot locate elbow anchor');
  elbow.push((xs[0]+xs.at(-1))/2);contour.push([xs[0],xs.at(-1)]);
 }
 const handBottom=Math.max(...pixels.map(p=>p[1])),hand=pixels.filter(p=>p[1]>=handBottom-20),elbowX=median(elbow),handX=median(hand.map(p=>p[0])),handY=median(hand.map(p=>p[1]));
 const widths=[];for(let y=329;y<=338;y++){const xs=pixels.filter(p=>p[1]===y).map(p=>p[0]);if(xs.length)widths.push(Math.max(...xs)-Math.min(...xs)+1);}
 const outputMask=includeMask?new Uint8Array(400*560):undefined;
 const radius=typeof includeMask==='number'?includeMask:2;
 if(outputMask)for(const [x,y] of pixels)for(let dy=-radius;dy<=radius;dy++)for(let dx=-radius;dx<=radius;dx++){const xx=x+dx,yy=y+dy;if(xx>=0&&xx<400&&yy>=0&&yy<560)outputMask[yy*400+xx]=1;}
 return {mask:outputMask,elbowX,handX,handY,handBottom,inwardOffset:side?elbowX-handX:handX-elbowX,projectedAngle:Math.atan2(Math.abs(handX-elbowX),handY-304)*180/Math.PI,forearmWidth:median(widths),contour};
}
module.exports={measureArm};
