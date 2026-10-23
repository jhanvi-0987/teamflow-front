# TeamFlow — Current Features Documentation

> **Status:** Production-Grade MVP Complete (Phases 1–5 Implemented & Verified)  
> **Last Updated:** October 2026  
> **Backend:** NestJS 10, Prisma 5, PostgreSQL 16, Socket.IO 4.8, Argon2id, JWT  
> **Mobile Client:** Flutter 3.29+, Riverpod 2.6, Dio 5.7, Flutter Secure Storage, Socket.IO Client 3.1  
> **Test Coverage:** 55 Backend E2E Tests (100% Pass) | 35 Backend Unit Tests (100% Pass) | 24 Flutter Unit & Widget Tests (100% Pass)  

---

## 1. Visual & Design System

The application strictly implements an elegant, tailored luxury aesthetic with **zero gradients**:
- **Background & Canvas:** Warm Linen Ivory (`#F5EFE1`)
- **Cards & Surfaces:** Warm Sand Champagne (`#E5D3AF`)
- **Primary Brand & Accents:** Deep Crimson Burgundy (`#790D16`)
- **Typography:** Deep Charcoal (`#1F1A17`) and Muted Mocha (`#5C554F`)
- **Indicators:** Amber / Gold for Warnings, Emerald Green for Live Sync, Crimson for Errors

---

## 2. Implemented Features Breakdown

### 2.1 Authentication & Session Management
- **User Registration & Validation:**
  - Email normalization and strict validation (`class-validator`).
  - Passwords hashed using memory-hard **Argon2id**.
  - Duplicate account prevention with clear error feedback.
- **Dual-Token JWT Handshake & Storage:**
  - Short-lived Access Token (15 min) for API & WebSocket authorization.
  - Rotating Refresh Token (7 days) stored securely in `Session` table with family tracking.
  - Client credentials stored via `flutter_secure_storage` (`SecureTokenStorage`).
- **Session Revocation & Logout:**
  - Revokes session from server on logout.
  - Token refresh failure auto-clears client cache and redirects to Login.
- **REST Endpoints:**
  - `POST /api/v1/auth/register`
  - `POST /api/v1/auth/login`
  - `POST /api/v1/auth/refresh`
  - `POST /api/v1/auth/logout`
  - `GET /api/v1/me`

---

### 2.2 Multi-Tenant Workspaces & Role-Based Access Control (RBAC)
- **Workspace Tenant Isolation:**
  - Every project, task, member, and activity log is scoped to a `workspaceId`.
  - Strict database-level isolation verified on every controller and socket handler.
- **Role Hierarchy:**
  - `OWNER`: Full control, billing placeholder, workspace deletion, ownership transfer.
  - `ADMIN`: Member management, role adjustment, project creation, invitations.
  - `MANAGER`: Project & task assignment, status updates.
  - `MEMBER`: View permitted projects, task status progression, comment posting.
- **Invitations Flow:**
  - Time-limited, cryptographically random invitation tokens.
  - Accept (`/invitations/accept`) and decline (`/invitations/decline`) flows.
  - Prevents duplicate invitations or adding users already belonging to workspace.
- **REST Endpoints:**
  - `POST /api/v1/workspaces` — Create workspace.
  - `GET /api/v1/workspaces` — List user's workspaces.
  - `GET /api/v1/workspaces/:id` — Workspace details.
  - `PATCH /api/v1/workspaces/:id` — Update workspace name.
  - `POST /api/v1/workspaces/:id/transfer-ownership` — Transfer ownership.
  - `POST /api/v1/workspaces/:id/leave` — Leave workspace.
  - `GET /api/v1/workspaces/:id/members` — List members with roles.
  - `PATCH /api/v1/workspaces/:id/members/:userId` — Promote/demote member role.
  - `DELETE /api/v1/workspaces/:id/members/:userId` — Remove member.
  - `POST /api/v1/workspaces/:id/invitations` — Generate invitation.
  - `GET /api/v1/workspaces/:id/invitations` — View pending invitations.
  - `DELETE /api/v1/workspaces/:id/invitations/:invitationId` — Revoke invite.

---

### 2.3 Project Management
- **Keyed Identifiers:**
  - Each project has a short project key (e.g. `TF`, `PRJ`) unique per workspace.
- **Project Lifecycle:**
  - Creation, updating, archiving, and soft-delete capabilities.
  - Task count metrics and completion tracking.
- **REST Endpoints:**
  - `POST /api/v1/workspaces/:workspaceId/projects` — Create project.
  - `GET /api/v1/workspaces/:workspaceId/projects` — List projects.
  - `GET /api/v1/projects/:projectId` — Project metadata with stats.
  - `PATCH /api/v1/projects/:projectId` — Update name/description.
  - `POST /api/v1/projects/:projectId/archive` — Archive project.

---

### 2.4 Tasks & Dynamic Kanban Board
- **4-Stage Workflow Pipeline:**
  - `TODO` → `IN_PROGRESS` → `IN_REVIEW` → `DONE`.
  - Fast one-tap status advancement directly from Kanban cards.
- **Priority Tiering:**
  - `LOW`, `MEDIUM`, `HIGH`, `URGENT` with distinct color accents.
- **Optimistic Concurrency Control (OCC):**
  - Every task entity includes an atomic integer `version` field.
  - Updates require `version` match: `WHERE id = ? AND version = ?`.
  - Returns `409 CONFLICT` when another user has updated the task in the interim.
  - Client catches 409, alerts the user, and auto-refreshes to latest server state.
