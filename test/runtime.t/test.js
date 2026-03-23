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

  const args = process.argv.slice(2);
  const input = args[0];
  const elements = args.slice(1);

  const filePath = path.resolve(process.cwd(), input);
  if (existsSync(filePath)) {
    await page.goto(`file://${filePath}`, { waitUntil: "domcontentloaded" });
  } else {
    // interpret as url
    await page.goto(input, { waitUntil: "domcontentloaded" });
  }

  // await page.waitForTimeout(500000);

  async function testOne() {
    for (const item of elements) {
      if (item.startsWith("select:")) {
        const [_, sid, val] = item.split(":");
        await page.locator(`#${sid}`).selectOption(val);
      } else {
        await page.getByRole("link", { name: item }).click({ timeout: 1000 });
      }
    }

    const res = await page.locator("#content").innerHTML();
    console.log(res);
  }

  await testOne();

  await browser.close();
})();
