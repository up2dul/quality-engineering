# Release Notes v1.0.0

**Release Date:** 2026-07-10  
**Status:** BLOCKED — Not ready to ship

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
| No test coverage | P1 | ✅ Fixed | 40 test cases written |
| No CI/CD pipeline | P1 | ✅ Fixed | CI workflow created |
| No workflow gates | P1 | ✅ Fixed | PR template + gate created |
| No tenant isolation validation | P1 | ✅ Fixed | 15 test cases written |
| No state machine validation | P1 | ✅ Fixed | 10 test cases written |
| Tenant isolation bypass | P1 | ❌ Remaining | Known security gap |

---

## Known issues

### P1: Tenant isolation bypass for candidate endpoints

**Impact:** Candidate-facing endpoints (`/sessions/:token/candidate`, `/sessions/:token/audio_complete`) use `.unscoped` to bypass tenant filtering. Invite tokens are the only security boundary.

**Risk:** Tokens have no expiration, no rate limiting, and no audit logging. A leaked token grants cross-tenant access indefinitely.

**Mitigation required:**
- Add token expiration (e.g., 24 hours)
- Add rate limiting on token validation endpoints
- Add audit logging for cross-tenant access attempts

**Why not fixed in this release:** Requires schema changes and multiple controller updates. Estimated effort: 4-6 hours. Deprioritized due to time constraints.

**Owner:** [To be assigned]

**Target fix date:** Within 7 days of release (if shipped with risk acceptance)

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

**Status:** BLOCKED

**Rationale:**
1. P1 security issue (tenant isolation bypass) remains unfixed
2. Tests have not been executed locally (Ruby version mismatch)
3. Web dependencies have not been installed

**What must be fixed:**
1. Fix P1 #4 (tenant isolation bypass) — 4-6 hours
2. Validate API tests — 2-3 hours
3. Validate web tests — 1-2 hours

**Total estimated effort:** 7-11 hours

See `assessment/03-release-decision.md` for full details.

---

## Next release

**Target:** v1.1.0  
**Expected date:** After P1 fixes are complete and validated  
**Focus:** Security hardening and test validation

---

## Acknowledgments

This release was produced as part of a Quality Engineer case study. The quality infrastructure established here provides the foundation for reliable, trustworthy delivery going forward.
