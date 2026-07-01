/**
 * Jyotira interpretation endpoint.
 *
 * Runs on the edge (Vercel Edge Functions / Cloudflare Workers). The Anthropic
 * API key NEVER leaves the server. The client sends only deterministic chart
 * facts ("ground truth"); this function asks the model to NARRATE those facts
 * and forbids it from inventing planetary positions.
 *
 * Token control:
 *  - Cheapest model for the high-volume daily reading; stronger models only for
 *    paid long-form reports.
 *  - Responses are cached by (type:lang:chartHash[:questionHash]). A repeated
 *    read costs zero tokens. Daily readings are keyed by moon sign + date, so a
 *    single generation is shared by every user with that moon sign that day.
 *
 * Deploy:
 *   Vercel:      place at /api/interpret.ts, set env ANTHROPIC_API_KEY.
 *   Cloudflare:  wrap `handler` in your Worker fetch handler; use KV for cache.
 */
 
const MODEL: Record<string, string> = {
  daily: "claude-haiku-4-5-20251001",
  report: "claude-opus-4-8",
  compat: "claude-opus-4-8",
  ask: "claude-sonnet-4-6",
};
 
const MAX_TOKENS: Record<string, number> = {
  daily: 320,
  report: 1500,
  compat: 1100,
  ask: 600,
};
 
const LANG_NAME: Record<string, string> = {
  en: "English",
  hi: "Hindi",
  ta: "Tamil",
  te: "Telugu",
  bn: "Bengali",
  mr: "Marathi",
};
 
const SYSTEM = `You are a knowledgeable, compassionate Vedic astrologer (Jyotish).
You will be given the user's chart as exact, pre-computed facts (JSON).
HARD RULES:
1. Use ONLY the planetary positions, signs, nakshatras, houses and dasha given. NEVER invent or alter a position.
2. Do not contradict the supplied facts. If a detail is not provided, do not fabricate it.
3. Be specific to THIS chart (reference the actual signs/houses/dasha given), not generic.
4. Warm, respectful, culturally rooted tone. No fear-mongering, no medical/legal/financial directives, no guarantees.
5. Keep within the requested length. Plain text, short paragraphs, no markdown headers.`;
 
function promptFor(type: string, focus: string | null, ground: unknown, question?: string): string {
  const facts = JSON.stringify(ground);
  switch (type) {
    case "daily":
      return `Chart facts: ${facts}\nWrite a concise, uplifting daily guidance (4-5 sentences) grounded in the Moon sign, current mahadasha and one notable placement.`;
    case "report":
      if (focus === "dosha_and_remedies")
        return `Chart facts: ${facts}\nIdentify any classical doshas indicated strictly by these placements (e.g. Mangal/Manglik from Mars house, Kaal Sarp from Rahu-Ketu axis, Sade Sati from Saturn-Moon). For each, explain why based on the given positions, and give 2-3 traditional, non-harmful remedies. If a dosha is not indicated by the facts, clearly say it is not present.`;
      if (focus === "auspicious_timing")
        return `Chart facts: ${facts}\nBased on the current mahadasha and Moon placement, describe broadly favourable themes and timing windows for new beginnings. General guidance only; no exact dated predictions.`;
      return `Chart facts: ${facts}\nWrite a structured life report covering: personality (lagna + Moon), career (10th house lord context), relationships, strengths, and the current mahadasha's themes. Reference the actual placements provided.`;
    case "compat":
      return `Compatibility facts (Ashtakoota already computed): ${facts}\nExplain what the Guna Milan score and koota breakdown mean for this match, note any Nadi/Bhakoot dosha present, and give balanced, constructive guidance. Do not recompute the score.`;
    case "ask":
      return `Chart facts: ${facts}\nUser question: "${question ?? ""}"\nAnswer in 3-4 sentences, grounded strictly in the chart facts above. If the chart does not speak to the question, say so honestly.`;
    default:
      return `Chart facts: ${facts}\nProvide grounded Vedic guidance.`;
  }
}
 
// Ephemeral in-memory cache. Swap for Vercel KV / Cloudflare KV / Redis in prod.
const cache = new Map<string, string>();
 
async function hashQuestion(q: string): Promise<string> {
  const data = new TextEncoder().encode(q);
  const buf = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(buf))
    .slice(0, 8)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
 
export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
 
  let body: {
    chartHash?: string;
    ground?: unknown;
    type?: string;
    focus?: string | null;
    lang?: string;
    question?: string;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
 
  const { chartHash, ground, type = "daily", lang = "en", focus = null, question } = body;
  if (!chartHash || !ground) return json({ error: "Missing chart data" }, 400);
 
  const apiKey = (globalThis as { process?: { env?: Record<string, string> } })
    .process?.env?.ANTHROPIC_API_KEY;
  if (!apiKey) return json({ error: "Server not configured" }, 500);
 
  const langName = LANG_NAME[lang] ?? "English";
  const qPart = question ? `:${await hashQuestion(question)}` : "";
  const cacheKey = `${type}:${focus ?? ""}:${lang}:${chartHash}${qPart}`;
 
  if (cache.has(cacheKey)) {
    return json({ text: cache.get(cacheKey), cached: true });
  }
 
  const model = MODEL[type] ?? MODEL.daily;
  const maxTokens = MAX_TOKENS[type] ?? 400;
  const userPrompt =
    promptFor(type, focus, ground, question) +
    `\n\nRespond entirely in ${langName}.`;
 
  try {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens,
        system: SYSTEM,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });
 
    if (!res.ok) {
      const detail = await res.text();
      return json({ error: "Upstream error", detail }, 502);
    }
 
    const data = (await res.json()) as {
      content?: Array<{ type: string; text?: string }>;
    };
    const text = (data.content ?? [])
      .filter((b) => b.type === "text")
      .map((b) => b.text ?? "")
      .join("\n")
      .trim();
 
    if (!text) return json({ error: "Empty completion" }, 502);
 
    cache.set(cacheKey, text);
    return json({ text, cached: false });
  } catch (e) {
    return json({ error: "Request failed", detail: String(e) }, 500);
  }
}
 
function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json" },
  });
}
 
// Vercel Edge entry point.
export const config = { runtime: "edge" };
export default handler;
