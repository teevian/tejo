// Verify the finished running faces/hair against the approved walking pixels.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const identity = JSON.parse(fs.readFileSync(path.join(root, 'assets/characters/running/identity.json'), 'utf8'));

(async () => {
  if (identity.head_scale !== 1) throw Error('Running must preserve the approved head scale');
  const keys = new Set(identity.placements.map(p => `${p.kind}/${p.row}/${p.key}`));
  if (identity.placements.length !== 60 || keys.size !== 60) throw Error('All sixty running head placements must be recorded');
  let total = 0, matching = 0;
  for (let kind = 0; kind < 2; kind++) {
    const reference = await sharp(path.join(root, identity.references[kind])).ensureAlpha().raw().toBuffer();
    const running = await sharp(path.join(root, 'assets/characters/running', kind === 0 ? 'te-run.png' : 'jo-run.png')).ensureAlpha().raw().toBuffer();
    for (const pose of identity.placements.filter(p => p.kind === kind)) {
      const [dx, dy] = pose.translation;
      let sampled = 0, identical = 0;
      // This region includes the crown, hair silhouette, eyes, brows and nose.
      // Near-opaque source pixels keep PNG premultiplication rounding bounded.
      for (let y = 45; y < pose.feature_max_y; y++) for (let x = 100; x < 300; x++) {
        const source = ((pose.row * 560 + y) * 2000 + x) * 4;
        if (reference[source + 3] < 240) continue;
        const target = ((pose.row * 560 + y + dy) * 3456 + pose.key * 576 + x + dx) * 4;
        sampled++;
        if ([0, 1, 2, 3].every(c => Math.abs(reference[source + c] - running[target + c]) <= 2)) identical++;
      }
      if (sampled < 3000 || identical / sampled < .995) {
        throw Error(`Approved face/hair drift at character ${kind}, view ${pose.row}, frame ${pose.key}: ${(100 * identical / sampled).toFixed(2)}% retained, ${sampled} pixels sampled`);
      }
      total += sampled;
      matching += identical;
    }
  }
  console.log(`PASS: all 60 running heads retain approved walking features at native scale (${(matching / total * 100).toFixed(3)}% retained feature pixels, within two levels of PNG alpha rounding)`);
})().catch(error => { console.error(error.message); process.exitCode = 1; });
