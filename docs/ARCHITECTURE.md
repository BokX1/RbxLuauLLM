# Architecture

RbxLuauLLM is designed as a small pipeline:

## A) UI / Input (optional)
- Collect text input
- Provide mode toggle (Translator / Assistant)
- Show status states (thinking/fixing)

## B) Context
- Local player name (optional)
- Current experience name (optional)
- Player list for targeting (optional)

## C) Prompt Router
Two system prompts:
- Translator prompt: strict “return only the action”
- Assistant prompt: short response, context-aware

Optional context injection:
- Include player list when request likely targets a player

## D) Transport
- Builds JSON:
  - model
  - messages
  - temperature
- Sends to your configured endpoint (proxy recommended)

## E) Validation + Retry (optional)
- Validate target existence, syntax, allowed output format
- Retry with explicit feedback
- Stop after `MaxRetries`

## F) Bridge / Adapter
- Executes final output:
  - run a command string, or
  - apply a Luau action, or
  - pass to your own system

This separation allows contributors to add adapters without changing the core prompting/transport logic.

---

## Data flow summary

User input
 → choose mode
 → build prompt (+ optional context)
 → HTTP request to endpoint
 → parse response
 → validate (optional)
 → retry if needed
 → execute via adapter (or display assistant text)
