// https://playwright.dev/docs/next/library

const { chromium } = require("playwright");
const path = require("path");
const { existsSync, readFileSync } = require("fs");

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

    async function testSequence() {
      for (const item of elements) {
        if (item.startsWith("select:")) {
          const [_, sid, val] = item.split(":");
          await page.locator(`#${sid}`).selectOption(val);
        } else {
          await page.getByRole("link", { name: item }).click({ timeout: 1000 });
        }
      }
    }
    await testSequence();
  } else {
    // interpret as url
    await page.goto(input, { waitUntil: "domcontentloaded" });

    // the input to the page can be given either by url or a js file
    if (elements[0].endsWith(".js")) {
      const js = readFileSync(elements[0], { encoding: "utf-8" });
      // interpret the second element as the path to a file containing js to evaluate
      try {
        await page.evaluate((code) => {
          return eval(code);
        }, js);
      } catch (err) {
        console.error(err.message);
      }
    }
  }

  const res = await page.locator("#content").innerHTML();
  console.log(res);

  if (process.env.DEBUG) {
    await page.waitForTimeout(500000);
  }

  await browser.close();
})();
