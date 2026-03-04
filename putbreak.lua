-- PUT / BREAK PLAT - Standalone with Tabs
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
local worldName = string.upper(GetWorld().name)

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

local function Log(x)
    LogToConsole("`0[`9PutBreak`0] "..x)
end

local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PUTBREAK_SETTINGS.txt", "w")
    if file then
        for k, v in pairs(Settings) do
            file:write(k.."="..tostring(v).."\n")
        end
        file:close()
        Log("Settings Saved!")
    else
        Log("Failed to save settings")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PUTBREAK_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if value == "true" then value = true
                elseif value == "false" then value = false
                elseif tonumber(value) then value = tonumber(value) end
                Settings[key] = value
            end
        end
        file:close()
        Log("Settings Loaded!")
    else
        Log("No previous settings found")
    end
end

local function runPut()
    if running then return end
    running = true; stopRequested = false
    ChangeValue("[C] Modfly", true)
    ChangeValue("[C] Ghost mode", true)
    local put = Settings.Mray and 10 or 1
    local sizeX, sizeY = getWorldSize()
    RunThread(function()
        for y = sizeY - 2, 0, -1 do
            if stopRequested then break end
            for x1 = 0, put - 1 do
                if stopRequested then break end
                for x2 = 0, (sizeX / put) - 1 do
                    if stopRequested then break end
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
        Log("Put Plat DONE")
        running = false
    end)
end

local function runBreak()
    if running then return end
    running = true; stopRequested = false
    ChangeValue("[C] Modfly", true)
    local put = Settings.Mray and 10 or 1
    local sizeX, sizeY = getWorldSize()
    RunThread(function()
        for y = sizeY - 2, 0, -1 do
            if stopRequested then break end
            for x1 = 0, put - 1 do
                if stopRequested then break end
                for x2 = 0, (sizeX / put) - 1 do
                    if stopRequested then break end
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
        Log("Break Plat DONE")
        running = false
    end)
end

AddHook("OnDraw", "PutBreakGUI", function(dt)
    if ImGui.Begin("PUT / BREAK PLAT", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PutBreakTabs") then
            -- MAIN TAB
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
                    if ImGui.Button("Start Put", 120, 30) then runPut() end
                    ImGui.SameLine()
                    if ImGui.Button("Start Break", 120, 30) then runBreak() end
                else
                    if ImGui.Button("Stop", 120, 30) then stopRequested = true; running = false end
                end
                
                ImGui.EndTabItem()
            end
            
            -- SETTINGS TAB
            if ImGui.BeginTabItem("Settings") then
                ImGui.Text("Position Settings")
                ImGui.Separator()
                
                local changedPX, newPX = ImGui.InputInt("Pos X", Settings.PosX, 1, 100)
                if changedPX then Settings.PosX = newPX end
                
                local changedPY, newPY = ImGui.InputInt("Pos Y", Settings.PosY, 1, 100)
                if changedPY then Settings.PosY = newPY end
                
                ImGui.Separator()
                if ImGui.Button("Save Settings", 150, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load Settings", 150, 30) then LoadSettings() end
                
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Ertoxz")
                ImGui.Text("PUT / BREAK PLAT Module")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("PUT/BREAK PLAT module loaded")
LoadSettings()
