-- AUTO GEIGER - Standalone with Tabs
local Settings = {
    Webhook = "",
    WorldGeiger = "GEIGERB",
    WorldSave = "SAVEGEIGERSS",
    AliveGeigerX = 63,
    AliveGeigerY = 24,
    DeadDropX = 60,
    DeadDropY = 24,
    ItemDropX = 65,
    ItemDropY = 24,
}
local running = false
local stopRequested = false

local function Log(x)
    LogToConsole("`0[`9Geiger`0] "..x)
end

local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GEIGER_SETTINGS.txt", "w")
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
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/GEIGER_SETTINGS.txt", "r")
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

local function runGeiger()
    if running then return end
    running = true; stopRequested = false
    Log("Geiger started (simplified)")
    -- Implementasi geiger lengkap bisa ditambahkan di sini
end

AddHook("OnDraw", "GeigerGUI", function(dt)
    if ImGui.Begin("AUTO GEIGER", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("GeigerTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                
                local changedWG, newWG = ImGui.InputText("World Geiger", Settings.WorldGeiger, 30)
                if changedWG then Settings.WorldGeiger = newWG end
                
                local changedWS, newWS = ImGui.InputText("World Save", Settings.WorldSave, 30)
                if changedWS then Settings.WorldSave = newWS end
                
                local changedWeb, newWeb = ImGui.InputText("Webhook URL", Settings.Webhook, 100)
                if changedWeb then Settings.Webhook = newWeb end
                
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Geiger", 120, 30) then runGeiger() end
                else
                    if ImGui.Button("Stop", 120, 30) then stopRequested = true; running = false end
                end
                
                ImGui.EndTabItem()
            end
            
            -- SETTINGS TAB
            if ImGui.BeginTabItem("Settings") then
                ImGui.Text("Alive Geiger Position:")
                local changedAGX, newAGX = ImGui.InputInt("Alive X", Settings.AliveGeigerX, 1, 10)
                if changedAGX then Settings.AliveGeigerX = newAGX end
                local changedAGY, newAGY = ImGui.InputInt("Alive Y", Settings.AliveGeigerY, 1, 10)
                if changedAGY then Settings.AliveGeigerY = newAGY end
                
                ImGui.Text("Dead Drop Position:")
                local changedDDX, newDDX = ImGui.InputInt("Dead X", Settings.DeadDropX, 1, 10)
                if changedDDX then Settings.DeadDropX = newDDX end
                local changedDDY, newDDY = ImGui.InputInt("Dead Y", Settings.DeadDropY, 1, 10)
                if changedDDY then Settings.DeadDropY = newDDY end
                
                ImGui.Text("Item Drop Position:")
                local changedIDX, newIDX = ImGui.InputInt("Item X", Settings.ItemDropX, 1, 10)
                if changedIDX then Settings.ItemDropX = newIDX end
                local changedIDY, newIDY = ImGui.InputInt("Item Y", Settings.ItemDropY, 1, 10)
                if changedIDY then Settings.ItemDropY = newIDY end
                
                ImGui.Separator()
                if ImGui.Button("Save Settings", 150, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load Settings", 150, 30) then LoadSettings() end
                
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Ertoxz")
                ImGui.Text("AUTO GEIGER Module")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("Geiger module loaded")
LoadSettings()
