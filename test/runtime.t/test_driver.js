#!/usr/bin/env node

/*

This driver script opens a Fable HTML file or URL, makes a bunch of choices, then dumps the DOM #content.

Usage:
node test_driver.js FILE_OR_URL INPUT...

INPUT is either a choice label to click or select:ID:VALUE to set the value of a widget.

set BROWSER=1 to use chromium (default), firefox, or webkit.

set DEBUG=1 to run headed and keep the browser open.

*/

// https://playwright.dev/docs/next/library

const { chromium } = require("playwright");
const path = require("path");
const { existsSync } = require("fs");

(async function main() {
  let browser = await chromium.launch({
    // headless: true,
    // headless: false,
    headless: !process.env.DEBUG,
  });
  const page = await browser.newPage(); // new tab

  const [input, ...elements] = process.argv.slice(2);

  const filePath = path.resolve(process.cwd(), input);

  const url = existsSync(filePath) ? `file://${filePath}` : input;
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await page.waitForSelector("body[data-ready]");

  for (const item of elements) {
    const m = /^select:([^:]*):(.*)$/s.exec(item);
    if (m) {
      await page.locator(`#${m[1]}`).selectOption(m[2]);
    } else {
      await page.getByRole("link", { name: item }).click({ timeout: 1000 });
    }
  }

  const res = await page.locator("#content").innerHTML();
  console.log(res);

  if (process.env.DEBUG) {
    await page.waitForTimeout(500000);
  }

  await browser.close();
})();
