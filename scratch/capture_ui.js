const puppeteer = require('puppeteer');

(async () => {
  console.log("Launching puppeteer...");
  const browser = await puppeteer.launch({
    headless: 'new',
    defaultViewport: { width: 1440, height: 900 }
  });
  
  const page = await browser.newPage();
  
  console.log("Navigating to Titan Cloud Dashboard...");
  await page.goto('http://localhost:5173', { waitUntil: 'networkidle0', timeout: 30000 });
  
  // Wait a few seconds for the telemetry to populate
  await new Promise(r => setTimeout(r, 4000));
  
  const outputPath = 'docs/assets/titan_command_center.png';
  console.log(`Taking screenshot to ${outputPath}...`);
  await page.screenshot({ path: outputPath, fullPage: false });
  
  await browser.close();
  console.log("Screenshot complete!");
})();
