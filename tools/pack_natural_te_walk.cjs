// Repaired whole-body walk poses + the approved face and dark hair.
// Everything is baked into complete poses. Requires Node and sharp.
const sharp=require('sharp');
const {largest}=require('./prepare_te_natural_sources.cjs');
const fs=require('node:fs/promises');
const path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const FACTOR=4,W=200*FACTOR,CELL_H=280*FACTOR;
const HEIGHTS=[219,213,212,212,232];
const HEAD_HEIGHTS=[73,70,66,64,66],OLD_HEIGHTS=[64,65,62,60,70];
const BLENDS=[68,64,61,60,64],REPAIR_ENDS=[84,80,76,76,78];
const OLD_BLEND=[59,60,54,55,64];
const OLD_CRANIA=[{center:99.5,width:48},{center:102.5,width:56},{center:106.5,width:58},{center:107.5,width:56},{center:99.5,width:50}];
const LIMITS=[
 [[52,85,112],[57,85,112],[61,86,111],[64,88,109]],
 [[49,86,122],[53,85,121],[56,86,120],[59,88,117],[62,92,110],[65,96,108]],
 [[48,92,132],[51,92,131],[53,93,126],[55,94,119],[58,98,117],[61,108,115]],
 [[49,90,123],[53,91,120],[56,93,117],[59,104,115]],
 [[59,85,114],[63,86,113],[66,90,110],[69,98,105]]
];
function skin(data,i){return data[i+3]>127&&data[i]>105&&data[i]>data[i+1]*1.12&&data[i+1]>data[i+2]*1.07;}
function bounds(data,width,height){
 let left=width,right=0,top=height;
 for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(data[(y*width+x)*4+3]>127){left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);}
 return{left,right,top,center:(left+right)/2,width:right-left+1};
}
function lerp(points,y,c){
 if(y<=points[0][0])return points[0][c];
 for(let j=1;j<points.length;j++)if(y<=points[j][0]){const t=(y-points[j-1][0])/(points[j][0]-points[j-1][0]);return points[j-1][c]*(1-t)+points[j][c]*t;}
 return points.at(-1)[c];
}
function clothMask(data,width,height,row){
 const mask=new Uint8Array(width*height),seen=new Uint8Array(mask.length);
 const minY=[55,49,49,50,57][row]*FACTOR;
 for(let y=minY;y<height;y++)for(let x=0;x<width;x++){
  const p=y*width+x,i=p*4,r=data[i],g=data[i+1],b=data[i+2];
  if(data[i+3]>32&&Math.max(r,g,b)-Math.min(r,g,b)<30&&b>=g-4)mask[p]=1;
 }
 let largest=[];
 for(let p=0;p<mask.length;p++){
  if(!mask[p]||seen[p])continue;const stack=[p],part=[];seen[p]=1;
  while(stack.length){const q=stack.pop(),x=q%width,y=Math.floor(q/width);part.push(q);
   for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const nx=x+dx,ny=y+dy,n=ny*width+nx;
    if(nx>=0&&nx<width&&ny>=0&&ny<height&&mask[n]&&!seen[n]){seen[n]=1;stack.push(n);}
   }
  }
  if(part.length>largest.length)largest=part;
 }
 mask.fill(0);for(const p of largest)mask[p]=1;return mask;
}
async function selectedHead(row,target){
 const file=path.join(DIR,'sources/te-heads-dark-v9.png'),meta=await sharp(file).metadata();
 const left=Math.round(row*meta.width/5),right=Math.round((row+1)*meta.width/5);
 const raw=await sharp(file).extract({left,top:0,width:right-left,height:meta.height}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 for(let i=0;i<raw.data.length;i+=4){const r=raw.data[i],g=raw.data[i+1],b=raw.data[i+2];
  if((r>180&&g<60&&b<80)||(r>170&&g>130&&b<65))raw.data.fill(0,i,i+4);
 }
 // Remove matte-coloured contour flecks and detached specks without touching
 // warm skin shading in the interior of the selected face.
 for(let y=2;y<raw.info.height-2;y++)for(let x=2;x<raw.info.width-2;x++){
  const i=(y*raw.info.width+x)*4,r=raw.data[i],g=raw.data[i+1],b=raw.data[i+2];
  if(!((r>150&&g>110&&b<85)||(r>170&&g<70&&b<90)))continue;
  let edge=false;
  for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++)if(raw.data[((y+dy)*raw.info.width+x+dx)*4+3]<10)edge=true;
  if(edge)raw.data.fill(0,i,i+4);
 }
 const connected=largest(Uint8Array.from({length:raw.info.width*raw.info.height},(_,p)=>raw.data[p*4+3]>10?1:0),raw.info.width,raw.info.height);
 for(let p=0;p<connected.length;p++)if(!connected[p])raw.data.fill(0,p*4,p*4+4);
 const full=bounds(raw.data,raw.info.width,raw.info.height);
 const bottom=[562,561,559,548,549][row];
 const source=Buffer.from(raw.data.subarray(full.top*raw.info.width*4,(bottom+1)*raw.info.width*4));
 const sourceH=bottom-full.top+1,sourceHair=bounds(source,raw.info.width,Math.round(sourceH*.6));
 const oldHair=OLD_CRANIA[row],xScale=target.width/oldHair.width;
 const rw=Math.round(raw.info.width*target.width*FACTOR/sourceHair.width),rh=HEAD_HEIGHTS[row]*FACTOR;
 // Match the native brush/detail scale of the incoming 200px-wide body.
 // Keeping photographic-scale head detail in a 4x atlas made it look pasted on.
 const painted=await sharp(source,{raw:{width:raw.info.width,height:sourceH,channels:4}})
  .resize(Math.round(rw/FACTOR),HEAD_HEIGHTS[row],{fit:'fill',kernel:'lanczos3'}).png().toBuffer();
 const projected=await sharp(painted).resize(rw,rh,{fit:'fill',kernel:'linear'}).raw().toBuffer();
 const ox=Math.round(target.center*FACTOR-sourceHair.center*rw/raw.info.width),oy=target.top*FACTOR;
 const h=REPAIR_ENDS[row]*FACTOR,head=Buffer.alloc(W*h*4),bust=Buffer.alloc(W*h*4),foreground=new Uint8Array(W*h);
 for(let y=0;y<rh;y++)for(let x=0;x<rw;x++){
  const xx=x+ox,yy=y+oy;if(xx<0||xx>=W||yy>=h)continue;
  const from=(y*rw+x)*4,to=(yy*W+xx)*4;
  projected.copy(bust,to,from,from+4);
  const oldY=y/FACTOR*OLD_HEIGHTS[row]/HEAD_HEIGHTS[row];
  const oldX=(xx/FACTOR-target.center)/xScale+oldHair.center;
  const limit=LIMITS[row];
  if(oldY>=limit[0][0]&&(oldY>limit.at(-1)[0]||oldX<lerp(limit,oldY,1)||oldX>lerp(limit,oldY,2)))continue;
  if(oldY>=OLD_BLEND[row]&&!skin(projected,from))continue;
  projected.copy(head,to,from,from+4);
  if(oldY<OLD_BLEND[row]&&projected[from+3]>0)foreground[yy*W+xx]=1;
 }
 return{head,bust,foreground,blend:(target.top+BLENDS[row])*FACTOR};
}
function over(paint,i,head,a){
 const ba=paint[i+3]/255,alpha=a+ba*(1-a);
 if(alpha===0){paint.fill(0,i,i+4);return;}
 for(let c=0;c<3;c++)paint[i+c]=Math.round((head[i+c]*a+paint[i+c]*ba*(1-a))/alpha);
 paint[i+3]=Math.round(alpha*255);
}
function blit(atlas,data,key,row,top,height){
 for(let y=0;y<height;y++)data.copy(atlas,((row*CELL_H+top+y)*4000+key*W)*4,y*W*4,(y+1)*W*4);
}
async function main(){
 const source=path.join(DIR,'sources/te-natural-body-v9.png'),meta=await sharp(source).metadata();
 if(meta.width!==4000||meta.height!==5600)throw Error('Register the corrected whole poses with tools/prepare_te_natural_sources.cjs first');
 const atlas=Buffer.alloc(4000*5600*4),regions=[],anchors=[],report=[];
 for(let row=0;row<5;row++){
  const top=260-HEIGHTS[row],repair=REPAIR_ENDS[row]*FACTOR;
  const neutral=await sharp(path.join(DIR,'sources/te-pulled-10593d9.png')).extract({left:0,top:row*CELL_H+top*FACTOR,width:W,height:HEIGHTS[row]*FACTOR}).ensureAlpha().raw().toBuffer();
  const native=await sharp(neutral,{raw:{width:W,height:HEIGHTS[row]*FACTOR,channels:4}}).resize(200,HEIGHTS[row]).raw().toBuffer();
  const target=bounds(native,200,35),replacement=await selectedHead(row,target);
  for(let key=0;key<5;key++){
   const body=await sharp(source).extract({left:key*W,top:row*CELL_H+top*FACTOR,width:W,height:HEIGHTS[row]*FACTOR}).ensureAlpha().raw().toBuffer();
   const paint=Buffer.from(body),cloth=clothMask(body,W,repair,row);
   for(let y=0;y<repair;y++)for(let x=0;x<W;x++){
    const p=y*W+x,i=p*4;if(cloth[p]&&!replacement.foreground[p])continue;
    const originalNeck=y>=[65,62,59,59,63][row]*FACTOR&&skin(body,i);
    if(!cloth[p]&&y<replacement.blend&&!originalNeck)paint.fill(0,i,i+4);
    const fade=y<replacement.blend?1:Math.max(0,1-(y-replacement.blend)/(4*FACTOR));
    over(paint,i,replacement.head,replacement.head[i+3]/255*fade);
   }
   // The selected portrait includes a natural charcoal collar. Its garment
   // contour identifies tiny gaps behind the new neck. Fill those gaps with
   // incoming fabric (not with old head pixels), retaining the body outline.
   for(let y=48*FACTOR;y<repair;y++)for(let x=70*FACTOR;x<135*FACTOR;x++){
    const p=y*W+x,i=p*4,r=replacement.bust[i],g=replacement.bust[i+1],b=replacement.bust[i+2];
    const fabric=Math.max(r,g,b)<145&&Math.max(r,g,b)-Math.min(r,g,b)<25&&b>=g-6;
    if(body[i+3]>127&&paint[i+3]<33&&replacement.bust[i+3]>127&&fabric){
     for(let dy=1;dy<30*FACTOR&&y+dy<repair;dy++){
      const q=(y+dy)*W+x;if(cloth[q]){body.copy(paint,i,q*4,q*4+4);break;}
     }
    }
   }
   // Close sub-pixel gaps where the new jaw/nape meets the incoming collar.
   // Only interpolate bounded gaps within the join, without changing the
   // outside body contour or any incoming limb pixels.
   for(let y=[60,55,54,55,62][row]*FACTOR;y<[79,75,71,72,73][row]*FACTOR;y++)for(let x=55*FACTOR;x<145*FACTOR;x++){
    const i=(y*W+x)*4;if(paint[i+3]>32||paint[i-1]<128)continue;
    let last=x;while(last<145*FACTOR&&paint[(y*W+last)*4+3]<33)last++;
    if(last-x<=3*FACTOR&&last<145*FACTOR){const a=(y*W+x-1)*4,b=(y*W+last)*4;
     for(let xx=x;xx<last;xx++){const t=(xx-x+1)/(last-x+1),j=(y*W+xx)*4;
      for(let c=0;c<3;c++)paint[j+c]=Math.round(paint[a+c]*(1-t)+paint[b+c]*t);
      paint[j+3]=255;
     }
    }
    x=last;
   }
   if(!paint.subarray(repair*W*4).equals(body.subarray(repair*W*4)))throw Error('Corrected body changed below the neck in view '+row+' key '+key);
   const final=paint;
   let minx=W,maxx=0;
   for(let y=0;y<HEIGHTS[row]*FACTOR;y++)for(let x=0;x<W;x++)if(final[(y*W+x)*4+3]>10){minx=Math.min(minx,x);maxx=Math.max(maxx,x);}
   regions.push([key*W+minx,row*CELL_H+top*FACTOR,maxx-minx+1,HEIGHTS[row]*FACTOR]);
   anchors.push([100*FACTOR-minx,HEIGHTS[row]*FACTOR]);
   blit(atlas,final,key,row,top*FACTOR,HEIGHTS[row]*FACTOR);
  }
  report.push({view:row,cranialWidth:target.width,headHeight:HEAD_HEIGHTS[row],unchangedBodyBelow:REPAIR_ENDS[row]});
 }
 await sharp(atlas,{raw:{width:4000,height:5600,channels:4}}).png().toFile(path.join(DIR,'te-walk-v9.png'));
 const cycle=[0,1,1,2,2,3,3,4,4];
 const rows=(list,ctor)=>Array.from({length:5},(_,r)=>'\t'+cycle.map(k=>ctor+'('+list[r*5+k].join(',')+')').join(',')).join(',\n');
 let art=await fs.readFile(path.join(ROOT,'tools/pulled_walk_reference.gd'),'utf8');
 art=art.replace(/# Five authored[\s\S]*?const ATLASES:/,'# Repaired whole-body poses and the approved dark-haired head are baked together.\n# Runtime draws one complete sprite, with no separate head or limb pieces.\nconst ATLASES:');
 art=art.replace('open_world/te-walk-v4.png','open_world/te-walk-v9.png');
 art=art.replace(/const TeFrontGait[\s\S]*?const HEIGHTS:/,'const HEIGHTS:');
 const begin=art.indexOf('const TE:'),finish=art.indexOf('const JO:',begin);
 art=art.slice(0,begin)+'const TE: Array[Rect2] = [\n'+rows(regions,'Rect2')+']\nconst TE_ANCHORS: Array[Vector2] = [\n'+rows(anchors,'Vector2')+']\n'+art.slice(finish);
 const joSection=art.slice(art.indexOf('const JO:'),art.indexOf('static func direction_row'));
 const joAnchors=[...joSection.matchAll(/Rect2\(([^)]+)\)/g)].map(match=>{const r=match[1].split(',').map(Number);return 'Vector2('+r[2]/2+','+r[3]+')';});
 art=art.replace('static func direction_row','const JO_ANCHORS: Array[Vector2] = ['+joAnchors.join(',')+']\n\nstatic func direction_row');
 const draw=art.indexOf('static func draw_pose(');
 art=art.slice(0,draw)+`static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, moving: bool, distance: float, origin := Vector2.ZERO) -> void:
\tvar row := direction_row(facing)
\tvar frame := frame_for(moving,distance)
\tvar region := pose_region(kind,row,frame)
\tvar scale_value: float = HEIGHTS[kind]/(876.0 if kind==0 else 219.0)
\tvar anchor := TE_ANCHORS[row*9+frame] if kind==0 else Vector2(region.size.x*.5,region.size.y)
\tcanvas.draw_set_transform(origin,0,Vector2(-1 if facing.x<0 else 1,1))
\tcanvas.draw_texture_rect_region(ATLASES[kind],Rect2(-anchor*scale_value,region.size*scale_value),region)
\tcanvas.draw_set_transform(Vector2.ZERO)
`;
 await fs.writeFile(path.join(ROOT,'scripts/open_world_art.gd'),art);
 await fs.writeFile(path.join(DIR,'te-walk-v9.recipe.json'),JSON.stringify({incomingCommit:'10593d9',body:'sources/te-natural-body-v9.png',bodyWidth:0.95,wholePoseRepair:true,faceIdentity:'sources/te-heads-v7.png',paintedFace:'sources/te-heads-dark-v9.png',factor:FACTOR,repairEnds:REPAIR_ENDS,views:report},null,2)+'\n');
 console.log('Baked 25 complete corrected Te poses: continuous moving sleeves, grounded diagonal steps, fixed approved face and dark hair.');
 // Preserve Jo's newer identity when rebuilding through any older entry point.
 try{await fs.access(path.join(DIR,'sources/jo-busts-v9.raw.png'));}
 catch(error){if(error.code==='ENOENT')return;throw error;}
 await require('./pack_jo_walk.cjs').packJo();
}
main().catch(error=>{console.error(error);process.exitCode=1;});
