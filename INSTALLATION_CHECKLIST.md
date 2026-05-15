# Legislation System - Installation Checklist

## ⚠️ IMPORTANT: Complete these steps in order

### Step 1: Database Setup ✅
**Action Required:** Run the SQL script to create tables

**Option A - Command Line:**
```bash
cd resources/[02UNSTABLE]/[SCRIPTS]/[UNSTABLE]/un-government
mysql -u your_username -p your_database < legislation_tables.sql
```

**Option B - HeidiSQL/phpMyAdmin:**
1. Open `legislation_tables.sql` file
2. Copy all SQL content
3. Paste into SQL query window
4. Execute the queries

**Verification:**
```sql
-- Check if tables exist
SHOW TABLES LIKE 'government_laws%';

-- Should return:
-- government_laws
-- government_law_votes
```

---

### Step 2: Restart Resource ✅
**Action Required:** Restart the un-government resource

**In Server Console:**
```
restart un-government
```

**Expected Output:**
```
^2[un-government]^7 Government system loaded successfully
```

**If you see errors:**
- Check MySQL connection
- Verify tables were created
- Check for syntax errors in server/main.lua

---

### Step 3: Test Basic Functionality ✅
**Action Required:** In-game testing

**Test as Governor or Senator:**
1. Log in as a character with `governer` or `senator` job
2. Type `/gov` in chat
3. Click **Legislation** tab (should be visible)
4. Click **Propose New Law** button
5. Fill in:
   - Title: "Test Law"
   - Description: "This is a test law proposal"
   - Duration: 24 hours
6. Click **Propose Law**
7. Check for success notification

**Expected Result:**
- ✅ Notification: "A new law has been proposed: Test Law"
- ✅ Law appears in **Proposed** tab
- ✅ Can click "View Details" to see full law

**If it doesn't work:**
- Check browser console (F8 in game, then F12)
- Check server console for errors
- Verify job name matches exactly ('governer' or 'senator')

---

### Step 4: Test Voting ✅
**Action Required:** Test the voting system

**Test as any Government Official:**
1. Open `/gov` dashboard
2. Go to **Legislation** > **Proposed**
3. Click **View Details** on the test law
4. Click **Vote Yes** (or **Vote No**)
5. Check for confirmation notification

**Expected Result:**
- ✅ Notification: "Your vote has been recorded"
- ✅ Modal closes automatically
- ✅ Vote percentage updates when viewing again
- ✅ Cannot vote again (error if attempted)

**If it doesn't work:**
- Check if player has government job
- Verify law is still in 'proposed' status
- Check server console for SQL errors

---

### Step 5: Test Governor Veto ✅
**Action Required:** Test veto functionality

**Test as Governor ONLY:**
1. Open `/gov` dashboard
2. Go to **Legislation** > **Proposed**
3. Click **View Details** on any proposed law
4. Look for **Veto** button (yellow, bottom-right)
5. Click **Veto Law**
6. Confirm the action

**Expected Result:**
- ✅ Confirmation dialog appears
- ✅ Notification: "Law has been vetoed by [Governor Name]"
- ✅ Law moves to **Veto'd** tab immediately
- ✅ Law no longer in Proposed tab

**If it doesn't work:**
- Verify player job is exactly 'governer'
- Check if Veto button is visible (Governor only)
- Check Config.Legislation.canVetoLaws array

---

### Step 6: Test Auto-Processing ⏳
**Action Required:** Wait for vote to expire

**Setup:**
1. Create a new test law with 24 hour duration
2. Cast at least 1 vote
3. Wait 24 hours + 10 minutes (or manually advance time in DB)

**OR Manually Trigger:**
```lua
-- In server console or admin command
TriggerEvent('un-government:server:processExpiredLawVotes')
```

**Expected Result:**
- ✅ Cron runs every 10 minutes
- ✅ Expired vote is processed
- ✅ If yes votes ≥ 51% and quorum met → Law moves to **Active**
- ✅ If failed → Law removed or marked failed
- ✅ Notification sent to all players

**Check Database:**
```sql
SELECT * FROM government_laws WHERE status = 'active';
SELECT * FROM government_laws WHERE status = 'failed';
```

---

### Step 7: Verify UI/CSS ✅
**Action Required:** Visual inspection

