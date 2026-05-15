# UN-Government Installation & Usage Guide

## Overview

The UN-Government system is a comprehensive government management solution for FiveM roleplay servers. It provides a complete framework for democratic governance, including voting systems, appointment management, budget control, and inspection capabilities.

## Features

### 🏛️ Core Features
- **Government Dashboard** - Central hub for all government operations
- **Voting System** - Democratic voting on laws, officials, and budgets
- **Appointment System** - Manage government positions with optional Senate confirmation
- **Budget Management** - Track and allocate funds across departments
- **Inspection System** - Health and safety inspections with document integration
- **Officials Directory** - Real-time directory of government officials
- **Permission System** - Role-based access control with God override

### 👥 Government Structure
- **Executive Branch**: Governor
- **Legislative Branch**: Senators
- **Judicial Branch**: Judges, Lawyers, Attorney General
- **Departments**: Treasury, Health, Transportation, Parks, Public Works
- **City Hall**: Managers, Coordinators, Representatives, Clerks, Interns

## Installation

### Step 1: Database Setup

Run the SQL file to create all required tables:
```sql
-- Located in: INSTALL FIRST/government_tables.sql
```

This creates the following tables:
- `government_votes` - Stores all votes
- `government_vote_records` - Tracks individual vote submissions
- `government_appointments` - Appointment records
- `government_budget` - Department budget balances
- `government_transactions` - Financial transaction history
- `government_inspection_history` - Inspection records

### Step 2: Add to Server.cfg

Add the resource to your `server.cfg`:
```cfg
ensure un-government
```

**IMPORTANT:** Make sure to start `unstable-documents` BEFORE `un-government`:
```cfg
ensure unstable-documents
ensure un-government
```

### Step 3: Configuration

Edit `config.lua` to customize:

**Basic Settings:**
- `Config.Command` - Command to open dashboard (default: `/gov`)
- `Config.TargetResource` - Your target resource (default: `qb-target`)

**Voting Locations:**
Add or modify voting kiosk locations in `Config.Voting.locations`:
```lua
{
    coords = vector4(x, y, z, heading),
    label = "Location Name - Voting Kiosk"
}
```

**Budget Allocations:**
Modify department budgets in `Config.Budget.departments`:
```lua
['department_name'] = {
    label = "Department Display Name",
    monthlyAllocation = 50000,
    jobs = {'job1', 'job2'}
}
```

### Step 4: Verify Jobs

Ensure all government jobs from the config exist in your `qb-core/shared/jobs.lua`. The script uses these government jobs:
- governer, senator, judge, lawyer, stateag, deputyag
- cityhallgm, cityhallcoord, cityhallrep, cityhallclerk, cityhallintern
- treasurysec, treasurydeputy, treasuryaccountant, treasuryclerk
- healthdirector, healthinspector
- transportdirector, transportinspector
- parksdirector, publicworksdirector

### Step 5: Add Logo (Optional)

Place a government seal image at:
```
html/logo.png
```
Recommended size: 512x512px

### Step 6: Restart Server

Restart your FiveM server or start the resource:
```
refresh
ensure un-government
```

## Usage Guide

### For Government Officials

#### Accessing the Dashboard

1. Use the command: `/gov`
2. You must have a government job or god permission
3. Dashboard shows based on your role and permissions

#### Navigation

The sidebar shows sections based on your permissions:
- **Overview** - Statistics and recent activity
- **Voting** - Create and view votes
- **Appointments** - Appoint and manage officials
- **Budget** - View and manage budgets (Treasury)
- **Inspections** - Conduct inspections (Health/Transport)
- **Officials** - Directory of online officials
- **Documents** - Quick access to document creator

### Governor Functions

As Governor (or with god permission), you have access to all features:

#### Creating Votes
1. Navigate to **Voting** section
2. Click **Create Vote**
3. Select vote type:
   - **Law Proposal** - New laws or ordinances
   - **Official Election** - Elect government positions
   - **Budget Approval** - Budget allocations
   - **Impeachment** - Remove officials
   - **General Proposal** - Other matters
4. Fill in title, description, duration
5. Add options (one per line)
6. Click **Create Vote**

#### Appointing Officials
1. Navigate to **Appointments** section
2. Click **Appoint Official**
3. Enter citizen ID
4. Select position
5. Add optional notes
6. Click **Appoint**

**Note:** Certain positions require Senate confirmation:
- Treasury Secretary
- Attorney General
- Health Director
- Transportation Director
- Judges

#### Managing Budget
1. Navigate to **Budget** section
2. View department balances
3. View recent transactions
4. Allocate or withdraw funds (if implemented)

### Senator Functions

Senators can:
- Propose laws
- Vote on all active votes
- View budget (read-only)
- Confirm appointments

### Health Department

Health Director and Inspectors can:
1. Navigate to **Inspections** section
2. Click **Start Inspection**
3. This opens the document creator
4. Select "Health Inspection Report"
5. Complete the inspection checklist
6. System automatically calculates grade (A-F)
7. Document is created and added to history

### Treasury Department

Treasury Secretary can:
- View all department budgets
- See all transactions
- Allocate funds to departments
- Manage payroll

### For Citizens

#### Public Voting Kiosks

Citizens can vote at any city hall:

1. Go to a city hall voting kiosk
2. Use qb-target on the kiosk
3. View active votes
4. Click option to cast your vote
5. Each citizen can only vote once per issue

