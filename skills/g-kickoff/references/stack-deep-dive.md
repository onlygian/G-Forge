# g-kickoff Step 1 Group 4 — stack deep dive questions

Load when the interview reaches Group 4 (Group 3 answers in hand). Go through each technology mentioned in Group 3 and each integration dimension below. Ask the questions that aren't already answered — don't repeat what the developer already told you.

*For each committed technology (framework, language, runtime):*
- "You mentioned [tech]. What alternatives did you consider and rule out, and why [tech]?"
- "What's the team's actual experience with [tech] — have you shipped something with it before?"

*Integration map — ask about each of these explicitly if not already covered:*
- **Auth:** Are users logging in? Which provider — Supabase Auth, Auth0, Firebase, Clerk, custom JWT, or something else?
- **Database:** What are you storing? Relational or document? Which engine (Postgres, MySQL, SQLite, MongoDB, etc.)?
- **File storage:** Any uploads, images, or documents to store? (S3, Cloudflare R2, Supabase Storage, local?)
- **Real-time:** Any live updates, chat, notifications, or presence? (WebSockets, SSE, polling?)
- **External APIs:** Which third-party services does this call? (payment processors, maps, email, SMS, analytics?)
- **Deployment target:** Where does this run — Vercel, Netlify, VPS, Railway, AWS, self-hosted, local only?
- **CI/CD:** Any automated testing or deployment pipeline already in place or planned?

Wait for answers before proceeding.