**Check These Elements:**
- ✅ Legislation tab visible (gavel icon)
- ✅ Purple theme matches other tabs
- ✅ Filter buttons (Active/Proposed/Vetoed) styled correctly
- ✅ Law cards have colored left border
- ✅ Status badges visible (ACTIVE LAW, IN VOTING, VETO'D)
- ✅ Vote progress bars show green fill
- ✅ Modals open/close properly
- ✅ Buttons have hover effects

**If styling is broken:**
- Press F5 to clear cache
- Check style.css was saved correctly
- Check browser console for CSS errors

---

### Step 8: Test Permissions ✅
**Action Required:** Test with different roles

**Test Matrix:**

| Role | Should See Tab? | Can Propose? | Can Vote? | Can Veto? |
|------|-----------------|--------------|-----------|-----------|
| Governor | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Senator | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| City Hall Staff | ✅ Yes | ❌ No | ✅ Yes | ❌ No |
| Citizen | ❌ No | ❌ No | ❌ No | ❌ No |

**How to Test:**
1. Log in as each role
2. Try to access `/gov` command
3. Check if Legislation tab is visible
4. Try to propose a law
5. Try to vote
6. Try to veto (Governor only)

**Expected Errors:**
- Non-government: "You don't have permission"
- Non-Senator/Governor proposing: "You don't have permission to propose laws"
- Non-Governor veto: Button not visible

---

### Step 9: Production Deployment ✅
**Action Required:** Deploy to live server

**Pre-Deployment:**
- [ ] Backup current database (`mysqldump`)
- [ ] Backup un-government resource folder
- [ ] Test in dev environment first
- [ ] Create rollback plan

**Deployment Steps:**
1. Stop server (or use `ensure un-government`)
2. Run SQL script on production database
3. Restart un-government resource
4. Monitor server console for errors
5. Test with admin account
6. Announce feature to players

**Post-Deployment:**
- [ ] Monitor server performance (10min cron impact)
- [ ] Watch for SQL errors in logs
- [ ] Gather player feedback
- [ ] Adjust vote durations if needed

---

### Step 10: Configure for Your Server ⚙️
**Action Required:** Customize settings

**Edit `config.lua` - Config.Legislation section:**

```lua
-- Adjust vote durations
minVoteDuration = 24,    -- Change to your preference
maxVoteDuration = 168,   -- Change to your preference
defaultVoteDuration = 72, -- Change to your preference

-- Adjust pass requirements
passThreshold = 51,      -- 51% = simple majority, 66% = supermajority
requiresQuorum = true,   -- Require minimum turnout
quorumPercent = 60,      -- Percentage of eligible voters needed

-- Document integration
createDocumentOnPass = true, -- Set to false if not using unstable-documents
```

**Add More Roles:**
```lua
-- Let City Hall GM also propose laws
canProposeLaws = {
    'governer',
    'senator',
    'cityhallgm' -- Add this
},
```

---

## Common Issues & Solutions

### Issue: "Player not found"
**Solution:** 
- Player not logged in properly
- Check QBCore is loaded
- Verify Player object exists

### Issue: Legislation tab not visible
**Solution:**
- Check Config.GovernmentJobs has `propose_laws` permission
- Verify job name matches exactly
- Check JavaScript permission checking

### Issue: Can't propose law
**Solution:**
- Verify job is 'governer' or 'senator' (exact spelling)
- Check Config.Legislation.canProposeLaws array
- Look for server errors when submitting

### Issue: Votes not counting
**Solution:**
- Check database unique constraint exists
- Verify player has government job
- Check law status is 'proposed'

### Issue: Auto-processing not working
**Solution:**
- Wait 10 minutes after vote expires
- Check server console for cron errors
- Manually trigger: `TriggerEvent('un-government:server:processExpiredLawVotes')`

### Issue: CSS not applied
**Solution:**
- Clear browser cache (F5)
- Check style.css file was saved
- Look for CSS errors in browser console

---

## Files Changed Summary

**Modified:**
- ✅ `html/index.html` - Added Legislation tab, modals
- ✅ `html/script.js` - Added ~350 lines of JavaScript
- ✅ `html/style.css` - Added ~300 lines of CSS
- ✅ `config.lua` - Added Config.Legislation section
- ✅ `server/main.lua` - Added 5 callbacks + cron
- ✅ `client/main.lua` - Added 5 NUI callbacks

**Created:**
- ✅ `legislation_tables.sql` - Database schema
- ✅ `LEGISLATION_GUIDE.md` - Full documentation
- ✅ `IMPLEMENTATION_SUMMARY.md` - Feature overview
- ✅ `INSTALLATION_CHECKLIST.md` - This file

---

## Quick Reference

### Important Commands
```lua
-- In-game
/gov                    -- Open government dashboard

-- Server console
restart un-government   -- Restart resource
TriggerEvent('un-government:server:processExpiredLawVotes')  -- Manual process

-- SQL queries
SELECT * FROM government_laws;
SELECT * FROM government_law_votes;
```

### Config Locations
- Main config: `config.lua` line ~150 (Config.Legislation)
- Database tables: `config.lua` line ~615 (Config.Tables)
- Permissions: `config.lua` lines 20-120 (Config.GovernmentJobs)

### Documentation
- Full guide: `LEGISLATION_GUIDE.md` (800+ lines)
- Summary: `IMPLEMENTATION_SUMMARY.md`
- This checklist: `INSTALLATION_CHECKLIST.md`
- SQL schema: `legislation_tables.sql`

---

## Final Verification

Before marking complete, verify:
- [ ] Tables created in database
- [ ] Resource restarts without errors
- [ ] Legislation tab visible to correct roles
- [ ] Can propose law as Governor/Senator
- [ ] Can vote as any government official
- [ ] Governor can veto
- [ ] Filters work (Active/Proposed/Vetoed)
- [ ] Vote percentages calculate correctly
- [ ] Auto-processing runs (test with expired vote)
- [ ] Notifications appear
- [ ] CSS styling looks correct
- [ ] No console errors (server or client)

**If all checked, system is ready for production! ✅**

---

## Support & Troubleshooting

Need help? Check these in order:
1. **Server Console** - Look for red error messages
2. **Browser Console** - F8 in game, then F12
3. **Database** - Verify tables and data exist
4. **LEGISLATION_GUIDE.md** - Troubleshooting section
5. **This Checklist** - Common issues section

---

## Status: [ ] Complete

Mark this as complete when all steps are verified! ✅
