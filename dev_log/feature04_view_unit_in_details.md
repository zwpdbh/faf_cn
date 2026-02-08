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
- [ ] Create `user_roles` table (user_id, role, granted_by, granted_at)
- [ ] Create `unit_comments` table (unit_id, user_id, content, inserted_at, updated_at)
- [ ] Create `unit_edit_logs` table (unit_id, field, old_value, new_value, reason, edited_by, inserted_at)

### Phase 2: Authorization System
- [ ] Create `FafCn.Accounts.UserRoles` context
- [ ] Create `is_admin?/1` helper function
- [ ] Create super admin check (`zwpdbh` by email or provider_uid)
- [ ] Create admin-only navigation (Settings link)

### Phase 3: Admin Management Page
- [ ] Create `SettingsLive` for admin management (zwpdbh only)
- [ ] List all users with admin status
- [ ] Add/Remove admin buttons

### Phase 4: Unit Detail Page (Basic)
- [ ] Create `UnitLive.Show` LiveView
- [ ] Route: `/units/:unit_id`
- [ ] Display unit info (name, image 2x size, mass/energy/time)
- [ ] Add links from Eco Comparison unit names
- [ ] Require login to view (redirect to home with message if not logged in)

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

