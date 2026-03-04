-- AUTO GRINDER - Standalone with Tabs
local Settings = {
    ItemID = 4584,
    ResultID = 4570,
    Delay = 150,
    DropX = 84,
    DropY = 22,
    MaxAttempts = 125,
    PosX = 0,
    PosY = 0,
}
local running = false
local stopRequested = false

local function inv(id)
    for _, item in pairs(GetInventory()) do
        if item.id == id then return item.amount end
    end
    return 0
end

local function Log(x)
    LogToConsole("`0[`9Grinder`0] "..x)
end

local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GRINDER_SETTINGS.txt", "w")
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
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GRINDER_SETTINGS.txt", "r")
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

local function runGrinder()
    if running then return end
    running = true; stopRequested = false
    local startX, startY = Settings.PosX, Settings.PosY
    if startX == 0 or startY == 0 then
        startX = math.floor(GetLocal().pos.x / 32)
        startY = math.floor(GetLocal().pos.y / 32)
    end
    
    RunThread(function()
        local counter = 0
        local grindMode = false
        while not stopRequested do
            if inv(Settings.ResultID) >= 250 then
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..Settings.ResultID.."|\nitem_count|"..inv(Settings.ResultID).."|\n")
                Sleep(500)
                counter = 0
                grindMode = false
            end
            
            if grindMode then
                SendPacket(2, "action|dialog_return\ndialog_name|grinder\nx|"..startX.."|\ny|"..startY.."|\nitemID|"..Settings.ItemID.."|\namount|2")
                Sleep(100)
            else
                if counter < Settings.MaxAttempts then
                    SendPacket(2, "action|dialog_return\ndialog_name|item_search\n"..Settings.ItemID.."|1\n")
                    Sleep(Settings.Delay)
                    SendPacket(2, "action|dialog_return\ndialog_name|grinder\nx|"..startX.."|\ny|"..startY.."|\nitemID|"..Settings.ItemID.."|\namount|2")
                    Sleep(100)
                    counter = counter + 1
                    Log("Attempt: "..counter.."/"..Settings.MaxAttempts)
                    if counter >= Settings.MaxAttempts then grindMode = true end
                end
            end
            Sleep(100)
        end
        running = false
    end)
end

AddHook("OnDraw", "GrinderGUI", function(dt)
    if ImGui.Begin("AUTO GRINDER", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("GrinderTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                
                local changedItem, newItem = ImGui.InputInt("ID Item Grind", Settings.ItemID, 1, 100)
                if changedItem then Settings.ItemID = newItem end
                
                local changedResult, newResult = ImGui.InputInt("ID Item Hasil", Settings.ResultID, 1, 100)
                if changedResult then Settings.ResultID = newResult end
                
                local changedDelay, newDelay = ImGui.InputInt("Delay (ms)", Settings.Delay, 10, 100)
                if changedDelay then Settings.Delay = newDelay end
                
                local changedMax, newMax = ImGui.InputInt("Max Attempts", Settings.MaxAttempts, 1, 10)
                if changedMax then Settings.MaxAttempts = newMax end
                
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Grinder", 120, 30) then runGrinder() end
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
                
                ImGui.Text("Drop Position:")
                local changedDX, newDX = ImGui.InputInt("Drop X", Settings.DropX, 1, 10)
                if changedDX then Settings.DropX = newDX end
                local changedDY, newDY = ImGui.InputInt("Drop Y", Settings.DropY, 1, 10)
                if changedDY then Settings.DropY = newDY end
                
                ImGui.Separator()
                if ImGui.Button("Save Settings", 150, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load Settings", 150, 30) then LoadSettings() end
                
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Ertoxz")
                ImGui.Text("AUTO GRINDER Module")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("Grinder module loaded")
LoadSettings()
