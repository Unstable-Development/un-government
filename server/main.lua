local QBCore = exports['qb-core']:GetCoreObject()

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Check if player has a government job
local function IsGovernmentOfficial(Player)
    if not Player then return false end
    local job = Player.PlayerData.job.name
    return Config.GovernmentJobs[job] ~= nil
end

-- Check if player is Governor or has god permission
local function IsGovernor(Player)
    if not Player then return false end
    if Config.GodHasGovernorAccess and QBCore.Functions.HasPermission(Player.PlayerData.source, 'god') then
        return true
    end
    return Player.PlayerData.job.name == 'governer'
end

-- Check if player has specific permission
local function HasPermission(Player, permission)
    if not Player then return false end
    
    -- God always has access
    if Config.GodHasGovernorAccess and QBCore.Functions.HasPermission(Player.PlayerData.source, 'god') then
        return true
    end
    
    local job = Player.PlayerData.job.name
    if not Config.GovernmentJobs[job] then return false end
    
    local jobData = Config.GovernmentJobs[job]
    if jobData.canAccessAll then return true end
    
    if jobData.permissions then
        for _, perm in pairs(jobData.permissions) do
            if perm == permission then
                return true
            end
        end
    end
    
    return false
end

-- Check if player can appoint specific job
local function CanAppoint(Player, targetJob)
    if not Player then return false end
    
    if IsGovernor(Player) then return true end
    
    local playerJob = Player.PlayerData.job.name
    if not Config.Appointments.canAppoint[playerJob] then return false end
    
    for _, job in pairs(Config.Appointments.canAppoint[playerJob]) do
        if job == targetJob then
            return true
        end
    end
    
    return false
end

-- =====================================================
-- DASHBOARD DATA
-- =====================================================

QBCore.Functions.CreateCallback('un-government:server:getDashboardData', function(source, cb)
    print("^2[UN-Government] Server callback triggered for source:^7", source)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        print("^1[UN-Government] Player not found^7")
        cb(nil) 
        return 
    end
    
    print("^2[UN-Government] Player job:^7", Player.PlayerData.job.name)
    print("^2[UN-Government] Is government official:^7", IsGovernmentOfficial(Player))
    print("^2[UN-Government] Has god permission:^7", QBCore.Functions.HasPermission(source, 'god'))
    
    if not IsGovernmentOfficial(Player) and not QBCore.Functions.HasPermission(source, 'god') then
        print("^1[UN-Government] Access denied - not government official or god^7")
        cb(nil)
        return
    end
    
    local data = {
        isGod = QBCore.Functions.HasPermission(source, 'god'),
        permissions = Config.GovernmentJobs[Player.PlayerData.job.name] and Config.GovernmentJobs[Player.PlayerData.job.name].permissions or {},
        activeVotes = 0,
        pendingAppointments = 0,
        governmentBalance = 0
    }
    
    -- Get active votes count
    local votes = exports.oxmysql:scalarSync('SELECT COUNT(*) FROM ' .. Config.Tables.votes .. ' WHERE status = ?', {'active'})
    data.activeVotes = votes or 0
    
    -- Get pending appointments count
    local appointments = exports.oxmysql:scalarSync('SELECT COUNT(*) FROM ' .. Config.Tables.appointments .. ' WHERE status = ?', {'pending'})
    data.pendingAppointments = appointments or 0
    
    -- Get government balance
    local balance = exports.oxmysql:scalarSync('SELECT SUM(balance) FROM ' .. Config.Tables.budget)
    data.governmentBalance = balance or 0
    
    print("^2[UN-Government] Sending data:^7", json.encode(data))
    cb(data)
end)

-- =====================================================
-- VOTING SYSTEM
-- =====================================================

