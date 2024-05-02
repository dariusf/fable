#!/usr/bin/env node

// npm install selenium-webdriver
const { Builder, Browser, By } = require("selenium-webdriver");
const Chrome = require("selenium-webdriver/chrome");
const options = new Chrome.Options();

(async function main() {
  let driver = await new Builder()
    .forBrowser(Browser.CHROME)
    .setChromeOptions(options.setPageLoadStrategy("eager"))
    // .setChromeOptions(options.addArguments("--headless=new"))
    .build();

  async function click(l) {
    // https://www.selenium.dev/documentation/webdriver/elements/locators/
    await driver.findElement(By.linkText(l)).click();
  }

  let inp = process.env.INPUT || "story.html";
  await driver.get(`file://${process.cwd()}/${inp}`);

  async function testOne() {
    // this is compatible with testing, but not exhaustive testing
    await driver.manage().setTimeouts({ implicit: 10000 });
    let args = process.argv.slice(2);
    // args = ["The bed...", "Test the bed"];
    for (let a of args) {
      await click(a);
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
