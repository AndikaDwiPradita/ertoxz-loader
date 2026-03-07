-- ==================== AUTO GRINDER (DENGAN STATUS DETAIL) ====================
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

-- (Fungsi asli grinder di sini, misal runAutoGrinder, dll.)

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
                ImGui.Text("Jumlah Item Grind: " .. inv(grinderConfig.itemID))
                ImGui.Text("Jumlah Item Hasil: " .. inv(grinderConfig.resultID))
                ImGui.Text("Attempt: " .. (grinderVars.counter or 0) .. "/" .. grinderConfig.maxAttempts)
                ImGui.Text("Mode: " .. (grinderVars.grindMode and "Grind" or "Ambil"))
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Grinder Script by Lantas")
                ImGui.Text("Modified by Ertoxz")
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)
