# BayBeat

A curated guide to what's new and fresh across the Bay Area — restaurant openings, concerts, free festivals, pop-ups, and one-night-only happenings from San Francisco to San Jose.

Single-file static site. No build step. No frameworks.

## Live demo

Open `index.html` in any browser. Or drop it on [Netlify Drop](https://app.netlify.com/drop) for an instant URL.

## Launch checklist for `baybeat.co`

You'll need ~30 minutes total. Files in this folder are ready to deploy as-is — the steps below are about creating accounts and clicking through.

### 1. Buy the domain (~$25/yr)

Recommended: [Cloudflare Registrar](https://dash.cloudflare.com/?to=/:account/domains/register) — at-cost pricing, no markup. Otherwise: [Porkbun](https://porkbun.com/), [Namecheap](https://www.namecheap.com/), [Gandi](https://www.gandi.net/).

If `baybeat.co` is taken, reasonable alternatives: `baybeat.io`, `baybeat.fyi`, `baybeat.day`, `getbaybeat.com`, `bay-beat.co`.

### 2. Push to GitHub

```bash
cd <this-folder>
mv baybeat.html index.html       # GitHub Pages serves index.html by default
git init
git add .
git commit -m "Initial BayBeat launch"
gh repo create baybeat --public --source=. --push
```

(Or do it via the github.com UI if you don't have `gh` installed.)

### 3. Pick a host (free tier is plenty)

**Easiest — Cloudflare Pages** (recommended if your domain is at Cloudflare):
1. Go to [pages.cloudflare.com](https://pages.cloudflare.com/)
2. Click "Create a project" → "Connect to Git"
3. Pick your `baybeat` repo
4. Build settings: leave everything blank (no build step), output directory `/`
5. Deploy — done in ~30 seconds
6. Click "Custom domains" → add `baybeat.co` → DNS auto-configures if domain is at Cloudflare

**Alternative — Netlify**:
1. Go to [app.netlify.com](https://app.netlify.com/)
2. "Add new site" → "Import an existing project" → pick the GitHub repo
3. Deploy
4. Site settings → Domain management → Add `baybeat.co`

**Alternative — GitHub Pages**:
1. Repo → Settings → Pages
2. Source: deploy from `main` branch, root folder
3. Add `CNAME` file with content `baybeat.co`
4. At your DNS registrar, add `A` records pointing to GitHub's IPs:
   - `185.199.108.153`
   - `185.199.109.153`
   - `185.199.110.153`
   - `185.199.111.153`

All three options give you free SSL automatically.

### 4. (Optional) Wire up shared encores & shouts via Supabase

Without this step, encores and shouts are stored per-browser via localStorage — fine for a personal/demo site, but each visitor sees their own counts. If you want the social layer to actually be shared:

**4a. Create a Supabase project** at [supabase.com](https://supabase.com/) — free tier is generous (500MB DB, unlimited API requests).

**4b. Run the schema.** In your project's SQL Editor, paste the contents of [`supabase-schema.sql`](./supabase-schema.sql) and click Run. Creates the `encores` table, `shouts` table, the atomic `increment_encore` RPC, and locks everything down with row-level-security policies (anyone can read, shout inserts have size limits, encore counts can only change through the RPC which caps delta to ±1 per call).

**4c. Get your credentials.** Project Settings → API → copy:
- **Project URL** (looks like `https://xyzabc.supabase.co`)
- **anon / public key** (long JWT)

**4d. Paste them in.** In `index.html`, find:
```js
const SUPABASE_URL = '';
const SUPABASE_ANON_KEY = '';
```
Paste the URL and anon key in. Save, push, refresh — the app will fetch real shared counts and shouts on every page load.

**4e. Push the change.** `git add index.html && git commit -m "Wire up Supabase" && git push`. Cloudflare/Netlify auto-deploy.

That's it — encores and shouts are now real and shared across every visitor.

## Notes on moderation

The shouts feature accepts anonymous input from anyone. The schema has size limits (200 chars for text, 32 for name) baked into the RLS policy, but you'll still want to keep an eye on things. Easy options:

- **Supabase Dashboard** → Table Editor → `shouts` — delete any spam manually.
- **Add a profanity filter** — easiest is hooking [Sightengine](https://sightengine.com) or [PerspectiveAPI](https://perspectiveapi.com) into a Supabase Edge Function (free tier on both).
- **Add captcha** — drop in [hCaptcha](https://www.hcaptcha.com/) (free) before insert.

For a small launch, manual moderation is fine.

## What's where

```
.
├── index.html             # the entire app
├── supabase-schema.sql    # paste into Supabase SQL Editor
└── README.md              # this file
```

## Tech

- Plain HTML / CSS / JS — ~3,000 lines, all in one file
- Plus Jakarta Sans + Fraunces from Google Fonts
- Photos from Unsplash CDN with graceful emoji+color fallback
- Supabase JS SDK (loaded via CDN, optional)
- localStorage for "my encores" (always per-device, by design)

## License

MIT.
