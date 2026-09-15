import { test, expect } from '@playwright/test';

test('has body', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('body')).toBeVisible();
});
