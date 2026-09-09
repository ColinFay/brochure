import { test, expect } from '@playwright/test';

/**
 * `redirect(from, to, code)` entries are honoured server-side: a request to
 * `from` returns an HTTP redirect (301 by default) with a `Location` header
 * pointing at `to`. The `inst/simple` example declares:
 *   - redirect("/page3", "/page2")
 *   - redirect("/page4", "/")
 */

test('"/page3" responds with a 301 to "/page2"', async ({ request }) => {
  // `maxRedirects: 0` so we inspect the redirect itself instead of following it.
  const res = await request.get('/page3', { maxRedirects: 0 });
  expect(res.status()).toBe(301);
  expect(res.headers()['location']).toBe('/page2');
});

test('"/page4" responds with a 301 to "/"', async ({ request }) => {
  const res = await request.get('/page4', { maxRedirects: 0 });
  expect(res.status()).toBe(301);
  expect(res.headers()['location']).toBe('/');
});

test('a browser visiting "/page3" lands on the second page', async ({ page }) => {
  await page.goto('/page3');
  await expect(page).toHaveURL(/\/page2$/);
  await expect(page.getByRole('heading', { name: 'This is my second page' })).toBeVisible();
});

test('a browser visiting "/page4" lands on the home page', async ({ page }) => {
  await page.goto('/page4');
  await expect(page).toHaveURL(/127\.0\.0\.1:3000\/$/);
  await expect(page.getByRole('heading', { name: 'This is my first page' })).toBeVisible();
});