**Kiosk Locations:**
- Legion Square City Hall
- West City Hall
- Sandy Shores City Hall
- Paleto Bay City Hall

## Permissions System

### Permission Levels

Each government job has specific permissions defined in the config:

**Key Permissions:**
- `view_all_departments` - See all department data
- `appoint_officials` - Appoint government officials
- `issue_executive_orders` - Create executive orders
- `manage_budget` - Full budget control
- `veto_laws` - Veto legislation
- `access_voting` - Create and manage votes
- `access_inspections` - Conduct inspections
- `access_treasury` - View/manage finances
- `propose_laws` - Create legislation votes
- `notarize_documents` - Notarize legal documents

### God Permission

Players with `god` permission have the same access as Governor:
- Set in config: `Config.GodHasGovernorAccess = true`
- Full access to all features
- Can override all restrictions

## Integration with unstable-documents

The government system seamlessly integrates with the document creator:

### Health Inspections
1. Health inspectors can access document creator
2. Use "Health Inspection Report" template
3. Inspection data is saved in both systems:
   - Custom document created
   - Inspection history recorded in government system

### Executive Orders
1. Governor creates "Executive Order" document
2. Document is marked as official
3. Stored in document system with government seal

### Legal Documents
1. Attorney General and lawyers create legal documents
2. Can be notarized
3. Tracked in government system

## Voting System Details

### Vote Types & Thresholds

| Type | Quorum Required | Pass Threshold |
|------|----------------|----------------|
| Law Proposal | 60% | 51% |
| Official Election | No | 50% |
| Budget Approval | 66% | 66% |
| Impeachment | 75% | 75% |
| General Proposal | No | 51% |

### Vote Duration
- Minimum: 24 hours
- Maximum: 168 hours (7 days)
- Configurable when creating vote

### Automatic Vote Ending
The server automatically checks every minute for expired votes:
- Calculates results
- Determines pass/fail based on type
- Notifies all government officials

## Budget System

### Department Budgets
Each department has:
- Monthly allocation amount
- Current balance
- Transaction history

### Budget Reset
- Configurable cycle (weekly/monthly)
- Automatically resets to allocation amount
- Default: Monthly on the 1st

### Transactions
All financial activities are logged:
- Allocations
- Withdrawals
- Transfers
- Payments

## Troubleshooting

### Dashboard won't open
- Check if you have a government job
- Verify job name matches config exactly
- Check console for errors

### Can't create votes
- Verify your job has `propose_laws` or equivalent permission
- Check if you're in the `Config.Voting.canCreateVotes` list

### Voting kiosks not working
- Verify qb-target is running
- Check kiosk coordinates in config
- Ensure database tables exist

### Inspection system issues
- Verify unstable-documents is running
- Check that custom_documents table exists
- Ensure inspector has correct job

### Budget not showing
- Verify `government_budget` table exists
- Check if departments are initialized (run SQL again)
- Verify permission `access_treasury` or `manage_budget`

## Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/gov` | Open government dashboard | Any government job or god |
| `/createdoc` | Open document creator | Set in unstable-documents |

## Exports

### Server-Side

```lua
-- Check if player is a government official
local isOfficial = exports['un-government']:IsGovernmentOfficial(Player)

-- Check if player is Governor
local isGov = exports['un-government']:IsGovernor(Player)

-- Check specific permission
local hasPerm = exports['un-government']:HasPermission(Player, 'manage_budget')

-- Check if can appoint job
local canAppoint = exports['un-government']:CanAppoint(Player, 'judge')
```

### Client-Side

```lua
-- Check if has permission
local hasPerm = exports['un-government']:HasPermission('access_voting')
```

## Customization

### Theme Colors

Edit `html/style.css` CSS variables:
```css
:root {
    --primary-color: #b604da;      /* Main purple */
    --secondary-color: #8a03a8;    /* Darker purple */
    --accent-color: #00ffff;       /* Cyan accent */
}
```

### Adding New Departments

1. Add to `Config.GovernmentJobs`:
```lua
['newdept'] = {
    label = 'New Department',
    tier = 2,
    salary = 3000,
    permissions = {'custom_perm'}
}
```

2. Add to `Config.Budget.departments`:
```lua
['newdept'] = {
    label = "New Department",
    monthlyAllocation = 50000,
    jobs = {'newdept'}
}
```

3. Run SQL to add budget entry:
```sql
INSERT INTO government_budget (department, balance) VALUES ('newdept', 50000.00);
```

### Adding Vote Types

Edit `Config.Voting.voteTypes`:
```lua
['custom_type'] = {
    label = 'Custom Vote Type',
    description = 'Description here',
    requiresQuorum = false,
    passThreshold = 51
}
```

## Future Enhancements

Planned features for future versions:
- [ ] Term limits and elections
- [ ] Executive order approval workflow
- [ ] Budget proposal system
- [ ] Department reports
- [ ] Government email system
- [ ] Meeting scheduler
- [ ] Legislative session management
- [ ] Citizen petitions
- [ ] Freedom of Information requests
- [ ] Government analytics dashboard

## Support

For issues or questions:
1. Check this guide thoroughly
2. Verify all installation steps completed
3. Check server console for errors
4. Review config.lua settings

---

**Version:** 1.0.0  
**Author:** Prelude RP Development  
**Last Updated:** May 11, 2026  
**Dependencies:** qb-core, oxmysql, qb-target, unstable-documents
