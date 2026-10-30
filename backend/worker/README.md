# Borj Portal API
Backend foundation for multi-building identity, unit relationships, invitations and server-side permissions.

## Provisioning
1. Create a Cloudflare D1 database named borjportal-core.
2. Put its UUID in wrangler.toml.
3. Apply migrations/0001_core.sql to the remote database.
4. Set a long random BOOTSTRAP_KEY Worker secret; never commit it.
5. Deploy this Worker to a workers.dev hostname.
6. Call POST /auth/setup once with X-Setup-Key and administrator email, full name, a password of at least 12 characters, and the first building name. The endpoint permanently locks after the first person is created.
7. Rotate/remove the bootstrap secret after setup.
8. Configure the frontend API base URL and replace demo role selectors with /auth/me permissions.

## Endpoints
GET /health
POST /auth/setup (one-time secret)
POST /auth/login
POST /auth/logout
GET /auth/me
POST /auth/accept-invite
GET|POST /buildings/:buildingId/units
POST /buildings/:buildingId/invitations

## Roles
manager, board, owner, resident, guard, technical, building_admin.

## Security model
PBKDF2-SHA-256 password hashes with random per-user salts; opaque random session tokens with only SHA-256 digests stored; HttpOnly Secure SameSite=None cookies; exact-origin CORS; permission checks in API routes; one-time 72-hour invitations; multi-building membership records.

## Outstanding before public rollout
Email verification, password reset and mail delivery; rate limiting or Turnstile; expanded unit-level authorization for each financial/document/guest endpoint; integration tests, monitoring, backups and retention policy. Invitation tokens must be delivered through a trusted channel until email is connected.

This repository scaffold is not a live backend until D1 is provisioned, the Worker secret is set, and the Worker is deployed.


## Expanded tower operations
Apply migrations/0002_operations.sql after the core migration. The operational data model and proposed REST contract are documented in docs/NEGIN-OPERATIONS-API.md. The static Negin management workspace currently uses browser-local storage and is not connected to this Worker or D1.
