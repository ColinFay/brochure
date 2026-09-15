// Probe a deployed brochure app from a real browser.
//
//   node tests/playwright/connect-probe.mjs https://connect.thinkr.fr/brochure-subpage
//
// It drives `inst/subpage`, whose every page renders a `#probe` block saying
// which page's *server* is actually running, the keys it matched and the
// cookies it sees. That is what makes a wrong answer visible: a page running
// someone else's server still looks right until you read the marker.
//
import { chromium } from 'playwright';

const BASE = (process.argv[2] || '').replace(/\/$/, '');
if (!BASE) {
  console.error('usage: node connect-probe.mjs <base url>');
  process.exit(2);
}

const browser = await chromium.launch();
const ctx = await browser.newContext();
let pass = 0;
let fail = 0;
const ok = (name, cond, detail = '') => {
  cond ? pass++ : fail++;
  console.log(`${cond ? 'ok  ' : 'FAIL'}  ${name}${cond ? '' : '   <- ' + detail}`);
};

// Load a page and return its probe, plus anything that went wrong loading it.
const load = async (path) => {
  const page = await ctx.newPage();
  const bad = [];
  page.on('requestfailed', (r) => bad.push('failed ' + r.url()));
  page.on('response', (r) => {
    if (r.status() >= 400) bad.push(r.status() + ' ' + r.url());
  });
  await page.goto(BASE + path);
  await page.locator('#probe code').waitFor({ timeout: 25000 });
  await page.waitForFunction(
    () => document.querySelector('#probe code')?.textContent?.length > 2,
    null,
    { timeout: 25000 },
  );
  const probe = JSON.parse(await page.locator('#probe code').textContent());
  const extra = await page.evaluate(() => window.__brochure_extra__ === true);
  const uiKey = (await page.locator('#ui_key').count())
    ? await page.locator('#ui_key').textContent()
    : null;
  return { page, probe, bad, extra, uiKey };
};

console.log(`\n--- ${BASE}\n`);

// The right server answers, at every depth
for (const [path, marker] of [
  ['/', 'home'],
  ['/one', 'one'],
  ['/one/two', 'one/two'],
  ['/one/two/three/', 'one/two/three'],
  ['/who/colin', 'who'],
  ['/pair/a/b', 'pair'],
]) {
  const r = await load(path);
  ok(`${path} runs its own server`, r.probe.server === marker, `got ${r.probe.server}`);
  ok(`${path} loads every asset`, r.bad.length === 0, r.bad.join(', '));
  ok(`${path} gets the injected extra content`, r.extra === true);
  await r.page.close();
}

// Keys, in the ui and in the server
{
  const r = await load('/who/colin');
  ok('/who/:id server keys', r.probe.keys?.id === 'colin', JSON.stringify(r.probe.keys));
  ok('/who/:id ui keys', (r.uiKey || '').includes('colin'), r.uiKey);
  await r.page.close();

  const p = await load('/pair/x/y');
  ok(
    '/pair/:a/:b server keys',
    p.probe.keys?.a === 'x' && p.probe.keys?.b === 'y',
    JSON.stringify(p.probe.keys),
  );
  ok('/pair/:a/:b ui keys', (p.uiKey || '').includes('x/y'), p.uiKey);
  await p.page.close();
}

// Two sessions at once must not see each other's keys
{
  const [a, b] = await Promise.all([load('/who/alice'), load('/who/bob')]);
  ok(
    'concurrent sessions keep their own keys',
    a.probe.keys?.id === 'alice' && b.probe.keys?.id === 'bob',
    `${a.probe.keys?.id} / ${b.probe.keys?.id}`,
  );
  await Promise.all([a.page.close(), b.page.close()]);
}

// Cookies set and removed by page level res_handlers, seen from another page
{
  const login = await load('/login');
  await login.page.close();
  const after = await load('/one');
  ok(
    'cookie set by /login is visible from /one',
    after.probe.cookies?.BROCHURE === 'logged-in',
    JSON.stringify(after.probe.cookies),
  );
  await after.page.close();

  const logout = await load('/logout');
  await logout.page.close();
  const gone = await load('/one');
  ok(
    'cookie removed by /logout',
    gone.probe.cookies?.BROCHURE === undefined,
    JSON.stringify(gone.probe.cookies),
  );
  await gone.page.close();
}

// server_redirect
{
  const r = await load('/');
  await r.page.getByRole('button', { name: /one\/two\/three/ }).click();
  await r.page.waitForURL('**/one/two/three', { timeout: 20000 }).catch(() => {});
  ok('server_redirect to a deep page', r.page.url().endsWith('/one/two/three'), r.page.url());
  await r.page.close();

  const k = await load('/');
  await k.page.getByRole('button', { name: /from-button/ }).click();
  await k.page.waitForURL('**/who/from-button', { timeout: 20000 }).catch(() => {});
  ok(
    'server_redirect to a parameterised page',
    k.page.url().endsWith('/who/from-button'),
    k.page.url(),
  );
  await k.page.close();

  const e = await load('/');
  const before = e.page.url();
  await e.page.getByRole('button', { name: /javascript/ }).click();
  await e.page.waitForTimeout(3000);
  const probe = await e.page.locator('#probe code').textContent();
  ok(
    'server_redirect refuses a javascript: target',
    e.page.url() === before && probe.includes('REFUSED'),
    probe,
  );
  await e.page.close();
}

// HTTP level behaviour, through whatever proxy sits in front
{
  const req = ctx.request;

  const health = await req.get(BASE + '/healthcheck');
  ok(
    '/healthcheck answers 200 OK from a req_handler',
    health.status() === 200 && (await health.text()).trim() === 'OK',
    health.status(),
  );

  const post = await req.post(BASE + '/post-only');
  ok('POST /post-only answers 201', post.status() === 201, post.status());
  const get = await req.get(BASE + '/post-only', { maxRedirects: 0 });
  ok('GET /post-only is a 404', get.status() === 404, get.status());

  const missing = await req.get(BASE + '/nexistepas');
  ok(
    'unknown url is a 404 with content_404',
    missing.status() === 404 && (await missing.text()).includes('Nothing here'),
    missing.status(),
  );

  const one = await req.get(BASE + '/one');
  ok(
    'app level res_handler header survives',
    one.headers()['x-brochure'] === 'app-level',
    JSON.stringify(one.headers()['x-brochure']),
  );

  for (const [from, to, code] of [
    ['/old', '/one/two', 301],
    ['/old/deep/path', '/who/from-redirect', 302],
  ]) {
    const r = await req.get(BASE + from, { maxRedirects: 0 });
    ok(
      `redirect ${from} -> ${to} (${code})`,
      r.status() === code && (r.headers()['location'] || '').endsWith(to),
      `${r.status()} ${r.headers()['location']}`,
    );
  }
}

console.log(`\n${pass} ok, ${fail} failed\n`);
await browser.close();
process.exit(fail ? 1 : 0);
