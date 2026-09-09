import { test, expect } from '@playwright/test';

/**
 * Navigation in brochure is plain HTTP navigation: the nav links are real
 * `<a href>` elements, and clicking one triggers a full document load of the
 * target page (not a client-side tab swap). These tests follow a user clicking
 * through the app and assert the URL and the rendered page change together.
 */

test('clicking "page2" navigates from home to the second page', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'This is my first page' })).toBeVisible();

  await page.getByRole('link', { name: 'page2', exact: true }).click();

  await expect(page).toHaveURL(/\/page2$/);
  await expect(page.getByRole('heading', { name: 'This is my second page' })).toBeVisible();
});

test('clicking "contact" navigates to the contact page', async ({ page }) => {
  await page.goto('/');

  await page.getByRole('link', { name: 'contact', exact: true }).click();

  await expect(page).toHaveURL(/\/contact$/);
  await expect(page.getByRole('heading', { name: 'Contact us' })).toBeVisible();
});

test('clicking "home" returns to the first page', async ({ page }) => {
  await page.goto('/contact');

  await page.getByRole('link', { name: 'home', exact: true }).click();

  await expect(page).toHaveURL(/127\.0\.0\.1:3000\/$/);
  await expect(page.getByRole('heading', { name: 'This is my first page' })).toBeVisible();
});

test('a full round-trip across all pages keeps each page distinct', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'page2', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'This is my second page' })).toBeVisible();

  await page.getByRole('link', { name: 'contact', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Contact us' })).toBeVisible();

  await page.getByRole('link', { name: 'home', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'This is my first page' })).toBeVisible();
});
