````md
# Cloudflare Worker Proxy (Recommended)

Goal: keep LLM keys out of client code and out of git history.

---

## Client contract

RbxLuauLLM sends:

POST `/v1/chat/completions`  
Headers:
- `Content-Type: application/json`
- (optional) `X-Client-Token: <token>`

Body:
```json
{
  "model": "your-model",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "temperature": 0.3
}
````

Expected response:

```json
{
  "choices": [
    { "message": { "content": "..." } }
  ]
}
```

---

## Recommended protections

Minimum:

* Store provider keys as Worker **Secrets**
* Rate limit (by IP or token)
* Clear errors (401 missing token, 429 rate limited)

Nice-to-have:

* Per-user token allowlist
* Abuse monitoring + automatic blocks
* Minimal logging (avoid storing prompts by default)

---

## Open-source note

Never commit secrets (keys/tokens) to git.
Rotate keys immediately if exposed.

```
::contentReference[oaicite:0]{index=0}
```
