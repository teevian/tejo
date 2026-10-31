// V14: original faces, two subtle head turns and consistent exposed arm widths.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const F=4,W=800,H=1120,AW=7200,AH=5600,HEIGHTS=[219,213,212,212,232];
const smooth=t=>{t=Math.max(0,Math.min(1,t));return t*t*(3-2*t);};
function bounds(d, w, h, y0 = 0, y1 = h) {
  let l=w, r=-1, t=h, b=-1;
  for(let y=y0;y<y1;y++) for(let x=0;x<w;x++) if(d[(y*w+x)*4+3]>127) {
    l=Math.min(l,x); r=Math.max(r,x); t=Math.min(t,y); b=Math.max(b,y);
  }
  if(r<0) throw Error('Empty sprite');
  return {left:l, top:t, width:r-l+1, height:b-t+1, center:(l+r)/2};
}

// Premultiplied interpolation avoids dark fringes around the rotating heads.
function sample(d,w,h,x,y,out) {
  const ix=Math.floor(x), iy=Math.floor(y), fx=x-ix, fy=y-iy;
  out.fill(0);
  for(let dy=0;dy<2;dy++) for(let dx=0;dx<2;dx++) {
    const xx=ix+dx, yy=iy+dy;
    if(xx<0||xx>=w||yy<0||yy>=h) continue;
    const i=(yy*w+xx)*4, weight=(dx?fx:1-fx)*(dy?fy:1-fy), a=d[i+3]*weight;
    out[3]+=a;
    for(let c=0;c<3;c++) out[c]+=d[i+c]*a;
  }
  if(out[3]>0) for(let c=0;c<3;c++) out[c]/=out[3];
  return out;
}

function mix(a,i,b,weight) {
  const aa=a[i+3]*(1-weight), ba=b[3]*weight, alpha=aa+ba;
  for(let c=0;c<3;c++) a[i+c]=alpha?Math.round((a[i+c]*aa+b[c]*ba)/alpha):0;
  a[i+3]=Math.round(alpha);
}

// Interpolate one shared silhouette, instead of crossfading two cutout edges.
// This joins the collar to each authored moving shoulder without ghost fabric.
function morphRow(base,target,result,y,weight) {
  if(weight<=0) return;
  const offset=y*W*4;
  if(weight>=1) {target.copy(result,offset,offset,offset+W*4);return;}
  function span(d) {
    let left=W,right=-1;
    for(let x=0;x<W;x++) if(d[offset+x*4+3]>96) {left=Math.min(left,x);right=x;}
    return [left,right];
  }
  const a=span(base),b=span(target);
  if(a[1]<0||b[1]<0) return;
  const left=a[0]*(1-weight)+b[0]*weight,right=a[1]*(1-weight)+b[1]*weight;
  result.fill(0,offset,offset+W*4);
  const pa=new Float64Array(4),pb=new Float64Array(4);
  for(let x=Math.floor(left);x<=Math.ceil(right);x++) {
    if(x<0||x>=W) continue;
    const u=(x-left)/Math.max(1,right-left),i=offset+x*4;
    sample(base,W,H,a[0]+u*(a[1]-a[0]),y,pa);
    sample(target,W,H,b[0]+u*(b[1]-b[0]),y,pb);
    const aa=pa[3]*(1-weight),ba=pb[3]*weight,alpha=aa+ba;
    for(let c=0;c<3;c++) result[i+c]=alpha?Math.round((pa[c]*aa+pb[c]*ba)/alpha):0;
    const edge=Math.max(0,Math.min(1,x-left+1,right-x+1));
    result[i+3]=Math.round(alpha*edge);
  }
}

async function cell(file,row,key) {
  return sharp(file).extract({left:key*W,top:row*H,width:W,height:H}).ensureAlpha().raw().toBuffer();
}

function shifted(data,dx) {
  const output=Buffer.alloc(data.length);
  for(let y=0;y<H;y++) {
    const left=Math.max(0,-dx),right=Math.min(W,W-dx);
    data.copy(output,(y*W+left+dx)*4,(y*W+left)*4,(y*W+right)*4);
  }
  return output;
}

