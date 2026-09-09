import { test, expect } from '@playwright/test';

/**
 * `brochureApp(content_404 = ...)` is documented to serve a "Not found" page
 * when no route matches the request.
 */

test('an unknown route serves the 404 content', async ({ page }) => {
  await page.goto('/this-page-does-not-exist');
  await expect(page.getByText('Not found')).toBeVisible();
});

test('an unknown route responds with HTTP 404', async ({ request }) => {
  const res = await request.get('/this-page-does-not-exist');
  expect(res.status()).toBe(404);
});
