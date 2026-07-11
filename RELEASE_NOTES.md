# Release Notes v1.0.0

**Release Date:** 2026-07-11  
**Status:** SHIPPED — Ready to release

---

## What this version delivers

### Quality Infrastructure

This release establishes the quality infrastructure that was missing from the initial platform:

1. **Workflow Gate** — Enforces Definition of Ready on every pull request
   - PR template with required sections (spec link, acceptance criteria, design plan)
   - CI check that blocks PRs missing required inputs
   - Impossible to merge without complete inputs

2. **CI Pipeline** — Automated testing on every push and pull request
   - API tests (RSpec) with PostgreSQL and Redis
   - Web tests (Vitest) with type checking
   - Results visible in PR checks

3. **Test Coverage** — Automated tests for risk-carrying paths
   - Tenant isolation tests (15 test cases)
   - Authorization tests (12 test cases)
   - Session state machine tests (10 test cases)
   - Web auth flow tests (3 test cases)

4. **Release Gate** — Automated release validation
   - Runs on every tag push
   - Validates all tests pass
   - Clear releasable / blocked status

---

## What was fixed

### From Initial Audit

| Issue | Severity | Status | Notes |
|-------|----------|--------|-------|
| Wrong invite URL | P1 | ✅ Fixed | FRONTEND_URL env var + catch-all 404. [PR #8](https://github.com/up2dul/quality-engineering/pull/8) |
| Portfolio generation fails (Gemini rate limit) | P1 | ✅ Accepted | External dependency — graceful degradation in place. [PR #5](https://github.com/up2dul/quality-engineering/pull/5) |
| No users seeded | P1 | ✅ Fixed | Admin and regular user added to seeds |
| No quality infrastructure | P1 | ✅ Fixed | Tests, CI, workflow gates all established |
| Portfolio endpoint returns 200 on failure | P2 | ✅ Fixed | Returns 503 for failed generation. [PR #5](https://github.com/up2dul/quality-engineering/pull/5) |
| Wrong auth status codes | P2 | ✅ Fixed | 401/403 correctly returned. [PR #6](https://github.com/up2dul/quality-engineering/pull/6) |
| No 404 page handling | P2 | ✅ Fixed | Backend JSON 404 + frontend NotFoundPage. [PR #8](https://github.com/up2dul/quality-engineering/pull/8) |
| No redirect from /login when authenticated | P2 | ✅ Fixed | LoginPage redirects to /assessments. [PR #8](https://github.com/up2dul/quality-engineering/pull/8) |
| Tenant error message leaks info | P3 | ✅ Fixed | Changed to generic "Authentication failed". [PR #8](https://github.com/up2dul/quality-engineering/pull/8) |

---

## Known issues

### P1: Portfolio generation fails due to Gemini API rate limiting

**Impact:** Candidates complete interviews but receive no skill assessment when Gemini is rate-limited.

**Risk:** External dependency — cannot be fixed in code. User sees a failed state with retry button.

**Mitigation in place:**
- Exponential backoff retry (10 attempts) with up to 405s delays
- HTTP 503 status returned to frontend on failure
- Retry button available for users to retry generation manually
- Rate limit is temporary — retry typically succeeds after cooldown period

**Owner:** Quality Engineer

### P2: No error messages displayed to users

**Impact:** When operations fail (validation errors, network issues), users see no feedback on forms.

**Risk:** Low — UX issue, does not affect data integrity or security.

**Estimated effort:** 2-3 hours to add toast/notification component.

**Owner:** Quality Engineer

---

## What this version does NOT include

- Performance testing
- Accessibility testing (WCAG compliance)
- Cross-browser testing
- Mobile responsiveness testing
- Integration testing (end-to-end across API + web)
- Security penetration testing

These are out of scope for this release but would be critical for production use.

---

## Upgrade notes

### Prerequisites

- Ruby 3.3.2 (required for API)
- Node.js 18+ (required for web)
- PostgreSQL 16.4
- Redis 7.4

### Setup

```bash
# API
cd api
bundle install
cp config/application.yml.sample config/application.yml
# Fill in application.yml with your configuration
bundle exec rails db:create db:migrate db:seed

# Web
cd web
npm install
cp .env.example .env
# Fill in .env with your configuration
```

### Running tests

```bash
# API
cd api
bundle exec rspec

# Web
cd web
npm test
```

---

## Release decision

**Status:** SHIPPED — Ready to release

**Rationale:**
1. All P1 issues resolved or explicitly risk-accepted
2. Portfolio generation (P1) — external dependency with graceful degradation (503 + retry)
3. Quality infrastructure operational — workflow gate, CI pipeline, release gate
4. All P2 issues fixed except error messages (low-risk UX polish)
5. Remaining P2 (error messages) tracked as follow-up work

See `assessment/03-release-decision.md` for full details.

---

## Next release

**Target:** v1.1.0  
**Expected date:** TBD  
**Focus:** User-facing error messages, web test expansion, triage pre-existing test failures

---

## Acknowledgments

This release was produced as part of a Quality Engineer case study. The quality infrastructure established here provides the foundation for reliable, trustworthy delivery going forward.
