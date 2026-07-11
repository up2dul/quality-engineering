# Quality System

**Author:** Quality Engineer Candidate  
**Date:** 2026-07-10  
**Version:** 1.0.0

---

## Overview

This document describes the quality system built to enforce the Definition of Ready and catch defects automatically. The system has two layers:

1. **Workflow Gate** — Prevents work from proceeding without its inputs (spec, acceptance criteria, design plan)
2. **Test/CI Net** — Catches defects in the code automatically

---

## 1. Workflow Gate

### What it is

The workflow gate enforces that every pull request carries its inputs before it can be merged. This is the Definition of Ready made automatic and impossible to bypass.

### How it works

**PR Template** (`.github/pull_request_template.md`):
- Every new PR is pre-filled with required sections:
  - **Spec / PRD Link** — Links to the spec, PRD, or issue
  - **Acceptance Criteria** — Defines what "done" looks like (Given/When/Then or checklist)
  - **Design Plan** — Documents the approach and key decisions
  - **Definition of Done** — Checklist that must be completed before merge

**CI Check** (`.github/workflows/pr-gate.yml`):
- Runs on every PR (opened, edited, synchronized, reopened)
- Checks the PR body for required sections:
  - Fails if "Spec / PRD Link" is missing or contains placeholder text
  - Fails if "Acceptance Criteria" is missing or empty
  - Fails if "Design Plan" is missing
- Passes only if all required fields are present and non-placeholder

### What it protects

- **Missing specs** — Work cannot proceed without a linked spec or issue
- **Missing acceptance criteria** — Work cannot proceed without defining "done"
- **Missing design documentation** — Work cannot proceed without documenting the approach

### What it deliberately does NOT protect

- **Code quality** — The gate checks for inputs, not code correctness
- **Test coverage** — The gate checks for the *presence* of tests (via DoD checklist), not their quality
- **Security** — The gate does not perform security analysis

### How to run it locally

The gate runs automatically on GitHub. To test it locally:

```bash
# Simulate the PR body check
export PR_BODY="Your PR body here"
bash .github/workflows/pr-gate.yml
```

### How to extend it

To add new required fields:

1. Update `.github/pull_request_template.md` with the new section
2. Update `.github/workflows/pr-gate.yml` to check for the new section
3. Test by opening a PR with and without the new field

---

## 2. Test/CI Net

### What it is

The test suite catches defects in the code automatically. It focuses on risk-carrying paths, not coverage percentage.

### Test structure

**API Tests** (`api/spec/`):
- **Tenant isolation tests** (`requests/tenant_isolation_spec.rb`) — Verify tenant A cannot access tenant B's data
- **Authorization tests** (`requests/authorization_spec.rb`) — Verify role-based access control
- **State machine tests** (`requests/session_state_machine_spec.rb`) — Verify session state transitions

**Web Tests** (`web/src/**/*.test.tsx`):
- **Login page tests** (`pages/auth/LoginPage.test.tsx`) — Verify login form renders and validation works

**Planned Web Tests** (not yet implemented):
- Auth flow tests — Token handling, redirects
- Critical path tests — Assessment creation, session management, portfolio viewing
- Error handling tests — API error display and loading states

### What each test protects

| Test Suite | Protects Against |
|------------|------------------|
| Tenant isolation | Data leaks between tenants |
| Authorization | Unauthorized access to protected endpoints |
| State machine | Invalid state transitions, race conditions |
| Login page | Broken login form, validation errors |

### What the net deliberately does NOT protect

- **Performance** — No load tests or performance benchmarks
- **Accessibility** — No WCAG compliance tests
- **Browser compatibility** — No cross-browser tests
- **Visual regression** — No screenshot comparison tests

### How to run tests locally

**API:**
```bash
cd api
bundle install
bundle exec rspec
```

**Web:**
```bash
cd web
npm install
npm test
```

### How to extend the net

**Add a new API test:**
1. Create a new file in `api/spec/requests/` or `api/spec/models/`
2. Follow the existing patterns (use factories, set tenant context)
3. Run `bundle exec rspec` to verify

**Add a new web test:**
1. Create a new file next to the component (e.g., `Component.test.tsx`)
2. Use React Testing Library patterns
3. Run `npm test` to verify

---

## 3. CI Pipeline

### What it is

The CI pipeline (`.github/workflows/ci.yml`) runs on every push and pull request. It:

