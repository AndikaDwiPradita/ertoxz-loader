-- ==================== AUTO GEIGER (DENGAN KONTROL START/STOP) ====================
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

-- Fungsi asli (dari script sebelumnya, harus didefinisikan)
function geigerLog(k)
    SendVariantList{[0] = "OnTextOverlay", [1] = k}
    LogToConsole(k)
end

function geigerClamp(val, minVal, maxVal)
    return math.max(minVal, math.min(val, maxVal))
end

function geigerReconnect()
    while GetWorld().name ~= geigerConfig.worldGeiger do
        SendPacket(2, "action|input\n|text|/warp "..geigerConfig.worldGeiger.."\n")
        Sleep(5000)
    end
end

function geigerRenewRing()
    while geigerVars.newRing == false do
        geigerReconnect()
        Sleep(500)
    end
    geigerVars.newRing = false
end

function geigerFoundYellow()
    local foundPosX = GetLocal().pos.x // 32
    local foundPosY = GetLocal().pos.y // 32
    local currentLoc = 2
    local isLeft = false
    local isUp = false

    while true do
        if geigerVars.breakLoop == true then
            if GetLocal().pos.y // 32 <= 15 then
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 15, 0, 29))
            else
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -15, 0, 29))
            end
            geigerVars.breakLoop = false
            return
        end
        if geigerVars.itemFound == true then return end
        FindPath(geigerClamp(foundPosX + currentLoc, 0, 29), foundPosY)
        isLeft = false
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.yellow then break end
        FindPath(geigerClamp(foundPosX + -currentLoc, 0, 29), foundPosY)
        isLeft = true
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.yellow then break end
        currentLoc = currentLoc + 2
    end
    if geigerVars.currentRing == geigerVars.red then
        if isLeft == false then
            FindPath(geigerClamp(GetLocal().pos.x // 32 + -12, 0, 29), foundPosY)
            geigerRenewRing()
            if geigerVars.currentRing ~= geigerVars.green then
                if GetLocal().pos.y // 32 >= 20 then
                    FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -8, 0, 29))
                else
                    FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 8, 0, 29))
                end
                return
            end
        else
            FindPath(geigerClamp(GetLocal().pos.x // 32 + 12, 0, 29), foundPosY)
            geigerRenewRing()
            if geigerVars.currentRing ~= geigerVars.green then
                if GetLocal().pos.y // 32 >= 20 then
                    FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -8, 0, 29))
                else
                    FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 8, 0, 29))
                end
                return
            end
        end
        Sleep(10000)
    elseif geigerVars.currentRing == geigerVars.green then
        if isLeft == false then
            FindPath(geigerClamp(GetLocal().pos.x // 32 + 4, 0, 29), foundPosY)
        else
            FindPath(geigerClamp(GetLocal().pos.x // 32 + -4, 0, 29), foundPosY)
        end
        Sleep(10000)
    end
    foundPosX = GetLocal().pos.x // 32
    foundPosY = GetLocal().pos.y // 32
    currentLoc = 1
    while true do
        if geigerVars.breakLoop == true then
            if GetLocal().pos.y // 32 <= 15 then
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 15, 0, 29))
            else
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -15, 0, 29))
            end
            geigerVars.breakLoop = false
            return
        end
        if geigerVars.itemFound == true then return end
        FindPath(foundPosX, geigerClamp(foundPosY + currentLoc, 0, 29))
        isUp = false
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.green then break end
        FindPath(foundPosX, geigerClamp(foundPosY + -currentLoc, 0, 29))
        isUp = true
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.green then break end
        currentLoc = currentLoc + 1
    end
    if geigerVars.currentRing == geigerVars.yellow then
        if isUp == false then
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + -5, 0, 29))
        else
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + 5, 0, 29))
        end
        Sleep(10000)
    end
end

