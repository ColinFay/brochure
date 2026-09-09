import { test, expect } from '@playwright/test';

/**
 * A page declared with a parameterised `href` ("/who/:id") exposes the matched
 * values through `get_keys()` -- with the `request` in the UI, and with no
 * argument in the server.
 */

test('a parameterised page reads its keys in the UI', async ({ page }) => {
  await page.goto('/who/colin');
  await expect(page.getByRole('heading', { name: 'Hello colin' })).toBeVisible();
});

test('a parameterised page reads its keys in the server', async ({ page }) => {
  await page.goto('/who/colin');
  await expect(page.getByText('server sees colin')).toBeVisible();
});

test('two parameterised pages do not share their keys', async ({ browser }) => {
  const [a, b] = await Promise.all([browser.newPage(), browser.newPage()]);
  await Promise.all([a.goto('/who/alice'), b.goto('/who/bob')]);
  await expect(a.getByText('server sees alice')).toBeVisible();
  await expect(b.getByText('server sees bob')).toBeVisible();
  await Promise.all([a.close(), b.close()]);
});
