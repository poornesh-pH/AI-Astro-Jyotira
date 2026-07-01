# Jyotira interpretation server
 
A single serverless function that turns deterministic chart facts into grounded,
multilingual Vedic guidance. The Anthropic API key stays server-side.
 
## Environment
- `ANTHROPIC_API_KEY` — your Anthropic key.
 
## Deploy (Vercel)
1. Create a Vercel project; put `interpret.ts` at `api/interpret.ts`.
2. Set `ANTHROPIC_API_KEY` in Project → Settings → Environment Variables.
3. Deploy. Your endpoint is `https://<project>.vercel.app/api/interpret`.
4. Build the app with `--dart-define=API_BASE_URL=https://<project>.vercel.app/api`.
 
## Deploy (Cloudflare Workers)
Wrap `handler(req)` inside `export default { fetch: handler }` and bind a KV
namespace for the cache instead of the in-memory `Map`.
 
## Cost control
- `daily` uses the cheapest model and is cached per (moonSign + date + lang),
  so one generation serves every user with that moon sign that day.
- Long-form `report`/`compat` use a stronger model but are cached per chart hash,
  so re-opening a report costs zero tokens.
- Replace the in-memory cache with a durable KV/Redis store in production.