- **Filters & Search:**
  - Real-time text search across title and description.
  - Filter chips by status and priority.
  - Dual view modes: **Kanban Board** & **Task List**.
- **Cross-Platform Email User Assignment & Auto-Enrollment:**
  - Search any registered platform user by email or name (including users without any current workspace/group).
  - Assign task directly via `assigneeId` or `assigneeEmail`.
  - External assignees are automatically enrolled into the target workspace with `MEMBER` role, granting immediate access to the workspace and their assigned tasks.
- **REST Endpoints:**
  - `POST /api/v1/projects/:projectId/tasks` — Create task (supports `assigneeId` and `assigneeEmail`).
  - `GET /api/v1/projects/:projectId/tasks` — List & filter tasks (cursor paginated).
  - `GET /api/v1/tasks/:taskId` — Full task inspector with assignee & comments.
  - `PATCH /api/v1/tasks/:taskId` — Atomic update with version check and auto-membership on reassignment.
  - `PATCH /api/v1/tasks/:taskId/status` — Status transition with position & version.
  - `DELETE /api/v1/tasks/:taskId` — Soft deletion (`deletedAt`).
  - `GET /api/v1/users/search` — Platform-wide user search by email or name.


---

### 2.5 Task Comments & Audit Trail
- **Discussion Feed:**
  - Chronological comment threads on each task.
  - Author avatars, timestamps, and delete controls (authors & admins).
- **Append-Only Activity Log:**
  - System logs recorded in `ActivityLog` for task actions, comments, and state changes.
- **REST Endpoints:**
  - `POST /api/v1/tasks/:taskId/comments` — Add comment.
  - `GET /api/v1/tasks/:taskId/comments` — List comments.
  - `DELETE /api/v1/comments/:commentId` — Delete comment.

---

### 2.6 Real-Time WebSocket Collaboration
- **Socket.IO Gateway (`EventsGateway`):**
  - Handshake JWT authentication; rejects unauthenticated connections.
  - Room isolation by project: `project:<projectId>`.
  - Validates that the connecting user is an active workspace member before allowing room subscriptions.
- **Automatic REST-to-Socket Triggers:**
  - `task:created`: Broadcasts newly created tasks.
  - `task:updated`: Broadcasts title, description, priority, or assignee edits.
  - `task:status_changed`: Broadcasts Kanban column moves.
  - `task:deleted`: Broadcasts task removal.
  - `comment:created`: Broadcasts new discussion comments to active viewers.
- **Flutter Client Integration (`SocketService`):**
  - Auto-reconnection with backoff delay.
  - Riverpod subscription inside `ProjectDetailScreen` and `TaskDetailScreen`.
  - Visual **LIVE** emerald pulse indicator in the top AppBar.
  - Instant UI reactivity across devices without pulling down to refresh.

---

## 3. Architecture & Technical Stack

```
+-----------------------------------------------------------+
|                  Flutter Mobile Client                    |
|  - Riverpod State Management & Notifiers                  |
|  - Dio Network Layer + AuthInterceptor (JWT Auto-Refresh) |
|  - Socket.IO Client (Real-Time Subscriptions)             |
|  - SecureTokenStorage (iOS Keychain / Android Keystore)   |
+-----------------------------+-----------------------------+
                              |
                     HTTPS REST / WSS Events
                              |
+-----------------------------v-----------------------------+
|                     NestJS Backend API                    |
|  - Guards: JwtAuthGuard, RolesGuard, WorkspaceMemberGuard |
|  - EventsGateway: Socket.IO Gateway with JWT Handshake    |
|  - Modules: Auth, Users, Workspaces, Projects, Tasks,     |
|             Comments, Realtime, Health                    |
+-----------------------------+-----------------------------+
                              |
                         Prisma ORM
                              |
+-----------------------------v-----------------------------+
|                   PostgreSQL 16 Database                  |
|  - Tables: User, Session, Workspace, WorkspaceMember,     |
|            Invitation, Project, Task, Comment,            |
|            ActivityLog                                    |
|  - Indices: Multi-tenant compound keys, unique emails     |
+-----------------------------------------------------------+
```

---

## 4. Quality & Test Matrix

| Layer | Test Suite | Tests | Result |
|---|---|---|---|
| Backend | `auth.e2e-spec.ts` | 9 | Pass |
| Backend | `workspaces.e2e-spec.ts` | 17 | Pass |
| Backend | `projects-tasks.e2e-spec.ts` | 17 | Pass |
| Backend | `realtime.e2e-spec.ts` | 8 | Pass |
| Backend Total | **4 E2E Suites** | **51 tests** | **100% Pass** |
| Client | `auth_repository_test.dart` | 4 | Pass |
| Client | `auth_controller_test.dart` | 4 | Pass |
| Client | `workspaces_repository_test.dart` | 5 | Pass |
| Client | `projects_repository_test.dart` | 2 | Pass |
| Client | `tasks_repository_test.dart` | 4 | Pass |
| Client | `socket_service_test.dart` | 3 | Pass |
| Client | `widget_test.dart` | 1 | Pass |
| Client Total | **7 Test Suites** | **23 tests** | **100% Pass** |
| Static Analysis | `flutter analyze` | 0 issues | **Clean** |
