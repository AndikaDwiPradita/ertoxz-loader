-- ==================== AUTO GRINDER (DENGAN KONTROL START/STOP) ====================
local grinderConfig = {
    itemID = 4584,
    resultID = 4570,
    delay = 150,
    dropX = 84,
    dropY = 22,
    maxAttempts = 125,
}
local grinderRunning = false
local grinderStop = false
local grinderVars = {
    startX = 0,
    startY = 0,
    dropY = {},
    counter = 0,
    grindMode = false,
}
local currentStatus = "Idle"

-- Fungsi asli
function grinderInv(id)
    local count = 0
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            count = count + item.amount
        end
    end
    return count
end

function grinderFP(x, y)
    local px = math.floor(GetLocal().pos.x / 32)
    local py = math.floor(GetLocal().pos.y / 32)
    
    while math.abs(y - py) > 6 do
        py = py + (y - py > 0 and 6 or -6)
        FindPath(px, py, 520)
        Sleep(200)
        if grinderStop then return end
    end
    while math.abs(x - px) > 6 do
        px = px + (x - px > 0 and 6 or -6)
        FindPath(px, py, 520)
        Sleep(200)
        if grinderStop then return end
    end
    Sleep(100)
    FindPath(x, y, 520)
end

function grinderDrops(id, index, startX, startY)
    if not grinderVars.dropY then grinderVars.dropY = {} end
    if not grinderVars.dropY[index] then
        grinderVars.dropY[index] = startY
    end
    local x = startX + (index - 1)
    local y = grinderVars.dropY[index] or startY
    
    grinderFP(x - 1, y)
    Sleep(500)
    if grinderStop then return end
    
    for a = 1, 24 do
        if grinderInv(id) >= 250 then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..id.."|\nitem_count|"..grinderInv(id).."|\n")
            Sleep(400)
            if grinderStop then return end
        end
    end
    
    grinderFP(grinderVars.startX, grinderVars.startY)
    Sleep(500)
    
    if grinderInv(id) >= 250 then
        grinderVars.dropY[index] = grinderVars.dropY[index] - 1
    end
end

-- Fungsi utama
local function runAutoGrinder()
    grinderVars.startX = math.floor(GetLocal().pos.x / 32)
    grinderVars.startY = math.floor(GetLocal().pos.y / 32)
    grinderVars.dropY = {}

    -- Hook untuk memblok dialog Item Finder
    local grinderHookLabel = "GrinderHook_" .. math.random(1000, 9999)
    AddHook("OnVariant", grinderHookLabel, function(var)
        if var[0] == "OnDialogRequest" and var[1] and var[1]:find("Item Finder") then
            return true
        end
        return false
    end)

    ChangeValue("[C] Modfly", true)

    local counter = 0
    local grindMode = false

    while grinderRunning and not grinderStop do
        if grinderInv(grinderConfig.resultID) >= 250 then
            grinderDrops(grinderConfig.resultID, 1, grinderConfig.dropX, grinderConfig.dropY)
            if grinderStop then break end
            counter = 0
            grindMode = false
        end

        if grindMode then
            SendPacket(2, "action|dialog_return\ndialog_name|grinder\nx|"..grinderVars.startX.."|\ny|"..grinderVars.startY.."|\nitemID|"..grinderConfig.itemID.."|\namount|2")
            Sleep(100)
        else
            if counter < grinderConfig.maxAttempts then
                SendPacket(2, "action|dialog_return\ndialog_name|item_search\n"..grinderConfig.itemID.."|1\n")
                Sleep(grinderConfig.delay)
                SendPacket(2, "action|dialog_return\ndialog_name|grinder\nx|"..grinderVars.startX.."|\ny|"..grinderVars.startY.."|\nitemID|"..grinderConfig.itemID.."|\namount|2")
                Sleep(100)
                counter = counter + 1
                LogToConsole(string.format("Grinder Attempt: %d/%d", counter, grinderConfig.maxAttempts))
                if counter >= grinderConfig.maxAttempts then
                    grindMode = true
                end
            end
        end

        if grindMode and counter < grinderConfig.maxAttempts then
            grindMode = false
        end

        Sleep(100)
    end

    RemoveHook(grinderHookLabel)
    grinderRunning = false
    currentStatus = "Stopped"
    LogToConsole("Auto Grinder dihentikan.")
