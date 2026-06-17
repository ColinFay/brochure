import { test, expect } from '@playwright/test';

/**
 * `brochureApp(content_404 = ...)` is documented to serve a "Not found" page
 * when no route matches the request.
 *
 * NOTE: in the current `routr`-based rewrite this is not wired up yet — an
 * unmatched URL falls through to whatever page UI is currently stored instead
 * of returning the 404 content. These tests are therefore marked `fixme`: they
 * describe the expected behaviour and will start running (and should pass) once
 * `content_404` is honoured again in `brochureApp()`.
 */

test.fixme('an unknown route serves the 404 content', async ({ page }) => {
  await page.goto('/this-page-does-not-exist');
  await expect(page.getByText('Not found')).toBeVisible();
});

test.fixme('an unknown route responds with HTTP 404', async ({ request }) => {
  const res = await request.get('/this-page-does-not-exist');
  expect(res.status()).toBe(404);
});
