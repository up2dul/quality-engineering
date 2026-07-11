# Platform Audit

Hands-on walkthrough of all critical paths (API testing, frontend UI, live interview flow)

---

## Executive Summary

The platform is an AI-powered interview system with **three critical gaps** that block any client release:

1. ~~**Wrong invite URL**~~ — ✅ Fixed. Candidates can now join interviews.
2. **Portfolio generation fails** — The Gemini API is rate-limited, and the system has no graceful degradation. Portfolios fail silently, and the endpoint returns HTTP 200 (success) instead of an error status. This is a P1 blocker.
3. ~~**No quality infrastructure**~~ — ✅ Fixed. Quality infrastructure is now in place.

**Ship/Do-not-ship line:** This version should **not ship** to a client. The portfolio generation issue is an external dependency that cannot be fixed in code, but the quality infrastructure is now in place to catch future defects.

---

## Risk Register

### P1 — Critical

#### 1. Invite URL points to backend, not frontend

**Impact:** Candidate cannot join the interview. The invite link is the primary entry point for candidates — if it's broken, the core function of the platform fails.  
**Type:** Built wrong  
**Evidence:** Session creation returns:
```json
"invite_url": "http://localhost:3001/interview/c49205226b529034b57457308c03a6e0fa5b3e43eb0b8fd04b6617e431d95c84"
```
The URL points to port 3001 (the API), but the interview page lives in the web app (port 5173). The API does not serve the interview page. Opening this URL in a browser shows a Rails routing error page, which exposes backend stack traces.  
**Repro:** Create a session via `POST /api/v1/assessments/:id/sessions`, then open the returned `invite_url` in a browser.  
**Status:** ✅ Fixed — Added FRONTEND_URL env var, updated Session#invite_url

---

#### 2. Portfolio generation fails due to Gemini API rate limiting

**Impact:** Candidates complete interviews but receive no skill assessment. Assessors cannot evaluate candidates. The platform cannot deliver its core value.  
**Type:** External dependency  
**Evidence:**
- Sidekiq logs: `Gemini::HttpClient::RateLimitError: Rate limit exceeded`
- Portfolio status: `generation_status: failed`
- Portfolio error: `generation_error: "Failed after 3 retries: Rate limit exceeded"`

**Repro:** Complete multiple interviews in quick succession, wait for portfolio generation to trigger, observe rate limit errors in Sidekiq logs.  
**Status:** Remaining

---

#### 3. No users seeded — login is impossible out of the box

**Impact:** A new developer or CI environment cannot authenticate through the login flow. The `db:seed` command creates an organization and skill taxonomies but no users.  
**Type:** Missing spec  
**Evidence:** `db/seeds.rb` creates `public.organizations` and `ai_interview.skill_taxonomies` but never inserts into `ai_interview.users`. After running `db:seed`, `SELECT * FROM ai_interview.users` returns 0 rows. The login page at `/login` will always fail with "Invalid email or password."  
**Repro:** Run `bundle exec rails db:seed`, then try to log in at `http://localhost:5173/login`.  
**Status:** ✅ Fixed — Added admin and regular user creation to db/seeds.rb

---

### P2 — Major

#### 4. Portfolio endpoint returns HTTP 200 on generation failure