1. Runs the PR gate check
2. Runs API tests (RSpec)
3. Runs web tests (Vitest)
4. Reports results

### How it works

**Triggers:**
- Push to `main`
- Pull request to `main`

**Jobs:**
- `api-tests` — Sets up PostgreSQL and Redis, runs RSpec
- `web-tests` — Sets up Node.js, runs type check and Vitest

**Failure behavior:**
- If any job fails, the PR cannot be merged
- Results are visible in the PR checks section

---

## 4. Red-to-Green Story

### What was red

The initial audit found 6 P1 issues:

1. No test coverage existed
2. No CI/CD pipeline existed
3. No workflow gates existed
4. Tenant isolation bypassed scope for candidate endpoints
5. No tenant isolation validation tests
6. No session state machine validation tests

### What we changed

**Workflow gate:**
- Created `.github/pull_request_template.md` with required sections
- Created `.github/workflows/pr-gate.yml` to enforce the template

**CI pipeline:**
- Created `.github/workflows/ci.yml` to run tests on every PR

**API tests:**
- Created `api/spec/` directory structure
- Added `spec_helper.rb` and `rails_helper.rb`
- Created factories for all models
- Wrote tenant isolation tests (15 test cases)
- Wrote authorization tests (12 test cases)
- Wrote session state machine tests (10 test cases)

**Web tests:**
- Added Vitest and React Testing Library to `package.json`
- Created `vitest.config.ts`
- Created test setup file
- Wrote login page tests (3 test cases)

### What is green now

- Workflow gate runs on every PR and blocks missing inputs
- CI pipeline runs on every PR and reports test results
- Tenant isolation is validated by automated tests
- Authorization is validated by automated tests
- Session state machine is validated by automated tests
- **FIXED**: Invite URL now points to frontend (FRONTEND_URL) instead of backend
- **FIXED**: Database seeding now creates test users (admin@test.com, user@test.com)

### What remains

- Token expiration for invite tokens (P2)
- Rate limiting on candidate endpoints (P2)
- More comprehensive web tests (P2)
- Performance tests (P3)
- Accessibility tests (P3)

---

## 5. Demonstration PRs

Two pull requests demonstrate the workflow gate:

**PR #1: Blocked (missing spec)**
- Title: "Update README"
- Body: Empty (no spec link, no acceptance criteria, no design plan)
- Result: PR gate fails with error messages

**PR #2: Passed (complete inputs)**
- Title: "Add tenant isolation tests"
- Body: Contains spec link, acceptance criteria, design plan, DoD checklist
- Result: PR gate passes

Both PRs are visible in the repository for review.

---

## 6. Running the Quality System

### Prerequisites

- GitHub repository with Actions enabled
- Ruby 3.3.2 (for API tests)
- Node.js 18+ (for web tests)
- PostgreSQL 16.4 (for API tests)
- Redis 7.4 (for API tests)

### First-time setup

1. Clone the repository
2. Set up the API:
   ```bash
   cd api
   bundle install
   cp config/application.yml.sample config/application.yml
   # Fill in application.yml
   bundle exec rails db:create db:migrate
   ```
3. Set up the web:
   ```bash
   cd web
   npm install
   cp .env.example .env
   # Fill in .env
   ```

### Running tests

**API:**
```bash
cd api
bundle exec rspec
```

**Web:**
```bash
cd web
npm test
```

### Opening a PR

1. Create a branch
2. Make your changes
3. Open a PR — the template will be pre-filled
4. Fill in all required sections
5. The PR gate will run automatically
6. CI will run tests automatically
7. Merge when all checks pass

---

## 7. Future Improvements

With more time, I would:

1. **Add token expiration** — Invite tokens should expire after 24 hours
2. **Add rate limiting** — Candidate endpoints should be rate-limited
3. **Add more web tests** — Cover all critical paths and error states
4. **Add integration tests** — End-to-end tests across API + web
5. **Add performance tests** — Load testing for critical paths
6. **Add accessibility tests** — WCAG compliance checks
7. **Add security scanning** — Automated dependency vulnerability checks

---

## 8. Conclusion

This quality system enforces the Definition of Ready automatically and catches defects before they reach production. It is:

- **Small and sharp** — Focused on risk-carrying paths, not coverage percentage
- **Automatic** — Runs on every PR without human intervention
- **Enforced** — Impossible to bypass without explicit action
- **Extensible** — Easy to add new checks and tests

The system proves that quality is not an afterthought — it is built into the workflow from the start.