-- Create a new vote
QBCore.Functions.CreateCallback('un-government:server:createVote', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    -- Check permission
    local canCreate = false
    if IsGovernor(Player) then
        canCreate = true
    else
        local playerJob = Player.PlayerData.job.name
        for _, job in pairs(Config.Voting.canCreateVotes) do
            if job == playerJob then
                canCreate = true
                break
            end
        end
    end
    
    if not canCreate then
        cb(false, "You don't have permission to create votes")
        return
    end
    
    -- Validate data
    if not data.title or not data.description or not data.type or not data.duration then
        cb(false, "Missing required vote data")
        return
    end
    
    -- Validate duration
    if data.duration < Config.Voting.minVoteDuration or data.duration > Config.Voting.maxVoteDuration then
        cb(false, "Invalid vote duration")
        return
    end
    
    -- Calculate end time
    local endTime = os.time() + (data.duration * 3600)
    
    -- Insert vote
    local voteId = exports.oxmysql:insert([[
        INSERT INTO ]] .. Config.Tables.votes .. [[ 
        (title, description, type, created_by_cid, created_by_name, created_by_job, 
         options, status, end_time, created_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?), NOW())
    ]], {
        data.title,
        data.description,
        data.type,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.job.label,
        json.encode(data.options or {"Yes", "No"}),
        'active',
        endTime
    })
    
    if voteId then
        -- Notify all government officials
        local Players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(Players) do
            if IsGovernmentOfficial(player) then
                TriggerClientEvent('un-government:client:voteCreated', player.PlayerData.source, {
                    title = data.title,
                    type = data.type
                })
            end
        end
        
        cb(true, "Vote created successfully")
    else
        cb(false, "Failed to create vote")
    end
end)

-- Cast a vote
QBCore.Functions.CreateCallback('un-government:server:castVote', function(source, cb, voteId, option)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    -- Get vote details
    local vote = exports.oxmysql:singleSync('SELECT * FROM ' .. Config.Tables.votes .. ' WHERE id = ? AND status = ?', {voteId, 'active'})
    if not vote then
        cb(false, "Vote not found or has ended")
        return
    end
    
    -- Check if already voted
    local hasVoted = exports.oxmysql:scalarSync([[
        SELECT COUNT(*) FROM ]] .. Config.Tables.voteRecords .. [[ 
        WHERE vote_id = ? AND citizenid = ?
    ]], {voteId, Player.PlayerData.citizenid})
    
    if hasVoted > 0 then
        cb(false, "You have already voted on this")
        return
    end
    
    -- Record vote
    local success = exports.oxmysql:insert([[
        INSERT INTO ]] .. Config.Tables.voteRecords .. [[
        (vote_id, citizenid, name, option, voted_date)
        VALUES (?, ?, ?, ?, NOW())
    ]], {
        voteId,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        option
    })
    
    if success then
        cb(true, "Vote cast successfully")
    else
        cb(false, "Failed to cast vote")
    end
end)

-- Get votes
QBCore.Functions.CreateCallback('un-government:server:getVotes', function(source, cb, filter)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end
    
    local query = 'SELECT * FROM ' .. Config.Tables.votes
    local params = {}
    
    if filter == 'active' then
        query = query .. ' WHERE status = ?'
        params = {'active'}
    elseif filter == 'ended' then
        query = query .. ' WHERE status = ?'
        params = {'ended'}
    end
    
    query = query .. ' ORDER BY created_date DESC LIMIT 50'
    
    local votes = exports.oxmysql:fetchSync(query, params)
    
    -- Get vote counts for each
    for _, vote in pairs(votes) do
        vote.options = json.decode(vote.options)
        
        local voteRecords = exports.oxmysql:fetchSync([[
            SELECT option, COUNT(*) as count 
            FROM ]] .. Config.Tables.voteRecords .. [[ 
            WHERE vote_id = ? 
            GROUP BY option
        ]], {vote.id})
        
        vote.results = {}
        for _, record in pairs(voteRecords) do
            vote.results[record.option] = record.count
        end
        
        -- Check if current player has voted
        vote.hasVoted = exports.oxmysql:scalarSync([[
            SELECT COUNT(*) FROM ]] .. Config.Tables.voteRecords .. [[
            WHERE vote_id = ? AND citizenid = ?
        ]], {vote.id, Player.PlayerData.citizenid}) > 0
    end
    
    cb(votes)
end)

