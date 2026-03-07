-- ==================== AUTO PTHT (DENGAN KONTROL START/STOP) ====================
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

-- Fungsi asli (harus didefinisikan di sini, dari script sebelumnya)
function pthtSendPacketRaw(H, I, J, K, L)
    SendPacketRaw(false, {type = H, state = I, value = J, px = K, py = L, x = K * 32, y = L * 32})
end

function pthtTextO(x)
    SendVariantList{[0] = "OnTextOverlay", [1] = x}
    LogToConsole(x)
end

function pthtIsReady(tile)
    return tile and tile.extra and tile.extra.progress == 1
end

function pthtGetMagplant()
    local Found = {}
    local sizeX, sizeY = 200, 200
    for x = 0, sizeX - 1 do
        for y = 0, sizeY - 1 do
            local tile = GetTile(x, y)
            if tile and tile.fg == 5638 and tile.bg == pthtConfig.magplantBcg then
                table.insert(Found, {x, y})
            end
        end
    end
    return Found
end

function pthtGetRemote()
    local Magplant = pthtGetMagplant()
    if #Magplant > 0 then
        local x = Magplant[pthtVars.current][1]
        local y = Magplant[pthtVars.current][2]
        pthtSendPacketRaw(0, 32, 0, x, y)
        Sleep(500)
        pthtSendPacketRaw(3, 0, 32, x, y)
        Sleep(500)
        SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. x .. "|\ny|" .. y .. "|\nbuttonClicked|getRemote")
        Sleep(5000)
        pthtVars.remoteEmpty = false
        pthtTextO("`2Remote Magplant diambil.")
    else
        pthtVars.remoteEmpty = true
        pthtTextO("`4Magplant tidak ditemukan!")
    end
end

function pthtChangeMode()
    if pthtConfig.startMode:upper() == "PT" then
        pthtTextO("`4[PTHT] Mode: PLANT ONLY")
        pthtVars.plant = true
        pthtVars.harvest = false
        return
    end
    if pthtVars.plant then
        pthtVars.plant = false
        pthtVars.uwsUsed = pthtVars.uwsUsed + 1
        pthtTextO("`oUWS Used: " .. pthtVars.uwsUsed)
        SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
        Sleep(5600)
        pthtTextO("`4[PTHT] Harvest Mode")
        pthtVars.harvest = true
    else
        pthtVars.harvest = false
        pthtTextO("`4[PTHT] Plant Mode")
        pthtVars.plant = true
    end
end

function pthtRotation()
    local sizeX, sizeY = 200, 200
    local put = pthtConfig.mray and 10 or 1
    for y = sizeY - 2, 0, -1 do
        if pthtStop then break end
        for x1 = 0, put - 1 do
            if pthtStop then break end
            for x2 = 0, (sizeX / put) - 1 do
                if pthtStop then break end
                local x = x2 * put + x1
                local tile = GetTile(x, y)
                if pthtVars.plant then
                    if tile and tile.fg == 0 then
                        FindPath(x, y - 1, pthtConfig.pathfinderDelay)
                        Sleep(1)
                        pthtSendPacketRaw(0, 32, 0, x, y)
                        Sleep(pthtConfig.delayPlant * 10)
                        pthtSendPacketRaw(3, 32, pthtConfig.treeID, x, y)
                        Sleep(pthtConfig.delayPlant * 10)
                    end
                elseif pthtVars.harvest then
                    if tile and tile.fg == pthtConfig.treeID and pthtIsReady(tile) then
                        FindPath(x, y, pthtConfig.pathfinderDelay)
                        Sleep(1)
                        while not pthtStop and GetTile(x, y).fg == pthtConfig.treeID and pthtIsReady(GetTile(x, y)) do
                            pthtSendPacketRaw(3, 0, 18, x, y)
                            Sleep(pthtConfig.delayHarvest * 5)
                        end
                    end
                end
            end
        end
    end
    pthtVars.counter = pthtVars.counter + 1
    pthtChangeMode()
end

function pthtReconnect()
    if GetWorld() == nil then
        SendPacket(3, "action|join_request\nname|" .. GetWorld().name .. "|\ninvitedWorld|0")
        pthtTextO("Entering world...")
        Sleep(pthtConfig.delayEntering * 100)
        pthtVars.remoteEmpty = true
    else
        if pthtVars.remoteEmpty then
            pthtTextO("Taking remote...")
            pthtGetRemote()
        end
        pthtRotation()
    end
end

-- Fungsi utama yang akan dijalankan di thread
local function runPTHT()
    pthtVars = {
        plant = pthtConfig.startMode:upper() == "PT" or pthtConfig.startMode:upper() == "PTHT",
        harvest = pthtConfig.startMode:upper() == "HT",
        limiter = 0,
        current = 1,
        remoteEmpty = true,
        counter = 0,
        uwsUsed = 0,
        iM = 0,
    }
    ChangeValue("[C] Modfly", true)

    while pthtRunning and not pthtStop do
        local loopValue = pthtConfig.loop
        if type(loopValue) == "string" and loopValue:lower() == "unli" then
            while pthtRunning and not pthtStop do
                pthtReconnect()
                Sleep(100)
            end
        elseif type(loopValue) == "number" then
            repeat
                pthtReconnect()
                if pthtStop then break end
                if (pthtVars.counter // 2) + 1 >= loopValue then
                    pthtRotation()
                    pthtTextO("PTHT DONE")
                    break
                end
            until pthtStop
        end
    end
    pthtRunning = false
    currentStatus = "Stopped"
    pthtTextO("PTHT stopped")
end

-- Fungsi start/stop
local function startPTHT()
    if pthtRunning then return end
    pthtRunning = true
    pthtStop = false
    currentStatus = "Running"
    RunThread(runPTHT)
end

local function stopPTHT()
    if pthtRunning then
        pthtStop = true
        currentStatus = "Stopping..."
    end
end

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

-- Helper untuk status
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

LogToConsole("PTHT loaded. Use GUI to start.")
