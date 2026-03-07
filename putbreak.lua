-- ==================== PUT/BREAK PLAT (DENGAN SAVE/LOAD) ====================
local Settings = {
    PlatID = 7520,
    Delay = 3000,
    WorldType = "island",
    Mray = false,
    AutoFind = false,
    PosX = 0,
    PosY = 0,
}
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PUTBREAK_SETTINGS.txt", "w")
    if file then
        file:write("PlatID=" .. Settings.PlatID .. "\n")
        file:write("Delay=" .. Settings.Delay .. "\n")
        file:write("WorldType=" .. Settings.WorldType .. "\n")
        file:write("Mray=" .. tostring(Settings.Mray) .. "\n")
        file:write("AutoFind=" .. tostring(Settings.AutoFind) .. "\n")
        file:write("PosX=" .. Settings.PosX .. "\n")
        file:write("PosY=" .. Settings.PosY .. "\n")
        file:close()
        LogToConsole("`2PutBreak settings saved.")
    else
        LogToConsole("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PUTBREAK_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "PlatID" then Settings.PlatID = tonumber(value)
                elseif key == "Delay" then Settings.Delay = tonumber(value)
                elseif key == "WorldType" then Settings.WorldType = value
                elseif key == "Mray" then Settings.Mray = (value == "true")
                elseif key == "AutoFind" then Settings.AutoFind = (value == "true")
                elseif key == "PosX" then Settings.PosX = tonumber(value)
                elseif key == "PosY" then Settings.PosY = tonumber(value)
                end
            end
        end
        file:close()
        LogToConsole("`2Settings loaded.")
    else
        LogToConsole("`3No settings file found.")
    end
end

-- (Fungsi asli runPut, runBreak di sini)

-- ==================== GUI ====================
AddHook("OnDraw", "PutBreakGUI", function(dt)
    if ImGui.Begin("PUT / BREAK PLAT - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PBTabs") then
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                local changed, newID = ImGui.InputInt("ID Plat", Settings.PlatID, 1, 100)
                if changed then Settings.PlatID = newID end
                local changedD, newDelay = ImGui.InputInt("Delay (ms)", Settings.Delay, 10, 100)
                if changedD then Settings.Delay = newDelay end
                ImGui.Text("World Type:")
                if ImGui.RadioButton("Normal", Settings.WorldType == "normal") then Settings.WorldType = "normal" end
                ImGui.SameLine()
                if ImGui.RadioButton("Island", Settings.WorldType == "island") then Settings.WorldType = "island" end
                ImGui.SameLine()
                if ImGui.RadioButton("Nether", Settings.WorldType == "nether") then Settings.WorldType = "nether" end
                local changedM, newMray = ImGui.Checkbox("Mray", Settings.Mray)
                if changedM then Settings.Mray = newMray end
                local changedAF, newAF = ImGui.Checkbox("Auto Find Item", Settings.AutoFind)
                if changedAF then Settings.AutoFind = newAF end
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Put", 100, 30) then startPut() end
                    ImGui.SameLine()
                    if ImGui.Button("Start Break", 100, 30) then startBreak() end
                else
                    if ImGui.Button("Stop", 100, 30) then stopAction() end
                end
                ImGui.SameLine()
                if ImGui.Button("Save", 80, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load", 80, 30) then LoadSettings() end
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Settings") then
                ImGui.Text("Position Settings")
                ImGui.Separator()
                local changedPX, newPX = ImGui.InputInt("Pos X", Settings.PosX, 1, 100)
                if changedPX then Settings.PosX = newPX end
                local changedPY, newPY = ImGui.InputInt("Pos Y", Settings.PosY, 1, 100)
                if changedPY then Settings.PosY = newPY end
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Ertoxz")
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)
