# Legislation System - Implementation Guide

## Overview
This document outlines the complete legislation system that has been integrated into the `un-government` script. This system allows Governors and Senators to propose laws, government officials to vote on them, and the Governor to veto proposals.

---

## Features Implemented

### ✅ Client-Side (HTML/CSS/JS)
- **Legislation Tab** in government dashboard with gavel icon
- **Three-Filter System**: Active Laws, Proposed Laws, Vetoed Laws
- **Propose Law Modal**: Title (max 200 chars), Description (max 5000 chars), Vote Duration (24-168 hours)
- **View Law Modal**: Detailed view with vote results, description, proposer info
- **Vote Buttons**: Yes/No voting for government officials
- **Veto Button**: Governor-only veto functionality with confirmation
- **Status Badges**: Visual indicators (ACTIVE LAW, IN VOTING, VETO'D)
- **Vote Progress Bars**: Real-time visualization of yes/no vote percentages
- **Purple Theme**: Matches existing un-admin aesthetic

### ✅ Server-Side (Lua)
- **Permission System**: `propose_laws` (Governor/Senator), `veto_laws` (Governor only)
- **5 Server Callbacks**:
  - `un-government:server:getLaws` - Fetch laws by status filter
  - `un-government:server:proposeLaw` - Create new law proposal
  - `un-government:server:getLawDetails` - Get detailed law information
  - `un-government:server:voteOnLaw` - Cast yes/no vote
  - `un-government:server:vetoLaw` - Governor veto
- **Auto-Processing**: Cron job runs every 10 minutes to check expired votes
- **Vote Validation**: Prevents double voting, checks quorum, calculates pass threshold
- **Notifications**: TriggerClientEvent notifications for law proposals, passes, vetoes

### ✅ Database
- **`government_laws` table**: Stores all law data (title, description, status, dates, proposer info)
- **`government_law_votes` table**: Records individual votes with unique constraint
- **Status Enum**: 'proposed', 'active', 'vetoed', 'failed'
- **Indexes**: Optimized for filtering by status and date

### ✅ Configuration
- **Config.Legislation**: 
  - `canProposeLaws`: ['governer', 'senator']
  - `canVetoLaws`: ['governer']
  - `minVoteDuration`: 24 hours
  - `maxVoteDuration`: 168 hours (7 days)
  - `passThreshold`: 51% (simple majority)
  - `requiresQuorum`: true
  - `quorumPercent`: 60%
  - `createDocumentOnPass`: true (integrates with unstable-documents)

---

## Installation Steps

### 1. Database Setup
Run the SQL file to create required tables:
```bash
# Navigate to the un-government folder
cd resources/[02UNSTABLE]/[SCRIPTS]/[UNSTABLE]/un-government

# Execute the SQL file in your MySQL database
mysql -u your_username -p your_database < legislation_tables.sql
```

Or manually execute in HeidiSQL/phpMyAdmin:
- Open `legislation_tables.sql`
- Copy and execute the SQL commands
- Verify tables `government_laws` and `government_law_votes` are created

### 2. Restart the Resource
```
restart un-government
```

### 3. Verify Installation
- Check server console for: `^2[un-government]^7 Government system loaded successfully`
- Check for any SQL errors in console
- Verify tables exist in database

---

## Usage Guide

### For Governors & Senators

#### Proposing a Law
1. Open government dashboard: `/gov`
2. Click the **Legislation** tab
3. Click **Propose New Law** button
4. Fill in:
   - **Law Title**: Clear, descriptive title (max 200 characters)
   - **Description**: Full law text and details (max 5000 characters)
   - **Vote Duration**: How long voting will be open (24-168 hours)
5. Click **Propose Law**
6. All government officials will be notified

#### Viewing Proposed Laws
1. Go to **Legislation** tab
2. Click **Proposed** filter
3. See all laws currently in voting
4. Click **View Details** on any law

### For All Government Officials

#### Voting on Laws
1. Open **Legislation** > **Proposed** tab
2. Click **View Details** on a law
3. Read the full description
4. Click **Vote Yes** or **Vote No**
5. Vote is recorded (cannot change after submission)
6. View live vote percentages

### For Governor Only

#### Vetoing a Law
1. Open any **Proposed** law details
2. Click **Veto Law** button (only visible to Governor)
3. Confirm the veto action
4. Law immediately moves to **Veto'd** status
5. Voting is terminated and cannot be reversed

### For Everyone

#### Viewing Active Laws
1. Go to **Legislation** > **Active** tab
2. See all passed laws currently in effect
3. Click **View Details** to read full law text
4. Shows when law was proposed and passed

#### Viewing Vetoed Laws
1. Go to **Legislation** > **Veto'd** tab
2. See laws that were vetoed by Governor
3. View veto date and who vetoed

---

## Technical Details

### Vote Processing Logic

**When a Vote Expires:**
1. System checks every 10 minutes for laws where `end_time < NOW()`
2. Counts yes votes and no votes
3. Checks quorum (60% of Senators + Governor must vote)
4. Calculates yes percentage
5. If quorum met AND yes ≥ 51%:
   - Status changes to `active`
   - Law is passed
   - Document created in unstable-documents (if enabled)
6. If quorum not met OR yes < 51%:
   - Status changes to `failed`
   - Law is rejected

**Vote Validation:**
- Each citizen can only vote once per law (enforced by unique constraint)
- Voting closes when `end_time` is reached
- Governor can veto at any point before vote expires
- Only government officials can vote

### Permission Hierarchy

| Role | Propose Laws | Vote on Laws | Veto Laws |
|------|--------------|--------------|-----------|
| Governor | ✅ Yes | ✅ Yes | ✅ Yes |
| Senator | ✅ Yes | ✅ Yes | ❌ No |
| Other Gov Officials | ❌ No | ✅ Yes | ❌ No |
| Citizens | ❌ No | ❌ No | ❌ No |

### Status Flow Diagram
```
[Proposed] ──(Voting Period)──┬──> [Active] (passed)
             │                 │
             │                 ├──> [Failed] (rejected/no quorum)
             │                 │
             └──(Governor)────> [Vetoed]
```

---

## Integration with Other Systems

### Unstable-Documents Integration
When a law passes (status changes to 'active'), the system triggers:
```lua
TriggerEvent('unstable-documents:server:createLawDocument', {
    title = law.title,
    content = law.description,
    author = law.created_by_name,
    lawId = law.id
})
```

You may need to add this event handler in `unstable-documents` if it doesn't exist:
```lua
RegisterNetEvent('unstable-documents:server:createLawDocument', function(data)
    -- Create a legal statute document
    -- Your unstable-documents logic here
end)
```

### QBCore Notifications
The system uses QBCore notifications:
- New law proposed: Notifies all players
- Law passed: Notifies all players
- Law vetoed: Notifies all players
- Vote recorded: Notifies voter only

---

## Configuration Options

### Adjusting Vote Duration
Edit `config.lua`:
```lua
Config.Legislation = {
    minVoteDuration = 24, -- Minimum hours (1 day)
    maxVoteDuration = 168, -- Maximum hours (7 days)
    defaultVoteDuration = 72, -- Default (3 days)
}
```

### Changing Pass Threshold
```lua
Config.Legislation = {
    passThreshold = 51, -- Percentage needed to pass (51 = simple majority)
    requiresQuorum = true, -- Require minimum turnout
    quorumPercent = 60, -- Minimum turnout percentage
}
```

### Disabling Document Creation
```lua
Config.Legislation = {
    createDocumentOnPass = false, -- Don't create documents
}
```

### Adding More Roles to Propose
```lua
Config.Legislation = {
    canProposeLaws = {
        'governer',
        'senator',
        'cityhallgm', -- Add city hall general manager
    },
}
```

---

## File Changes Summary

### New Files Created
- `legislation_tables.sql` - Database schema
- `LEGISLATION_GUIDE.md` - This documentation

### Modified Files
- `html/index.html` - Added Legislation tab, propose modal, view modal
- `html/script.js` - Added ~350 lines of legislation JavaScript functions
- `html/style.css` - Added ~300 lines of legislation CSS styles
- `config.lua` - Added Config.Legislation section, updated Config.Tables
- `server/main.lua` - Added 5 server callbacks + auto-processing logic

---

## Troubleshooting

### "Player not found" Error
- Ensure player is logged in properly
- Check QBCore is loaded

### "You don't have permission" Error
- Verify player job is 'governer' or 'senator' for proposing
- Check Config.Legislation.canProposeLaws array
- Verify job name matches exactly (spelling)

### Legislation Tab Not Visible
- Check player has `propose_laws` permission in Config.GovernmentJobs
- Verify HTML includes the tab with `data-permission="propose_laws"`
- Check JavaScript permission checking

### Votes Not Processing
- Check server console for errors in auto-processing cron
- Manually trigger: `TriggerEvent('un-government:server:processExpiredLawVotes')`
- Verify `end_time` is in the past
- Check vote counts meet quorum/threshold

### CSS Not Applied
- Clear browser cache (F5 in game)
- Verify `style.css` is linked in `index.html`
- Check for CSS syntax errors in console

### Database Errors
- Verify tables exist: `SHOW TABLES LIKE 'government_laws%'`
- Check foreign key constraints are created
- Ensure unique constraint on law_votes

---

## Testing Checklist

- [ ] Database tables created successfully
- [ ] Resource restarts without errors
- [ ] Legislation tab visible to Governor/Senator
- [ ] Propose law modal opens and submits
- [ ] Law appears in Proposed tab
- [ ] Vote buttons work for government officials
- [ ] Double voting is prevented
- [ ] Vote percentages update correctly
- [ ] Governor can veto proposed laws
- [ ] Vetoed laws appear in Veto'd tab
- [ ] Auto-processing runs every 10 minutes
- [ ] Passed laws move to Active tab
- [ ] Failed laws are removed/flagged
- [ ] Notifications are sent correctly
- [ ] CSS styling matches purple theme
- [ ] Modal close buttons work

---

## Future Enhancements (Optional)

### Possible Additions
1. **Amendment System**: Allow amending active laws
2. **Law Categories**: Organize laws by type (criminal, civil, tax, etc.)
3. **Vote History**: Show individual voter records to admins
4. **Public Voting**: Allow citizens to vote on certain laws
5. **Law Expiration**: Auto-expire laws after X days
6. **Vote Comments**: Allow voters to add comments explaining their vote
7. **Email Integration**: Send email notifications when laws are proposed
8. **Law Search**: Full-text search through law titles/descriptions
9. **Vote Reminders**: Notify officials who haven't voted yet
10. **Law Statistics**: Dashboard with pass/fail rates, most active proposers

---

## Support

If you encounter issues:
1. Check server console for errors
2. Verify database tables exist and have data
3. Check QBCore is up to date
4. Review this guide's troubleshooting section
5. Test with a fresh database (dev environment)

---

## Credits

**Developed for:** un-government FiveM resource  
**System:** QBCore Framework  
**Features Migrated From:** ap-government, ap-court  
**UI Theme:** Purple theme matching un-admin  
**Database:** MySQL/MariaDB via oxmysql  

---

## Version History

### v1.0.0 (Initial Release)
- Complete legislation system implementation
- Client-side UI with 3-tab filter system
- Server-side vote processing and validation
- Database schema with optimized indexes
- Auto-processing cron job
- Governor veto functionality
- Integration with unstable-documents
- Comprehensive configuration options
