#!/usr/bin/env node

// npm install selenium-webdriver
// or
// npm install -g selenium-webdriver
// npm link selenium-webdriver
const { Builder, Browser, By } = require("selenium-webdriver");

let options;
if (process.env.BROWSER === "FIREFOX") {
  const Firefox = require("selenium-webdriver/firefox");
  options = new Firefox.Options();
} else {
  const Chrome = require("selenium-webdriver/chrome");
  options = new Chrome.Options();
}

(async function main() {
  let driver;
  if (process.env.BROWSER === "FIREFOX") {
    let d = new Builder().forBrowser(Browser.FIREFOX);
    if (!process.env.DEBUG) {
      d = d.setFirefoxOptions(options.addArguments("--headless"));
    }
    driver = await d.build();
  } else {
    let d = new Builder()
      .forBrowser(Browser.CHROME)
      .setChromeOptions(options.setPageLoadStrategy("eager"));
    if (!process.env.DEBUG) {
      d = d.setChromeOptions(options.addArguments("--headless=new"));
    }
    driver = await d.build();
  }

  async function click(l) {
    // https://www.selenium.dev/documentation/webdriver/elements/locators/
    await driver.findElement(By.linkText(l)).click();
  }

  let inp = process.env.INPUT || "index.html";
  await driver.get(`file://${process.cwd()}/${inp}`);

  async function testOne() {
    // this is compatible with testing, but not exhaustive testing
    await driver.manage().setTimeouts({ implicit: 10000 });
    let args = process.argv.slice(2);
    // args = ["The bed...", "Test the bed"];
    for (let a of args) {
      await click(a);
      await driver.sleep(30);
    }
    let res = await driver
      .findElement(By.id("content"))
      .getAttribute("innerHTML");
    console.log(res);
  }

  async function testExhaustive() {
    for (let i = 0; i < 10000; i++) {
      // await driver.wait(until.elementIsVisible(revealed), 2000);
      // https://github.com/SeleniumHQ/selenium/blob/trunk/javascript/node/selenium-webdriver/lib/until.js
      // https://github.com/SeleniumHQ/selenium/blob/trunk/javascript/node/selenium-webdriver/lib/webdriver.js
      let choices = await driver.findElements(By.css(".choice"));
      while (choices.length) {
        let c = choices[Math.floor(Math.random() * choices.length)];
        // let c = choices[0];
        let t = await c.getAttribute("textContent");
        console.log("picked", t);
        await c.click();
        await driver.sleep(30);
        choices = await driver.findElements(By.css(".choice"));
      }

      let errors = await driver.findElements(By.css(".error"));
      console.log("---");
      if (errors.length) {
        let res = await driver
          .findElement(By.id("content"))
          .getAttribute("innerHTML");
        console.log(res);
        await driver.sleep(3600_000);
      } else {
        console.log("ALL OK!");
      }
      console.log("---");
      await driver.navigate().refresh();
    }
  }

  if (process.env.INSIDE_DUNE) {
    await testOne();
  } else {
    await testExhaustive();
  }

  await driver.quit();
})();
