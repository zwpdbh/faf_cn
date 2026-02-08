# Feature02 -- Auth

## Goal

1. User could login using GitHub account (extensible for Google/Microsoft later)

## Plan

### Phase 1: Database & Schema
- [x] Create users table migration
- [x] Create `FafCn.Accounts.User` schema
- [x] Create `FafCn.Accounts` context

### Phase 2: OAuth Integration
- [x] Add `assent` dependency
- [x] Configure GitHub OAuth credentials
- [x] Create `FafCnWeb.AuthController` (request/callback/logout)

### Phase 3: Session Management
- [x] Create session plug to fetch current user
- [x] Add session handling in router
- [x] Create LiveView auth hooks

### Phase 4: UI
- [x] Add user menu to navbar (avatar + logout dropdown)
- [x] Update EcoGuidesLive with auth hook

## Next Steps

To use GitHub OAuth:

1. Create a GitHub OAuth App at https://github.com/settings/developers
2. Set environment variables:
   ```bash
   export GITHUB_CLIENT_ID="your_client_id"
   export GITHUB_CLIENT_SECRET="your_client_secret"
   ```
3. Visit `/auth/github` to login
4. User will be redirected back with session set

## Extending to Google/Microsoft

To add more providers:

1. Add provider config in `config/runtime.exs` and `config/dev.exs`
2. Update `AuthController.request/2` and `callback/2` with new provider cases
3. Add provider buttons to the user menu component

Example for Google:
```elixir
# config/dev.exs
google: [
  client_id: System.get_env("GOOGLE_CLIENT_ID", ""),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET", ""),
  redirect_uri: "http://localhost:4000/auth/google/callback"
]

# auth_controller.ex
def request(conn, %{"provider" => "google"}) do
  # Use Assent.Strategy.Google
end
```

## Design Decisions

- Use **Assent** library - single library, supports multiple providers natively
- Store minimal user data: email, provider, provider_uid, name, avatar_url
- Session-based auth (simple, no JWT complexity)

## Progress Log

### 2026-02-08
- Phase 1-4 completed
- Created comprehensive test suite:
  - `test/faf_cn/accounts_test.exs` - 21 tests for Accounts context
  - `test/faf_cn_web/controllers/auth_controller_test.exs` - Tests for OAuth flow
  - `test/faf_cn_web/plugs/fetch_user_test.exs` - Tests for session plug
  - `test/faf_cn_web/live/user_auth_test.exs` - Tests for LiveView auth hooks
- Added test helpers to `conn_case.ex`:
  - `user_fixture/1` - Creates test users
  - `log_in_user/2` - Simulates logged in session
- All 37 tests passing
- Updated home page to use `Layouts.app` with user menu:
  - Modified `PageController.home/2` to pass `current_user`
  - Wrapped home template with navigation header
  - Shows Login button when not authenticated
  - Shows user avatar + dropdown when authenticated

### Test Commands
```bash
# Run all tests
mix test

# Run specific test file
mix test test/faf_cn/accounts_test.exs
mix test test/faf_cn_web/controllers/auth_controller_test.exs
```

