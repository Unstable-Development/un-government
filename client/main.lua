local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isGovernmentUIOpen = false

-- =====================================================
-- INITIALIZATION
-- =====================================================

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
end)

-- =====================================================
-- GOVERNMENT DASHBOARD COMMAND
-- =====================================================

RegisterCommand('gov', function()
    print("^2[UN-Government] Command triggered^7")
    -- Server will handle all permission checks (government job + god access)
    OpenGovernmentDashboard()
end, false)

TriggerEvent('chat:addSuggestion', '/gov', 'Open Government Dashboard')

-- =====================================================
-- OPEN GOVERNMENT DASHBOARD
-- =====================================================

function OpenGovernmentDashboard()
    if isGovernmentUIOpen then 
        print("^3[UN-Government] Dashboard already open^7")
        return 
    end
    
    print("^2[UN-Government] Requesting dashboard data...^7")
    print("^2[UN-Government] PlayerData:^7", json.encode(PlayerData))
    
    QBCore.Functions.TriggerCallback('un-government:server:getDashboardData', function(data)
        print("^2[UN-Government] Callback received. Data:^7", json.encode(data))
        if data then
            print("^2[UN-Government] Opening dashboard UI^7")
            isGovernmentUIOpen = true
            SetNuiFocus(true, true)
            
            local nuiData = {
                action = "openDashboard",
                playerData = {
                    job = PlayerData.job and PlayerData.job.name or "unknown",
                    jobLabel = PlayerData.job and PlayerData.job.label or "Unknown",
                    grade = PlayerData.job and PlayerData.job.grade and PlayerData.job.grade.level or 0,
                    name = PlayerData.charinfo and (PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname) or "Unknown",
                    citizenid = PlayerData.citizenid or "unknown",
                    isGod = data.isGod
                },
                config = {
                    GovernmentJobs = Config.GovernmentJobs,
                    Dashboard = Config.Dashboard
                },
                data = data
            }
            
            print("^2[UN-Government] Sending NUI message:^7", json.encode(nuiData))
            SendNUIMessage(nuiData)
        else
            print("^1[UN-Government] No data returned - access denied^7")
            QBCore.Functions.Notify("You don't have access to the government system", "error")
        end
    end)
end

-- =====================================================
-- CLOSE DASHBOARD
-- =====================================================

RegisterNUICallback('closeDashboard', function(data, cb)
    isGovernmentUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- =====================================================
-- VOTING SYSTEM - CLIENT CALLBACKS
-- =====================================================

RegisterNUICallback('createVote', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:createVote', function(success, message)
        cb({success = success, message = message})
    end, data)
end)

RegisterNUICallback('castVote', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:castVote', function(success, message)
        cb({success = success, message = message})
    end, data.voteId, data.option)
end)

RegisterNUICallback('getVotes', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:getVotes', function(votes)
        cb(votes)
    end, data.filter)
end)

RegisterNUICallback('endVote', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:endVote', function(success, message)
        cb({success = success, message = message})
    end, data.voteId)
end)

-- =====================================================
-- APPOINTMENT SYSTEM - CLIENT CALLBACKS
-- =====================================================

RegisterNUICallback('appointOfficial', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:appointOfficial', function(success, message)
        cb({success = success, message = message})
    end, data)
end)

RegisterNUICallback('getAppointments', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:getAppointments', function(appointments)
        cb(appointments)
    end)
end)

RegisterNUICallback('removeOfficial', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:removeOfficial', function(success, message)
        cb({success = success, message = message})
    end, data.citizenid, data.reason)
end)

-- =====================================================
-- BUDGET MANAGEMENT - CLIENT CALLBACKS
-- =====================================================

RegisterNUICallback('getBudgetData', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:getBudgetData', function(budgetData)
        cb(budgetData)
    end)
end)

RegisterNUICallback('allocateFunds', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:allocateFunds', function(success, message)
        cb({success = success, message = message})
    end, data)
end)

RegisterNUICallback('withdrawFunds', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:withdrawFunds', function(success, message)
        cb({success = success, message = message})
    end, data)
end)

-- =====================================================
-- INSPECTION SYSTEM - CLIENT CALLBACKS
-- =====================================================

RegisterNUICallback('getInspectionHistory', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:getInspectionHistory', function(history)
        cb(history)
    end, data.businessName)
end)

