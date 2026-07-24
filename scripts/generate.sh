#!/usr/bin/env bash
# generate.sh — Generate CV PDF from HTML template
# Uses Puppeteer (headless Chrome) via Node.js
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$DIR")"
TEMPLATE="$PROJECT_DIR/template/cv.html"
OUTPUT_DIR="$PROJECT_DIR/output"
OUTPUT_PDF="$OUTPUT_DIR/CV_Abdan_Zam_Zam_Ramadhan.pdf"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📄 Generating CV PDF...${NC}"

# Ensure output dir
mkdir -p "$OUTPUT_DIR"

# Check if puppeteer is available
if ! command -v node &> /dev/null; then
  echo "❌ Node.js is required. Install it first."
  exit 1
fi

# Use npx puppeteer if available, or install on the fly
if ! command -v npx &> /dev/null; then
  echo "❌ npx is required."
  exit 1
fi

# Generate script inline
node -e "
const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();
  
  // Load HTML file
  const fs = require('fs');
  const path = require('path');
  const html = fs.readFileSync('$TEMPLATE', 'utf-8');
  
  await page.setContent(html, { waitUntil: 'networkidle0' });
  
  // Wait for JS rendering
  await page.evaluate(() => {
    return new Promise(resolve => {
      if (document.readyState === 'complete') {
        // Check if our render function already ran
        const summary = document.getElementById('summary-text');
        if (summary && summary.textContent.length > 10) {
          resolve();
        } else {
          // Wait a bit for the DOMContentLoaded handler
          setTimeout(resolve, 500);
        }
      } else {
        window.addEventListener('load', () => setTimeout(resolve, 500));
      }
    });
  });
  
  // Extra wait for fonts
  await new Promise(r => setTimeout(r, 1000));
  
  await page.pdf({
    path: '$OUTPUT_PDF',
    format: 'A4',
    printBackground: true,
    margin: { top: '0mm', bottom: '0mm', left: '0mm', right: '0mm' },
    preferCSSPageSize: true,
  });
  
  await browser.close();
  
  const stats = fs.statSync('$OUTPUT_PDF');
  console.log('✅ PDF generated successfully!');
  console.log('   📍 ' + '$OUTPUT_PDF');
  console.log('   📦 ' + (stats.size / 1024).toFixed(1) + ' KB');
})();
" 2>&1 || {
  # Fallback: try installing puppeteer and retry
  echo "⚠️  Puppeteer not found. Installing..."
  cd "$PROJECT_DIR"
  npm init -y --silent 2>/dev/null
  npm install puppeteer --save-dev 2>&1 | tail -2
  
  node -e "
  const puppeteer = require('puppeteer');
  (async () => {
    const browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();
    const fs = require('fs');
    const html = fs.readFileSync('$TEMPLATE', 'utf-8');
    await page.setContent(html, { waitUntil: 'networkidle0' });
    await page.evaluate(() => new Promise(r => setTimeout(r, 1500)));
    await page.pdf({
      path: '$OUTPUT_PDF',
      format: 'A4',
      printBackground: true,
      margin: { top: '0mm', bottom: '0mm', left: '0mm', right: '0mm' },
      preferCSSPageSize: true,
    });
    await browser.close();
    const stats = fs.statSync('$OUTPUT_PDF');
    console.log('✅ PDF generated successfully!');
    console.log('   📍 ' + '$OUTPUT_PDF');
    console.log('   📦 ' + (stats.size / 1024).toFixed(1) + ' KB');
  })();
  " 2>&1
}

echo -e "${GREEN}✅ Done!${NC}"