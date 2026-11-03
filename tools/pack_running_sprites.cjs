// Registration/packing only: the complete painted figures come from image_gen.
// Usage: node tools/pack_running_sprites.cjs /absolute/path/to/five-cutouts.json
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const destination = path.join(root, 'assets/characters/running');

function figures(data, width, height) {
  const seen = new Uint8Array(width * height), result = [];
  for (let start = 0; start < seen.length; start++) {
    if (seen[start] || data[start * 4 + 3] < 100) continue;
    seen[start] = 1;
    const pixels = [start];
    let x0 = width, y0 = height, x1 = 0, y1 = 0;
    for (let index = 0; index < pixels.length; index++) {
      const n = pixels[index], x = n % width, y = Math.floor(n / width);
      x0 = Math.min(x0, x); y0 = Math.min(y0, y);
      x1 = Math.max(x1, x); y1 = Math.max(y1, y);
      for (const next of [n - 1, n + 1, n - width, n + width]) {
        if (next < 0 || next >= seen.length || Math.abs(next % width - x) > 1 || seen[next] || data[next * 4 + 3] < 100) continue;
        seen[next] = 1; pixels.push(next);
      }
    }
    if (pixels.length > 5000) result.push({pixels, x0, y0, x1, y1, cx: (x0 + x1) / 2, cy: (y0 + y1) / 2});
  }
  return result;
}

function headCenter(figure, width) {
  // A stable head registration avoids limb extent and fabric folds causing
  // sideways jumps. The directional lean below offsets the body root.
  const pixels = figure.pixels.filter(n => Math.floor(n / width) < figure.y0 + (figure.y1 - figure.y0) * .2);
  return pixels.reduce((sum, n) => sum + n % width, 0) / pixels.length;
}

(async () => {
  const sources = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  if (sources.length !== 5) throw Error('Five source views required');
  fs.mkdirSync(destination, {recursive: true});
  const layers = [[], []];
  const manifest = {cell: [576, 560], anchor: [288, 520], source_height: 438, frames: 6, stride: 176, rows: ['south', 'southeast', 'east', 'northeast', 'north'], characters: [{name: 'Te', keys: []}, {name: 'Jo', keys: []}]};
  for (const [row, source] of sources.entries()) {
    const {data, info} = await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject: true});
    const {width, height} = info;
    const all = figures(data, width, height).sort((a, b) => a.cy - b.cy);
    if (all.length !== 12) throw Error(`View ${row}: expected twelve complete figures, got ${all.length}`);
    for (let kind = 0; kind < 2; kind++) {
      const sequence = all.slice(kind * 6, kind * 6 + 6).sort((a, b) => a.cx - b.cx);
      // One anatomical scale per sequence, never stretch the compressed poses.
      const factor = 420 / ((sequence[0].y1 - sequence[0].y0 + sequence[3].y1 - sequence[3].y0) / 2);
      for (const [key, figure] of sequence.entries()) {
        const bx = Math.max(0, figure.x0 - 2), by = Math.max(0, figure.y0 - 2);
        const bw = Math.min(width - bx, figure.x1 - bx + 3), bh = Math.min(height - by, figure.y1 - by + 3);
        const mask = new Uint8Array(width * height), raw = Buffer.alloc(bw * bh * 4);
        for (const n of figure.pixels) {
          const x = n % width, y = Math.floor(n / width);
          for (let yy = Math.max(0, y - 1); yy <= Math.min(height - 1, y + 1); yy++)
            for (let xx = Math.max(0, x - 1); xx <= Math.min(width - 1, x + 1); xx++) mask[yy * width + xx] = 1;
        }
        for (let y = 0; y < bh; y++) for (let x = 0; x < bw; x++) {
          const n = (by + y) * width + bx + x;
          if (mask[n]) data.copy(raw, (y * bw + x) * 4, n * 4, n * 4 + 4);
        }
        const rootX = headCenter(figure, width) - [0,18,26,18,0][row] / factor;
        const lift = key % 3 === 2 ? 20 : 0;
        const ow = Math.round(bw * factor), oh = Math.round(bh * factor);
        const left = Math.round(288 - (rootX - bx) * factor);
        const top = Math.round(520 - (figure.y1 - by) * factor - lift);
        if (left < 3 || left + ow > 573 || top < 3 || top + oh > 557) throw Error(`Figure outside cell: ${row}/${kind}/${key}`);
        layers[kind].push({input: await sharp(raw, {raw: {width: bw, height: bh, channels: 4}}).resize(ow, oh).png().toBuffer(), left: key * 576 + left, top: row * 560 + top});
        manifest.characters[kind].keys.push({row, key, source_bounds: [figure.x0, figure.y0, figure.x1, figure.y1], scale: factor, root_x: rootX, flight_lift: lift, bounds: [left, top, ow, oh]});
      }
    }
  }
  for (let kind = 0; kind < 2; kind++) {
    const name = kind === 0 ? 'te' : 'jo';
    await sharp({create: {width: 3456, height: 2800, channels: 4, background: {r: 0, g: 0, b: 0, alpha: 0}}}).composite(layers[kind]).png().toFile(path.join(destination, name + '-run.png'));
  }
  fs.writeFileSync(path.join(destination, 'animations.json'), JSON.stringify(manifest, null, 2) + '\n');
  console.log('Packed 60 complete running drawings, five views, six frames per character.');
})();