function geigerFoundGreen()
    local foundPosX = GetLocal().pos.x // 32
    local foundPosY = GetLocal().pos.y // 32
    local currentLocX = 1
    local isLeft = false
    local isUp = false

    while true do
        if geigerVars.breakLoop == true then
            if GetLocal().pos.y // 32 <= 15 then
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 15, 0, 29))
            else
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -15, 0, 29))
            end
            geigerVars.breakLoop = false
            return
        end
        if geigerVars.itemFound == true then return end
        FindPath(geigerClamp(foundPosX + currentLocX, 0, 29), foundPosY)
        isLeft = false
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.green then break end
        FindPath(geigerClamp(foundPosX + -currentLocX, 0, 29), foundPosY)
        isLeft = true
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.green then break end
        currentLocX = currentLocX + 1
    end
    if geigerVars.currentRing == geigerVars.yellow then
        if isLeft == false then
            FindPath(geigerClamp(GetLocal().pos.x // 32 + -5, 0, 29), foundPosY)
        else
            FindPath(geigerClamp(GetLocal().pos.x // 32 + 5, 0, 29), foundPosY)
        end
        Sleep(10000)
    end
    foundPosX = GetLocal().pos.x // 32
    foundPosY = GetLocal().pos.y // 32
    local currentLocY = 1
    while true do
        if geigerVars.breakLoop == true then
            if GetLocal().pos.y // 32 <= 15 then
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 15, 0, 29))
            else
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -15, 0, 29))
            end
            geigerVars.breakLoop = false
            return
        end
        if geigerVars.itemFound == true then return end
        FindPath(foundPosX, geigerClamp(foundPosY + currentLocY, 0, 29))
        isUp = false
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.green then break end
        FindPath(foundPosX, geigerClamp(foundPosY + -currentLocY, 0, 29))
        isUp = true
        geigerRenewRing()
        if geigerVars.currentRing ~= geigerVars.green then break end
        currentLocY = currentLocY + 1
    end
    if geigerVars.currentRing == geigerVars.yellow then
        if isUp == false then
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + -5, 0, 29))
        else
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + 5, 0, 29))
        end
        Sleep(10000)
    end
end

function geigerRingHook(packet)
    if packet.type == 17 then
        if packet.xspeed == 2.00 then
            geigerLog("`2Green...")
            geigerVars.currentRing = geigerVars.green
            geigerVars.newRing = true
        elseif packet.xspeed == 1.00 then
            geigerLog("`9Yellow...")
            geigerVars.currentRing = geigerVars.yellow
            geigerVars.newRing = true
        else
            geigerLog("`4Red...")
            geigerVars.currentRing = geigerVars.red
            geigerVars.newRing = true
        end
    end
end

function geigerFoundHook(varlist)
    if varlist[0]:find("OnConsoleMessage") and varlist[1]:find("oGiven") then
        if varlist[1]:find("Stuff") then
            geigerVars.listFound[1] = geigerVars.listFound[1] + 1
            geigerVars.totalFound = geigerVars.totalFound + 1
        elseif varlist[1]:find("Crystal") then
            if varlist[1]:find("Black") then
                geigerVars.listFound[2] = geigerVars.listFound[2] + 1
                geigerVars.totalFound = geigerVars.totalFound + 1
            elseif varlist[1]:find("Green") then
                geigerVars.listFound[3] = geigerVars.listFound[3] + 1
                geigerVars.totalFound = geigerVars.totalFound + 1
            elseif varlist[1]:find("Red") then
                geigerVars.listFound[4] = geigerVars.listFound[4] + 1
                geigerVars.totalFound = geigerVars.totalFound + 1
            elseif varlist[1]:find("White") then
                geigerVars.listFound[5] = geigerVars.listFound[5] + 1
                geigerVars.totalFound = geigerVars.totalFound + 1
            end
        elseif varlist[1]:find("Haunted") then
            geigerVars.listFound[6] = geigerVars.listFound[6] + 1
            geigerVars.totalFound = geigerVars.totalFound + 1
        elseif varlist[1]:find("Radioactive") then
            geigerVars.listFound[7] = geigerVars.listFound[7] + 1
            geigerVars.totalFound = geigerVars.totalFound + 1
        elseif varlist[1]:find("Growtoken") then
            geigerVars.listFound[8] = geigerVars.listFound[8] + 1
            geigerVars.totalFound = geigerVars.totalFound + 1
        elseif varlist[1]:find("`w1 Battery") then
            geigerVars.listFound[9] = geigerVars.listFound[9] + 1
            geigerVars.totalFound = geigerVars.totalFound + 1
        elseif varlist[1]:find("D Battery") then
            geigerVars.listFound[10] = geigerVars.listFound[10] + 1
            geigerVars.totalFound = geigerVars.totalFound + 1
        elseif varlist[1]:find("Charger") then
            geigerVars.listFound[11] = geigerVars.listFound[11] + 1
            geigerVars.totalFound = geigerVars.totalFound + 1
        end
        geigerLog(string.format([[
Item Found : %d
Stuff : %d
Crystal Black : %d
Crystal Green : %d
Crystal Red : %d
Crystal White : %d
Chemical Haunted : %d
Chemical Radioactive : %d
Growtoken : %d
Battery : %d
D Battery : %d
Geiger Charger : %d
]], geigerVars.totalFound, geigerVars.listFound[1], geigerVars.listFound[2], geigerVars.listFound[3], geigerVars.listFound[4], geigerVars.listFound[5], geigerVars.listFound[6], geigerVars.listFound[7], geigerVars.listFound[8], geigerVars.listFound[9], geigerVars.listFound[10], geigerVars.listFound[11]))
        geigerVars.itemFound = true
    end
    if varlist[0]:find("OnTextOverlay") and varlist[1]:find("You can't drop") then
        geigerVars.canDrop = false
    end
