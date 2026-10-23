# TeamFlow Architecture Overview

## 1. System Context & Overview

TeamFlow is a production-style, multi-tenant project management SaaS featuring:
- **Mobile Client**: Flutter cross-platform mobile client with feature-first Clean Architecture, Riverpod state management, and Dio network client.
- **Backend API**: TypeScript / NestJS modular service adhering to SOLID principles, layered Clean Architecture, and strict tenant isolation.
- **Persistence**: PostgreSQL managed with Prisma ORM with audit timestamps, UUID primary keys, and strict foreign key constraints.
- **Security & Session Management**: Argon2id password hashing, short-lived JWT access tokens, and rotating refresh tokens hashed in a dedicated `Session` table with token-family reuse detection.

## 2. Monorepo Structure

```
teamflow/
├── apps/
│   ├── api/            # NestJS API backend
│   └── mobile/         # Flutter cross-platform client
├── packages/
│   └── api-contract/   # OpenAPI specification and shared contract models
├── infra/
│   └── docker-compose.yml
├── docs/
│   ├── architecture.md
│   ├── threat-model.md
│   ├── test-plan.md
│   └── adr/
├── .github/
│   └── workflows/ci.yml
├── README.md
└── .env.example
```

## 3. Backend Architecture (NestJS)

Layered architecture with clear module boundaries:
- **Presentation / Transport Layer**: NestJS Controllers mapping HTTP requests, validating input with DTOs and `class-validator`, enforcing authentication via Guards.
- **Application / Domain Layer**: NestJS Services implementing business logic, transaction boundaries, and tenant isolation policies.
- **Infrastructure / Persistence Layer**: PrismaService abstracting PostgreSQL access.

### Global Interceptors & Filters
- **Standardized Error Envelope**:
  ```json
  {
    "error": {
      "code": "ERROR_CODE",
      "message": "Human-readable explanation",
      "requestId": "uuid",
      "details": {}
    }
  }
  ```
- **Logging & Request Context**: Request IDs propagated through all error and log boundaries.

## 4. Mobile Architecture (Flutter)

Feature-First Clean Architecture:
```
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── bootstrap.dart
├── core/
│   ├── network/        # Dio client, token interceptor, retry policy
│   ├── auth/           # Secure token storage & session holder
│   ├── errors/         # Typed Failures and exceptions
│   ├── theme/          # Design system tokens and styling
│   └── widgets/        # Shared presentation components
└── features/
    └── authentication/
        ├── data/       # DTOs, AuthRemoteDataSource, AuthRepositoryImpl
        ├── domain/     # User entity, AuthRepository interface, Use Cases
        └── presentation/ # Riverpod StateNotifier/AsyncNotifier, Login/Register screens
```
