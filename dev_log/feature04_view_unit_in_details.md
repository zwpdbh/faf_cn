# Feature04: View Unit in Details 

- Currently at right colum `Eco Comparison`, each unit is list.
- Improve it such that user could click its full name to direct to another page: View Unit 
  - It shows unit full name 
  - unit image 
  - unit mass, energy and build time 
  - below all of them is the user's comments about it.
- Because this is a dedicated page for displaying unit, the ui could be adjust to suit this purpose.
- User could also edit mass, enery, and build power 
  - Only admin could do this. 
- Any user could edit his own comment 


## Goal01: direct user to unit detail page 

## Goal02: user could edit unit mass, energy and build power.

## Goal03: user could edit comments 

## Goal04: create authorization system such that only some user could edit unit information. 

- Only user with admin level could do this. 
- User `zwpdbh` has full control to decide whether or not add or remove user into admin group. 

## Design Decisions (Completed)

### 1. Comments
- **Multiple comments per user per unit** (discussion style)
- **Plain text for now**, markdown support to be added later

### 2. Unit Edit History
- **Audit log required**: who, when, why edited
- **Visible to all users**, displayed nicely or on dedicated audit page

### 3. Unit Images
- Use **same sprite/icon system** as Eco Guide page
- **~2x size** of Eco Guide display (w-24 h-24 or similar)

### 4. Admin Management
- **"Settings" link** in navigation (only visible to zwpdbh)
- Manage admin users (grant/revoke admin rights)

### 5. Build Power
- **No new field needed**
- Display: mass, energy (build power), build time

### 6. Unit Detail Page URL
- `/units/:unit_id` (e.g., `/units/UEL0105`)

### 7. Comments Visibility
- **Logged-in users only**

---

## Implementation Plan

### Phase 1: Database Schema
- [x] Create `user_roles` table (user_id, role, granted_by, granted_at)
- [x] Create `unit_comments` table (unit_id, user_id, content, inserted_at, updated_at)
- [x] Create `unit_edit_logs` table (unit_id, field, old_value, new_value, reason, edited_by, inserted_at)

### Phase 2: Authorization System
- [x] Create `UserRoles` context functions in `Accounts`
  - `is_super_admin?/1` - Check if user is zwpdbh
  - `grant_admin_role/2` - Grant admin (super admin only)
  - `revoke_admin_role/2` - Revoke admin (super admin only)
  - `is_admin?/1` - Check if user has admin role
  - `list_admins/0` - List all admin users
- [x] Tests for authorization functions (13 tests)

### Phase 3: Admin Management Page
- [x] Create `SettingsLive` for admin management (zwpdbh only)
  - Super admin check on mount
  - Redirect non-super-admins with error message
- [x] List all users with admin status in table
- [x] Add/Remove admin buttons
- [x] Tests for SettingsLive (5 tests)

### Phase 4: Unit Detail Page (Basic)
- [x] Create `UnitLive` LiveView
- [x] Route: `/units/:unit_id`
- [x] Display unit info (name, image 2x size, mass/energy/time)
- [x] Display categories as badges
- [x] Add links from Eco Comparison unit names
- [x] Require login to view (uses `ensure_authenticated` hook)

### Phase 5: Comments System
- [ ] Create `FafCn.UnitComments` context
- [ ] Display comments list (newest first)
- [ ] Add comment form (bottom of comments)
- [ ] Edit/Delete own comments
- [ ] Timestamp display (relative: "2 hours ago")

### Phase 6: Admin Edit & Audit
- [ ] Editable form for unit stats (admin only, inline or modal)
- [ ] "Reason" field for edit (required)
- [ ] Save to `unit_edit_logs`
- [ ] Display edit history (collapsible section or separate tab)

### Phase 7: UI Polish
- [ ] Responsive layout for unit detail
- [ ] Better styling for comments
- [ ] Empty states (no comments yet)

---

## Progress Log

### 2026-02-08 - Phase 1 Complete
Created database schema and tests:

**Migrations:**
- `create_user_roles.exs` - Stores user roles (admin)
- `create_unit_comments.exs` - Stores user comments on units
- `create_unit_edit_logs.exs` - Audit log for unit stat edits

**Schemas:**
- `FafCn.Accounts.UserRole` - User role schema
- `FafCn.UnitComments.UnitComment` - Unit comment schema
- `FafCn.UnitEditLogs.UnitEditLog` - Unit edit log schema

**Tests:**
- `test/faf_cn/accounts/user_role_test.exs` - User role validation tests
- `test/faf_cn/unit_comments/unit_comment_test.exs` - Unit comment validation tests
- `test/faf_cn/unit_edit_logs/unit_edit_log_test.exs` - Unit edit log validation tests

All tests passing (50 tests).

### 2026-02-08 - Phase 2 Complete
Created authorization system in `FafCn.Accounts`:

**Functions:**
- `is_super_admin?/1` - Checks if user is zwpdbh (by email or provider_uid)
- `grant_admin_role/2` - Grants admin role (super admin only)
- `revoke_admin_role/2` - Revokes admin role (super admin only)
- `is_admin?/1` - Checks if user has admin role
- `list_admins/0` - Returns list of all admin users

**Tests:**
- `test/faf_cn/accounts/user_roles_test.exs` - 13 tests for authorization

All tests passing (63 tests).

### 2026-02-08 - Phase 3 Complete
Created admin management page:

**Files:**
- `lib/faf_cn_web/live/settings_live.ex` - Settings LiveView
- `lib/faf_cn_web/live/settings_live.html.heex` - Admin management UI

**Features:**
- `/settings` route (super admin only)
- User table with admin status
- "Make Admin" / "Remove Admin" buttons
- Auto-redirect with error for non-super-admins

**Tests:**
- `test/faf_cn_web/live/settings_live_test.exs` - 5 tests

All tests passing (68 tests).

### 2026-02-08 - Phase 4 Complete
Created unit detail page:

**Files:**
- `lib/faf_cn_web/live/unit_live.ex` - Unit detail LiveView
- `lib/faf_cn_web/live/unit_live.html.heex` - Inline template
- `test/faf_cn_web/live/unit_live_test.exs` - 4 tests

**Features:**
- `/units/:unit_id` route (e.g., `/units/UEL0105`)
- Large unit icon (2x size)
- Unit info: name, description, faction badge
- Economy stats: Mass, Energy, Build Time
- Categories displayed as badges
- "Back to Eco Guides" link
- Requires login (redirects if not authenticated)
- Links from Eco Comparison (unit names are now clickable)

**Tests:**
- Logged-in user can view unit detail
- Unit stats are displayed
- Non-logged-in user is redirected
- Non-existent unit returns error

All tests passing (72 tests).

