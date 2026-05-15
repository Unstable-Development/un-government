Config = {}

-- =====================================================
-- GENERAL SETTINGS
-- =====================================================

Config.Command = "gov" -- Command to open government dashboard
Config.TargetResource = "qb-target" -- Your target resource name

-- =====================================================
-- GOVERNMENT JOB HIERARCHY
-- =====================================================
-- Based on jobs.lua government section

Config.GovernmentJobs = {
    -- Executive Branch
    ['governer'] = { 
        label = 'Governor',
        tier = 1, -- Highest authority
        salary = 5000,
        canAccessAll = true,
        permissions = {
            'view_all_departments',
            'appoint_officials',
            'issue_executive_orders',
            'manage_budget',
            'veto_laws',
            'access_voting',
            'access_inspections',
            'access_treasury',
            'access_appointments'
        }
    },
    
    -- Legislative Branch
    ['senator'] = {
        label = 'Senator',
        tier = 2,
        salary = 3500,
        permissions = {
            'propose_laws',
            'vote_on_laws',
            'view_budget',
            'access_voting'
        }
    },
    
    -- Judicial Branch
    ['judge'] = {
        label = 'Judge',
        tier = 2,
        salary = 4000,
        permissions = {
            'issue_warrants',
            'notarize_documents',
            'view_legal_documents'
        }
    },
    ['lawyer'] = {
        label = 'Lawyer',
        tier = 3,
        salary = 2500,
        permissions = {
            'create_legal_documents',
            'notarize_documents',
            'represent_citizens'
        }
    },
    
    -- City Hall Positions
    ['cityhallgm'] = {
        label = 'City Hall Manager',
        tier = 2,
        salary = 3000,
        permissions = {
            'manage_cityhall',
            'hire_cityhall_staff',
            'view_budget',
            'access_appointments'
        }
    },
    ['cityhallcoord'] = {
        label = 'City Hall Coordinator',
        tier = 3,
        salary = 2000,
        permissions = {
            'process_applications',
            'schedule_appointments'
        }
    },
    ['cityhallrep'] = {
        label = 'City Hall Representative',
        tier = 4,
        salary = 1800,
        permissions = {
            'assist_citizens',
            'process_documents'
        }
    },
    ['cityhallclerk'] = {
        label = 'City Hall Clerk',
        tier = 4,
        salary = 1500,
        permissions = {
            'process_documents',
            'assist_citizens'
        }
    },
    ['cityhallintern'] = {
        label = 'City Hall Intern',
        tier = 5,
        salary = 1000,
        permissions = {
            'assist_citizens'
        }
    },
    
    -- Treasury Department
    ['treasurysec'] = {
        label = 'Treasury Secretary',
        tier = 2,
        salary = 4000,
        permissions = {
            'manage_budget',
            'distribute_funds',
            'set_salaries',
            'view_finances',
            'access_treasury'
        }
    },
    ['treasurydeputy'] = {
        label = 'Deputy Treasury Secretary',
        tier = 3,
        salary = 3000,
        permissions = {
            'view_finances',
            'assist_treasury',
            'access_treasury'
        }
    },
    ['treasuryaccountant'] = {
        label = 'Treasury Accountant',
        tier = 4,
        salary = 2200,
        permissions = {
            'view_finances',
            'process_payments'
        }
    },
    ['treasuryclerk'] = {
        label = 'Treasury Clerk',
        tier = 4,
        salary = 1800,
        permissions = {
            'process_payments'
        }
    },
    
    -- Attorney General Office
    ['stateag'] = {
        label = 'Attorney General',
        tier = 2,
        salary = 4500,
        permissions = {
            'prosecute_cases',
            'issue_legal_opinions',
            'oversee_legal_matters',
            'notarize_documents'
        }
    },
    ['deputyag'] = {
        label = 'Deputy Attorney General',
        tier = 3,
        salary = 3500,
        permissions = {
            'prosecute_cases',
            'legal_research',
            'notarize_documents'
        }
    },
    
    -- Department of Health
    ['healthdirector'] = {
        label = 'Health Director',
        tier = 2,
        salary = 3800,
        permissions = {
            'conduct_health_inspections',
            'issue_health_certificates',
            'manage_health_department',
            'access_inspections'
        }
    },
    ['healthinspector'] = {
        label = 'Health Inspector',
        tier = 3,
        salary = 2500,
        permissions = {
            'conduct_health_inspections',
            'access_inspections'
        }
    },
    
    -- Department of Transportation
    ['transportdirector'] = {
        label = 'Transportation Director',
        tier = 2,
        salary = 3600,
        permissions = {
            'conduct_safety_inspections',
            'issue_permits',
            'manage_transport_department',
            'access_inspections'
        }
    },
    ['transportinspector'] = {
        label = 'Transportation Inspector',
        tier = 3,
        salary = 2400,
        permissions = {
            'conduct_safety_inspections',
            'access_inspections'
        }
    },
    
    -- Parks and Recreation
    ['parksdirector'] = {
        label = 'Parks Director',
        tier = 3,
        salary = 3000,
        permissions = {
            'manage_parks',
            'schedule_events'
        }
    },
    
    -- Public Works
    ['publicworksdirector'] = {
        label = 'Public Works Director',
        tier = 3,
        salary = 3200,
        permissions = {
            'manage_infrastructure',
            'approve_projects'
        }
    }
}

