import { test, expect } from '@playwright/test';

/**
 * Each `page()` declared in the app is served at its own `href`, with its own
 * UI. A brochure app is *not* a single Shiny UI toggling tabs: navigating to a
 * URL returns a full HTML document built from that page's `ui`.
 *
 * The `inst/simple` example declares three pages:
 *   - "/"        -> "This is my first page"  + plot
 *   - "/page2"   -> "This is my second page" + plot
 *   - "/contact" -> "Contact us"             + a static list
 */

test('"/" serves the home page', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'This is my first page' })).toBeVisible();
  // The other pages' headings must NOT be present: each href is its own document.
  await expect(page.getByText('This is my second page')).toHaveCount(0);
  await expect(page.getByText('Contact us')).toHaveCount(0);
});

test('"/page2" serves the second page', async ({ page }) => {
  await page.goto('/page2');
  await expect(page.getByRole('heading', { name: 'This is my second page' })).toBeVisible();
  await expect(page.getByText('This is my first page')).toHaveCount(0);
});

test('"/contact" serves the contact page with its static content', async ({ page }) => {
  await page.goto('/contact');
  await expect(page.getByRole('heading', { name: 'Contact us' })).toBeVisible();
  // `exact` so "Here" doesn't also match the substring inside "There".
  await expect(page.getByText('Here', { exact: true })).toBeVisible();
  await expect(page.getByText('There', { exact: true })).toBeVisible();
});

test('every page renders the shared navigation links', async ({ page }) => {
  for (const href of ['/', '/page2', '/contact']) {
    await page.goto(href);
    await expect(page.getByRole('link', { name: 'home', exact: true })).toHaveAttribute('href', '/');
    await expect(page.getByRole('link', { name: 'page2', exact: true })).toHaveAttribute('href', '/page2');
    await expect(page.getByRole('link', { name: 'contact', exact: true })).toHaveAttribute('href', '/contact');
  }
});
