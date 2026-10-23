# TeamFlow Test Plan (TDD)

## 1. Testing Pyramid

- **Backend Unit Tests**: Focus on pure business logic, security policies, token rotation logic, password hashing, and input validation without IO dependencies.
- **Backend Integration / E2E Tests**: Test controller to database queries with PostgreSQL test database, testing authorization, duplicate handling, and transactional boundaries.
- **Flutter Unit Tests**: StateNotifiers, repository implementations, network interceptors, token refresh queuing.
- **Flutter Widget Tests**: Form validation, loading states, error dialogues, navigation flows.

## 2. Test-Driven Development (TDD) Cycle

Every feature strictly follows the Red-Green-Refactor cycle:
1. **Red**: Write a test verifying the new requirement. Run test to verify it fails.
2. **Green**: Write the minimal code to satisfy the test. Run test to verify it passes.
3. **Refactor**: Clean up the implementation, improve abstractions, and ensure no regressions.

## 3. Foundation Test Matrix

| ID | Test Scenario | Expected Outcome |
|---|---|---|
| `AUTH-01` | Invalid credentials on `/auth/login` | Returns 401 with generic error envelope |
| `AUTH-02` | Valid registration on `/auth/register` | User created with argon2id hash, returns 201 |
| `AUTH-03` | Duplicate email registration | Returns 409 Conflict with standardized error code |
| `AUTH-04` | Refresh token exchange | Issues new access token + new refresh token |
| `AUTH-05` | Refresh token replay | Revokes entire session family, returns 401 |
| `AUTH-06` | Logout revocation | Revokes session immediately, returns 200 |
| `AUTH-07` | Protected `/me` endpoint | Returns user profile if valid JWT, 401 if missing/invalid |
| `HEALTH-01` | Liveness check `/health/live` | Returns 200 OK `{ status: "ok" }` |
| `HEALTH-02` | Readiness check `/health/ready` | Returns 200 OK `{ status: "ok", database: "connected" }` |
