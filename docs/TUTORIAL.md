# RbxLuauLLM Tutorial (Authorized Use)

This tutorial explains how to use and extend RbxLuauLLM in **permissioned/dev/admin/testing contexts**.

---

## 1) Two common modes

### Translator mode (natural language → action)
Goal: Convert natural language into **one** actionable output.

Examples (depending on your integration):
- a single command string (e.g., `;fly 50`)
- a small Luau snippet (e.g., `humanoid.WalkSpeed = 50`)

Recommended prompt rules:
- Output only the action (no explanations)
- Keep outputs short and deterministic
- Prefer known command vocab / glossary if you have one

### Assistant mode (natural language → short response)
Goal: Provide short help text for your experience/testing.

Recommended prompt rules:
- 1–3 sentences
- Don’t claim to know hidden game logic
- If unsure, say so briefly

---

## 2) Validation → feedback → retry (optional but powerful)

Common failure:
- Model targets a player that doesn’t exist

Recommended flow:
1) User request: “bring ben”
2) Client collects player list: `[Ben_123, BennyGamer, ...]`
3) Model returns invalid target: `bring BennyGame`
4) Client retries with feedback:
   `[FEEDBACK ERROR: Target not found. Use only names from: ...]`
5) Model returns corrected output

This reduces “almost correct” hallucinations.

---

## 3) Extending command/code coverage

Great contribution areas:
- Expand a command glossary by category
- Add aliases (“speed”, “walkspeed”, “ws”)
- Add structured output (optional): return JSON and validate it
- Add “preview” mode for safety

---

## 4) Transport expectations

RbxLuauLLM expects an OpenAI-style chat shape at:

`POST /v1/chat/completions`

Body:
- `model`
- `messages`
- `temperature` (optional)

Response:
- `choices[1].message.content`

See: `docs/WORKER.md`