-- =====================================================
-- GOD PERMISSION SETTINGS
-- =====================================================
-- Players with 'god' permission have same access as Governor

Config.GodHasGovernorAccess = true

-- =====================================================
-- VOTING SYSTEM
-- =====================================================

Config.Voting = {
    enabled = true,
    
    -- Voting locations (city halls)
    locations = {
        {
            coords = vector4(232.5, -411.5, 48.1, 160.0),
            label = "Legion Square City Hall - Voting Kiosk"
        },
        {
            coords = vector4(-545.0, -204.0, 38.2, 210.0),
            label = "West City Hall - Voting Kiosk"
        },
        {
            coords = vector4(1855.0, 3686.0, 34.3, 210.0),
            label = "Sandy Shores City Hall - Voting Kiosk"
        },
        {
            coords = vector4(-437.0, 6161.0, 31.5, 45.0),
            label = "Paleto Bay City Hall - Voting Kiosk"
        }
    },
    
    -- Voting settings
    minVoteDuration = 24, -- Hours
    maxVoteDuration = 168, -- Hours (7 days)
    requiresCitizenID = true,
    oneVotePerCitizen = true,
    
    -- Who can create votes
    canCreateVotes = {
        'governer',
        'senator',
        'cityhallgm',
        'god' -- Permission level
    },
    
    -- Vote types
    voteTypes = {
        ['law'] = {
            label = 'Law Proposal',
            description = 'Vote on a new law or ordinance',
            requiresQuorum = true,
            quorumPercent = 60, -- % of active government needed
            passThreshold = 51 -- % to pass
        },
        ['official'] = {
            label = 'Government Official Election',
            description = 'Elect a government official',
            requiresQuorum = false,
            passThreshold = 50
        },
        ['budget'] = {
            label = 'Budget Approval',
            description = 'Approve budget allocation',
            requiresQuorum = true,
            quorumPercent = 66,
            passThreshold = 66
        },
        ['impeachment'] = {
            label = 'Impeachment Vote',
            description = 'Remove official from office',
            requiresQuorum = true,
            quorumPercent = 75,
            passThreshold = 75
        },
        ['general'] = {
            label = 'General Proposal',
            description = 'General government matter',
            requiresQuorum = false,
            passThreshold = 51
        }
    }
}

-- =====================================================
-- LEGISLATION SYSTEM
-- =====================================================

Config.Legislation = {
    enabled = true,
    
    -- Who can propose laws
    canProposeLaws = {
        'governer',
        'senator'
    },
    
    -- Who can veto laws
    canVetoLaws = {
        'governer'
    },
    
    -- Law voting settings
    minVoteDuration = 24, -- Hours
    maxVoteDuration = 168, -- Hours (7 days)
    defaultVoteDuration = 72, -- Default 3 days
    
    -- Passing requirements
    passThreshold = 51, -- % to pass (simple majority)
    requiresQuorum = true,
    quorumPercent = 60, -- % of Senators + Governor needed to vote
    
    -- Document integration (passed laws become documents)
    createDocumentOnPass = true,
    documentResource = 'unstable-documents',
    documentType = 'legal_statute', -- Document type in unstable-documents
    
    -- Law expiration
    lawsExpireAfter = 0 -- Days (0 = never expire)
}

-- =====================================================
-- APPOINTMENT SYSTEM
-- =====================================================

Config.Appointments = {
    enabled = true,
    
    -- Who can make appointments
    canAppoint = {
        ['governer'] = { -- Governor can appoint anyone
            'cityhallgm',
            'treasurysec',
            'stateag',
            'healthdirector',
            'transportdirector',
            'parksdirector',
            'publicworksdirector',
            'judge'
        },
        ['cityhallgm'] = { -- City Hall GM can appoint city hall staff
            'cityhallcoord',
            'cityhallrep',
            'cityhallclerk',
            'cityhallintern'
        },
        ['treasurysec'] = { -- Treasury Secretary can appoint treasury staff
            'treasurydeputy',
            'treasuryaccountant',
            'treasuryclerk'
        },
        ['stateag'] = { -- AG can appoint deputy
            'deputyag'
        },
        ['healthdirector'] = { -- Health Director can appoint inspectors
            'healthinspector'
        },
        ['transportdirector'] = { -- Transport Director can appoint inspectors
            'transportinspector'
        }
    },
    
    -- Appointments require Senate confirmation
    requiresConfirmation = {
        'treasurysec',
        'stateag',
        'healthdirector',
        'transportdirector',
        'judge'
    },
    
    -- Confirmation vote settings
    confirmationVoteDuration = 48, -- Hours
    confirmationPassThreshold = 60 -- % of senators
}

