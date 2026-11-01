// Pack eight newly painted lateral keys. Preserve only the approved face and neck;
// shoulders, sleeves and the whole body belong to each painted pose.
const sharp=require('sharp'),fs=require('node:fs/promises'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..'),DIR=path.join(ROOT,'assets/characters/open_world');
const W=400,H=560,FLOOR=520,TOP=40;
function bounds(d,w,h,y0=0,y1=h){let l=w,r=-1,t=h,b=-1;for(let y=y0;y<y1;y++)for(let x=0;x<w;x++)if(d[(y*w+x)*4+3]>127){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}if(r<0)throw Error('Empty painted region');return{left:l,top:t,width:r-l+1,height:b-t+1};}
function clean(d,w,h){const seen=new Uint8Array(w*h),q=new Int32Array(w*h);let largest=[];for(let p=0;p<w*h;p++)if(!seen[p]&&d[p*4+3]>70){let n=0,len=1;q[0]=p;seen[p]=1;const group=[];while(n<len){const a=q[n++],x=a%w,y=Math.floor(a/w);group.push(a);for(const k of [x>0?a-1:-1,x<w-1?a+1:-1,y>0?a-w:-1,y<h-1?a+w:-1])if(k>=0&&!seen[k]&&d[k*4+3]>70){seen[k]=1;q[len++]=k;}}if(group.length>largest.length)largest=group;}seen.fill(0);for(const p of largest)seen[p]=1;for(let p=0;p<w*h;p++)if(!seen[p])d.fill(0,p*4,p*4+4);}
function sample(d,x,y){const p=[0,0,0,0],ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy;for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++){const xx=ix+dx,yy=iy+dy;if(xx<0||xx>=W||yy<0||yy>=H)continue;const i=(yy*W+xx)*4,a=d[i+3]*(dx?fx:1-fx)*(dy?fy:1-fy);p[3]+=a;for(let c=0;c<3;c++)p[c]+=d[i+c]*a;}if(p[3])for(let c=0;c<3;c++)p[c]/=p[3];return p;}
async function main(){
 const recipe={version:16,scope:'lateral only',cell:[W,H],ground:[200,FLOOR],head:'exact v15 neutral face and neck through y145',gait:'8 complete painted poses, rigid whole-sprite rendering',characters:{}};
 for(const who of ['te','jo']){
  const file=path.join(DIR,`sources/${who}-side-walk-v16.raw.png`),m=await sharp(file).metadata();
  const neutral=await sharp(path.join(DIR,`sources/${who}-neutral-v15-2.png`)).ensureAlpha().raw().toBuffer(),atlas=Buffer.alloc(W*9*H*4);let poses=[];
  for(let frame=0;frame<9;frame++){
   let out=Buffer.from(neutral);
   if(frame){const f=frame-1,x=Math.round((f%4)*m.width/4),y=Math.round(Math.floor(f/4)*m.height/2),sw=Math.round((f%4+1)*m.width/4)-x,sh=Math.round((Math.floor(f/4)+1)*m.height/2)-y;
    const raw=await sharp(file).extract({left:x,top:y,width:sw,height:sh}).ensureAlpha().raw().toBuffer();clean(raw,sw,sh);const bb=bounds(raw,sw,sh),nw=Math.round(bb.width*480/bb.height);
    const resized=await sharp(raw,{raw:{width:sw,height:sh,channels:4}}).extract(bb).resize(nw,480).raw().toBuffer();let norm=Buffer.alloc(W*H*4);const left=Math.round(200-nw/2);for(let yy=0;yy<480;yy++)resized.copy(norm,((TOP+yy)*W+left)*4,yy*nw*4,(yy+1)*nw*4);
    const hair=bounds(norm,W,H,40,85),shift=Math.round(200-hair.left-(hair.width-1)/2),registered=Buffer.alloc(norm.length);for(let yy=0;yy<H;yy++)for(let xx=0;xx<W;xx++){const sx=xx-shift;if(sx>=0&&sx<W)norm.copy(registered,(yy*W+xx)*4,(yy*W+sx)*4,(yy*W+sx+1)*4);}norm=registered;
    // Collar location is registered per painting; nothing below the neck is frozen.
    const collar=(who==='te'?[151,151,151,151,151,151,151,151]:[153,153,153,153,153,153,153,153])[f];
    const body=Buffer.alloc(norm.length);for(let yy=116;yy<H;yy++)for(let xx=0;xx<W;xx++){const sy=collar+(yy-154)*(FLOOR-collar)/(FLOOR-154),p=sample(norm,xx,sy),i=(yy*W+xx)*4;for(let c=0;c<4;c++)body[i+c]=Math.round(p[c]);}
    out=Buffer.from(body);
    for(let yy=0;yy<159;yy++){if(yy<145){neutral.copy(out,yy*W*4,yy*W*4,(yy+1)*W*4);continue;}const weight=(yy-145)/14,a=bounds(neutral,W,H,yy,yy+1),b=bounds(body,W,H,yy,yy+1),l=Math.round(a.left+(b.left-a.left)*weight),r=Math.round(a.left+a.width+(b.left+b.width-a.left-a.width)*weight);out.fill(0,yy*W*4,(yy+1)*W*4);for(let xx=l;xx<r;xx++){const u=(xx-l)/Math.max(1,r-l-1),pa=sample(neutral,a.left+u*(a.width-1),yy),pb=sample(body,b.left+u*(b.width-1),yy),aa=pa[3]*(1-weight),ab=pb[3]*weight,alpha=aa+ab,i=(yy*W+xx)*4;for(let c=0;c<3;c++)out[i+c]=alpha?Math.round((pa[c]*aa+pb[c]*ab)/alpha):0;out[i+3]=Math.round(alpha);}}
   }
   for(let yy=0;yy<H;yy++)out.copy(atlas,(yy*W*9+frame*W)*4,yy*W*4,(yy+1)*W*4);const bb=bounds(out,W,H);poses.push({frame,bounds:bb});
  }
  await sharp(atlas,{raw:{width:W*9,height:H,channels:4}}).png().toFile(path.join(DIR,`${who}-side-walk-v16.png`));recipe.characters[who]=poses;
 }
 await fs.writeFile(path.join(DIR,'side-walk-v16.recipe.json'),JSON.stringify(recipe,null,2)+'\n');console.log('Packed lateral atlases: unchanged idle and eight painted walking poses per character.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
