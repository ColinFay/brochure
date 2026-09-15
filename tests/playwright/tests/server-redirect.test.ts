import { test, expect } from '@playwright/test';

/**
 * `server_redirect()` sends a custom message that the script brochure injects
 * turns into a navigation. That script is the only thing standing between the
 * server call and the browser, so this is what covers it.
 */

test('server_redirect() navigates to the target page', async ({ page }) => {
  await page.goto('/page2');
  await expect(page.getByRole('heading', { name: 'This is my second page' })).toBeVisible();

  await page.getByRole('button', { name: 'Take me to contact' }).click();

  await page.waitForURL('**/contact');
  await expect(page.getByRole('heading', { name: 'Contact us' })).toBeVisible();
});
