import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "test",
  outputDir: "_build/test-results",
  webServer: {
    command: "make editor",
    url: "http://localhost:8005",
    reuseExistingServer: true,
    stdout: "ignore",
    stderr: "pipe",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "firefox",
      use: { ...devices["Desktop Firefox"] },
    },
    {
      name: "webkit",
      use: { ...devices["Desktop Safari"] },
    },
  ],
});
