-- ==================== PUT/BREAK PLAT (DENGAN KONTROL START/STOP) ====================
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
local currentAction = ""  -- "put" atau "break"
local currentStatus = "Idle"

-- Fungsi asli
local function getWorldSize()
    if Settings.WorldType == "normal" then return 100, 60
    elseif Settings.WorldType == "nether" then return 150, 150
    else return 200, 200 end
end

local function inv(id)
    for _, item in pairs(GetInventory()) do
        if item.id == id then return item.amount end
    end
    return 0
end

-- Fungsi untuk Put
local function runPut()
    currentAction = "put"
    ChangeValue("[C] Modfly", true)
    ChangeValue("[C] Ghost mode", true)
    local put = Settings.Mray and 10 or 1
    local sizeX, sizeY = getWorldSize()
    while running and not stopRequested do
        for y = sizeY - 2, 0, -1 do
            if not running or stopRequested then break end
            for x1 = 0, put - 1 do
                if not running or stopRequested then break end
                for x2 = 0, (sizeX / put) - 1 do
                    if not running or stopRequested then break end
                    local x = x2 * put + x1
                    local tile = GetTile(x, y)
                    if tile and tile.fg == 0 and y % 2 == 1 then
                        FindPath(x, y - 1, 520)
                        Sleep(1)
                        SendPacketRaw(false, {state = 32, x = x * 32 - 32, y = y * 32})
                        Sleep(1)
                        SendPacketRaw(false, {type = 3, value = Settings.PlatID, px = x, py = y, x = x * 32, y = y * 32})
                        Sleep(Settings.Delay)
                    end
                end
            end
        end
        if not stopRequested then Sleep(1000) end
    end
    running = false
    currentStatus = "Stopped"
    LogToConsole("Put Plat stopped")
end

-- Fungsi untuk Break
local function runBreak()
    currentAction = "break"
    ChangeValue("[C] Modfly", true)
    local put = Settings.Mray and 10 or 1
    local sizeX, sizeY = getWorldSize()
    while running and not stopRequested do
        for y = sizeY - 2, 0, -1 do
            if not running or stopRequested then break end
            for x1 = 0, put - 1 do
                if not running or stopRequested then break end
                for x2 = 0, (sizeX / put) - 1 do
                    if not running or stopRequested then break end
                    local x = x2 * put + x1
                    local tile = GetTile(x, y)
                    if tile and tile.fg == Settings.PlatID then
                        FindPath(x, y, 520)
                        Sleep(1)
                        while not stopRequested and GetTile(x, y).fg == Settings.PlatID do
                            SendPacketRaw(false, {type = 3, value = 18, px = x, py = y, x = x * 32, y = y * 32})
                            Sleep(Settings.Delay)
                        end
                    end
                end
            end
        end
        if not stopRequested then Sleep(1000) end
    end
    running = false
    currentStatus = "Stopped"
    LogToConsole("Break Plat stopped")
end

-- Fungsi start/stop
local function startPut()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running (Put)"
    RunThread(runPut)
end

local function startBreak()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running (Break)"
    RunThread(runBreak)
end

local function stopAction()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

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
        LogToConsole("`2Settings saved.")
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
                ImGui.Text("Running: " .. tostring(running))
                ImGui.Text("Action: " .. currentAction)
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

LogToConsole("PUT/BREAK PLAT loaded. Use GUI to start.")