-- Get active votes (for kiosks)
QBCore.Functions.CreateCallback('un-government:server:getActiveVotes', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end
    
    local votes = exports.oxmysql:fetchSync([[
        SELECT * FROM ]] .. Config.Tables.votes .. [[
        WHERE status = 'active' AND end_time > NOW()
        ORDER BY created_date DESC
    ]])
    
    -- Get vote counts and check if player voted
    for _, vote in pairs(votes) do
        vote.options = json.decode(vote.options)
        
        local voteRecords = exports.oxmysql:fetchSync([[
            SELECT option, COUNT(*) as count 
            FROM ]] .. Config.Tables.voteRecords .. [[
            WHERE vote_id = ? 
            GROUP BY option
        ]], {vote.id})
        
        vote.results = {}
        for _, record in pairs(voteRecords) do
            vote.results[record.option] = record.count
        end
        
        vote.hasVoted = exports.oxmysql:scalarSync([[
            SELECT COUNT(*) FROM ]] .. Config.Tables.voteRecords .. [[
            WHERE vote_id = ? AND citizenid = ?
        ]], {vote.id, Player.PlayerData.citizenid}) > 0
    end
    
    cb(votes)
end)

-- End a vote manually
QBCore.Functions.CreateCallback('un-government:server:endVote', function(source, cb, voteId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    if not IsGovernor(Player) then
        cb(false, "Only the Governor can manually end votes")
        return
    end
    
    exports.oxmysql:update('UPDATE ' .. Config.Tables.votes .. ' SET status = ? WHERE id = ?', {'ended', voteId})
    cb(true, "Vote ended")
end)

-- Check and end expired votes (runs every minute)
CreateThread(function()
    while true do
        Wait(60000) -- 1 minute
        
        local expiredVotes = exports.oxmysql:fetchSync([[
            SELECT * FROM ]] .. Config.Tables.votes .. [[
            WHERE status = 'active' AND end_time <= NOW()
        ]])
        
        for _, vote in pairs(expiredVotes) do
            -- Calculate results
            local voteRecords = exports.oxmysql:fetchSync([[
                SELECT option, COUNT(*) as count 
                FROM ]] .. Config.Tables.voteRecords .. [[
                WHERE vote_id = ? 
                GROUP BY option
            ]], {vote.id})
            
            local totalVotes = 0
            local results = {}
            for _, record in pairs(voteRecords) do
                results[record.option] = record.count
                totalVotes = totalVotes + record.count
            end
            
            -- Determine if passed
            local voteType = Config.Voting.voteTypes[vote.type]
            local passed = false
            
            if voteType and results["Yes"] then
                local yesPercent = (results["Yes"] / totalVotes) * 100
                passed = yesPercent >= voteType.passThreshold
            end
            
            -- Update vote
            exports.oxmysql:update([[
                UPDATE ]] .. Config.Tables.votes .. [[
                SET status = ?, passed = ?, total_votes = ?, results = ?
                WHERE id = ?
            ]], {'ended', passed and 1 or 0, totalVotes, json.encode(results), vote.id})
            
            -- Notify government officials
            local Players = QBCore.Functions.GetQBPlayers()
            for _, player in pairs(Players) do
                if IsGovernmentOfficial(player) then
                    TriggerClientEvent('un-government:client:voteEnded', player.PlayerData.source, {
                        title = vote.title,
                        passed = passed
                    })
                end
            end
        end
    end
end)

-- =====================================================
-- APPOINTMENT SYSTEM
-- =====================================================

QBCore.Functions.CreateCallback('un-government:server:appointOfficial', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    -- Check permission
    if not CanAppoint(Player, data.job) then
        cb(false, "You don't have permission to appoint this position")
        return
    end
    
    -- Get target player
    local TargetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.citizenid)
    if not TargetPlayer then
        cb(false, "Target player not found or offline")
        return
    end
    
    -- Check if requires confirmation
    local requiresConfirmation = false
    for _, job in pairs(Config.Appointments.requiresConfirmation) do
        if job == data.job then
            requiresConfirmation = true
            break
        end
    end
    
    if requiresConfirmation then
        -- Create confirmation vote
        local endTime = os.time() + (Config.Appointments.confirmationVoteDuration * 3600)
        
        local voteId = exports.oxmysql:insert([[
            INSERT INTO ]] .. Config.Tables.votes .. [[
            (title, description, type, created_by_cid, created_by_name, created_by_job,
             options, status, end_time, created_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?), NOW())
        ]], {
            "Appointment Confirmation: " .. Config.GovernmentJobs[data.job].label,
            "Confirm appointment of " .. TargetPlayer.PlayerData.charinfo.firstname .. " " .. TargetPlayer.PlayerData.charinfo.lastname .. " to " .. Config.GovernmentJobs[data.job].label,
            'official',
            Player.PlayerData.citizenid,
            Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            Player.PlayerData.job.label,
            json.encode({"Confirm", "Deny"}),
            'active',
            endTime
        })
        
        -- Store pending appointment
        exports.oxmysql:insert([[
            INSERT INTO ]] .. Config.Tables.appointments .. [[
            (vote_id, citizenid, name, job, job_label, appointed_by_cid, appointed_by_name, status, created_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ]], {
            voteId,
            data.citizenid,
            TargetPlayer.PlayerData.charinfo.firstname .. " " .. TargetPlayer.PlayerData.charinfo.lastname,
            data.job,
            Config.GovernmentJobs[data.job].label,
            Player.PlayerData.citizenid,
            Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            'pending'
        })
        
        cb(true, "Appointment created and sent for Senate confirmation")
    else
        -- Direct appointment
        TargetPlayer.Functions.SetJob(data.job, 0)
        
        -- Record appointment
        exports.oxmysql:insert([[
            INSERT INTO ]] .. Config.Tables.appointments .. [[
            (citizenid, name, job, job_label, appointed_by_cid, appointed_by_name, status, created_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        ]], {
            data.citizenid,
            TargetPlayer.PlayerData.charinfo.firstname .. " " .. TargetPlayer.PlayerData.charinfo.lastname,
            data.job,
            Config.GovernmentJobs[data.job].label,
            Player.PlayerData.citizenid,
            Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            'approved'
        })
        
        TriggerClientEvent('un-government:client:appointed', TargetPlayer.PlayerData.source, Config.GovernmentJobs[data.job].label)
        cb(true, "Official appointed successfully")
    end
end)

QBCore.Functions.CreateCallback('un-government:server:getAppointments', function(source, cb)
    local appointments = exports.oxmysql:fetchSync([[
        SELECT * FROM ]] .. Config.Tables.appointments .. [[
        ORDER BY created_date DESC LIMIT 100
    ]])
    cb(appointments or {})
end)

QBCore.Functions.CreateCallback('un-government:server:removeOfficial', function(source, cb, citizenid, reason)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    if not IsGovernor(Player) then
        cb(false, "Only the Governor can remove officials")
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if TargetPlayer then
        TargetPlayer.Functions.SetJob('unemployed', 0)
        TriggerClientEvent('un-government:client:notify', TargetPlayer.PlayerData.source, "You have been removed from your government position. Reason: " .. reason, "error")
    end
    
    exports.oxmysql:update([[
        UPDATE ]] .. Config.Tables.appointments .. [[
        SET status = 'removed', removed_reason = ?, removed_date = NOW()
        WHERE citizenid = ? AND status = 'approved'
    ]], {reason, citizenid})
    
    cb(true, "Official removed")
end)

-- =====================================================
-- BUDGET MANAGEMENT
-- =====================================================

QBCore.Functions.CreateCallback('un-government:server:getBudgetData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(nil) return end
    
    if not HasPermission(Player, 'view_budget') and not HasPermission(Player, 'manage_budget') then
        cb(nil)
        return
    end
    
    local budgetData = {}
    
    -- Get department budgets
    for dept, info in pairs(Config.Budget.departments) do
        local balance = exports.oxmysql:scalarSync([[
            SELECT balance FROM ]] .. Config.Tables.budget .. [[
            WHERE department = ?
        ]], {dept}) or 0
        
        budgetData[dept] = {
            label = info.label,
            balance = balance,
            monthlyAllocation = info.monthlyAllocation
        }
    end
    
    -- Get recent transactions
    local transactions = exports.oxmysql:fetchSync([[
        SELECT * FROM ]] .. Config.Tables.transactions .. [[
        ORDER BY transaction_date DESC LIMIT 50
    ]])
    
    cb({
        departments = budgetData,
        transactions = transactions or {}
    })
end)

QBCore.Functions.CreateCallback('un-government:server:allocateFunds', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    if not HasPermission(Player, 'manage_budget') then
        cb(false, "You don't have permission to manage the budget")
        return
    end
    
    -- Allocate funds logic here
    cb(true, "Funds allocated successfully")
end)

QBCore.Functions.CreateCallback('un-government:server:withdrawFunds', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    if not HasPermission(Player, 'manage_budget') then
        cb(false, "You don't have permission to withdraw funds")
        return
    end
    
    -- Withdrawal logic here
    cb(true, "Funds withdrawn successfully")
end)

-- =====================================================
-- INSPECTION SYSTEM
-- =====================================================

QBCore.Functions.CreateCallback('un-government:server:getInspectionHistory', function(source, cb, businessName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end
    
    if not HasPermission(Player, 'access_inspections') then
        cb({})
        return
    end
    
    local history = exports.oxmysql:fetchSync([[
        SELECT * FROM ]] .. Config.Tables.inspectionHistory .. [[
        WHERE business_name LIKE ?
        ORDER BY inspection_date DESC LIMIT 20
    ]], {'%' .. businessName .. '%'})
    
    cb(history or {})
end)

QBCore.Functions.CreateCallback('un-government:server:scheduleInspection', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false, "Player not found") return end
    
    if not HasPermission(Player, 'access_inspections') then
        cb(false, "You don't have permission to schedule inspections")
        return
    end
    
    -- Schedule inspection logic
    cb(true, "Inspection scheduled")
end)

-- =====================================================
-- GOVERNMENT OFFICIALS DIRECTORY
-- =====================================================

QBCore.Functions.CreateCallback('un-government:server:getGovernmentOfficials', function(source, cb)
    local officials = {}
    
    local Players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(Players) do
        if IsGovernmentOfficial(player) then
            table.insert(officials, {
                citizenid = player.PlayerData.citizenid,
                name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                job = player.PlayerData.job.name,
                jobLabel = player.PlayerData.job.label,
                grade = player.PlayerData.job.grade.level,
                phone = player.PlayerData.charinfo.phone
            })
        end
    end
    
    cb(officials)
end)

-- =====================================================
-- LEGISLATION SYSTEM
-- =====================================================

-- Helper to check if player can propose laws
local function CanProposeLaws(Player)
    if not Player then return false end
    if Config.GodHasGovernorAccess and QBCore.Functions.HasPermission(Player.PlayerData.source, 'god') then
        return true
    end
    
    local job = Player.PlayerData.job.name
    for _, allowedJob in pairs(Config.Legislation.canProposeLaws) do
        if job == allowedJob then return true end
    end
    return false
end

-- Helper to check if player can veto laws
local function CanVetoLaws(Player)
    if not Player then return false end
    if Config.GodHasGovernorAccess and QBCore.Functions.HasPermission(Player.PlayerData.source, 'god') then
        return true
    end
    
    local job = Player.PlayerData.job.name
    for _, allowedJob in pairs(Config.Legislation.canVetoLaws) do
        if job == allowedJob then return true end
    end
    return false
end

-- Get laws by filter
QBCore.Functions.CreateCallback('un-government:server:getLaws', function(source, cb, filter)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not IsGovernmentOfficial(Player) then
        cb({})
        return
    end
    
    filter = filter or 'active'
    
    -- Query laws
    local result = MySQL.query.await([[
        SELECT 
            l.*,
            (SELECT COUNT(*) FROM government_law_votes WHERE law_id = l.id AND vote = 'yes') as yes_votes,
            (SELECT COUNT(*) FROM government_law_votes WHERE law_id = l.id AND vote = 'no') as no_votes
        FROM government_laws l
        WHERE l.status = ?
        ORDER BY l.created_date DESC
        LIMIT 50
    ]], { filter })
    
    -- Format laws for client
    local laws = {}
    for _, law in pairs(result) do
        table.insert(laws, {
            id = law.id,
            title = law.title,
            description = law.description,
            status = law.status,
            created_by_cid = law.created_by_cid,
            created_by_name = law.created_by_name,
            created_by_job = law.created_by_job,
            created_date = law.created_date,
            end_time = law.end_time,
            passed_date = law.passed_date,
            veto_date = law.veto_date,
            results = {
                yes = law.yes_votes or 0,
                no = law.no_votes or 0
            }
        })
    end
    
    cb(laws)
end)

-- Propose a new law
QBCore.Functions.CreateCallback('un-government:server:proposeLaw', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ success = false, message = "Player not found" })
        return
    end
    
    if not CanProposeLaws(Player) then
        cb({ success = false, message = "You don't have permission to propose laws" })
        return
    end
    
    -- Validate input
    if not data.title or data.title == '' then
        cb({ success = false, message = "Law title is required" })
        return
    end
    
    if not data.description or data.description == '' then
        cb({ success = false, message = "Law description is required" })
        return
    end
    
    local duration = tonumber(data.duration) or Config.Legislation.defaultVoteDuration
    if duration < Config.Legislation.minVoteDuration or duration > Config.Legislation.maxVoteDuration then
        cb({ success = false, message = "Invalid vote duration" })
        return
    end
    
    -- Calculate end time
    local endTime = os.time() + (duration * 3600)
    
    -- Insert law
    local lawId = MySQL.insert.await([[
        INSERT INTO government_laws 
        (title, description, status, created_by_cid, created_by_name, created_by_job, created_date, end_time)
        VALUES (?, ?, 'proposed', ?, ?, ?, NOW(), FROM_UNIXTIME(?))
    ]], {
        data.title,
        data.description,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.job.label,
        endTime
    })
    
    if lawId then
        -- Notify government officials
        TriggerClientEvent('QBCore:Notify', -1, 'A new law has been proposed: ' .. data.title, 'info', 5000)
        
        cb({ success = true, message = "Law proposed successfully", lawId = lawId })
    else
        cb({ success = false, message = "Failed to propose law" })
    end
