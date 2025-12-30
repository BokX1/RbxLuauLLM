# FAQ

## Why not store provider keys in the Lua/Luau client?
Because open-source client code can be copied. Keys will be harvested and abused.
Use a server-side proxy (Cloudflare Worker) with secrets.

## Is this only for “commands”?
No. The output can be a command string or a Luau action/snippet — it depends on your adapter/bridge.

## Why add retries?
Models often output “almost correct” targets. Validation + feedback improves reliability.

## What contributions are most helpful?
- Preview-before-execute safety toggle
- Better validation/guardrails
- Prompt improvements (reduce hallucinations)
- UI polish and accessibility
- More robust parsing and error handling

## Do you accept PRs that help bypass permissions?
No. This project is for authorized environments only.
