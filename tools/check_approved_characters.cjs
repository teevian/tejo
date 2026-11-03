// Keep the two user-approved directional atlases and their geometry intact.
const fs=require('node:fs/promises'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const manifest=JSON.parse(await fs.readFile(path.join(root,'assets/characters/approved-directions.json'))),allowed=new Set();
 for(const item of manifest.files){
  const bytes=await fs.readFile(path.join(root,item.path));
  if(sha(bytes)!==item.sha256)throw Error(item.character+': approved sprite pixels/file changed');
  if(bytes.subarray(1,4).toString()!=='PNG'||bytes.readUInt32BE(16)!==item.dimensions[0]||bytes.readUInt32BE(20)!==item.dimensions[1])throw Error(item.character+': invalid atlas dimensions');
  allowed.add(path.basename(item.path));allowed.add(path.basename(item.path)+'.import');
 }
 const entries=await fs.readdir(path.join(root,'assets/characters/open_world'));
 if(entries.some(name=>!allowed.has(name)))throw Error('Obsolete or unexpected files in the final sprite directory');
 if(entries.length!==allowed.size)throw Error('Missing final atlas/import metadata');
 if(sha(await fs.readFile(path.join(root,manifest.renderScript)))!==manifest.renderScriptSha256)throw Error('Approved directional layout/gait renderer changed');
 const scale=await fs.readFile(path.join(root,'scripts/world_scale.gd'),'utf8');
 if(!/PERSON_HEIGHTS: Array\[float\] = \[156\.0,153\.0\]/.test(scale))throw Error('Approved character heights changed');
 console.log('PASS: final Te and Jo atlases, dimensions, layout, scale and walking renderer preserved; only approved sprites/import files remain.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