end)

-- Get law details
QBCore.Functions.CreateCallback('un-government:server:getLawDetails', function(source, cb, lawId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not IsGovernmentOfficial(Player) then
        cb(nil)
        return
    end
    
    -- Get law data
    local law = MySQL.single.await([[
        SELECT * FROM government_laws WHERE id = ?
    ]], { lawId })
    
    if not law then
        cb(nil)
        return
    end
    
    -- Get vote counts
    local votes = MySQL.query.await([[
        SELECT vote, COUNT(*) as count
        FROM government_law_votes
        WHERE law_id = ?
        GROUP BY vote
    ]], { lawId })
    
    local results = { yes = 0, no = 0 }
    for _, vote in pairs(votes) do
        results[vote.vote] = vote.count
    end
    
    -- Check if player has voted
    local hasVoted = MySQL.scalar.await([[
        SELECT COUNT(*) FROM government_law_votes
        WHERE law_id = ? AND citizenid = ?
    ]], { lawId, Player.PlayerData.citizenid }) > 0
    
    cb({
        id = law.id,
        title = law.title,
        description = law.description,
        status = law.status,
        created_by_cid = law.created_by_cid,
        created_by_name = law.created_by_name,
        created_by_job = law.created_by_job,
        created_date = law.created_date,
        end_time = law.end_time,
        passed_date = law.passed_date,
        veto_date = law.veto_date,
        veto_by_name = law.veto_by_name,
        results = results,
        hasVoted = hasVoted
    })
end)

-- Vote on a law
QBCore.Functions.CreateCallback('un-government:server:voteOnLaw', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not IsGovernmentOfficial(Player) then
        cb({ success = false, message = "Only government officials can vote" })
        return
    end
    
    local lawId = tonumber(data.lawId)
    local vote = data.vote -- 'yes' or 'no'
    
    if vote ~= 'yes' and vote ~= 'no' then
        cb({ success = false, message = "Invalid vote option" })
        return
    end
    
    -- Check if law exists and is in proposed status
    local law = MySQL.single.await([[
        SELECT * FROM government_laws WHERE id = ? AND status = 'proposed'
    ]], { lawId })
    
    if not law then
        cb({ success = false, message = "Law not found or voting has ended" })
        return
    end
    
    -- Check if voting period has ended
    local endTime = os.time(law.end_time)
    if os.time() > endTime then
        cb({ success = false, message = "Voting period has ended" })
        return
    end
    
    -- Check if player already voted
    local hasVoted = MySQL.scalar.await([[
        SELECT COUNT(*) FROM government_law_votes
        WHERE law_id = ? AND citizenid = ?
    ]], { lawId, Player.PlayerData.citizenid }) > 0
    
    if hasVoted then
        cb({ success = false, message = "You have already voted on this law" })
        return
    end
    
    -- Record vote
    MySQL.insert.await([[
        INSERT INTO government_law_votes (law_id, citizenid, name, vote, voted_date)
        VALUES (?, ?, ?, ?, NOW())
    ]], {
        lawId,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        vote
    })
    
    TriggerClientEvent('QBCore:Notify', source, 'Your vote has been recorded', 'success')
    cb({ success = true, message = "Vote recorded successfully" })
    
    -- Check if voting should end (optional: end early if quorum met)
    -- Auto-processing of votes will be handled by a separate function/cron
end)

-- Veto a law
QBCore.Functions.CreateCallback('un-government:server:vetoLaw', function(source, cb, lawId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ success = false, message = "Player not found" })
        return
    end
    
    if not CanVetoLaws(Player) then
        cb({ success = false, message = "You don't have permission to veto laws" })
        return
    end
    
    -- Check if law exists and is in proposed status
    local law = MySQL.single.await([[
        SELECT * FROM government_laws WHERE id = ? AND status = 'proposed'
    ]], { lawId })
    
    if not law then
        cb({ success = false, message = "Law not found or already processed" })
        return
    end
    
    -- Update law to vetoed
    MySQL.update.await([[
        UPDATE government_laws
        SET status = 'vetoed', veto_date = NOW(), veto_by_cid = ?, veto_by_name = ?
        WHERE id = ?
    ]], {
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        lawId
    })
    
    TriggerClientEvent('QBCore:Notify', -1, 'Law "' .. law.title .. '" has been vetoed by ' .. Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, 'error', 5000)
    
    cb({ success = true, message = "Law vetoed successfully" })
end)

