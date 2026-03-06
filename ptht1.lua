-- AUTO PTHT - Standalone with Tabs
local Settings = {
    TreeID = 15159,
    StartMode = "PT",
    Loop = 1,
    DelayHarvest = 50,
    DelayEntering = 50,
    DelayPlant = 10,
    Mray = true,
    Webhook = "",
    DiscordID = "",
    MagplantLimit = 200,
    MagplantBcg = 12840,
    PathfinderDelay = 520,
    PosX = 0,
    PosY = 0,
}
local running = false
local stopRequested = false
local worldName = string.upper(GetWorld().name)

local function inv(id)
    for _, item in pairs(GetInventory()) do
        if item.id == id then return item.amount end
    end
    return 0
end

local function Log(x)
    LogToConsole("`0[`9PTHT`0] "..x)
end

local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_SETTINGS.txt", "w")
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
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_SETTINGS.txt", "r")
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

local function pthtSendPacketRaw(H, I, J, K, L)
    SendPacketRaw(false, {type = H, state = I, value = J, px = K, py = L, x = K * 32, y = L * 32})
end

local function pthtIsReady(tile)
    return tile and tile.extra and tile.extra.progress == 1
end

local function runPTHT()
    if running then return end
    running = true; stopRequested = false
    local plant = Settings.StartMode:upper() == "PT" or Settings.StartMode:upper() == "PTHT"
    local harvest = Settings.StartMode:upper() == "HT"
    local put = Settings.Mray and 10 or 1
    
    ChangeValue("[C] Modfly", true)
    RunThread(function()
        while not stopRequested do
            for y = 198, 0, -2 do
                if stopRequested then break end
                for x = 0, 199, put do
                    if stopRequested then break end
                    local tile = GetTile(x, y)
                    if plant and tile and tile.fg == 0 then
                        FindPath(x, y - 1, Settings.PathfinderDelay)
                        Sleep(1)
                        pthtSendPacketRaw(0, 32, 0, x, y)
                        Sleep(Settings.DelayPlant * 10)
                        pthtSendPacketRaw(3, 32, Settings.TreeID, x, y)
                        Sleep(Settings.DelayPlant * 10)
                    elseif harvest and tile and tile.fg == Settings.TreeID and pthtIsReady(tile) then
                        FindPath(x, y, Settings.PathfinderDelay)
                        Sleep(1)
                        pthtSendPacketRaw(3, 0, 18, x, y)
                        Sleep(Settings.DelayHarvest * 5)
                    end
                end
            end
            Sleep(100)
        end
        running = false
    end)
end

AddHook("OnDraw", "PTHTGUI", function(dt)
    if ImGui.Begin("AUTO PTHT", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PTHTTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                
                local changedTree, newTree = ImGui.InputInt("ID Tree", Settings.TreeID, 1, 100)
                if changedTree then Settings.TreeID = newTree end
                
                local changedMode, newMode = ImGui.InputText("Mode (PT/PTHT/HT)", Settings.StartMode, 10)
                if changedMode then Settings.StartMode = newMode end
                
                local loopStr = tostring(Settings.Loop)
                local changedLoop, newLoop = ImGui.InputText("Loop (angka/'unli')", loopStr, 10)
                if changedLoop then
                    if newLoop:lower() == "unli" then Settings.Loop = "unli"
                    else local num = tonumber(newLoop); if num then Settings.Loop = num end end
                end
                
                local changedDH, newDH = ImGui.InputInt("Harvest Delay", Settings.DelayHarvest, 1, 10)
                if changedDH then Settings.DelayHarvest = newDH end
                
                local changedDP, newDP = ImGui.InputInt("Plant Delay", Settings.DelayPlant, 1, 10)
                if changedDP then Settings.DelayPlant = newDP end
                
                local changedPD, newPD = ImGui.InputInt("Pathfinder Delay", Settings.PathfinderDelay, 10, 100)
                if changedPD then Settings.PathfinderDelay = newPD end
                
                local changedMray, newMray = ImGui.Checkbox("Mray", Settings.Mray)
                if changedMray then Settings.Mray = newMray end
                
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start PTHT", 120, 30) then runPTHT() end
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
                
                ImGui.Text("Webhook:")
                local changedWeb, newWeb = ImGui.InputText("URL", Settings.Webhook, 100)
                if changedWeb then Settings.Webhook = newWeb end
                
                local changedDisc, newDisc = ImGui.InputText("Discord ID", Settings.DiscordID, 30)
                if changedDisc then Settings.DiscordID = newDisc end
                
                ImGui.Text("Magplant:")
                local changedLimit, newLimit = ImGui.InputInt("Limit", Settings.MagplantLimit, 1, 10)
                if changedLimit then Settings.MagplantLimit = newLimit end
                
                local changedBcg, newBcg = ImGui.InputInt("Background ID", Settings.MagplantBcg, 1, 100)
                if changedBcg then Settings.MagplantBcg = newBcg end
                
                ImGui.Separator()
                if ImGui.Button("Save Settings", 150, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load Settings", 150, 30) then LoadSettings() end
                
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Ertoxz")
                ImGui.Text("AUTO PTHT Module")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("PTHT module loaded")
LoadSettings()
