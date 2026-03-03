-- ERTOXZ LOADER - PUT/BREAK PLAT + AUTO PTHT + AUTO VEND STOCK

-- ==================== VARIABEL GLOBAL ====================
local platID = 7520
local delay = 3000
local worldType = "island"   -- "normal", "island", "nether"
local mray = false
local autoFind = false
local running = false
local stopRequested = false
local currentAction = ""
local teleX = 0
local teleY = 0

-- Fitur Auto Geiger (dari script Swipez)
local geigerConfig = {
    webhook = "",
    worldGeiger = "GEIGERB",
    worldSave = "SAVEGEIGERSS",
    aliveGeigerPos = {63, 24},
    deadDropLeft = {60, 24},
    itemDropLeft = {65, 24},
    enabled = false,
}

local geigerVars = {
    redPosX = {25, 5, 5, 25, 15, 14},
    redPosY = {5, 25, 5, 25, 25, 3},
    listFound = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, -- Stuff, Black, Green, Red, White, Hchem, Rchem, Growtoken, Battery, D Battery, Charger
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

local geigerRunning = false
local geigerStop = false
local geigerThread = nil

-- Konfigurasi PTHT
local pthtConfig = {
    treeID = 15159,
    startMode = "PT",         -- "PT", "PTHT", "HT"
    loop = 1,                 -- angka atau "unli"
    delayHarvest = 50,
    delayEntering = 50,
    delayPlant = 10,
    mray = true,
    webhook = "",
    discordID = "",
    magplantLimit = 200,
    magplantBcg = 12840,
    pathfinderDelay = 520,
}

local pthtRunning = false
local pthtStop = false
local pthtVars = {}

-- Fitur Auto Grinder
local grinderConfig = {
    itemID = 4584,           -- ID item yang akan digrind
    resultID = 4570,         -- ID item hasil grind
    delay = 150,             -- delay antar aksi
    dropX = 84,              -- koordinat X awal untuk drop
    dropY = 22,              -- koordinat Y awal untuk drop
    maxAttempts = 125,       -- jumlah maksimum percobaan
}
local grinderRunning = false
local grinderStop = false
local grinderVars = {}


-- ==================== FUNGSI UMUM ====================
local function getWorldSize()
    if worldType == "normal" then
        return 100, 60
    elseif worldType == "nether" then
        return 150, 150
    else -- island
        return 200, 200
    end
end

local function inv(id)
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            return item.amount
        end
    end
    return 0
end

local hookLabel = "ErtoxzHook"
local function setupHook(enable)
    if enable then
        AddHook("OnVariant", hookLabel, function(var)
            if var[0] == "OnDialogRequest" and var[1] and var[1]:find("item_finder") then
                return true
            end
            return false
        end)
    else
        RemoveHook(hookLabel)
    end
end



-- ==================== FUNGSI PUT PLAT ====================
local function runPutPlat()
    if running or pthtRunning or vendRunning then return end
    running = true
    stopRequested = false
    currentAction = "put"

    ChangeValue("[C] Modfly", true)
    ChangeValue("[C] Ghost mode", true)

    local put = mray and 10 or 1
    local sizeX, sizeY = getWorldSize()

    if autoFind then
        setupHook(true)
    end

    RunThread(function()
        for y = sizeY - 2, 0, -1 do
            if stopRequested then break end
            for x1 = 0, put - 1 do
                if stopRequested then break end
                for x2 = 0, (sizeX / put) - 1 do
                    if stopRequested then break end
                    local x = x2 * put + x1
                    local tile = GetTile(x, y)

                    if autoFind and not stopRequested and inv(platID) == 0 then
                        SendPacket(2, "action|dialog_return\ndialog_name|item_search\n" .. platID .. "|1")
                        Sleep(1000)
                    end

                    if tile and tile.fg == 0 and y % 2 == 1 and not stopRequested then
                        FindPath(x, y - 1, pthtConfig.pathfinderDelay)
                        Sleep(1)
                        SendPacketRaw(false, {state = 32, x = x * 32 - 32, y = y * 32})
                        Sleep(1)
                        SendPacketRaw(false, {type = 3, value = platID, px = x, py = y, x = x * 32, y = y * 32})
                        Sleep(delay)
                    end
                end
            end
        end

        if stopRequested then
            LogToConsole("Put Plat dihentikan oleh user.")
        else
            LogToConsole("Put Plat DONE")
        end

        if autoFind then
            setupHook(false)
        end
        running = false
        stopRequested = false
    end)
end

-- ==================== FUNGSI BREAK PLAT ====================
local function runBreakPlat()
    if running or pthtRunning or vendRunning then return end
    running = true
    stopRequested = false
    currentAction = "break"

    ChangeValue("[C] Modfly", true)

    local put = mray and 10 or 1
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

                    if tile and tile.fg == platID and not stopRequested then
                        FindPath(x, y, pthtConfig.pathfinderDelay)
                        Sleep(1)
                        while not stopRequested and GetTile(x, y).fg == platID do
                            SendPacketRaw(false, {type = 3, value = 18, px = x, py = y, x = x * 32, y = y * 32})
                            Sleep(delay)
                        end
                    end
                end
            end
        end

        if stopRequested then
            LogToConsole("Break Plat dihentikan oleh user.")
        else
            LogToConsole("Break Plat DONE")
        end

        running = false
        stopRequested = false
    end)
