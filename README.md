# RbxLuauLLM

An open-source LLM wrapper for Roblox Luau scripting and scripted actions: natural language → Luau/actions (or command strings), with a proxy-first security model and optional validation/retry. ([Example Working Project](https://github.com/BokX1/InfiniteYieldWithAI))

> ✅ Authorized use only  
> This project is intended for **your own Roblox experiences**, private test places, or other dev/admin/testing contexts where you have explicit permission.  
> Do not use this project to bypass restrictions, gain unauthorized advantages, or violate any platform/game terms.

---

## What it does

RbxLuauLLM provides a small pipeline that can be embedded into a Luau client:

- **Translator mode**: converts plain English into a single action (e.g., a command string or a small Luau snippet depending on your bridge).
- **Assistant mode**: returns short, context-aware help text (e.g., for your experience/testing session).

It can also support a **self-correcting retry loop**:
- if the model outputs an invalid target (common case: a player name that doesn’t exist), the client can re-prompt with feedback and try again.

---

## Why proxy-first matters (security)

This repo is open source. **Do not commit API keys**.

Recommended architecture:

**Luau client → Cloudflare Worker proxy → LLM provider**

Benefits:
- Provider keys stay server-side (Worker secrets)
- You can rate-limit, add allowlists, and monitor abuse
- You can require a per-user token header

See: `docs/WORKER.md`

---

## Documentation

- `docs/TUTORIAL.md` — How modes work + how to extend safely
- `docs/ARCHITECTURE.md` — Data flow + responsibilities
- `docs/WORKER.md` — Proxy contract + protections
- `docs/FAQ.md` — Common questions

---

## Contributing

PRs are welcome. Please read:
- `CONTRIBUTING.md`
- `SECURITY.md`
- `CODE_OF_CONDUCT.md`

Good starter contributions:
- Better validation/guardrails and “preview before execute”
- Prompt improvements to reduce hallucinations
- UI polish and accessibility
- Docs improvements and examples
- Additional adapters/bridges for different authorized systems

---

## License

Apache-2.0 (see LICENSE).