-- Process expired law votes (called by cron or manually)
RegisterNetEvent('un-government:server:processExpiredLawVotes', function()
    -- Get all proposed laws with expired voting periods
    local expiredLaws = MySQL.query.await([[
        SELECT 
            l.*,
            (SELECT COUNT(*) FROM government_law_votes WHERE law_id = l.id AND vote = 'yes') as yes_votes,
            (SELECT COUNT(*) FROM government_law_votes WHERE law_id = l.id AND vote = 'no') as no_votes,
            (SELECT COUNT(*) FROM government_law_votes WHERE law_id = l.id) as total_votes
        FROM government_laws l
        WHERE l.status = 'proposed' AND l.end_time < NOW()
    ]])
    
    for _, law in pairs(expiredLaws) do
        local totalVotes = law.total_votes or 0
        local yesVotes = law.yes_votes or 0
        local noVotes = law.no_votes or 0
        
        -- Calculate pass percentage
        local passPercentage = totalVotes > 0 and (yesVotes / totalVotes * 100) or 0
        
        -- Check if quorum met (if required)
        local quorumMet = true
        if Config.Legislation.requiresQuorum then
            -- Count total government officials (senators + governor)
            local totalOfficials = 0
            for jobName, jobData in pairs(Config.GovernmentJobs) do
                for _, allowedJob in pairs(Config.Legislation.canProposeLaws) do
                    if jobName == allowedJob then
                        totalOfficials = totalOfficials + 1
                    end
                end
            end
            
            local quorumNeeded = math.ceil(totalOfficials * (Config.Legislation.quorumPercent / 100))
            quorumMet = totalVotes >= quorumNeeded
        end
        
        -- Determine if law passed
        if quorumMet and passPercentage >= Config.Legislation.passThreshold then
            -- Law passed
            MySQL.update.await([[
                UPDATE government_laws
                SET status = 'active', passed_date = NOW()
                WHERE id = ?
            ]], { law.id })
            
            -- Create document in unstable-documents
            if Config.Legislation.createDocumentOnPass then
                TriggerEvent('unstable-documents:server:createLawDocument', {
                    title = law.title,
                    content = law.description,
                    author = law.created_by_name,
                    lawId = law.id
                })
            end
            
            TriggerClientEvent('QBCore:Notify', -1, 'Law "' .. law.title .. '" has been passed and is now active', 'success', 5000)
        else
            -- Law failed
            MySQL.update.await([[
                UPDATE government_laws
                SET status = 'failed'
                WHERE id = ?
            ]], { law.id })
            
            TriggerClientEvent('QBCore:Notify', -1, 'Law "' .. law.title .. '" failed to pass', 'error', 5000)
        end
    end
end)

-- Auto-process expired votes every 10 minutes
CreateThread(function()
    while true do
        Wait(600000) -- 10 minutes
        TriggerEvent('un-government:server:processExpiredLawVotes')
    end
end)

-- =====================================================
-- EXPORTS
-- =====================================================

exports('IsGovernmentOfficial', IsGovernmentOfficial)
exports('IsGovernor', IsGovernor)
exports('HasPermission', HasPermission)
exports('CanAppoint', CanAppoint)

print('^2[un-government]^7 Government system loaded successfully')