const JAWS={
 te:[[[50,81,120],[60,86,116],[66,92,112],[71,98,107]],[[49,84,128],[56,91,127],[62,106,124],[66,115,121]],[[48,90,128],[53,96,127],[57,109,124],[59,114,120]],[[53,84,122],[59,91,116],[62,100,112]],[[57,81,121],[61,89,116],[63,97,108]]],
 jo:[[[48,82,117],[55,88,114],[60,94,110],[63,99,105]],[[48,87,128],[54,97,127],[59,106,124],[63,115,120]],[[48,89,128],[54,97,126],[59,110,123],[61,116,120]],[[51,84,127],[56,89,120],[60,99,112]],[[54,81,122],[58,88,117],[61,98,109]]]
};
const ARMS={
 te:[[[49,76,96,158,64,100],[121,148,97,158,133,100]],[[55,81,99,158,68,103],[123,145,91,151,132,95]],[[86,138,95,158,108,99]],[[60,81,92,151,70,97],[119,146,99,159,130,103]],[[53,81,105,167,66,110],[127,154,105,167,140,110]]],
 jo:[[[54,76,95,156,64,101],[121,145,96,156,133,101]],[[57,83,104,162,69,110],[122,141,85,143,130,92]],[[85,137,106,162,101,112]],[[63,84,86,141,72,92],[121,144,109,160,131,115]],[[62,84,106,165,73,113],[135,157,107,165,145,113]]]
};
const COLLAR={te:[75,70,67,66,71],jo:[73,72,71,68,69]};
const NECK_X={te:[100,103,106,105,100],jo:[100,105,106,105,102]};
function rangeAt(points,y){
 if(y<=points[0][0])return points[0].slice(1);
 for(let i=1;i<points.length;i++)if(y<=points[i][0]){const t=(y-points[i-1][0])/(points[i][0]-points[i-1][0]);return [1,2].map(k=>points[i-1][k]*(1-t)+points[i][k]*t);}
 return points.at(-1).slice(1);
}
function cloth(d,i,who){const r=d[i],g=d[i+1],b=d[i+2];return d[i+3]>24&&(who==='te'?Math.max(r,g,b)<150&&Math.max(r,g,b)-Math.min(r,g,b)<30:r>g*1.2&&b>g*.85);}
function over(dst,i,p){const a=p[3]/255,b=dst[i+3]/255,alpha=a+b*(1-a);if(!alpha)return;for(let c=0;c<3;c++)dst[i+c]=Math.round((p[c]*a+dst[i+c]*b*(1-a))/alpha);dst[i+3]=Math.round(alpha*255);}
function prepareBody(input,who,row,top){
 const out=Buffer.alloc(input.length),p=new Float64Array(4),jaw=JAWS[who][row].at(-1)[0],collar=COLLAR[who][row],cx=NECK_X[who][row]*F;
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){
  const yy=(y-top)/F,down=who==='te'?[4,2,1,1,1][row]*(1-smooth((yy-55)/45)):0;
  const neck=smooth((yy-(jaw-3))/4)*(1-smooth((yy-(collar-1))/8));
  const local=1-smooth((Math.abs(x-cx)/F-17)/12),factor=1-(who==='te'?.08:.14)*neck*local;
  sample(input,W,H,cx+(x-cx)/factor,y-down*F,p);
  const i=(y*W+x)*4;for(let c=0;c<4;c++)out[i+c]=Math.round(p[c]);
 }
 return out;
}
function makeBust(body,face,who,row,top){
 // Preserve the approved head, ears, jaw and continuous neck as one piece.
 const joined=Buffer.from(face),p=new Float64Array(4),end=JAWS[who][row].at(-1)[0],collar=COLLAR[who][row],cx=NECK_X[who][row]*F;
 for(let y=top+end*F;y<top+(collar+12)*F;y++)for(let x=0;x<W;x++){
  const yy=(y-top)/F,weight=smooth((yy-end)/3)*(1-smooth((yy-collar)/10));
  const local=1-smooth((Math.abs(x-cx)/F-14)/12),factor=1-(who==='jo'?.18:.06)*weight*local;
  sample(face,W,H,cx+(x-cx)/factor,y,p);const i=(y*W+x)*4;
  for(let c=0;c<4;c++)joined[i+c]=Math.round(p[c]);
 }
 // Clear old raised shirt fragments beside the neck, outside the retained skin.
 for(let y=top+54*F;y<top+collar*F;y++)for(let x=0;x<W;x++){
  const i=(y*W+x)*4;
  const fabric=who==='jo'?cloth(face,i,who):(y>=top+63*F&&cloth(face,i,who));
  if(fabric&&(body[i+3]<16||(who==='jo'&&(row===2&&x>112*F))))joined.fill(0,i,i+4);
 }
 const upper=Buffer.from(joined);
 for(let y=top+(collar+3)*F;y<H;y++)morphRow(upper,body,joined,y,smooth((y-top-(collar+3)*F)/(12*F)));
 return joined;
}
function headTurn(bust,who,row,top,angle){
 const out=Buffer.from(bust),p=new Float64Array(4),cx=NECK_X[who][row]*F,R=36*F,rad=angle*Math.PI/180,base=COLLAR[who][row];
 if(row===0){
  // Frontal yaw changes the visible facial planes, not the head's position.
  // Keep hair, ears, jaw silhouette and neck fixed. Nose projection is greater
  // than cheek/eye projection, so this is not a translated facial cutout.
  const end=JAWS[who][row].at(-1)[0],eye=who==='te'?40:34;
  for(let y=top+20*F;y<top+end*F;y++)for(let x=78*F;x<122*F;x++){
   const xx=x-cx,yy=(y-top)/F,u=xx/(22*F);
   const edge=Math.pow(Math.max(0,1-u*u),2);
   const vertical=smooth((yy-20)/9)*(1-smooth((yy-(end-7))/7));
   const nose=Math.exp(-Math.pow(xx/(6*F),2)-Math.pow((yy-eye-10)/7,2));
   const depth=(12+24*nose)*F*edge*vertical;
   sample(bust,W,H,x-depth*Math.sin(rad),y,p);
   const i=(y*W+x)*4;
   // Alpha and the outer contour remain byte-for-byte identical in both states.
   if(bust[i+3]>248&&p[3]>248)for(let c=0;c<3;c++)out[i+c]=Math.round(p[c]);
  }
  return out;
 }

 for(let y=0;y<top+(base+8)*F;y++){
  const yy=(y-top)/F,weight=1-smooth((yy-(JAWS[who][row].at(-1)[0]-1))/(base+8-JAWS[who][row].at(-1)[0]+1));
  for(let x=0;x<W;x++){
   // Pivot behind the face: the nose moves relative to the cheeks and ears.
   // Keep the full depth term; subtracting the radius cancels the visible turn.
   const xx=x-cx,a=rad*weight;
   const sx=Math.abs(xx)<R?xx*Math.cos(a)-Math.sqrt(Math.max(0,R*R-xx*xx))*Math.sin(a):xx;
   sample(bust,W,H,cx+sx,y,p);const i=(y*W+x)*4;for(let c=0;c<4;c++)out[i+c]=Math.round(p[c]);
  }
 }
 return out;
}
// Keep each authored gait silhouette intact. Normalize exposed arm widths
// along their existing centre lines, without cutting through hands or shorts.
function normalizeArms(source,neutral,who,row,top){
 const out=Buffer.from(source),guides=ARMS[who][row],p=new Float64Array(4);
 const skin=(d,x,y)=>{const i=(y*W+x)*4;return d[i+3]>96&&d[i]>105&&d[i]>d[i+1]*1.28&&d[i+1]>d[i+2]*1.08;};
 for(const config of guides){
  const [l,r,start,end]=config;
  for(let y=top+(start+6)*F;y<top+Math.min(end,139)*F;y++){
   const spans=[];
   for(const d of [neutral,source]){let left=W,right=-1;for(let x=l*F;x<r*F;x++)if(skin(d,x,y)){left=Math.min(left,x);right=x;}spans.push([left,right]);}
   const [ref,old]=spans;if(ref[1]<ref[0]||old[1]<old[0])continue;
   const width=old[1]-old[0]+1,target=ref[1]-ref[0]+1;
   // Restrict corrections to small thickness differences; do not distort poses.
   const ratio=Math.max(.86,Math.min(1.14,target/width)),centre=(old[0]+old[1])/2;
   const fade=smooth((y-top-(start+6)*F)/(5*F))*(1-smooth((y-top-132*F)/(7*F)));
   const factor=1+(ratio-1)*fade;
   for(let x=old[0]-5;x<=old[1]+5;x++){
    const distance=Math.abs(x-centre),edge=1-smooth((distance-width*.35)/(width*.25+5));
    sample(source,W,H,centre+(x-centre)/(1+(factor-1)*edge),y,p);
    const i=(y*W+x)*4;for(let c=0;c<4;c++)out[i+c]=Math.round(p[c]);
   }
  }
 }
 return out;
}
async function packCharacterNecks(){
 const layouts={},recipe={version:14,frames:9,factor:F,headStates:2,headAngles:[-2,2],sourceHeights:HEIGHTS.map(v=>v*F),characters:{}};
 for(const who of ['te','jo']){
  const atlas=Buffer.alloc(AW*AH*4),regions=[],anchors=[],poses=[];
  const original=path.join(DIR,`${who}-walk-v9.png`),bodyFile=path.join(DIR,who==='te'?'sources/te-natural-body-v9.png':'sources/jo-body-v8.png');
  for(let row=0;row<5;row++){
   const top=(260-HEIGHTS[row])*F,face=await cell(original,row,0),body=prepareBody(await cell(bodyFile,row,0),who,row,top);
   const headBox=bounds(face,W,H,top,top+35*F),shift=Math.round(400-headBox.center),bust=makeBust(body,face,who,row,top);
   const plate=bust;
   const heads=[0,-2,2].map(a=>headTurn(plate,who,row,top,a));
   for(let frame=0;frame<9;frame++){
    const key=frame===0?0:1+Math.floor((frame-1)/2),headState=frame===0?-1:Math.floor((frame-1)/4),headYaw=frame===0?0:headState===0?-2:2;
    const source=await cell(who==='jo'&&row===0?path.join(DIR,'sources/jo-south-gait-v12.png'):original,who==='jo'&&row===0?0:row,key);
    const hair=bounds(source,W,H,top,top+35*F),sourceShift=Math.round(headBox.center-hair.center);
    const gait=normalizeArms(shifted(source,sourceShift),body,who,row,top),result=Buffer.from(heads[headState+1]);
    const join=COLLAR[who][row]+3;
    for(let y=top+join*F;y<H;y++)morphRow(heads[headState+1],gait,result,y,smooth((y-top-join*F)/(16*F)));
    const final=shifted(result,shift),bb=bounds(final,W,H);
    regions.push([frame*W+bb.left,row*H+bb.top,bb.width,1040-bb.top]);anchors.push([400-bb.left,1040-bb.top]);
    for(let y=0;y<H;y++)final.copy(atlas,((row*H+y)*AW+frame*W)*4,y*W*4,(y+1)*W*4);
    poses.push({row,frame,key,headState,headYaw,armWidthNormalization:true,sourceShift:sourceShift+shift,neutralShift:shift,headEnd:JAWS[who][row].at(-1)[0],collar:COLLAR[who][row],pivot:[NECK_X[who][row]*F+shift,top+COLLAR[who][row]*F]});
   }
  }
  await sharp(atlas,{raw:{width:AW,height:AH,channels:4}}).png().toFile(path.join(DIR,`${who}-walk-v14.png`));
  layouts[who]={regions,anchors};recipe.characters[who]={source:`${who}-walk-v9.png`,body:bodyFile.slice(DIR.length+1),poses};
 }
 let art=await fs.readFile(path.join(ROOT,'scripts/open_world_art.gd'),'utf8');
 art=art.replace(/(te|jo)-walk-v\d+\.png/g,'$1-walk-v14.png').replace(/# (?:Approved|Original) faces[^\n]*/,'# Original faces, a continuous neck/collar and normalized arm widths.').replace(/# Two (?:subtle|head turns)[^\n]*/,'# Two head turns alternate with the steps; authored gait silhouettes are retained.');
 const rows=(list,type)=>Array.from({length:5},(_,r)=>'\t'+Array.from({length:9},(_,f)=>`${type}(${list[r*9+f].join(',')})`).join(',')).join(',\n');let layout='';
 for(const who of ['te','jo']){const name=who.toUpperCase();layout+=`const ${name}: Array[Rect2] = [\n${rows(layouts[who].regions,'Rect2')}]\nconst ${name}_ANCHORS: Array[Vector2] = [\n${rows(layouts[who].anchors,'Vector2')}]\n`;}
 art=art.slice(0,art.indexOf('const TE:'))+layout+'\n'+art.slice(art.indexOf('static func direction_row'));
 await fs.writeFile(path.join(ROOT,'scripts/open_world_art.gd'),art);await fs.writeFile(path.join(DIR,'neck-motion-v14.recipe.json'),JSON.stringify(recipe,null,2)+'\n');
 console.log('Built v14: original faces, subtle alternating yaw, continuous necks and normalized arm widths.');
}
module.exports={packCharacterNecks,ARMS};
if(require.main===module)packCharacterNecks().catch(e=>{console.error(e);process.exitCode=1;});
