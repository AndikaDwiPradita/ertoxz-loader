-- ==================== AUTO PTHT (DENGAN STATUS DETAIL) ====================
local pthtConfig = {
    treeID = 15159,
    startMode = "PT",
    loop = 1,
    delayHarvest = 50,
    delayEntering = 50,
    delayPlant = 10,
    mray = true,
    webhook = "",
    discordID = "",
    magplantLimit = 200,
    magplantBcg = 12840,
    pathfinderDelay = 520,
    PosX = 0,
    PosY = 0,
}
local pthtRunning = false
local pthtStop = false
local pthtVars = {
    plant = false,
    harvest = false,
    limiter = 0,
    current = 1,
    remoteEmpty = true,
    counter = 0,
    uwsUsed = 0,
    iM = 0,
}
local currentStatus = "Idle"

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_SETTINGS.txt", "w")
    if file then
        file:write("treeID=" .. pthtConfig.treeID .. "\n")
        file:write("startMode=" .. pthtConfig.startMode .. "\n")
        file:write("loop=" .. tostring(pthtConfig.loop) .. "\n")
        file:write("delayHarvest=" .. pthtConfig.delayHarvest .. "\n")
        file:write("delayEntering=" .. pthtConfig.delayEntering .. "\n")
        file:write("delayPlant=" .. pthtConfig.delayPlant .. "\n")
        file:write("mray=" .. tostring(pthtConfig.mray) .. "\n")
        file:write("webhook=" .. pthtConfig.webhook .. "\n")
        file:write("discordID=" .. pthtConfig.discordID .. "\n")
        file:write("magplantLimit=" .. pthtConfig.magplantLimit .. "\n")
        file:write("magplantBcg=" .. pthtConfig.magplantBcg .. "\n")
        file:write("pathfinderDelay=" .. pthtConfig.pathfinderDelay .. "\n")
        file:write("PosX=" .. pthtConfig.PosX .. "\n")
        file:write("PosY=" .. pthtConfig.PosY .. "\n")
        file:close()
        LogToConsole("`2PTHT settings saved.")
    else
        LogToConsole("`4Failed to save PTHT settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "treeID" then pthtConfig.treeID = tonumber(value)
                elseif key == "startMode" then pthtConfig.startMode = value
                elseif key == "loop" then
                    if value == "unli" then pthtConfig.loop = "unli"
                    else pthtConfig.loop = tonumber(value) end
                elseif key == "delayHarvest" then pthtConfig.delayHarvest = tonumber(value)
                elseif key == "delayEntering" then pthtConfig.delayEntering = tonumber(value)
                elseif key == "delayPlant" then pthtConfig.delayPlant = tonumber(value)
                elseif key == "mray" then pthtConfig.mray = (value == "true")
                elseif key == "webhook" then pthtConfig.webhook = value
                elseif key == "discordID" then pthtConfig.discordID = value
                elseif key == "magplantLimit" then pthtConfig.magplantLimit = tonumber(value)
                elseif key == "magplantBcg" then pthtConfig.magplantBcg = tonumber(value)
                elseif key == "pathfinderDelay" then pthtConfig.pathfinderDelay = tonumber(value)
                elseif key == "PosX" then pthtConfig.PosX = tonumber(value)
                elseif key == "PosY" then pthtConfig.PosY = tonumber(value)
                end
            end
        end
        file:close()
        LogToConsole("`2PTHT settings loaded.")
    else
        LogToConsole("`3No PTHT settings file found.")
    end
end

-- (Fungsi asli runPTHT dll di sini)

-- Helper untuk mendapatkan mode saat ini
local function getModeName()
    if pthtVars.plant then return "Planting"
    elseif pthtVars.harvest then return "Harvesting"
    else return "Idle" end
end

-- ==================== GUI ====================
AddHook("OnDraw", "PTHTGUI", function(dt)
    if ImGui.Begin("Auto PTHT - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PTHTTabs") then
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                local changedTree, newTree = ImGui.InputInt("ID Tree", pthtConfig.treeID, 1, 100)
                if changedTree then pthtConfig.treeID = newTree end
                local changedMode, newMode = ImGui.InputText("Mode (PT/PTHT/HT)", pthtConfig.startMode, 10)
                if changedMode then pthtConfig.startMode = newMode end
                local loopStr = tostring(pthtConfig.loop)
                local changedLoop, newLoop = ImGui.InputText("Loop (angka/'unli')", loopStr, 10)
                if changedLoop then
                    if newLoop:lower() == "unli" then pthtConfig.loop = "unli"
                    else pthtConfig.loop = tonumber(newLoop) end
                end
                local changedDH, newDH = ImGui.InputInt("Harvest Delay", pthtConfig.delayHarvest, 1, 10)
                if changedDH then pthtConfig.delayHarvest = newDH end
                local changedDE, newDE = ImGui.InputInt("Entering Delay", pthtConfig.delayEntering, 1, 10)
                if changedDE then pthtConfig.delayEntering = newDE end
                local changedDP, newDP = ImGui.InputInt("Plant Delay", pthtConfig.delayPlant, 1, 10)
                if changedDP then pthtConfig.delayPlant = newDP end
                local changedPD, newPD = ImGui.InputInt("Pathfinder Delay", pthtConfig.pathfinderDelay, 10, 100)
                if changedPD then pthtConfig.pathfinderDelay = newPD end
                local changedMray, newMray = ImGui.Checkbox("Mray", pthtConfig.mray)
                if changedMray then pthtConfig.mray = newMray end
                local changedWeb, newWeb = ImGui.InputText("Webhook URL", pthtConfig.webhook, 100)
                if changedWeb then pthtConfig.webhook = newWeb end
                local changedDisc, newDisc = ImGui.InputText("Discord ID", pthtConfig.discordID, 30)
                if changedDisc then pthtConfig.discordID = newDisc end
                local changedLimit, newLimit = ImGui.InputInt("Magplant Limit", pthtConfig.magplantLimit, 1, 10)
                if changedLimit then pthtConfig.magplantLimit = newLimit end
                local changedBcg, newBcg = ImGui.InputInt("Magplant BG", pthtConfig.magplantBcg, 1, 100)
                if changedBcg then pthtConfig.magplantBcg = newBcg end
                ImGui.Separator()
                if not pthtRunning then
                    if ImGui.Button("Start PTHT", 120, 30) then startPTHT() end
                else
                    if ImGui.Button("Stop PTHT", 120, 30) then stopPTHT() end
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
                local changedPX, newPX = ImGui.InputInt("Pos X", pthtConfig.PosX, 1, 100)
                if changedPX then pthtConfig.PosX = newPX end
                local changedPY, newPY = ImGui.InputInt("Pos Y", pthtConfig.PosY, 1, 100)
                if changedPY then pthtConfig.PosY = newPY end
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Mode: " .. getModeName())
                ImGui.Text("Counter: " .. (pthtVars.counter or 0) .. " / " .. tostring(pthtConfig.loop))
                ImGui.Text("Tree Count: " .. (pthtGetTree and pthtGetTree() or "N/A"))
                ImGui.Text("Harvest Ready: " .. (pthtGetHarvest and pthtGetHarvest() or "N/A"))
                ImGui.Text("UWS: " .. inv(12600))
                ImGui.Text("Limiter: " .. pthtVars.limiter)
                ImGui.Text("Magplant Index: " .. pthtVars.current)
                ImGui.Text("Remote Empty: " .. tostring(pthtVars.remoteEmpty))
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("PTHT Script by Lantas")
                ImGui.Text("Modified by Ertoxz")
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)
