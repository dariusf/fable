// https://playwright.dev/docs/next/library

const { chromium } = require("playwright");
const path = require("path");

(async function main() {
  let browser = await chromium.launch({
    headless: !process.env.DEBUG,
  });
  const page = await browser.newPage(); // new tab

  const args = process.argv.slice(2);
  const inputFileName = args[0];
  const elements = args.slice(1);

  const fileUrl = `file://${path.resolve(process.cwd(), inputFileName)}`;
  await page.goto(fileUrl, { waitUntil: "domcontentloaded" });

  async function testOne() {
    for (const text of elements) {
      await page.getByRole("link", { name: text }).click({ timeout: 1000 });
    }

    const res = await page.locator("#content").innerHTML();
    console.log(res);
  }

  await testOne();

  await browser.close();
})();