end

-- ==================== FUNGSI PTHT ====================
local function pthtSendPacketRaw(H, I, J, K, L)
    SendPacketRaw(false, {
        type = H,
        state = I,
        value = J,
        px = K,
        py = L,
        x = K * 32,
        y = L * 32,
    })
end

local function pthtTextO(x)
    SendVariantList{[0] = "OnTextOverlay", [1] = x}
    LogToConsole(x)
end

local function pthtIsReady(tile)
    return tile and tile.extra and tile.extra.progress and tile.extra.progress == 1
end

local function pthtGetMagplant()
    local Found = {}
    local sizeX, sizeY = getWorldSize()
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

local function pthtGetRemote()
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

local function pthtChangeMode()
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

local function pthtRotation()
    local sizeX, sizeY = getWorldSize()
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

local function pthtReconnect()
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

local function runPTHT()
    if pthtRunning or running or vendRunning then return end
    pthtRunning = true
    pthtStop = false
    currentAction = "ptht"

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

    RunThread(function()
        local loopValue = pthtConfig.loop
        if type(loopValue) == "string" and loopValue:lower() == "unli" then
            while not pthtStop do
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

        pthtRunning = false
        pthtStop = false
        running = false
    end)
end

-- Fungsi untuk mendapatkan warna sinyal geiger dari dialog
local function getGeigerSignal(dialog)
    if not dialog then return nil end
    
    -- Deteksi warna berdasarkan teks dalam dialog
    if dialog:find("Sinyal Merah") or dialog:find("Red Signal") then
        return "merah"
    elseif dialog:find("Sinyal Kuning") or dialog:find("Yellow Signal") then
        return "kuning"
    elseif dialog:find("Sinyal Hijau") or dialog:find("Green Signal") then
        return "hijau"
    end
    return nil
end

-- ==================== FUNGSI AUTO GEIGER ====================

local function geigerLog(k)
    SendVariantList{[0] = "OnTextOverlay", [1] = k}
    LogToConsole(k)
end

local function geigerClamp(val, minVal, maxVal)
    return math.max(minVal, math.min(val, maxVal))
end

local function geigerReconnect()
    while GetWorld().name ~= geigerConfig.worldGeiger do
        SendPacket(2, "action|input\n|text|/warp "..geigerConfig.worldGeiger.."\n")
        Sleep(5000)
    end
end

