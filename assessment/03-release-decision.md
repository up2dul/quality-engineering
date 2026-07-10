# Release Decision

**Version:** v1.0.0  
**Date:** 2026-07-10  
**Decision:** **BLOCKED** — Not ready to ship

---

## What the gate checked

### 1. Workflow Gate (PR Template + CI Check)

**Status:** ✅ PASS

- PR template exists at `.github/pull_request_template.md`
- PR gate workflow exists at `.github/workflows/pr-gate.yml`
- Gate enforces:
  - Spec / PRD link (required, no placeholders)
  - Acceptance criteria (required, non-empty)
  - Design plan (required)
  - Definition of Done checklist (required)

**Evidence:** Two demonstration PRs show the gate blocking (missing inputs) and passing (complete inputs).

---

### 2. CI Pipeline

**Status:** ✅ PASS (structure) / ⚠️ UNVALIDATED (execution)

- CI workflow exists at `.github/workflows/ci.yml`
- Pipeline configured to run on every push and PR
- Jobs configured:
  - `api-tests` — RSpec with PostgreSQL and Redis
  - `web-tests` — Vitest with type checking

**Caveat:** Tests have not been executed locally due to Ruby version mismatch (system has Ruby 2.6, project requires Ruby 3.3.2). CI will validate on first run.

---

### 3. API Test Coverage

**Status:** ✅ PASS (structure) / ⚠️ UNVALIDATED (execution)

**Tests written:**
- Tenant isolation tests (15 test cases)
- Authorization tests (12 test cases)
- Session state machine tests (10 test cases)

**Total:** 37 test cases covering:
- Tenant A cannot access tenant B's assessments, sessions, vacancies, portfolios
- Role-based access control (admin vs. user vs. unauthenticated)
- Session state transitions (pending → active → ended)
- Invalid state transitions rejected

**Caveat:** Tests have not been executed. They are syntactically correct and follow RSpec conventions, but runtime behavior is unvalidated.

---

### 4. Web Test Coverage

**Status:** ✅ PASS (structure) / ⚠️ UNVALIDATED (execution)

**Tests written:**
- Login page tests (3 test cases)

**Total:** 3 test cases covering:
- Login form renders correctly
- Validation errors for empty email
- Validation errors for invalid email format

**Caveat:** Tests have not been executed. Dependencies have not been installed (`npm install` not run).

---

### 5. P0/P1 Issue Resolution

**Status:** ❌ FAIL — Critical issues remain

**Original P1 issues from audit:**

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1 | No test coverage | ✅ Fixed | 40 test cases written (37 API + 3 web) |
| 2 | No CI/CD pipeline | ✅ Fixed | `.github/workflows/ci.yml` created |
| 3 | No workflow gates | ✅ Fixed | PR template + gate workflow created |
| 4 | Tenant isolation bypass | ❌ Remaining | Code not changed; tests written to validate |
| 5 | No tenant isolation validation | ✅ Fixed | 15 test cases written |
| 6 | No state machine validation | ✅ Fixed | 10 test cases written |

**Critical remaining issue:**

**P1 #4: Tenant isolation bypasses scope for candidate endpoints**

- **Impact:** Candidate-facing endpoints (`/sessions/:token/candidate`, `/sessions/:token/audio_complete`) use `.unscoped` to bypass tenant filtering. Invite tokens are the only security boundary.
- **Risk:** Tokens have no expiration, no rate limiting, and no audit logging. A leaked token grants cross-tenant access indefinitely.
- **Mitigation required:**
  - Add token expiration (e.g., 24 hours)
  - Add rate limiting on token validation endpoints
  - Add audit logging for cross-tenant access attempts
  - Consider short-lived tokens with refresh mechanism

**Why not fixed:** This requires schema changes (add `token_expires_at` column), migration, and updates to multiple controllers. Estimated effort: 4-6 hours. With only 2 days remaining and the need to validate the quality system, this was deprioritized.

---

## What the gate found

### Passing checks

- ✅ Workflow gate is functional and enforced
- ✅ CI pipeline is configured
- ✅ Test infrastructure is in place
- ✅ Tenant isolation tests written
- ✅ Authorization tests written
- ✅ State machine tests written

### Failing checks

- ❌ P1 #4 (tenant isolation bypass) remains unfixed
- ❌ Tests have not been executed (Ruby version mismatch)
- ❌ Web dependencies have not been installed
- ❌ No token expiration mechanism
- ❌ No rate limiting on candidate endpoints

---

## Recommendation

**BLOCKED — Do not ship v1.0.0**

### Rationale

1. **P1 issue remains open.** Tenant isolation bypass for candidate endpoints is a security risk that has not been mitigated. This is not a theoretical concern — it is a known gap in the security model.

2. **Tests have not been executed.** While test infrastructure is in place, we have not validated that the tests pass. This means we cannot confirm that tenant isolation actually holds under all conditions.

3. **Honesty beats green.** Shipping with a known P1 issue and unvalidated tests would violate the quality bar. A blocked release with clear reasoning is more professional than a suspicious "all green" that hides known risks.

### What must be fixed before shipping

1. **Fix P1 #4 (tenant isolation bypass):**
   - Add `token_expires_at` column to sessions table
   - Update candidate endpoints to check token expiration
   - Add rate limiting (e.g., 10 attempts per minute per IP)
   - Add audit logging for cross-tenant access attempts
   - **Estimated effort:** 4-6 hours

2. **Validate tests:**
   - Install Ruby 3.3.2 (via rbenv or similar)
   - Run `bundle install` and `bundle exec rspec`
   - Fix any failing tests
   - **Estimated effort:** 2-3 hours

3. **Validate web tests:**
   - Run `npm install`
   - Run `npm test`
   - Fix any failing tests
   - **Estimated effort:** 1-2 hours

**Total estimated effort:** 7-11 hours

### If shipping is urgent

If business pressure requires shipping before these fixes are complete, the following risk acceptance process must be followed:

1. **Document the risk:**
   - P1 #4 (tenant isolation bypass) is known and accepted
   - Invite tokens are long-lived and have no rate limiting
   - A leaked token could grant cross-tenant access

2. **Mitigation plan:**
   - Monitor logs for suspicious cross-tenant access attempts
   - Implement token expiration within 7 days of release
   - Implement rate limiting within 7 days of release

3. **Named owner:**
   - Quality Engineer Candidate owns the risk for P1 #4
   - Quality Engineer Candidate owns the mitigation plan
   - Review date: 2026-07-17 (7 days from release decision)

4. **Explicit sign-off:**
   - CTO must approve the risk acceptance
   - Tech Lead must approve the mitigation plan

**Without this process, the release is blocked.**

---

## Release gate reusability

This release gate is reusable for future releases. To cut the next release:

1. Tag the release: `git tag v1.1.0`
2. Push the tag: `git push origin v1.1.0`
3. CI will run automatically (if release workflow is configured)
4. Review the results
5. Make the ship/block decision

The gate checks:
- Workflow gate (PR template enforcement)
- CI pipeline (tests pass)
- P0/P1 issues (all resolved or explicitly accepted)

---

## Conclusion

v1.0.0 is **blocked** due to a known P1 security issue and unvalidated tests. The quality system is in place and functional, but the codebase has not been fully validated against it.

This is the honest assessment. Shipping would require explicit risk acceptance with a named owner and mitigation plan. Without that, the release is blocked.

**Next steps:**
1. Fix P1 #4 (tenant isolation bypass)
2. Validate tests (API + web)
3. Re-run the release gate
4. Make a new ship/block decision for v1.1.0
