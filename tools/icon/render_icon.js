const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const svg = fs.readFileSync(process.argv[2], 'utf8');
  const b = await chromium.launch();
  for (const [size, out, bg] of JSON.parse(process.argv[3])) {
    const p = await b.newPage({viewport:{width:size,height:size}});
    await p.setContent(`<html><body style="margin:0;background:${bg}">${svg.replace('width="512" height="512"', `width="${size}" height="${size}"`)}</body></html>`);
    await p.screenshot({path: out, omitBackground: bg === 'transparent'});
    await p.close();
  }
  await b.close();
})();
