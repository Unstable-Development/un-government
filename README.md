# un-government (WORK IN PROGRESS)

**Comprehensive Government Management System for Prelude RP**

A full-featured government dashboard for FiveM QBCore servers. Handles democratic voting, official appointments, department budgets, inspections, legislation, and a document creator — all in one purple-themed UI.

---

## Requirements

- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [oxmysql](https://github.com/overextended/oxmysql)
- [qb-target](https://github.com/qbcore-framework/qb-target)
- `unstable-documents` *(must start before un-government)*

---

## Installation

1. **Run the SQL files** (in order):
   - `INSTALL FIRST/government_tables.sql` — core tables (votes, appointments, budget, etc.)
   - `legislation_tables.sql` — legislation & law vote tables

2. **Add to `server.cfg`:**
   ```cfg
   ensure unstable-documents
   ensure un-government
   ```

3. **Configure** `config.lua` to match your job names, QB-target resource, and department settings.

---

## Commands

| Command | Description |
|---------|-------------|
| `/gov` | Open the government dashboard (government jobs only) |

Public voting kiosks are accessible via QB-target at 4 city hall locations (Legion Square, West LS, Sandy Shores, Paleto Bay).

---

## Features

### Government Dashboard
- Permission-based navigation — players only see tabs they have access to
- God permission grants full Governor-level access
- Real-time stats: active votes, pending appointments, department budgets

### Voting System
- Vote types: Law, Official Election, Budget, Impeachment, General
- Configurable duration (24–168 hours) and pass threshold (default 51%)
- Quorum requirement (default 60%)
- One vote per citizen, real-time progress bars
- Public kiosk access for citizens

### Legislation
- Senators propose laws; Governor can veto
- Full vote tracking with auto-processing every 10 minutes
- Integrated with `unstable-documents` for official records

### Appointment System
- Governor appoints officials to any position
- Department heads appoint their own staff
- Senate confirmation required for: Treasury Secretary, Attorney General, Health Director, Transportation Director, Judges
- Full appointment history & removal logging

### Budget Management
- 9 departments with individual balances
- Monthly allocations and transaction history
- Department-level fund management

### Inspection System
- Health inspections with automatic A–F grading
- Safety inspections with pass/fail scoring
- Results logged to `government_inspection_history`

### Document Creator
- Multi-page editor (up to 15 pages)
- 9 document types: letters, contracts, official reports, and more
- Signature & notary support
- Job-based permissions

---

## Government Structure

| Branch | Jobs |
|--------|------|
| Executive | `governer` (Governor) |
| Legislative | `senator` |
| Judicial | `judge`, `lawyer`, `attGeneral` |
| Departments | `treasurySec`, `healthDir`, `transportDir`, `parksDir`, `publicWorksDir` |
| City Hall | `cityhallgm`, `cityhallcoord`, `cityhallrep`, `cityhallclerk`, `cityhallintern` |

---

## Database Tables

| Table | Purpose |
|-------|---------|
| `government_votes` | Vote records |
| `government_vote_records` | Individual vote submissions |
| `government_appointments` | Appointment history |
| `government_budget` | Department balances |
| `government_transactions` | Financial history |
| `government_inspection_history` | Inspection results |
| `government_laws` | Proposed & active laws |
| `government_law_votes` | Law vote records |

---

## Configuration

Key options in `config.lua`:

```lua
Config.Command = "gov"               -- Dashboard open command
Config.TargetResource = "qb-target"  -- Target resource name
```

See `config.lua` for full department, job hierarchy, kiosk location, and permission settings.

---

*Prelude RP Development — v1.0.0*
