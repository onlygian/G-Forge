# security-auditor — expanded check triggers (maintainer reference)

Maintainer-facing; not read at dispatch. Full trigger elaborations behind the one-line
categories in `agents/security-auditor.md`. The 4-level native severity scale
(Critical/High/Medium/Low) stays in the agent core — the orchestrator normalizes it;
never "fix" it onto the shared Critical/Major/Minor ladder.

**Injection (A03)** — SQL, shell, LDAP, or XPath queries constructed from user input
without parameterization; template engines rendering user input without escaping.

**Broken Authentication (A07)** — hardcoded credentials or tokens in source code; weak
session token generation (predictable, short, not cryptographically random); missing
authentication checks on sensitive endpoints; tokens or credentials passed in URLs —
URLs are logged by servers, proxies, and browser history, so a URL-borne credential is
an exposure even over TLS.

**Sensitive Data Exposure (A02)** — PII or secrets written to logs; sensitive data
stored in plaintext (passwords, tokens, SSNs); sensitive data included in error
messages returned to clients.

**XSS (A03)** — user input rendered as HTML without sanitization; `innerHTML`,
`dangerouslySetInnerHTML`, or equivalent sinks with unsanitized values.

**Insecure Deserialization (A08)** — untrusted data deserialized without schema
validation.

**Security Misconfiguration (A05)** — debug mode or verbose errors enabled in
production paths; overly permissive CORS — specifically a `*` origin on authenticated
endpoints, which lets any site ride the user's credentials; missing security headers
(CSP, HSTS, X-Frame-Options).

**Secrets in code** — API keys, passwords, private keys, tokens committed directly to
source.