end

function geigerFullAFK()
    SendPacket(2, "action|input\n|text|/warp "..geigerConfig.worldSave.."\n")
    Sleep(5000)
    while GetWorld().name ~= geigerConfig.worldSave do
        Sleep(5000)
        SendPacket(2, "action|input\n|text|/warp "..geigerConfig.worldSave)
    end
    FindPath(geigerConfig.aliveGeigerPos[1], geigerConfig.aliveGeigerPos[2])
    Sleep(3000)
    local itemDrop = geigerConfig.itemDropLeft[1]
    local deadDrop = geigerConfig.deadDropLeft[1]
    local loop = true
    while loop == true do
        if geigerVars.breakLoop == true then
            if GetLocal().pos.y // 32 <= 15 then
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 15, 0, 29))
            else
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -15, 0, 29))
            end
            geigerVars.breakLoop = false
            return
        end
        loop = false
        FindPath(itemDrop, geigerConfig.itemDropLeft[2])
        Sleep(500)
        for _,cur in pairs(GetInventory()) do
            if cur.id == 2286 then
                loop = true
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..cur.id.."|\nitem_count|"..cur.amount.."\n")
                Sleep(500)
                if geigerVars.canDrop == false then
                    deadDrop = deadDrop - 1
                end
            end
        end
    end
    SendPacket(2, "action|input\n|text|/warp "..geigerConfig.worldGeiger.."\n")
    Sleep(5000)
    while GetWorld().name ~= geigerConfig.worldGeiger do
        Sleep(5000)
        SendPacket(2, "action|input\n|text|/warp "..geigerConfig.worldGeiger.."\n")
    end
end

-- Fungsi utama yang akan dijalankan di thread
local function runAutoGeiger()
    geigerVars.listFound = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    geigerVars.totalFound = 0
    geigerVars.currentRing = geigerVars.red
    geigerVars.newRing = false
    geigerVars.itemFound = false
    geigerVars.canDrop = true
    geigerVars.breakLoop = false
    geigerVars.aliveGeiger = inv(2204) or 0

    -- Pasang hooks
    AddHook("onvariant", "geigerFoundHook", geigerFoundHook)
    AddHook("onprocesstankupdatepacket", "geigerRingHook", geigerRingHook)

    ChangeValue("[C] Modfly", true)

    -- Thread untuk break loop periodik (setiap 5 menit)
    local breakThread = RunThread(function()
        while running and not stopRequested do
            Sleep(300000) -- 5 menit
            if running and not stopRequested then
                geigerVars.breakLoop = true
                geigerLog("Break")
            end
        end
    end)

    -- Main loop
    while running and not stopRequested do
        if geigerVars.breakLoop == true then
            if GetLocal().pos.y // 32 <= 15 then
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 15, 0, 29))
            else
                FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -15, 0, 29))
            end
            geigerVars.breakLoop = false
        end
        for i in ipairs(geigerVars.redPosX) do
            if not running or stopRequested then break end
            if geigerVars.itemFound == true then 
                geigerVars.currentRing = geigerVars.red 
                break
            end
            if geigerVars.currentRing ~= geigerVars.red then break end
            FindPath(geigerVars.redPosX[i], geigerVars.redPosY[i])
            geigerRenewRing()
        end
        if not running or stopRequested then break end
        if geigerVars.currentRing == geigerVars.yellow then
            geigerFoundYellow()
        elseif geigerVars.currentRing == geigerVars.green then
            geigerFoundGreen()
        end
        geigerVars.itemFound = false
        geigerVars.aliveGeiger = geigerVars.aliveGeiger - 1
        if geigerVars.aliveGeiger <= 5 then
            geigerFullAFK()
            geigerVars.aliveGeiger = inv(2204) or 0
        end
    end

    -- Hapus hooks saat selesai
    RemoveHook("geigerFoundHook")
    RemoveHook("geigerRingHook")
    running = false
    currentStatus = "Stopped"
    geigerLog("Geiger stopped")
end

-- Fungsi start/stop
local function startGeiger()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runAutoGeiger)
end

local function stopGeiger()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

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
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

LogToConsole("Geiger script loaded. Use GUI to start.")
