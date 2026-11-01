// Bake complete painted walking poses; the approved v9 face is scaled uniformly.
// Requires Sharp. No old walking bodies or per-frame head substitutions are consumed.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const W=400,H=560,TOP=40,FLOOR=520,HEIGHT=480,FRAMES=9;
const JAWS={te:[[[50,81,120],[60,86,116],[66,92,112],[71,98,107]],[[49,84,128],[56,91,127],[62,106,124],[66,115,121]],[[48,90,128],[53,96,127],[57,109,124],[59,114,120]],[[53,84,122],[59,91,116],[62,100,112]],[[57,81,121],[61,89,116],[63,97,108]]],jo:[[[48,82,117],[55,88,114],[60,94,110],[63,99,105]],[[48,87,128],[54,97,127],[59,106,124],[63,115,120]],[[48,89,128],[54,97,126],[59,110,123],[61,116,120]],[[51,84,127],[56,89,120],[60,99,112]],[[54,81,122],[58,88,117],[61,98,109]]]};
const OLD_HEIGHTS=[219,213,212,212,232];
// Neck/collar centres in the normalized painted turnaround.
const NECKS=[[200,145],[199,143],[200,139],[194,139],[200,139]];
const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
function interp(points,y){if(y<=points[0][0])return points[0].slice(1);for(let k=1;k<points.length;k++)if(y<=points[k][0]){const a=points[k-1],b=points[k],t=(y-a[0])/(b[0]-a[0]);return a.slice(1).map((v,i)=>v+(b[i+1]-v)*t);}return points.at(-1).slice(1);}
function bounds(d,w=W,h=H,y0=0,y1=h){let l=w,r=-1,t=h,b=-1;for(let y=y0;y<y1;y++)for(let x=0;x<w;x++)if(d[(y*w+x)*4+3]>127){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}if(r<0)throw Error('Empty sprite');return {left:l,top:t,width:r-l+1,height:b-t+1};}
function over(d,i,p){const a=p[3]/255,b=d[i+3]/255,out=a+b*(1-a);if(!out)return;for(let c=0;c<3;c++)d[i+c]=Math.round((p[c]*a+d[i+c]*b*(1-a))/out);d[i+3]=Math.round(out*255);}
function sample(d,w,h,x,y,p){p.fill(0);const ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy;for(let dy=0;dy<=1;dy++)for(let dx=0;dx<=1;dx++){const xx=ix+dx,yy=iy+dy;if(xx<0||xx>=w||yy<0||yy>=h)continue;const i=(yy*w+xx)*4,a=d[i+3]*(dx?fx:1-fx)*(dy?fy:1-fy);p[3]+=a;for(let c=0;c<3;c++)p[c]+=d[i+c]*a;}if(p[3]>0)for(let c=0;c<3;c++)p[c]/=p[3];return p;}
function translate(d,dx,dy){const out=Buffer.alloc(d.length);for(let y=0;y<H;y++){if(y+dy<0||y+dy>=H)continue;const l=Math.max(0,-dx),r=Math.min(W,W-dx);d.copy(out,((y+dy)*W+l+dx)*4,(y*W+l)*4,(y*W+r)*4);}return out;}
function composite(dst,src){for(let i=0;i<src.length;i+=4)if(src[i+3])over(dst,i,src.subarray(i,i+4));}
function cleanPaint(d,w,h){
 const seen=new Uint8Array(w*h),queue=new Int32Array(w*h);let largest=[];
 for(let p=0;p<w*h;p++)if(!seen[p]&&d[p*4+3]>=32){let n=0,len=1;queue[0]=p;seen[p]=1;const group=[];while(n<len){const q=queue[n++];group.push(q);const x=q%w,y=Math.floor(q/w);for(const k of [x>0?q-1:-1,x<w-1?q+1:-1,y>0?q-w:-1,y<h-1?q+w:-1])if(k>=0&&!seen[k]&&d[k*4+3]>=32){seen[k]=1;queue[len++]=k;}}if(group.length>largest.length)largest=group;}
 seen.fill(0);for(const p of largest)seen[p]=1;for(let p=0;p<w*h;p++)if(!seen[p])d.fill(0,p*4,p*4+4);
}
async function normalized(who,row){
 const sw=row===4?382:384,raw=await sharp(path.join(DIR,`sources/${who}-turnaround-v15.raw.png`)).extract({left:row*384,top:0,width:sw,height:820}).ensureAlpha().raw().toBuffer();
 cleanPaint(raw,sw,820);
 const bb=bounds(raw,sw,820),width=Math.round(bb.width*HEIGHT/bb.height*(who==='jo'?.92:.97));
 const resized=await sharp(raw,{raw:{width:sw,height:820,channels:4}}).extract(bb).resize(width,HEIGHT,{fit:'fill'}).raw().toBuffer();
 const out=Buffer.alloc(W*H*4),left=Math.round(200-width/2);
 for(let y=0;y<HEIGHT;y++)resized.copy(out,((TOP+y)*W+left)*4,y*width*4,(y+1)*width*4);
 // Register crowns, not the silhouette's arm-dependent centre.
 const hb=bounds(out,W,H,TOP,TOP+48),dx=Math.round(200-(hb.left+(hb.width-1)/2));
 return {data:translate(out,dx,0),registration:dx,sourceBounds:bb};
}
async function preservedHead(who,row){
 const top=(260-OLD_HEIGHTS[row])*4,original=await sharp(path.join(DIR,`${who}-walk-v9.png`)).extract({left:0,top:row*1120+top,width:800,height:300}).ensureAlpha().raw().toBuffer(),jaw=JAWS[who][row],end=jaw.at(-1)[0]*4;
 for(let y=0;y<300;y++)for(let x=0;x<800;x++){const [l,r]=interp(jaw,y/4),i=(y*800+x)*4;if(y>end||(y>jaw[0][0]*4&&(x<l*4||x>r*4)))original.fill(0,i,i+4);}
 const bb=bounds(original,800,300),targetHeight=104,scale=targetHeight/bb.height,width=Math.round(bb.width*scale);
 const resized=await sharp(original,{raw:{width:800,height:300,channels:4}}).extract(bb).resize(width,targetHeight,{fit:'fill'}).raw().toBuffer();
 const hair=bounds(resized,width,targetHeight,0,45);
 const left=Math.round(200-hair.left-(hair.width-1)/2),out=Buffer.alloc(W*H*4);
 for(let y=0;y<targetHeight;y++)resized.copy(out,((TOP+y)*W+left)*4,y*width*4,(y+1)*width*4);
 return {data:out,sourceBounds:bb,scale,width,height:targetHeight,left,top:TOP};
}
let repairedBoard;
async function joinHead(body,head,who,row){
 if(!repairedBoard)repairedBoard=await sharp(path.join(DIR,'sources/neck-collar-v15.raw.png')).resize(1300,500,{fit:'fill'}).png().toBuffer();
 const raw=await sharp(repairedBoard).extract({left:row*260,top:who==='te'?0:250,width:252,height:238}).resize(180,170,{fit:'fill'}).ensureAlpha().raw().toBuffer();
 cleanPaint(raw,180,170);
 let bust=Buffer.alloc(body.length);for(let y=0;y<170;y++)raw.copy(bust,((32+y)*W+110)*4,y*180*4,(y+1)*180*4);
 const hair=bounds(bust,W,H,0,85),dx=Math.round(200-hair.left-(hair.width-1)/2),dy=TOP-hair.top;bust=translate(bust,dx,dy);
 // Only the newly painted neck/collar is retained; the approved complete head wins.
 for(let y=0;y<TOP+76;y++)bust.fill(0,y*W*4,(y+1)*W*4);
 const out=Buffer.from(body);
 for(let y=0;y<200;y++){
  const weight=clamp((y-176)/24,0,1);
  if(weight===0){bust.copy(out,y*W*4,y*W*4,(y+1)*W*4);continue;}
  const a=bounds(bust,W,H,y,y+1),b=bounds(body,W,H,y,y+1),left=Math.round(a.left+(b.left-a.left)*weight),right=Math.round(a.left+a.width+(b.left+b.width-a.left-a.width)*weight);
  out.fill(0,y*W*4,(y+1)*W*4);const pa=new Float64Array(4),pb=new Float64Array(4);
  for(let x=left;x<right;x++){const u=(x-left)/Math.max(1,right-left-1);sample(bust,W,H,a.left+u*(a.width-1),y,pa);sample(body,W,H,b.left+u*(b.width-1),y,pb);const i=(y*W+x)*4,aa=pa[3]*(1-weight),ab=pb[3]*weight,alpha=aa+ab;for(let c=0;c<3;c++)out[i+c]=alpha?Math.round((pa[c]*aa+pb[c]*ab)/alpha):0;out[i+3]=Math.round(alpha);}
 }
 composite(out,head.data);return out;
}
const sheetRows=new Map();
async function rowCuts(file){
 if(sheetRows.has(file))return sheetRows.get(file);
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true}),groups=[];
 let start=-1;for(let y=0;y<info.height;y++){let n=0;for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>180)n++;if(n>20&&start<0)start=y;if((n<=20||y===info.height-1)&&start>=0){const end=y;if(groups.length&&start-groups.at(-1)[1]<12)groups.at(-1)[1]=end;else groups.push([start,end]);start=-1;}}
 if(groups.length!==5)throw Error(`Expected five complete pose rows in ${file}: ${JSON.stringify(groups)}`);
 const cuts=[0,...groups.slice(1).map((v,i)=>Math.round((groups[i][1]+v[0])/2)),info.height];sheetRows.set(file,cuts);return cuts;
}
// Hand-registered collar seams in the final painted sheets (four gait keys per view).
const SOURCE_COLLARS={te:[[181,184,184,181],[175,175,176,174],[188,177,182,175],[174,174,174,174],[172,171,171,172]],jo:[[189,198,192,191],[182,187,184,186],[182,182,185,185],[182,188,185,179],[176,178,175,182]]};
const TARGET_COLLARS={te:[158,158,154,149,149],jo:[159,159,154,154,153]};
// Whole painted poses avoid exposed seams around moving arms and legs.
async function paintedPose(who,row,key,neutral){
 const file=path.join(DIR,`sources/${who}-painted-walk-v15.raw.png`);
 const meta=await sharp(file).metadata();
 const cuts=await rowCuts(file);
 const x0=Math.max(0,Math.round(key*meta.width/5)-16),x1=Math.min(meta.width,Math.round((key+1)*meta.width/5)+16),y0=cuts[row],y1=cuts[row+1];
 const sw=x1-x0,sh=y1-y0,raw=await sharp(file).extract({left:x0,top:y0,width:sw,height:sh}).ensureAlpha().raw().toBuffer();
 cleanPaint(raw,sw,sh);
 const bb=bounds(raw,sw,sh),height=HEIGHT,width=Math.round(bb.width*height/bb.height);
 let resized=await sharp(raw,{raw:{width:sw,height:sh,channels:4}}).extract(bb).resize(width,height,{fit:'fill'}).raw().toBuffer();
 let out=Buffer.alloc(W*H*4);for(let y=0;y<height;y++)resized.copy(out,((TOP+y)*W+Math.round(200-width/2))*4,y*width*4,(y+1)*width*4);
 let hair=bounds(out,W,H,40,85),shift=Math.round(200-hair.left-(hair.width-1)/2);out=translate(out,shift,0);
 // Fit the new body's collar to the preserved bust, lengthening torso and legs.
 const sourceCollar=SOURCE_COLLARS[who][row][key-1],targetCollar=TARGET_COLLARS[who][row],vertical=Buffer.alloc(out.length),vp=new Float64Array(4);
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){
  const sy=sourceCollar+(y-targetCollar)*(FLOOR-sourceCollar)/(FLOOR-targetCollar);
  sample(out,W,H,x,sy,vp);const i=(y*W+x)*4;for(let c=0;c<4;c++)vertical[i+c]=Math.round(vp[c]);
 }
 out=vertical;
 // The shirt's shoulder span controls width, independently of the swinging arms.
 const reference=bounds(neutral,W,H,174,178),body=bounds(out,W,H,174,178),factor=reference.width/body.width;
 const p=new Float64Array(4),slim=Buffer.alloc(out.length);
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){sample(out,W,H,200+(x-200)/factor,y,p);const i=(y*W+x)*4;for(let c=0;c<4;c++)slim[i+c]=Math.round(p[c]);}
 // Join in the continuous painted shirt, above the sleeves and moving limbs.
 const joined=Buffer.from(slim);
 for(let y=0;y<210;y++){
  const weight=clamp((y-175)/35,0,1);
  if(weight===0){neutral.copy(joined,y*W*4,y*W*4,(y+1)*W*4);continue;}
  const a=bounds(neutral,W,H,y,y+1),b=bounds(slim,W,H,y,y+1),left=Math.round(a.left+(b.left-a.left)*weight),right=Math.round(a.left+a.width+(b.left+b.width-a.left-a.width)*weight);
  joined.fill(0,y*W*4,(y+1)*W*4);
  const pa=new Float64Array(4),pb=new Float64Array(4);
  for(let x=left;x<right;x++){const u=(x-left)/Math.max(1,right-left-1);sample(neutral,W,H,a.left+u*(a.width-1),y,pa);sample(slim,W,H,b.left+u*(b.width-1),y,pb);const i=(y*W+x)*4,aa=pa[3]*(1-weight),ab=pb[3]*weight,alpha=aa+ab;for(let c=0;c<3;c++)joined[i+c]=alpha?Math.round((pa[c]*aa+pb[c]*ab)/alpha):0;joined[i+3]=Math.round(alpha);}
 }
 return {data:joined,key,widthFactor:factor,sourceCollar,targetCollar};
}
async function main(){
 const recipe={version:15,cell:[W,H],frames:FRAMES,sourceHeight:HEIGHT,ground:[200,FLOOR],headSource:'*-walk-v9.png idle only',walkBodySource:'new complete painted walk v15 only',paintedKeys:4,headHeight:104,characters:{}};
 for(const who of ['te','jo']){
  const atlas=Buffer.alloc(W*9*H*5*4),poses=[],neutrals=[];
  for(let row=0;row<5;row++){
   const normalizedBody=await normalized(who,row),head=await preservedHead(who,row),neutral=await joinHead(normalizedBody.data,head,who,row);
   await sharp(neutral,{raw:{width:W,height:H,channels:4}}).png().toFile(path.join(DIR,`sources/${who}-neutral-v15-${row}.png`));
   await sharp(head.data,{raw:{width:W,height:H,channels:4}}).png().toFile(path.join(DIR,`sources/${who}-head-v15-${row}.png`));
   const keys=[null];for(let key=1;key<=4;key++)keys.push(await paintedPose(who,row,key,neutral));
   for(let frame=0;frame<9;frame++){
    const key=frame===0?0:1+Math.floor((frame-1)/2),pose=frame===0?{data:neutral,bob:0}:keys[key],bb=bounds(pose.data);
    for(let y=0;y<H;y++)pose.data.copy(atlas,((row*H+y)*W*9+frame*W)*4,y*W*4,(y+1)*W*4);
    poses.push({row,frame,key,bob:0,sourceCollar:pose.sourceCollar,targetCollar:pose.targetCollar,region:[frame*W+bb.left,row*H+bb.top,bb.width,FLOOR-bb.top],anchor:[200-bb.left,FLOOR-bb.top],bounds:bb});
   }
   neutrals.push({row,sourceBounds:normalizedBody.sourceBounds,registration:normalizedBody.registration,head:{...head,data:undefined},neck:NECKS[row]});
  }
  await sharp(atlas,{raw:{width:W*9,height:H*5,channels:4}}).png().toFile(path.join(DIR,`${who}-walk-v15.png`));recipe.characters[who]={neutrals,poses};
 }
 const rows=(values,type)=>Array.from({length:5},(_,r)=>'\t'+Array.from({length:9},(_,f)=>`${type}(${values[r*9+f].join(',')})`).join(',')).join(',\n');
 let art=await fs.readFile(path.join(ROOT,'scripts/open_world_art.gd'),'utf8');
 art=art.replace(/(te|jo)-walk-v\d+\.png/g,'$1-walk-v15.png').replace(/# Original faces[^\n]*/,'# Preserved faces on new slender painted bodies with connected necks and collars.').replace(/# (?:Two head turns|Eight unique poses)[^\n]*/,'# Four complete painted steps, each held for two of the eight gait phases.').replace(/# Fixed source heights[^\n]*/,'# A shared crown and ground registration prevents jumps when turning.').replace(/const SOURCE_HEIGHTS:[^\n]*/,'const SOURCE_HEIGHTS: Array[float] = [480.0,480.0,480.0,480.0,480.0]');
 let layout='';for(const who of ['te','jo']){const name=who.toUpperCase(),poses=recipe.characters[who].poses;layout+=`const ${name}: Array[Rect2] = [\n${rows(poses.map(p=>p.region),'Rect2')}]\nconst ${name}_ANCHORS: Array[Vector2] = [\n${rows(poses.map(p=>p.anchor),'Vector2')}]\n`;}
 art=art.slice(0,art.indexOf('const TE:'))+layout+'\n'+art.slice(art.indexOf('static func direction_row'));
 await fs.writeFile(path.join(ROOT,'scripts/open_world_art.gd'),art);await fs.writeFile(path.join(DIR,'character-walk-v15.recipe.json'),JSON.stringify(recipe,null,2)+'\n');
 console.log('Baked 90 complete v15 sprites: 5 directions, idle + 8 walking phases, preserved original faces.');
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1;});
module.exports={W,H,JAWS};