end

-- Fungsi start/stop
local function startGrinder()
    if grinderRunning then return end
    grinderRunning = true
    grinderStop = false
    currentStatus = "Running"
    RunThread(runAutoGrinder)
end

local function stopGrinder()
    if grinderRunning then
        grinderStop = true
        currentStatus = "Stopping..."
    end
end

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GRINDER_SETTINGS.txt", "w")
    if file then
        file:write("itemID=" .. grinderConfig.itemID .. "\n")
        file:write("resultID=" .. grinderConfig.resultID .. "\n")
        file:write("delay=" .. grinderConfig.delay .. "\n")
        file:write("dropX=" .. grinderConfig.dropX .. "\n")
        file:write("dropY=" .. grinderConfig.dropY .. "\n")
        file:write("maxAttempts=" .. grinderConfig.maxAttempts .. "\n")
        file:close()
        LogToConsole("`2Grinder settings saved.")
    else
        LogToConsole("`4Failed to save grinder settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GRINDER_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                local num = tonumber(value)
                if key == "itemID" then grinderConfig.itemID = num
                elseif key == "resultID" then grinderConfig.resultID = num
                elseif key == "delay" then grinderConfig.delay = num
                elseif key == "dropX" then grinderConfig.dropX = num
                elseif key == "dropY" then grinderConfig.dropY = num
                elseif key == "maxAttempts" then grinderConfig.maxAttempts = num
                end
            end
        end
        file:close()
        LogToConsole("`2Grinder settings loaded.")
    else
        LogToConsole("`3No grinder settings file found.")
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "GrinderGUI", function(dt)
    if ImGui.Begin("Auto Grinder - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("GrinderTabs") then
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                local changedItem, newItem = ImGui.InputInt("ID Item Grind", grinderConfig.itemID, 1, 100)
                if changedItem then grinderConfig.itemID = newItem end
                local changedResult, newResult = ImGui.InputInt("ID Item Hasil", grinderConfig.resultID, 1, 100)
                if changedResult then grinderConfig.resultID = newResult end
                local changedDelay, newDelay = ImGui.InputInt("Delay (ms)", grinderConfig.delay, 10, 100)
                if changedDelay then grinderConfig.delay = newDelay end
                local changedDropX, newDropX = ImGui.InputInt("Drop X", grinderConfig.dropX, 1, 10)
                if changedDropX then grinderConfig.dropX = newDropX end
                local changedDropY, newDropY = ImGui.InputInt("Drop Y", grinderConfig.dropY, 1, 10)
                if changedDropY then grinderConfig.dropY = newDropY end
                local changedMax, newMax = ImGui.InputInt("Max Attempts", grinderConfig.maxAttempts, 1, 10)
                if changedMax then grinderConfig.maxAttempts = newMax end
                ImGui.Separator()
                if not grinderRunning then
                    if ImGui.Button("Start Grinder", 120, 30) then startGrinder() end
                else
                    if ImGui.Button("Stop Grinder", 120, 30) then stopGrinder() end
                end
                ImGui.SameLine()
                if ImGui.Button("Save Settings", 120, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load Settings", 120, 30) then LoadSettings() end
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Item Grind: " .. grinderConfig.itemID)
                ImGui.Text("Item Hasil: " .. grinderConfig.resultID)
                ImGui.Text("Jumlah Item Grind: " .. grinderInv(grinderConfig.itemID))
                ImGui.Text("Jumlah Item Hasil: " .. grinderInv(grinderConfig.resultID))
                ImGui.Text("Attempt: " .. (grinderVars.counter or 0) .. "/" .. grinderConfig.maxAttempts)
                ImGui.Text("Mode: " .. (grinderVars.grindMode and "Grind" or "Ambil"))
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

LogToConsole("Grinder script loaded. Use GUI to start.")
