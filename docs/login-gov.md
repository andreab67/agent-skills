# login-gov

Federal identity provider integration skill for login.gov. Knows the OIDC authorization code flow, `private_key_jwt` client authentication, ACR/AAL value selection, and the Partner Portal setup process for both sandbox and production.

## Install

```bash
npx skills add andreab67/agent-skills@login-gov -g -y
```

## What it does

Guides the full login.gov OIDC integration: key pair generation, Partner Portal configuration, authorization request construction, callback handling, token exchange with `private_key_jwt`, `id_token` validation, and `userinfo` attribute fetching. Also covers ACR value selection for different identity assurance levels (auth-only through PIV/CAC) and the production deployment checklist.

## Authentication flows

| Flow | When to use |
|------|------------|
| **Authorization code + `private_key_jwt`** | Web applications (required — no client secrets) |
| **Authorization code + PKCE** | Native mobile apps |
| **SAML** | Legacy agency systems (login.gov supports it, but OIDC is preferred) |

## ACR levels at a glance

| ACR value | Assurance | Typical use case |
|-----------|-----------|-----------------|
| `urn:acr.login.gov:auth-only` | Password + optional MFA | Authenticated access, no identity proof needed |
| `urn:acr.login.gov:verified` | IAL2 (no facial match) | Benefits, grants, regulated services |
| `urn:acr.login.gov:verified-facial-match-required` | IAL2 + biometric | High-value transactions |
| `urn:acr.login.gov:verified-facial-match-preferred` | IAL2 + biometric (optional) | Upgrade path for users without cameras |

## Example prompts

- *"How do I integrate our agency web app with login.gov for federal SSO?"*
- *"Generate the `private_key_jwt` client assertion for the token exchange."*
- *"What ACR value do I use if I need identity verification but not facial recognition?"*
- *"My token request is returning `invalid_client`. What could cause that?"*
- *"How do I request the user's SSN and address after they authenticate?"*
- *"Walk me through the production deployment checklist for login.gov."*
- *"Set up login.gov sandbox — what's the sandbox discovery URL and how do I create test users?"*

## Common errors and fixes

| Error | Cause |
|-------|-------|
| `invalid_client` | Wrong `client_id` or key pair mismatch — verify both match the Partner Portal registration |
| `invalid_request: nonce too short` | `nonce` must be ≥ 22 characters |
| `redirect_uri_mismatch` | URI not registered in Partner Portal (including trailing slash) |
| `invalid_scope` | Identity attribute scopes require `urn:acr.login.gov:verified` or higher |
| `exp` claim rejected | Client assertion JWT must be generated fresh per request — max 5-minute validity |

## Prerequisites

- US federal agency (login.gov is restricted to federal agencies and their contractors)
- Inter-Agency Agreement (IAA) with GSA signed for production use
- Account at [dashboard.int.identitysandbox.gov](https://dashboard.int.identitysandbox.gov) for sandbox
- RSA 2048-bit key pair (generated via `openssl`)

## Important notes

- Use the `sub` UUID as the stable user identifier, not email — email can change
- `state` and `nonce` must be ≥ 22 cryptographically random characters, stored server-side
- Sandbox and production use separate key pairs and separate Partner Portal registrations
- `client_secret` is explicitly not supported — `private_key_jwt` is mandatory for web apps

## What it won't do

- Non-federal identity providers (Okta, Auth0, Cognito, Entra ID)
- Private-sector applications
- Full SAML SP setup (OIDC is preferred; ask to confirm before going SAML)

## Related skills

- [`arcgis-enterprise-k8s`](./arcgis-enterprise-k8s.md) — if you need to front ArcGIS with federal identity
- [`ubuntu24-stig`](./ubuntu24-stig.md) — OS hardening for the server running the integration