RegisterNUICallback('scheduleInspection', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:scheduleInspection', function(success, message)
        cb({success = success, message = message})
    end, data)
end)

RegisterNUICallback('startInspection', function(data, cb)
    -- Open document creator for inspection
    if Config.Inspections.useDocumentSystem then
        ExecuteCommand('createdoc')
    end
    cb('ok')
end)

RegisterNUICallback('openDocumentCreator', function(data, cb)
    -- Open document creator
    ExecuteCommand('createdoc')
    cb('ok')
end)

-- =====================================================
-- OFFICIALS DIRECTORY - CLIENT CALLBACKS
-- =====================================================

RegisterNUICallback('getGovernmentOfficials', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:getGovernmentOfficials', function(officials)
        cb(officials)
    end)
end)

-- =====================================================
-- LEGISLATION SYSTEM - CLIENT CALLBACKS
-- =====================================================

RegisterNUICallback('getLaws', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:getLaws', function(laws)
        cb(laws)
    end, data.filter)
end)

RegisterNUICallback('proposeLaw', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:proposeLaw', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getLawDetails', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:getLawDetails', function(law)
        cb(law)
    end, data.lawId)
end)

RegisterNUICallback('voteOnLaw', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:voteOnLaw', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('vetoLaw', function(data, cb)
    QBCore.Functions.TriggerCallback('un-government:server:vetoLaw', function(result)
        cb(result)
    end, data.lawId)
end)

-- =====================================================
-- VOTING KIOSKS - QB-TARGET
-- =====================================================

CreateThread(function()
    if not Config.Voting.enabled then return end
    
    local Target = exports[Config.TargetResource]
    
    for _, location in pairs(Config.Voting.locations) do
        Target:AddBoxZone("voting_kiosk_" .. _, location.coords.xyz, 1.5, 1.5, {
            name = "voting_kiosk_" .. _,
            heading = location.coords.w,
            debugPoly = false,
            minZ = location.coords.z - 1,
            maxZ = location.coords.z + 1.5,
        }, {
            options = {
                {
                    type = "client",
                    event = "un-government:client:openVotingKiosk",
                    icon = "fas fa-vote-yea",
                    label = location.label,
                }
            },
            distance = 2.0
        })
    end
end)

RegisterNetEvent('un-government:client:openVotingKiosk', function()
    QBCore.Functions.TriggerCallback('un-government:server:getActiveVotes', function(votes)
        if #votes == 0 then
            QBCore.Functions.Notify("No active votes at this time", "error")
            return
        end
        
        -- Open voting UI
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openVotingKiosk",
            votes = votes,
            citizenid = PlayerData.citizenid
        })
    end)
end)

RegisterNUICallback('closeVotingKiosk', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- =====================================================
-- NOTIFICATIONS
-- =====================================================

RegisterNetEvent('un-government:client:notify', function(message, type, duration)
    QBCore.Functions.Notify(message, type, duration or 5000)
end)

RegisterNetEvent('un-government:client:voteCreated', function(voteData)
    if Config.Notifications.notifyOnVoteCreated then
        QBCore.Functions.Notify("New vote created: " .. voteData.title, "inform", 10000)
    end
end)

RegisterNetEvent('un-government:client:voteEnded', function(voteData)
    if Config.Notifications.notifyOnVoteEnded then
        local result = voteData.passed and "PASSED" or "FAILED"
        QBCore.Functions.Notify("Vote ended: " .. voteData.title .. " - " .. result, "inform", 10000)
    end
end)

RegisterNetEvent('un-government:client:appointed', function(jobLabel)
    if Config.Notifications.notifyOnAppointment then
        QBCore.Functions.Notify("You have been appointed to: " .. jobLabel, "success", 10000)
    end
end)

RegisterNetEvent('un-government:client:budgetUpdate', function(message)
    if Config.Notifications.notifyOnBudgetChange then
        QBCore.Functions.Notify(message, "inform", 10000)
    end
end)

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

function HasPermission(permission)
    local job = PlayerData.job.name
    if not Config.GovernmentJobs[job] then return false end
    
    local jobPerms = Config.GovernmentJobs[job].permissions
    for _, perm in pairs(jobPerms) do
        if perm == permission then
            return true
        end
    end
    
    -- Check god permission
    if Config.GodHasGovernorAccess then
        return QBCore.Functions.HasPermission(source, 'god')
    end
    
    return false
end

-- Export for other resources
exports('HasPermission', HasPermission)
