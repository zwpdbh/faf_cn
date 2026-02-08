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

## Setup Instructions

### 1. Create GitHub OAuth App
1. Go to https://github.com/settings/developers
2. Click "New OAuth App"
3. Fill in:
   - **Application name**: FAF CN Dev (or any name)
   - **Homepage URL**: `http://localhost:4000/`
   - **Authorization callback URL**: `http://localhost:4000/auth/github/callback`
4. Click "Register application"
5. Note down the **Client ID** and **Client Secret** (generate one if needed)

### 2. Set Environment Variables

**Option A: Export in terminal (temporary)**
```bash
export GITHUB_CLIENT_ID="your_client_id_here"
export GITHUB_CLIENT_SECRET="your_client_secret_here"
mix phx.server
```

**Option B: Create .env file (recommended)**
Create `.env` file in project root:
```bash
GITHUB_CLIENT_ID=your_client_id_here
GITHUB_CLIENT_SECRET=your_client_secret_here
```

Then run with:
```bash
source .env && mix phx.server
```

### 3. Test the Flow
1. Visit http://localhost:4000/
2. Click "Login" button
3. Authorize on GitHub
4. Should redirect back and show your avatar

## Troubleshooting

### Error: "GitHub OAuth credentials not configured"
**Cause**: Environment variables not set
**Fix**: Set `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` before starting server

### Error: "Authentication failed: %Assent.ServerUnreachableError{}"
**Cause**: This error occurs when the OAuth credentials are empty/invalid
**Fix**: 
1. Verify env vars are set: `echo $GITHUB_CLIENT_ID`
2. Restart the server after setting env vars
3. Check config is loaded: `Application.fetch_env!(:faf_cn, :oauth_providers)` in IEx

### Error: "Authentication failed: Invalid session"
**Cause**: Session expired or cookies cleared between request and callback
**Fix**: Try logging in again; ensure you're not blocking cookies

### Error: "provider uid could not be empty"
**Cause**: GitHub OAuth returns OpenID Connect format (`sub` for user ID, `preferred_username` for login, `picture` for avatar)
**Fix**: Fixed code to handle both formats:
- User ID: `user_info["sub"]` (OIDC) or `user_info["id"]` (GitHub API)
- Username: `user_info["preferred_username"]` (OIDC) or `user_info["login"]` (GitHub API)
- Avatar: `user_info["picture"]` (OIDC) or `user_info["avatar_url"]` (GitHub API)

## Debugging

To see what GitHub returns during OAuth, check your server logs:
```
[info] GitHub OAuth user_info: %{"id" => 12345, "login" => "username", ...}
```

If `id` is missing, there may be an issue with the OAuth token exchange.

## Problems to fix 

1. When I click login, it redirect to GitHub now for auth, then I got redirect back to homd page.
   Then, it shows error notificatin "Authentication failed: %Assets.ServerUnreachableError".

   Currently, I set github app setting as:
   home page: `http://localhost:4000/`
   Authorization callback URL: `http://localhost:4000/auth/github/callback`