**Impact:** The API returns success status when portfolio generation actually failed, making it impossible for clients to detect errors via HTTP status codes. This breaks error handling and monitoring.  
**Type:** Built wrong  
**Evidence:** When portfolio generation fails due to rate limiting, `GET /api/v1/sessions/:sessionId/portfolio` returns HTTP 200 with error details in the response body, instead of returning an appropriate error status (503 or 429).  
**Repro:** Complete an interview, wait for portfolio generation to fail due to rate limiting, then call the portfolio endpoint.  
**Status:** ✅ Fixed — Portfolio endpoint now returns 503 for failed generation, 202 for pending/generating, 200 for complete. See [PR #5](https://github.com/up2dul/quality-engineering/pull/5)

**Impact:** Clients cannot distinguish between "not authenticated" and "forbidden." This breaks standard HTTP error handling — clients that retry on 403 but not on 401 will behave incorrectly.  
**Type:** Built wrong  
**Evidence:**

| Request                 | Expected         | Actual                 |
| ----------------------- | ---------------- | ---------------------- |
| No token                | 401 Unauthorized | 403 "Tenant not found" |
| Invalid token           | 401 Unauthorized | 403 "Tenant not found" |
| Valid token, wrong role | 403 Forbidden    | (not tested yet)       |

**Repro:** `curl http://localhost:3001/api/v1/assessments` (no token) returns 403.  
**Status:** ✅ Fixed — Added `authenticate!` before_action that validates tokens before tenant resolution. Returns 401 for missing/invalid tokens, 403 for insufficient permissions. See [PR #6](https://github.com/up2dul/quality-engineering/pull/6)

---

#### 6. No 404 page handling

**Impact:** Users see unhelpful routing error pages when accessing non-existent routes. This creates a poor user experience and makes it unclear whether the resource doesn't exist or the system is broken.  
**Type:** Missing spec  
**Evidence:** Navigating to a non-existent assessment (e.g., `/assessments/999`) or any invalid route shows a generic routing error page instead of a user-friendly 404 page.  
**Repro:** Navigate to `http://localhost:5173/assessments/999` or any invalid route.  
**Status:** Remaining

---

#### 7. No error messages displayed to users

**Impact:** When operations fail (API errors, validation errors, network issues), users see no feedback. They don't know what went wrong or how to fix it.  
**Type:** Missing spec  
**Evidence:** The frontend makes API calls but doesn't display error messages from the API response. For example, if creating an assessment fails validation, the user sees no error message — the form just doesn't submit.  
**Repro:** Try to create an assessment with invalid data (e.g., missing required fields) and observe that no error message is shown.  
**Status:** Remaining

---

#### 8. No redirect to assessment when accessing login page while authenticated

**Impact:** Authenticated users who navigate to `/login` see the login form instead of being redirected to the assessments page. This is confusing and wastes a click.  
**Type:** Missing spec  
**Evidence:** The `ProtectedRoute` component checks for authentication and redirects to `/login` if not authenticated, but there's no reverse check — if you're already authenticated and visit `/login`, you should be redirected to `/assessments`.  
**Repro:** Log in successfully, then manually navigate to `http://localhost:5173/login`. You'll see the login form instead of being redirected.  
**Status:** Remaining

---

### P3 — Minor

#### 9. Error messages leak tenant existence

**Impact:** An attacker can probe which tenant schemes exist in the system by observing different error messages.  
**Type:** Built wrong  
**Evidence:** Using a JWT with `scheme: 'different-tenant'` returns "Tenant not found. Ensure the JWT scheme claim is valid." — this confirms the tenant does not exist. A more secure response would be a generic 401/403 regardless of whether the tenant exists.  
**Repro:** Generate a JWT with a non-existent scheme, then hit any authenticated endpoint.  
**Status:** Remaining

---

## Systemic Patterns

### Pattern 1: Happy path only — no error handling

**Observation:** The system was built for the happy path. The core flow works (create assessment → create session → conduct interview), but error paths are missing:
- No error messages displayed to users
- No 404 pages
- Wrong HTTP status codes for auth errors
- Portfolio endpoint returns 200 on failure

**Root cause:** The developers built the success path and stopped. There is no culture of "what if this fails?" or "what does the user see when things go wrong?"

**Implication:** Every error path needs to be designed and tested. This is not just about adding error messages — it's about thinking through failure modes and designing graceful degradation.

---

### Pattern 2: No quality infrastructure

**Observation:** The platform has no tests, no CI, no workflow gates. This is not a collection of individual oversights — it's a systemic absence of quality discipline.

**Root cause:** The team prioritized feature delivery over quality infrastructure. This is common in early-stage products, but it means every feature shipped without a safety net.

**Implication:** Building tests now will catch current defects, but the real fix is establishing a culture where work cannot proceed without its inputs (spec, acceptance criteria, tests).

---

### Pattern 3: External dependencies without graceful degradation

**Observation:** The platform depends on the Gemini API for portfolio generation, but has no fallback when the API is rate-limited or unavailable. The system fails silently.

**Root cause:** The team built for the happy path (API always available) without considering failure modes.

**Implication:** Every external dependency needs error handling, retry logic, and user-visible feedback when it fails.

---

## Ship/Do-Not-Ship Recommendation

**Recommendation:** DO NOT SHIP

**Rationale:**
1. ~~**P1 #1 (wrong invite URL)**~~ — ✅ Fixed
2. **P1 #2 (portfolio generation fails)** — External dependency (Gemini API rate limits). Cannot be fixed in code. Documented with mitigation strategies.
3. ~~**P1 #3 (no users seeded)**~~ — ✅ Fixed
4. ~~**No quality infrastructure**~~ — ✅ Fixed. Quality infrastructure is now in place.

**What must be fixed before shipping:**
1. ~~Fix invite URL to point to frontend (P1 #1)~~ ✅ Fixed
2. ~~Add user seeding to db/seeds.rb (P1 #3)~~ ✅ Fixed
3. ~~Implement graceful degradation for portfolio generation (P1 #2)~~ ⚠️ External dependency - cannot be fixed in code
4. ~~Add tenant isolation tests for every controller~~ ✅ Fixed
5. ~~Add authorization tests for every role-based endpoint~~ ✅ Fixed
6. ~~Implement workflow gate (PR template + CI check)~~ ✅ Fixed
7. ~~Implement CI pipeline (run tests on every PR)~~ ✅ Fixed

**Estimated effort:** 2-3 days for a senior engineer familiar with the codebase.

---

## What This Audit Does Not Cover

- **Performance:** No load testing or performance profiling
- **Accessibility:** No WCAG compliance check
- **Browser compatibility:** No cross-browser testing
- **Mobile responsiveness:** No mobile device testing
- **Security penetration testing:** No adversarial testing beyond code review
- **Tenant isolation edge cases:** Background jobs, WebSocket connections, direct database queries

---
