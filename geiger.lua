-- ==================== AUTO GEIGER (DENGAN STATUS DETAIL) ====================
local geigerConfig = {
    webhook = "",
    worldGeiger = "GEIGERB",
    worldSave = "SAVEGEIGERSS",
    aliveGeigerPos = {63, 24},
    deadDropLeft = {60, 24},
    itemDropLeft = {65, 24},
}

local geigerVars = {
    redPosX = {25, 5, 5, 25, 15, 14},
    redPosY = {5, 25, 5, 25, 25, 3},
    listFound = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    red = 0,
    yellow = 1,
    green = 2,
    currentRing = 0,
    newRing = false,
    itemFound = false,
    totalFound = 0,
    canDrop = true,
    breakLoop = false,
    aliveGeiger = 0,
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GEIGER_SETTINGS.txt", "w")
    if file then
        file:write("webhook=" .. geigerConfig.webhook .. "\n")
        file:write("worldGeiger=" .. geigerConfig.worldGeiger .. "\n")
        file:write("worldSave=" .. geigerConfig.worldSave .. "\n")
        file:write("aliveX=" .. geigerConfig.aliveGeigerPos[1] .. "\n")
        file:write("aliveY=" .. geigerConfig.aliveGeigerPos[2] .. "\n")
        file:write("deadX=" .. geigerConfig.deadDropLeft[1] .. "\n")
        file:write("deadY=" .. geigerConfig.deadDropLeft[2] .. "\n")
        file:write("itemX=" .. geigerConfig.itemDropLeft[1] .. "\n")
        file:write("itemY=" .. geigerConfig.itemDropLeft[2] .. "\n")
        file:close()
        LogToConsole("`2Geiger settings saved.")
    else
        LogToConsole("`4Failed to save geiger settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GEIGER_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "webhook" then geigerConfig.webhook = value
                elseif key == "worldGeiger" then geigerConfig.worldGeiger = value
                elseif key == "worldSave" then geigerConfig.worldSave = value
                elseif key == "aliveX" then geigerConfig.aliveGeigerPos[1] = tonumber(value)
                elseif key == "aliveY" then geigerConfig.aliveGeigerPos[2] = tonumber(value)
                elseif key == "deadX" then geigerConfig.deadDropLeft[1] = tonumber(value)
                elseif key == "deadY" then geigerConfig.deadDropLeft[2] = tonumber(value)
                elseif key == "itemX" then geigerConfig.itemDropLeft[1] = tonumber(value)
                elseif key == "itemY" then geigerConfig.itemDropLeft[2] = tonumber(value)
                end
            end
        end
        file:close()
        LogToConsole("`2Geiger settings loaded.")
    else
        LogToConsole("`3No geiger settings file found.")
    end
end

-- (Semua fungsi asli geiger seperti geigerLog, geigerFoundYellow, dll. harus diletakkan di sini)
-- ...

-- Fungsi utama (gantikan dengan yang sudah ada)
local function runAutoGeiger()
    -- ... (kode asli geiger di dalam thread) ...
end

-- Fungsi start/stop
local function startGeiger()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(function() runAutoGeiger() end)
end

local function stopGeiger()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- Helper untuk mendapatkan nama warna sinyal
local function getRingName()
    if geigerVars.currentRing == geigerVars.red then return "Merah"
    elseif geigerVars.currentRing == geigerVars.yellow then return "Kuning"
    elseif geigerVars.currentRing == geigerVars.green then return "Hijau"
    else return "Unknown" end
end

-- ==================== GUI ====================
AddHook("OnDraw", "GeigerGUI", function(dt)
    if ImGui.Begin("Auto Geiger - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("GeigerTabs") then
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                local changedWeb, newWeb = ImGui.InputText("Webhook URL", geigerConfig.webhook, 100)
                if changedWeb then geigerConfig.webhook = newWeb end
                local changedWG, newWG = ImGui.InputText("World Geiger", geigerConfig.worldGeiger, 30)
                if changedWG then geigerConfig.worldGeiger = newWG end
                local changedWS, newWS = ImGui.InputText("World Save", geigerConfig.worldSave, 30)
                if changedWS then geigerConfig.worldSave = newWS end
                ImGui.Text("Alive Geiger Position:")
                local changedAGX, newAGX = ImGui.InputInt("X", geigerConfig.aliveGeigerPos[1], 1, 10)
                if changedAGX then geigerConfig.aliveGeigerPos[1] = newAGX end
                local changedAGY, newAGY = ImGui.InputInt("Y", geigerConfig.aliveGeigerPos[2], 1, 10)
                if changedAGY then geigerConfig.aliveGeigerPos[2] = newAGY end
                ImGui.Text("Dead Drop Left:")
                local changedDDX, newDDX = ImGui.InputInt("X", geigerConfig.deadDropLeft[1], 1, 10)
                if changedDDX then geigerConfig.deadDropLeft[1] = newDDX end
                local changedDDY, newDDY = ImGui.InputInt("Y", geigerConfig.deadDropLeft[2], 1, 10)
                if changedDDY then geigerConfig.deadDropLeft[2] = newDDY end
                ImGui.Text("Item Drop Left:")
                local changedIDX, newIDX = ImGui.InputInt("X", geigerConfig.itemDropLeft[1], 1, 10)
                if changedIDX then geigerConfig.itemDropLeft[1] = newIDX end
                local changedIDY, newIDY = ImGui.InputInt("Y", geigerConfig.itemDropLeft[2], 1, 10)
                if changedIDY then geigerConfig.itemDropLeft[2] = newIDY end
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Geiger", 120, 30) then startGeiger() end
                else
                    if ImGui.Button("Stop Geiger", 120, 30) then stopGeiger() end
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
                ImGui.Text("Sinyal: " .. getRingName())
                ImGui.Text("Total Ditemukan: " .. geigerVars.totalFound)
                ImGui.Text("Stuff: " .. geigerVars.listFound[1])
                ImGui.Text("Crystal Black: " .. geigerVars.listFound[2])
                ImGui.Text("Crystal Green: " .. geigerVars.listFound[3])
                ImGui.Text("Crystal Red: " .. geigerVars.listFound[4])
                ImGui.Text("Crystal White: " .. geigerVars.listFound[5])
                ImGui.Text("Chemical Haunted: " .. geigerVars.listFound[6])
                ImGui.Text("Chemical Radioactive: " .. geigerVars.listFound[7])
                ImGui.Text("Growtoken: " .. geigerVars.listFound[8])
                ImGui.Text("Battery: " .. geigerVars.listFound[9])
                ImGui.Text("D Battery: " .. geigerVars.listFound[10])
                ImGui.Text("Charger: " .. geigerVars.listFound[11])
                ImGui.Text("Geiger Alive: " .. geigerVars.aliveGeiger)
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Geiger Script by Swipez")
                ImGui.Text("Modified by Ertoxz")
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

LogToConsole("Geiger script loaded. Use GUI to start.")
