import { test, expect } from "@playwright/test";

test("editing changes to custom", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  await expect(page.locator("#examples")).toHaveValue("An Introduction");
  await page
    .locator("div")
    .filter({ hasText: "Hello! Fable is a narrative" })
    .nth(2)
    .click();
  await page.keyboard.type("a");
  await expect(page.locator("#examples")).toHaveValue("custom");
});

test("closing the page after editing", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  await expect(page.locator("#examples")).toHaveValue("An Introduction");
  await page
    .locator("div")
    .filter({ hasText: "Hello! Fable is a narrative" })
    .nth(2)
    .click();
  await page.keyboard.type("a");
  await expect(page.locator("#examples")).toHaveValue("custom");
  page.on("dialog", async (dialog) => {
    expect(dialog.type()).toBe("beforeunload");
    try {
      // https://playwright.dev/docs/dialogs
      // the docs say we have to do this, but there's an error?
      await dialog.dismiss();
    } catch (e) {}
  });
  await page.close({ runBeforeUnload: true });
  expect(page.isClosed()).toBe(false);
});

test("closing the page without editing", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  await expect(page.locator("#examples")).toHaveValue("An Introduction");
  await page.close({ runBeforeUnload: true });
});

test("closing the page after changing example", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  await expect(page.locator("#examples")).toHaveValue("An Introduction");
  await page.locator("#examples").selectOption("Scrum");
  await page.close({ runBeforeUnload: true });
});

test("publish button downloads file", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "Publish" }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe("index.html");
});

test("save button downloads file (non-chromium)", async ({
  page,
  browserName,
}) => {
  test.skip(browserName === "chromium", "This test only runs on non Chromium");
  await page.goto("http://localhost:8005/");
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "Save" }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe("story.md");
});

test("save button downloads file (chromium)", async ({ page, browserName }) => {
  test.skip(browserName !== "chromium", "This test only runs on Chromium");
  await page.goto("http://localhost:8005/");
  await page.evaluate(() => {
    const w = window as any;
    w._pickerCalled = false;
    const _ = w.showSaveFilePicker;
    w.showSaveFilePicker = async () => {
      w._pickerCalled = true;
      // We still throw to prevent the real OS dialog from hanging the test
      throw new DOMException("AbortError", "AbortError");
    };
  });
  await page.getByRole("button", { name: "Save" }).click();
  const wasCalled = await page.evaluate(() => (window as any)._pickerCalled);
  expect(wasCalled).toBe(true);
});

test("graph button opens new tab", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  const page1Promise = page.waitForEvent("popup");
  await page.getByRole("button", { name: "Graph" }).click();
  const page1 = await page1Promise;
  await expect(page1.locator("#graph-container")).toMatchAriaSnapshot(`
    - document:
      - paragraph: end
      - paragraph: page10
      - paragraph: persuasion
      - paragraph: prelude
    `);
});

const scrumInitial = `
    - text: Let’s begin today’s standup. How are you feeling today?
    - list:
      - listitem:
        - link "Green"
      - listitem:
        - link "Amber"
      - listitem:
        - link "Red"
    `;
test("back button", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  await page.locator("#examples").selectOption("Scrum");
  await expect(
    page.locator("iframe").contentFrame().locator("#content-container"),
  ).toMatchAriaSnapshot(scrumInitial);
  await page
    .locator("iframe")
    .contentFrame()
    .getByRole("link", { name: "Green" })
    .click();
  await expect(
    page.locator("iframe").contentFrame().locator("#content-container"),
  ).toMatchAriaSnapshot(`
    - text: Let’s begin today’s standup. How are you feeling today? What would you like to do next?
    - list:
      - listitem:
        - link "Review"
      - listitem:
        - link "Add a story"
    `);
  await page.getByRole("button", { name: "Back" }).click();
  await expect(
    page.locator("iframe").contentFrame().locator("#content-container"),
  ).toMatchAriaSnapshot(scrumInitial);
});

test("restart button", async ({ page }) => {
  await page.goto("http://localhost:8005/");
  await page.locator("#examples").selectOption("Scrum");
  await expect(
    page.locator("iframe").contentFrame().locator("#content-container"),
  ).toMatchAriaSnapshot(scrumInitial);
  await page
    .locator("iframe")
    .contentFrame()
    .getByRole("link", { name: "Green" })
    .click();
  await page
    .locator("iframe")
    .contentFrame()
    .getByRole("link", { name: "Review" })
    .click();
  await page
    .locator("iframe")
    .contentFrame()
    .getByRole("link", { name: "Pick a ticket" })
    .click();
  await expect(
    page.locator("iframe").contentFrame().locator("#content-container"),
  ).toMatchAriaSnapshot(`
    - text: Let’s begin today’s standup. How are you feeling today? What would you like to do next? Reviewing… So how are we doing on this next story?
    - list:
      - listitem:
        - link "It’s done":
          - /url: "#"
      - listitem:
        - link "It’s not yet done":
          - /url: "#"
    `);
  await page.getByRole("button", { name: "Restart" }).click();
  await expect(
    page.locator("iframe").contentFrame().locator("#content-container"),
  ).toMatchAriaSnapshot(scrumInitial);
});
