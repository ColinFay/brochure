import { test, expect } from '@playwright/test';

/**
 * Each page can ship its own `server` function. brochure must wire the matched
 * page's server to the Shiny session opened by that page's document. We prove
 * this end-to-end: the home and page2 servers render a plot into `#plot`, so
 * once Shiny connects an `<img>` appears inside that output. The contact page
 * declares no server, so it has no plot output at all.
 */

test('the home page server renders its plot', async ({ page }) => {
  await page.goto('/');
  // renderPlot() fills the output with an <img> once the Shiny session connects.
  await expect(page.locator('#plot img')).toBeVisible({ timeout: 15000 });
});

test('the page2 server renders its own plot', async ({ page }) => {
  await page.goto('/page2');
  await expect(page.locator('#plot img')).toBeVisible({ timeout: 15000 });
});

test('the contact page has no plot output (no server declared)', async ({ page }) => {
  await page.goto('/contact');
  await expect(page.getByRole('heading', { name: 'Contact us' })).toBeVisible();
  await expect(page.locator('#plot')).toHaveCount(0);
});