local function geigerRenewRing()
    while geigerVars.newRing == false do
        geigerReconnect()
        Sleep(500)
    end
    geigerVars.newRing = false
end

local function geigerFoundYellow()
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
-- X Yellow -> Red
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
-- X Yellow -> Green
    elseif geigerVars.currentRing == geigerVars.green then
        if isLeft == false then
            FindPath(geigerClamp(GetLocal().pos.x // 32 + 4, 0, 29), foundPosY)
        else
            FindPath(geigerClamp(GetLocal().pos.x // 32 + -4, 0, 29), foundPosY)
        end
        Sleep(10000)
    end
-- Reset For Y Axis
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
-- Y Green -> Yellow
    if geigerVars.currentRing == geigerVars.yellow then
        if isUp == false then
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + -5, 0, 29))
        else
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + 5, 0, 29))
        end
        Sleep(10000)
    end
end

local function geigerFoundGreen()
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
-- X Green -> Yellow
    if geigerVars.currentRing == geigerVars.yellow then
        if isLeft == false then
            FindPath(geigerClamp(GetLocal().pos.x // 32 + -5, 0, 29), foundPosY)
        else
            FindPath(geigerClamp(GetLocal().pos.x // 32 + 5, 0, 29), foundPosY)
        end
        Sleep(10000)
    end
-- Reset For Y Axis
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
-- Y Green -> Yellow
    if geigerVars.currentRing == geigerVars.yellow then
        if isUp == false then
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + -5, 0, 29))
        else
            FindPath(foundPosX, geigerClamp(GetLocal().pos.y // 32 + 5, 0, 29))
        end
        Sleep(10000)
    end
end

local function geigerRingHook(packet)
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

local function geigerFoundHook(varlist)
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

local function geigerFullAFK()
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

local function runAutoGeiger()
    if geigerRunning or running or pthtRunning then return end
    geigerRunning = true
    geigerStop = false
    currentAction = "geiger"

    -- Reset variabel
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
    RunThread(function()
        while geigerRunning and not geigerStop do
            Sleep(300000) -- 5 menit
            if geigerRunning and not geigerStop then
                geigerVars.breakLoop = true
                geigerLog("Break")
            end
        end
    end)

    -- Main loop
    geigerThread = RunThread(function()
        while geigerRunning and not geigerStop do
            if geigerVars.breakLoop == true then
                if GetLocal().pos.y // 32 <= 15 then
                    FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + 15, 0, 29))
                else
                    FindPath(GetLocal().pos.x // 32, geigerClamp(GetLocal().pos.y // 32 + -15, 0, 29))
                end
                geigerVars.breakLoop = false
            end
            for i in pairs(geigerVars.redPosX) do
                if geigerVars.itemFound == true then 
                    geigerVars.currentRing = geigerVars.red 
                    break
                end
                if geigerVars.currentRing ~= geigerVars.red then break end
                FindPath(geigerVars.redPosX[i], geigerVars.redPosY[i])
                geigerRenewRing()
            end
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
        geigerRunning = false
    end)
end

-- ==================== FUNGSI AUTO GRINDER ====================

-- Fungsi menghitung inventory
local function grinderInv(id)
    local count = 0
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            count = count + item.amount
        end
    end
    return count
end

-- Pathfinder bertahap (sumber: Rvnaa/Yasugami)
local function grinderFP(x, y)
    local px = math.floor(GetLocal().pos.x / 32)
    local py = math.floor(GetLocal().pos.y / 32)
    
    while math.abs(y - py) > 6 do
        py = py + (y - py > 0 and 6 or -6)
        FindPath(px, py, pthtConfig.pathfinderDelay or 520)
        Sleep(200)
        if grinderStop then return end
    end
    while math.abs(x - px) > 6 do
        px = px + (x - px > 0 and 6 or -6)
        FindPath(px, py, pthtConfig.pathfinderDelay or 520)
        Sleep(200)
        if grinderStop then return end
    end
    Sleep(100)
    FindPath(x, y, pthtConfig.pathfinderDelay or 520)
end

-- Fungsi untuk menjatuhkan item hasil
local function grinderDrops(id, index, startX, startY)
    if not grinderVars.dropY then grinderVars.dropY = {} end
    if not grinderVars.dropY[index] then
        grinderVars.dropY[index] = startY
    end
    local x = startX + (index - 1)
    local y = grinderVars.dropY[index] or startY
    
    grinderFP(x - 1, y)
    Sleep(500)
    if grinderStop then return end
    
    for a = 1, 24 do
        if grinderInv(id) >= 250 then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..id.."|\nitem_count|"..grinderInv(id).."|\n")
            Sleep(400)
            if grinderStop then return end
        end
    end
    
    -- Kembali ke posisi awal grinder
    grinderFP(grinderVars.startX, grinderVars.startY)
    Sleep(500)
    
    if grinderInv(id) >= 250 then
        grinderVars.dropY[index] = grinderVars.dropY[index] - 1
    end
end

local function runAutoGrinder()
    if grinderRunning or running or pthtRunning then return end
    grinderRunning = true
    grinderStop = false
    currentAction = "grinder"

    -- Simpan posisi awal (grinder)
    grinderVars.startX = math.floor(GetLocal().pos.x / 32)
    grinderVars.startY = math.floor(GetLocal().pos.y / 32)
    grinderVars.dropY = {}  -- array untuk menyimpan posisi Y per index

    -- Hook untuk memblok dialog Item Finder
    local grinderHookLabel = "GrinderHook_" .. math.random(1000, 9999)
    AddHook("OnVariant", grinderHookLabel, function(var)
        if var[0] == "OnDialogRequest" and var[1] and var[1]:find("Item Finder") then
            return true
        end
        return false
    end)

    ChangeValue("[C] Modfly", true)

    RunThread(function()
        local counter = 0
        local grindMode = false  -- false = ambil item, true = grind terus

        while not grinderStop do
            -- Cek inventory item hasil
            if grinderInv(grinderConfig.resultID) >= 250 then
                grinderDrops(grinderConfig.resultID, 1, grinderConfig.dropX, grinderConfig.dropY)
                if grinderStop then break end
                counter = 0
                grindMode = false
            end

            if grindMode then
                -- Mode grind: langsung masukkan ke grinder
                SendPacket(2, "action|dialog_return\ndialog_name|grinder\nx|"..grinderVars.startX.."|\ny|"..grinderVars.startY.."|\nitemID|"..grinderConfig.itemID.."|\namount|2")
                Sleep(100)
            else
                -- Mode ambil item
                if counter < grinderConfig.maxAttempts then
                    -- Ambil dari item finder
                    SendPacket(2, "action|dialog_return\ndialog_name|item_search\n"..grinderConfig.itemID.."|1\n")
                    Sleep(grinderConfig.delay)
                    -- Masukkan ke grinder
                    SendPacket(2, "action|dialog_return\ndialog_name|grinder\nx|"..grinderVars.startX.."|\ny|"..grinderVars.startY.."|\nitemID|"..grinderConfig.itemID.."|\namount|2")
                    Sleep(100)
                    counter = counter + 1
                    LogToConsole(string.format("Grinder Attempt: %d/%d", counter, grinderConfig.maxAttempts))
                    if counter >= grinderConfig.maxAttempts then
                        grindMode = true
                    end
                end
            end

            -- Jika sudah mode grind tapi counter masih kurang (mungkin untuk reset)
            if grindMode and counter < grinderConfig.maxAttempts then
                grindMode = false
            end

            Sleep(100)
        end

        -- Hapus hook
        RemoveHook(grinderHookLabel)
        LogToConsole("`2Auto Grinder dihentikan.")
        grinderRunning = false
    end)
end

-- =========================== StopAction ==============================
local function stopAction()
    if running then
        stopRequested = true
        running = false
    end
    if pthtRunning then
        pthtStop = true
        pthtRunning = false
    end
    if geigerRunning then
        geigerStop = true
        geigerRunning = false
    end
    if grinderRunning then
        grinderStop = true
        grinderRunning = false
    end
    if harvestRunning then
        harvestStop = true
        harvestRunning = false
    end
end

-- ==================== GUI UTAMA (COLLAPSING HEADER) ====================
AddHook("OnDraw", "ErtoxzGUI", function(dt)
    if ImGui.Begin("ERTOXZ LOADER") then
        
        -- ==================== PUT / BREK PLAT ====================
        if ImGui.CollapsingHeader("PUT / BREK PLAT") then
            ImGui.Columns(2, "col_putbreak", false)
            
            -- Kolom kiri: Settings
            ImGui.Text("Settings");
            ImGui.Separator();
            
            ImGui.Text("ID Plat:")
            local changed, newID = ImGui.InputInt("##platID", platID, 1, 100)
            if changed then platID = newID end

            ImGui.Text("Delay (ms):")
            local changedD, newDelay = ImGui.InputInt("##delay", delay, 10, 100)
            if changedD then delay = newDelay end

            ImGui.Text("Tipe World:")
            if ImGui.RadioButton("Normal##pb", worldType == "normal") then worldType = "normal" end
            ImGui.SameLine()
            if ImGui.RadioButton("Island##pb", worldType == "island") then worldType = "island" end
            ImGui.SameLine()
            if ImGui.RadioButton("Nether##pb", worldType == "nether") then worldType = "nether" end

            local changedM, newMray = ImGui.Checkbox("Mray (hand)##pb", mray)
            if changedM then mray = newMray end

            local changedAF, newAF = ImGui.Checkbox("Auto Find Item (Put)##pb", autoFind)
            if changedAF then autoFind = newAF end
            
            ImGui.NextColumn()
            
            -- Kolom kanan: Status
            ImGui.Text("Status");
            ImGui.Separator();
            
            if running then
                if currentAction == "put" then
                    ImGui.TextColored(0,255,0,255, "● Sedang Put Plat")
                elseif currentAction == "break" then
                    ImGui.TextColored(0,255,0,255, "● Sedang Break Plat")
                else
                    ImGui.TextColored(0,255,0,255, "● Running")
                end
            else
                ImGui.TextColored(255,255,255,100, "○ Stopped")
            end
            
            -- Informasi tambahan bisa ditambahkan di sini, misal posisi terakhir
            -- Namun karena tidak ada variabel spesifik, kita tampilkan saja.
            
            ImGui.Columns(1)
            
            ImGui.Separator()
            if not running and not pthtRunning and not vendSmartRunning and not geigerRunning and not grinderRunning and not harvestRunning then
                if ImGui.Button("Start Put Plat##pb") then
                    runPutPlat()
                end
                ImGui.SameLine()
                if ImGui.Button("Start Break Plat##pb") then
                    runBreakPlat()
                end
            else
                if ImGui.Button("Stop##pb") then
                    stopAction()
                end
                ImGui.SameLine()
                ImGui.Text("Sedang " .. currentAction .. "...")
            end
        end
        
        -- ==================== AUTO PTHT ====================
        if ImGui.CollapsingHeader("AUTO PTHT") then
            ImGui.Columns(2, "col_ptht", false)
            
            -- Kolom kiri: Settings
            ImGui.Text("Settings");
            ImGui.Separator();
            
            local changedTree, newTree = ImGui.InputInt("ID Tree##ptht", pthtConfig.treeID, 1, 100)
            if changedTree then pthtConfig.treeID = newTree end

            local changedMode, newMode = ImGui.InputText("Mode (PT/PTHT/HT)##ptht", pthtConfig.startMode, 10)
            if changedMode then pthtConfig.startMode = newMode end

            local loopStr = tostring(pthtConfig.loop)
            local changedLoop, newLoop = ImGui.InputText("Loop (angka/'unli')##ptht", loopStr, 10)
            if changedLoop then
                if newLoop:lower() == "unli" then pthtConfig.loop = "unli"
                else local num = tonumber(newLoop); if num then pthtConfig.loop = num end end
            end

            ImGui.Text("Delay:");
            local changedDH, newDH = ImGui.InputInt("Harvest (ms)##ptht", pthtConfig.delayHarvest, 1, 10)
            if changedDH then pthtConfig.delayHarvest = newDH end
            local changedDE, newDE = ImGui.InputInt("Entering (ms)##ptht", pthtConfig.delayEntering, 1, 10)
            if changedDE then pthtConfig.delayEntering = newDE end
            local changedDP, newDP = ImGui.InputInt("Plant (ms)##ptht", pthtConfig.delayPlant, 1, 10)
            if changedDP then pthtConfig.delayPlant = newDP end
            local changedPD, newPD = ImGui.InputInt("Pathfinder Delay##ptht", pthtConfig.pathfinderDelay, 10, 100)
            if changedPD then pthtConfig.pathfinderDelay = newPD end

            ImGui.Text("Other:");
            local changedMrayP, newMrayP = ImGui.Checkbox("Mray##ptht", pthtConfig.mray)
            if changedMrayP then pthtConfig.mray = newMrayP end
            local changedWeb, newWeb = ImGui.InputText("Webhook URL##ptht", pthtConfig.webhook, 100)
            if changedWeb then pthtConfig.webhook = newWeb end
            local changedDisc, newDisc = ImGui.InputText("Discord ID##ptht", pthtConfig.discordID, 30)
            if changedDisc then pthtConfig.discordID = newDisc end

            ImGui.Text("Magplant:");
            local changedLimit, newLimit = ImGui.InputInt("Limit##ptht", pthtConfig.magplantLimit, 1, 10)
            if changedLimit then pthtConfig.magplantLimit = newLimit end
            local changedBcg, newBcg = ImGui.InputInt("Background ID##ptht", pthtConfig.magplantBcg, 1, 100)
            if changedBcg then pthtConfig.magplantBcg = newBcg end

            ImGui.Text("Tipe World:");
            if ImGui.RadioButton("Normal##ptht", worldType == "normal") then worldType = "normal" end
            ImGui.SameLine()
            if ImGui.RadioButton("Island##ptht", worldType == "island") then worldType = "island" end
            ImGui.SameLine()
            if ImGui.RadioButton("Nether##ptht", worldType == "nether") then worldType = "nether" end
            
            ImGui.NextColumn()
            
            -- Kolom kanan: Status
            ImGui.Text("Status");
            ImGui.Separator();
            
            if pthtRunning then
                ImGui.TextColored(0,255,0,255, "● Running")
                ImGui.Text("Mode: " .. (pthtVars.plant and "Plant" or (pthtVars.harvest and "Harvest" or "?")))
                ImGui.Text("Loop: " .. (pthtVars.counter // 2 + 1) .. "/" .. (pthtConfig.loop == "unli" and "∞" or pthtConfig.loop))
                ImGui.Text("UWS Used: " .. pthtVars.uwsUsed)
                ImGui.Text("Magplant Stock: " .. (pthtVars.iM or 0))
            else
                ImGui.TextColored(255,255,255,100, "○ Stopped")
            end
            
            ImGui.Columns(1)
            
            ImGui.Separator()
            if not pthtRunning and not running and not vendSmartRunning and not geigerRunning and not grinderRunning and not harvestRunning then
                if ImGui.Button("Start PTHT##ptht") then
                    runPTHT()
                end
            else
                if ImGui.Button("Stop##ptht") then
                    stopAction()
                end
                ImGui.SameLine()
                ImGui.Text("Sedang " .. currentAction .. "...")
            end
        end
        

        
        -- ==================== AUTO GEIGER ====================
        if ImGui.CollapsingHeader("AUTO GEIGER") then
            ImGui.Columns(2, "col_geiger", false)
            
            -- Kolom kiri: Settings
            ImGui.Text("Settings");
            ImGui.Separator();
            
            local changedWeb, newWeb = ImGui.InputText("Webhook URL##geiger", geigerConfig.webhook, 200)
            if changedWeb then geigerConfig.webhook = newWeb end

            local changedWG, newWG = ImGui.InputText("World Geiger##geiger", geigerConfig.worldGeiger, 30)
            if changedWG then geigerConfig.worldGeiger = newWG end

            local changedWS, newWS = ImGui.InputText("World Save##geiger", geigerConfig.worldSave, 30)
            if changedWS then geigerConfig.worldSave = newWS end

            ImGui.Text("Alive Geiger Position:");
            local changedAGX, newAGX = ImGui.InputInt("X##geigerAG", geigerConfig.aliveGeigerPos[1], 1, 10)
            if changedAGX then geigerConfig.aliveGeigerPos[1] = newAGX end
            local changedAGY, newAGY = ImGui.InputInt("Y##geigerAG", geigerConfig.aliveGeigerPos[2], 1, 10)
            if changedAGY then geigerConfig.aliveGeigerPos[2] = newAGY end

            ImGui.Text("Dead Drop Left:");
            local changedDDX, newDDX = ImGui.InputInt("X##geigerDD", geigerConfig.deadDropLeft[1], 1, 10)
            if changedDDX then geigerConfig.deadDropLeft[1] = newDDX end
            local changedDDY, newDDY = ImGui.InputInt("Y##geigerDD", geigerConfig.deadDropLeft[2], 1, 10)
            if changedDDY then geigerConfig.deadDropLeft[2] = newDDY end

            ImGui.Text("Item Drop Left:");
            local changedIDX, newIDX = ImGui.InputInt("X##geigerID", geigerConfig.itemDropLeft[1], 1, 10)
            if changedIDX then geigerConfig.itemDropLeft[1] = newIDX end
            local changedIDY, newIDY = ImGui.InputInt("Y##geigerID", geigerConfig.itemDropLeft[2], 1, 10)
            if changedIDY then geigerConfig.itemDropLeft[2] = newIDY end
            
            ImGui.NextColumn()
            
            -- Kolom kanan: Status
            ImGui.Text("Status");
            ImGui.Separator();
            
            if geigerRunning then
                ImGui.TextColored(0,255,0,255, "● Running")
                local signalText = "Tidak ada"
                if geigerVars.currentRing == geigerVars.red then signalText = "Merah"
                elseif geigerVars.currentRing == geigerVars.yellow then signalText = "Kuning"
                elseif geigerVars.currentRing == geigerVars.green then signalText = "Hijau"
                end
                ImGui.Text("Sinyal: " .. signalText)
                ImGui.Text("Total Item: " .. geigerVars.totalFound)
                -- Tampilkan rincian item
                if geigerVars.listFound[1] > 0 then ImGui.Text("Stuff: " .. geigerVars.listFound[1]) end
                if geigerVars.listFound[2] > 0 then ImGui.Text("Crystal Black: " .. geigerVars.listFound[2]) end
                if geigerVars.listFound[3] > 0 then ImGui.Text("Crystal Green: " .. geigerVars.listFound[3]) end
                if geigerVars.listFound[4] > 0 then ImGui.Text("Crystal Red: " .. geigerVars.listFound[4]) end
                if geigerVars.listFound[5] > 0 then ImGui.Text("Crystal White: " .. geigerVars.listFound[5]) end
                if geigerVars.listFound[6] > 0 then ImGui.Text("Chemical Haunted: " .. geigerVars.listFound[6]) end
                if geigerVars.listFound[7] > 0 then ImGui.Text("Chemical Radioactive: " .. geigerVars.listFound[7]) end
                if geigerVars.listFound[8] > 0 then ImGui.Text("Growtoken: " .. geigerVars.listFound[8]) end
                if geigerVars.listFound[9] > 0 then ImGui.Text("Battery: " .. geigerVars.listFound[9]) end
                if geigerVars.listFound[10] > 0 then ImGui.Text("D Battery: " .. geigerVars.listFound[10]) end
                if geigerVars.listFound[11] > 0 then ImGui.Text("Charger: " .. geigerVars.listFound[11]) end
            else
                ImGui.TextColored(255,255,255,100, "○ Stopped")
            end
            
            ImGui.Columns(1)
            
            ImGui.Separator()
            if not geigerRunning and not running and not pthtRunning and not vendSmartRunning and not grinderRunning and not harvestRunning then
                if ImGui.Button("Start Auto Geiger##geiger") then
                    runAutoGeiger()
                end
            else
                if ImGui.Button("Stop##geiger") then
                    stopAction()
                end
                ImGui.SameLine()
                ImGui.Text("Sedang " .. currentAction .. "...")
            end
        end
        
        -- ==================== AUTO GRINDER ====================
        if ImGui.CollapsingHeader("AUTO GRINDER") then
            ImGui.Columns(2, "col_grinder", false)
            
            -- Kolom kiri: Settings
            ImGui.Text("Settings");
            ImGui.Separator();
            
            local changedItem, newItem = ImGui.InputInt("ID Item Grind##grinder", grinderConfig.itemID, 1, 100)
            if changedItem then grinderConfig.itemID = newItem end

            local changedResult, newResult = ImGui.InputInt("ID Item Hasil##grinder", grinderConfig.resultID, 1, 100)
            if changedResult then grinderConfig.resultID = newResult end

            local changedDelay, newDelay = ImGui.InputInt("Delay (ms)##grinder", grinderConfig.delay, 10, 100)
            if changedDelay then grinderConfig.delay = newDelay end

            local changedDropX, newDropX = ImGui.InputInt("Drop X Awal##grinder", grinderConfig.dropX, 1, 10)
            if changedDropX then grinderConfig.dropX = newDropX end
            local changedDropY, newDropY = ImGui.InputInt("Drop Y Awal##grinder", grinderConfig.dropY, 1, 10)
            if changedDropY then grinderConfig.dropY = newDropY end

            local changedMax, newMax = ImGui.InputInt("Max Attempts##grinder", grinderConfig.maxAttempts, 1, 10)
            if changedMax then grinderConfig.maxAttempts = newMax end
            
            ImGui.NextColumn()
            
            -- Kolom kanan: Status
            ImGui.Text("Status");
            ImGui.Separator();
            
            if grinderRunning then
                ImGui.TextColored(0,255,0,255, "● Running")
                -- Tampilkan progress jika ada
                ImGui.Text("Progress: " .. (grinderVars.counter or 0) .. "/" .. grinderConfig.maxAttempts)
            else
                ImGui.TextColored(255,255,255,100, "○ Stopped")
            end
            
            ImGui.Columns(1)
            
            ImGui.Separator()
            if not grinderRunning and not running and not pthtRunning and not vendSmartRunning and not geigerRunning and not harvestRunning then
                if ImGui.Button("Start Auto Grinder##grinder") then
                    runAutoGrinder()
                end
            else
                if ImGui.Button("Stop##grinder") then
                    stopAction()
                end
                ImGui.SameLine()
                ImGui.Text("Sedang " .. currentAction .. "...")
            end
        end
        

        
    end
    ImGui.End()
end)


LogToConsole("ERTOXZ LOADER siap. Klik header untuk membuka fitur.")
