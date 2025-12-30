# Security Policy

## Reporting a vulnerability

If you find a security issue (key exposure, endpoint abuse, etc.), please report it privately:
- GitHub Security Advisory (preferred), or
- Contact the maintainer.

## Key principles

- **Never commit API keys**. Use a server-side proxy and store keys as secrets.
- Assume exposed keys are compromised: rotate immediately.
- Prefer authentication + rate limiting on the proxy endpoint.
- Avoid logging prompt contents by default.

## In scope

- Credential exposure
- Proxy abuse / rate-limit bypass
- Injection leading to unintended execution
- Data leakage through logs

## Out of scope

- Issues caused by using the project in unauthorized contexts
