#!/usr/bin/env node

// npm install selenium-webdriver
const { Builder, Browser, By } = require("selenium-webdriver");

(async function helloSelenium() {
  let driver = await new Builder().forBrowser(Browser.CHROME).build();

  async function click(l) {
    // https://www.selenium.dev/documentation/webdriver/elements/locators/
    await driver.findElement(By.linkText(l)).click();
  }

  await driver.manage().setTimeouts({ implicit: 10000 });

  let inp = process.env.INPUT || "index.html";
  await driver.get(`file://${process.cwd()}/${inp}`);

  let args = process.argv.slice(2);
  // args = ["The bed...", "Test the bed"];
  for (let a of args) {
    await click(a);
  }
  let res = await driver
    .findElement(By.id("content"))
    .getAttribute("innerHTML");
  console.log(res);

  await driver.quit();
})();
