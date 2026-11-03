// Register generated rest cutouts into the same 480x560 cells as the existing poses.
// No directional atlas is read or written. The chroma matte removes stray saturated
// red/yellow background pixels from the generator's alpha output before registration.
const sharp=require('sharp');
const fs=require('node:fs/promises');
async function pack(source,kind){
 const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const bands=kind==='te'?[0,310,575,865,info.height]:[0,280,560,850,info.height];
 const cells=[];
 for(let row=0;row<4;row++)for(let col=0;col<5;col++){
  const x0=Math.round(col*info.width/5),x1=Math.round((col+1)*info.width/5),y0=bands[row],y1=bands[row+1],w=x1-x0,h=y1-y0;
  const raw=Buffer.alloc(w*h*4),seen=new Uint8Array(w*h);let components=[];
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
   const i=((y+y0)*info.width+x+x0)*4,j=(y*w+x)*4;
   data.copy(raw,j,i,i+4);
   const [r,g,b]=raw.subarray(j,j+3);
   if((r>190&&g<90&&b<90)||(r>205&&g>170&&b<70))raw[j+3]=0;
  }
  for(let j=0;j<w*h;j++){
   if(seen[j]||raw[j*4+3]<25)continue;
   const stack=[j],part=[];seen[j]=1;
   while(stack.length){const i=stack.pop();part.push(i);const x=i%w,y=Math.floor(i/w);for(const k of [x>0?i-1:-1,x<w-1?i+1:-1,y>0?i-w:-1,y<h-1?i+w:-1])if(k>=0&&!seen[k]&&raw[k*4+3]>=25){seen[k]=1;stack.push(k);}}
   components.push(part);
  }
  components.sort((a,b)=>b.length-a.length);const mask=new Uint8Array(w*h);
  for(const i of components[0])for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const x=i%w+dx,y=Math.floor(i/w)+dy;if(x>=0&&x<w&&y>=0&&y<h)mask[y*w+x]=1;}
  let left=w,top=h,right=0,bottom=0;
  for(let i=0;i<w*h;i++){if(!mask[i])raw[i*4+3]=0;if(raw[i*4+3]>25){left=Math.min(left,i%w);right=Math.max(right,i%w);top=Math.min(top,Math.floor(i/w));bottom=Math.max(bottom,Math.floor(i/w));}}
  cells.push({row,col,raw,w,h,left,top,width:right-left+1,height:bottom-top+1});
 }
 // One magnification per character, taken from the seated key. Stretch height is
 // deliberately allowed to grow; it is never independently squeezed to fit.
 const reference=cells[5],factor=306/reference.height, composites=[];
 const order=kind==='te'?[4,3,2,1,0]:[0,1,2,3,4];
 for(let row=0;row<4;row++)for(let col=0;col<5;col++){
  const index=row===0?order[col]:col;const cell=cells[row*5+index];
  const width=Math.round(cell.width*factor),height=Math.round(cell.height*factor);
  const input=await sharp(cell.raw,{raw:{width:cell.w,height:cell.h,channels:4}}).extract({left:cell.left,top:cell.top,width:cell.width,height:cell.height}).resize(width,height).png().toBuffer();
  composites.push({input,left:col*480+240-Math.round(width/2),top:row*560+520-height});
 }
 const target=`assets/characters/interactions/${kind}-rest-sequence.png`;
 await sharp({create:{width:2400,height:2240,channels:4,background:'#00000000'}}).composite(composites).png().toFile(target);
 console.log(target,`registered ${cells.length} keys, factor ${factor.toFixed(3)}`);
}
if(process.argv.length!==4)throw Error('Usage: pack_rest_sequence.cjs TE_GENERATED_PNG JO_GENERATED_PNG');
(async()=>{await pack(process.argv[2],'te');await pack(process.argv[3],'jo')})().catch(e=>{console.error(e);process.exitCode=1});