-- =====================================================
-- BUDGET MANAGEMENT
-- =====================================================

Config.Budget = {
    enabled = true,
    
    -- Starting government budget
    startingBalance = 1000000,
    
    -- Department budgets
    departments = {
        ['executive'] = {
            label = "Executive Office",
            monthlyAllocation = 50000,
            jobs = {'governer'}
        },
        ['cityhall'] = {
            label = "City Hall Operations",
            monthlyAllocation = 100000,
            jobs = {'cityhallgm', 'cityhallcoord', 'cityhallrep', 'cityhallclerk', 'cityhallintern'}
        },
        ['treasury'] = {
            label = "Treasury Department",
            monthlyAllocation = 80000,
            jobs = {'treasurysec', 'treasurydeputy', 'treasuryaccountant', 'treasuryclerk'}
        },
        ['legal'] = {
            label = "Legal Department",
            monthlyAllocation = 120000,
            jobs = {'judge', 'lawyer', 'stateag', 'deputyag'}
        },
        ['health'] = {
            label = "Department of Health",
            monthlyAllocation = 70000,
            jobs = {'healthdirector', 'healthinspector'}
        },
        ['transport'] = {
            label = "Department of Transportation",
            monthlyAllocation = 90000,
            jobs = {'transportdirector', 'transportinspector'}
        },
        ['parks'] = {
            label = "Parks and Recreation",
            monthlyAllocation = 40000,
            jobs = {'parksdirector'}
        },
        ['publicworks'] = {
            label = "Public Works",
            monthlyAllocation = 60000,
            jobs = {'publicworksdirector'}
        },
        ['legislative'] = {
            label = "Legislative Branch",
            monthlyAllocation = 70000,
            jobs = {'senator'}
        }
    },
    
    -- Budget reset cycle
    resetCycle = 'monthly', -- 'weekly' or 'monthly'
    resetDay = 1 -- Day of month/week to reset
}

-- =====================================================
-- INSPECTION SYSTEM
-- =====================================================

Config.Inspections = {
    enabled = true,
    
    -- Integration with unstable-documents
    useDocumentSystem = true,
    documentResource = 'unstable-documents',
    
    -- Business tracking
    trackBusinesses = true,
    
    -- Inspection types
    types = {
        ['health'] = {
            label = 'Health Inspection',
            jobs = {'healthdirector', 'healthinspector'},
            documentType = 'health_inspection',
            validityDays = 90, -- Re-inspection needed after 90 days
            requiredForBusiness = {'restaurant', 'bar', 'convenience', 'pharmacy'}
        },
        ['safety'] = {
            label = 'Safety Inspection',
            jobs = {'transportdirector', 'transportinspector'},
            documentType = 'safety_inspection',
            validityDays = 180,
            requiredForBusiness = {'mechanic', 'warehouse', 'factory', 'garage'}
        }
    },
    
    -- Inspection history
    keepHistoryDays = 365
}

-- =====================================================
-- DASHBOARD SETTINGS
-- =====================================================

Config.Dashboard = {
    theme = {
        primaryColor = '#b604da', -- Purple theme matching un-admin
        secondaryColor = '#8a03a8',
        backgroundColor = '#1a1a1a',
        textColor = '#ffffff',
        accentColor = '#00ffff'
    },
    
    -- Features visible to different roles
    features = {
        ['governer'] = {
            'overview',
            'appointments',
            'budget',
            'voting',
            'inspections',
            'documents',
            'officials',
            'executive_orders'
        },
        ['senator'] = {
            'overview',
            'voting',
            'budget_view',
            'laws'
        },
        ['judge'] = {
            'overview',
            'legal_documents',
            'warrants'
        },
        ['treasurysec'] = {
            'overview',
            'budget',
            'payroll',
            'transactions'
        },
        ['healthdirector'] = {
            'overview',
            'inspections',
            'health_department'
        },
        ['healthinspector'] = {
            'overview',
            'inspections'
        },
        ['transportdirector'] = {
            'overview',
            'inspections',
            'transport_department'
        },
        ['transportinspector'] = {
            'overview',
            'inspections'
        },
        ['cityhallgm'] = {
            'overview',
            'appointments',
            'staff_management',
            'public_services'
        }
    }
}

-- =====================================================
-- NOTIFICATION SETTINGS
-- =====================================================

Config.Notifications = {
    -- Notify government officials of important events
    notifyOnVoteCreated = true,
    notifyOnVoteEnded = true,
    notifyOnAppointment = true,
    notifyOnBudgetChange = true,
    notifyOnInspectionScheduled = true
}

-- =====================================================
-- DATABASE TABLE NAMES
-- =====================================================

Config.Tables = {
    votes = 'government_votes',
    voteRecords = 'government_vote_records',
    appointments = 'government_appointments',
    budget = 'government_budget',
    transactions = 'government_transactions',
    inspectionHistory = 'government_inspection_history',
    laws = 'government_laws',
    lawVotes = 'government_law_votes'
}
