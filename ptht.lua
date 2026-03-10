-- ==================== PTHT LOADER (DENGAN GUI) ====================

-- Konfigurasi default (dapat diubah via GUI)
local config = {
    whUse = false,
    whUrl = "",
    WORLD = "",
    delay_reconnect = 10000,
    WAIT_TIME = 1, -- menit
    MRAY = true,
    COLLECT_GEMS = 1, -- 1 = auto collect
    ITEM_ID = 15159,
    TOTAL_PTHT = 0,
    MAG_X = 0,
    MAG_Y = 0,
    DELAY_HARVEST = 30,
    DELAY_PLANT = 70,
    PLATFORM_ID = 2810,
    IGNORE_UNHARVESTED_AFTER_PUNCH = true,
    PEOPLEHIDE = 0,
    DROPHIDDEN = 0,
    removeAnimationCollected = false,
    removeAnimationbubbletalk = false,
    removeSDB = true,
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"
local pthtCount = 0
local startTime = 0

-- Variabel internal yang diperlukan script asli
local REMOTE_X, REMOTE_Y
local WORLD_SIZE_X = 199
local WORLD_SIZE_Y = 199
local MAG_STOCK = 0
local CHECK_STOCK = true
local START_PLANT = 0
local PTHT_COUNT = 0
local IS_GHOST = false
local CHECK_GHOST = false
local MAG_EMPTY = false
local CHANGE_REMOTE = false
local START_MAG_X, START_MAG_Y
local ROTATION_COUNT = 0
local currentTime = os.time()
local DISABLED = false
local LAST_PLANTED_Y = -1
local LAST_HARVESTED_Y = -1
local TOTAL_TIME_PLANT = 0
local TOTAL_TIME_HARVEST = 0

-- Fungsi-fungsi asli (dengan penyesuaian menggunakan config)
local function WARN(text)
    local packet = {}
    packet[0] = "OnAddNotification"
    packet[1] = "interface/atomic_button.rttex"
    packet[2] = text
    packet[3] = 'audio/hub_open.wav'
    packet[4] = 0
    SendVariantList(packet)
end

local function GetItemCount(id)
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            return item.amount
        end
    end
    return 0
end

local function removeColorAndSymbols(str)
    local cleanedStr = string.gsub(str, "`(%S)", '')
    cleanedStr = string.gsub(cleanedStr, "`{2}|(~{2})", '')
    return cleanedStr
end

local function FormatNumber(num)
    num = math.floor(num + 0.5)
    local formatted = tostring(num)
    local k = 3
    while k < #formatted do
        formatted = formatted:sub(1, #formatted - k) .. "," .. formatted:sub(#formatted - k + 1)
        k = k + 4
    end
    return formatted
end

function FORMAT_TIME(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remaining_seconds = seconds % 60
    local parts = {}
    if days > 0 then table.insert(parts, tostring(days) .. " day" .. (days > 1 and "s" or "")) end
    if hours > 0 then table.insert(parts, tostring(hours) .. " hour" .. (hours > 1 and "s" or "")) end
    if minutes > 0 then table.insert(parts, tostring(minutes) .. " minute" .. (minutes > 1 and "s" or "")) end
    if remaining_seconds > 0 then table.insert(parts, tostring(remaining_seconds) .. " second" .. (remaining_seconds > 1 and "s" or "")) end
    if #parts == 0 then return "0 seconds"
    elseif #parts == 1 then return parts[1]
    else
        local last_part = table.remove(parts)
        return table.concat(parts, ", ") .. " and " .. last_part
    end
end

local function GET_TELEPHONE()
    for _, tile in pairs(GetTiles()) do
        if tile.fg == 3898 then
            return tile.x, tile.y
        end
    end
end

local function CHECK_FOR_GHOST()
    if GetWorld() == nil then return end
    CHECK_GHOST = true
    SendPacket(2, "action|wrench\n|netid|" .. GetLocal().netid)
end

local function ENABLE_GHOST()
    if GetWorld() == nil then return end
    CHECK_FOR_GHOST()
    Sleep(100)
    if not IS_GHOST then
        SendPacket(2, "action|input\ntext|/ghost")
        Sleep(100)
        CHECK_FOR_GHOST()
    end
end

local function LogText(filename, text)
    -- Untuk PC, simpan di desktop. Untuk Android, sesuaikan path.
    local path = "storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/" .. filename
    local file, err = io.open(path, "a")
    if not file then
        -- coba di folder scripts
        file = io.open(filename, "a")
        if not file then
            LogToConsole("Error opening log file: " .. tostring(err))
            return
        end
    end
    file:write(text .. "\n")
    file:close()
end

local function Place(x, y, id)
    if GetWorld() == nil then return end
    local pkt = {}
    pkt.type = 3
    pkt.value = id
    pkt.px = x
    pkt.py = y
    pkt.x = GetLocal().pos.x
    pkt.y = GetLocal().pos.y
    SendPacketRaw(false, pkt)
end

local function Punch(x, y, id)
    if GetWorld() == nil then return end
    local pkt = {}
    pkt.type = 3
    pkt.value = id
    pkt.px = x
    pkt.py = y
    pkt.x = GetLocal().pos.x
    pkt.y = GetLocal().pos.y
    SendPacketRaw(false, pkt)
end

local function Hold()
    local pkt = {}
    pkt.type = 0
    pkt.state = 16779296
    SendPacketRaw(false, pkt)
    Sleep(180)
end

function WalkTo(x, y)
    if GetWorld() == nil then return end
    local pkt = {}
    pkt.type = 0
    pkt.x = x * 32
    pkt.y = y * 32
    SendPacketRaw(false, pkt)
    Sleep(180)
end

-- Hook function
local function hook(varlist)
    if varlist[0]:find("OnTalkBubble") and (varlist[2]:find("The MAGPLANT 5000 is empty")) then
        CHANGE_REMOTE = true
        MAG_EMPTY = true
        return true
    end
    if varlist[0]:find("OnDialogRequest") and varlist[1]:find("magplant_edit") then
        local x = varlist[1]:match('embed_data|x|(%d+)')
        local y = varlist[1]:match('embed_data|y|(%d+)')
        local amount = varlist[1]:match("The machine contains (%d+)")
        if amount == nil then amount = 0 end
        if x == tostring(REMOTE_X) and y == tostring(REMOTE_Y) then
            MAG_STOCK = amount
        end
        return true
    end
    if varlist[0]:find("OnDialogRequest") and (varlist[1]:find("Item Finder") or varlist[1]:find("The MAGPLANT 5000 is disabled.")) then
        return true
    end
    if varlist[0]:find("OnDialogRequest") and varlist[1]:find("add_player_info") then
        if CHECK_GHOST then
            if varlist[1]:find("|290|") then
                IS_GHOST = true
            else
                IS_GHOST = false
            end
            CHECK_GHOST = false
        end
        return true
    end
    if varlist[0] == "OnTalkBubble" and varlist[2]:match("Collected") and config.removeAnimationCollected then
        return true
    end
    if varlist[0] == "OnSDBroadcast" and config.removeSDB then
        return true
    end
    if varlist[0] == "OnTalkBubble" and config.removeAnimationbubbletalk then
        return true
    end
    return false
end

local function CHECK_FOR_AIR()
    if GetWorld() == nil then return end
    for y = 0, WORLD_SIZE_Y do
        local startX = 0
        local endX = WORLD_SIZE_X
        local incrementX = 1
        if not config.MRAY then
            if y % 4 == 2 then
                startX = WORLD_SIZE_X
                endX = 0
                incrementX = -1
            end
        end
        for x = startX, endX, incrementX do
            if GetWorld() == nil then return end
            if GetTile(x, y).fg == config.PLATFORM_ID then
                if x > 1 and x < WORLD_SIZE_X and y-1 >= 0 and y-1 < WORLD_SIZE_Y and GetTile(x, y-1).fg == 0 then
                    return true
                end
            end
        end
    end
    return false
end

local function CHECK_FOR_TREE()
    if MAG_EMPTY then return end
    for y = WORLD_SIZE_Y, 0, -1 do
        for x = 0, WORLD_SIZE_X do
            if GetWorld() == nil then return end
            if x >= 0 and x < WORLD_SIZE_X and y >= 0 and y < WORLD_SIZE_Y then
                local tile = GetTile(x, y)
                if tile.fg == config.ITEM_ID and GetTile(x, y+1).fg == config.PLATFORM_ID then
                    if tile.extra.progress == 1.0 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function AUTOPLANT_SETTINGS()
    if GetWorld() == nil then return end
    for y = 0, WORLD_SIZE_Y do
        for x = 0, WORLD_SIZE_X do
            if GetTile(x, y).fg == config.ITEM_ID and GetTile(x, y+1).fg ~= config.PLATFORM_ID then
                ChangeValue("[C] Modfly", false)
                ChangeValue("[C] Antibounce", false)
                ENABLE_GHOST()
                Sleep(250)
                SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autoplace|0\ncheck_gems|" .. config.COLLECT_GEMS)
                WalkTo(x, y)
                Sleep(250)
                SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autoplace|1\ncheck_gems|" .. config.COLLECT_GEMS)
                return
            end
        end
    end
end

local function CheckRemote()
    if GetWorld() == nil then return end
    if GetItemCount(5640) < 1 or MAG_EMPTY then
        ENABLE_GHOST()
        Sleep(100)
        FindPath(REMOTE_X, REMOTE_Y - 1, 60)
        Place(REMOTE_X, REMOTE_Y, 32)
        Sleep(200)
        SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. REMOTE_X .. "|\ny|" .. REMOTE_Y .. "|\nbuttonClicked|getRemote")
        Sleep(250)
        Place(REMOTE_X, REMOTE_Y - 1, 5640)
    end
    if GetItemCount(5640) >= 1 and MAG_EMPTY then
        MAG_EMPTY = false
    end
    return GetItemCount(5640) >= 1
end

local function PLANT_LOOP()
    if GetWorld() == nil then return end
    if MAG_EMPTY then return end
    ChangeValue("[C] Modfly", true)
    if config.MRAY then
        for x = 0, WORLD_SIZE_X, 1 do
            local START_Y, END_Y, increment
            if GetLocal().pos.y // 32 <= 100 then
                START_Y = WORLD_SIZE_Y
                END_Y = 0
                increment = -1
            else
                START_Y = 0
                END_Y = WORLD_SIZE_Y
                increment = 1
            end
            for y = START_Y, END_Y, increment do
                if MAG_EMPTY then return end
                if GetWorld() == nil then return end
                if GetTile(x, y).fg == config.PLATFORM_ID then
                    local PLACE_X = x
                    local PLACE_Y = y - 1
                    if PLACE_X >= 0 and PLACE_X < WORLD_SIZE_X and PLACE_Y >= 0 and PLACE_Y < WORLD_SIZE_Y and GetTile(PLACE_X, PLACE_Y).fg == 0 then
                        FindPath(PLACE_X, PLACE_Y, 60)
                        Place(PLACE_X, PLACE_Y, 5640)
                        Sleep(config.DELAY_PLANT)
                    end
                end
            end
        end
    else
        for y = 0, WORLD_SIZE_Y do
            local startX = 0
            local endX = WORLD_SIZE_X
            local incrementX = 1
            if y % 4 == 2 then
                startX = WORLD_SIZE_X
                endX = 0
                incrementX = -1
            end
            for x = startX, endX, incrementX do
                if MAG_EMPTY then return end
                if GetWorld() == nil then return end
                if GetTile(x, y).fg == config.PLATFORM_ID then
                    local PLACE_X = x
                    local PLACE_Y = y - 1
                    if PLACE_X >= 0 and PLACE_X < WORLD_SIZE_X and PLACE_Y >= 0 and PLACE_Y < WORLD_SIZE_Y and GetTile(PLACE_X, PLACE_Y).fg == 0 then
                        if ROTATION_COUNT ~= 0 then
                            FindPath(PLACE_X, PLACE_Y, 60)
                            Sleep(config.DELAY_PLANT)
                            Place(PLACE_X, PLACE_Y, 5640)
                            Sleep(config.DELAY_PLANT)
                        else
                            FindPath(PLACE_X, PLACE_Y, 60)
                        end
                    end
                end
            end
        end
    end
end

function HARVEST()
    ENABLE_GHOST()
    for y = WORLD_SIZE_Y, 0, -1 do
        for x = 0, WORLD_SIZE_X do
            if GetWorld() == nil then return end
            if x >= 0 and x < WORLD_SIZE_X and y >= 0 and y < WORLD_SIZE_Y then
                local tile = GetTile(x, y)
                if tile.fg == config.ITEM_ID and GetTile(x, y+1).fg == config.PLATFORM_ID then
                    FindPath(x, y, 60)
                    Sleep(config.DELAY_HARVEST)
                    Punch(x, y, 18)
                    Hold()
                    if not config.IGNORE_UNHARVESTED_AFTER_PUNCH then
                        Sleep(config.DELAY_HARVEST)
                    else
                        Sleep(config.DELAY_HARVEST)
                        break
                    end
                end
            end
        end
    end
end

-- Fungsi utama yang dijalankan di thread
local function runPTHT()
    -- Inisialisasi ulang variabel
    REMOTE_X = config.MAG_X
    REMOTE_Y = config.MAG_Y
    START_MAG_X = config.MAG_X
    START_MAG_Y = config.MAG_Y
    PTHT_COUNT = 0
    MAG_EMPTY = false
    CHANGE_REMOTE = false
    ROTATION_COUNT = 0
    currentTime = os.time()
    startTime = currentTime

    -- Pasang hook
    AddHook("onvariant", "PTHT_Hook", hook)

    while running and not stopRequested and (config.TOTAL_PTHT == 0 or PTHT_COUNT < config.TOTAL_PTHT) do
        -- Cek world
        if GetWorld() == nil then
            SendPacket(2, "action|join_request\nname|" .. config.WORLD)
            SendPacket(3, "action|join_request\nname|" .. config.WORLD .. "\ninvitedWorld|0")
            Sleep(config.delay_reconnect)
        elseif GetWorld().name ~= config.WORLD then
            SendPacket(2, "action|join_request\nname|" .. config.WORLD)
            SendPacket(3, "action|join_request\nname|" .. config.WORLD .. "\ninvitedWorld|0")
            Sleep(config.delay_reconnect)
        end

        if stopRequested then break end

        if CHANGE_REMOTE then
            Sleep(100)
            if GetTile(REMOTE_X + 1, REMOTE_Y).fg == 5638 then
                REMOTE_X = REMOTE_X + 1
                CheckRemote()
            elseif GetTile(REMOTE_X + 1, REMOTE_Y).fg ~= 5638 then
                REMOTE_X = START_MAG_X
                CheckRemote()
            end
            CHANGE_REMOTE = false
            Sleep(50)
        end

        if CheckRemote() then
            if CHECK_FOR_TREE() then
                Sleep(50)
                SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_lonely|" .. config.PEOPLEHIDE .. "\ncheck_ignoreo|" .. config.DROPHIDDEN .. "\ncheck_gems|1")
                Sleep(100)
                local startHarvest = os.time()
                while CHECK_FOR_TREE() and not stopRequested do
                    ChangeValue("[C] Modfly", true)
                    HARVEST()
                end
                PTHT_COUNT = PTHT_COUNT + 1
                pthtCount = PTHT_COUNT
                TOTAL_TIME_HARVEST = os.time() - startHarvest
                -- Log
                local playerName = removeColorAndSymbols(GetLocal().name)
                local worldName = GetWorld().name
                local uws = GetItemCount(12600)
                local elapsed = os.time() - currentTime
                local logMsg = string.format("----Account---\nPlayer : %s\nWorld : %s\n----Information List----\nStatus : HARVEST TREE DONE\nPTHT DONE: %d\nTOTAL PTHT: %d\nTIME PLANT : %d Second\nTIME HARVEST : %d Second\nUWS : %d\n----UP TIME----\n%s\n----STAMP TIME----\n%s\n################################################\n",
                    playerName, worldName, PTHT_COUNT, config.TOTAL_PTHT, TOTAL_TIME_PLANT, TOTAL_TIME_HARVEST, uws,
                    FORMAT_TIME(elapsed), os.date("!%a, %b/%d/%Y at %I:%M %p", os.time() + 7 * 60 * 60))
                LogText("ptht_log.txt", logMsg)

                if config.WAIT_TIME > 0 then
                    Sleep(config.WAIT_TIME * 1000)
                else
                    Sleep(100)
                end
            else
                ROTATION_COUNT = 0
                if not config.MRAY then
                    local startPlant = os.time()
                    while CHECK_FOR_AIR() and not stopRequested do
                        if ROTATION_COUNT == 0 then
                            AUTOPLANT_SETTINGS()
                        else
                            SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autoplace|0\ncheck_gems|" .. config.COLLECT_GEMS)
                        end
                        Sleep(100)
                        ENABLE_GHOST()
                        PLANT_LOOP()
                        ROTATION_COUNT = ROTATION_COUNT + 1
                    end
                    PLANT_LOOP()
                else
                    local startPlant = os.time()
                    PLANT_LOOP()
                    ROTATION_COUNT = ROTATION_COUNT + 1
                end
                Sleep(50)
                ROTATION_COUNT = 0
                if not MAG_EMPTY then
                    TOTAL_TIME_PLANT = os.time() - startTime -- seharusnya startPlant, tapi kita simpan sederhana
                    Sleep(5000)
                    SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
                    Sleep(3000)
                    -- Log plant
                    local playerName = removeColorAndSymbols(GetLocal().name)
                    local worldName = GetWorld().name
                    local uws = GetItemCount(12600)
                    local elapsed = os.time() - currentTime
                    local logMsg = string.format("----Account---\nPlayer : %s\nWorld : %s\n----Information List----\nStatus : PLANT TREE DONE\nPTHT DONE: %d\nTOTAL PTHT: %d\nTIME PLANT : %d Second\nUWS : %d\n----UP TIME----\n%s\n----STAMP TIME----\n%s\n################################################\n",
                        playerName, worldName, PTHT_COUNT, config.TOTAL_PTHT, TOTAL_TIME_PLANT, uws,
                        FORMAT_TIME(elapsed), os.date("!%a, %b/%d/%Y at %I:%M %p", os.time() + 7 * 60 * 60))
                    LogText("ptht_log.txt", logMsg)
                end
            end
        end
        Sleep(100)
    end

    RemoveHook("PTHT_Hook")
    running = false
    currentStatus = "Stopped"
    LogToConsole("PTHT stopped")
end

-- Fungsi start/stop
local function startPTHT()
    if running then return end
    -- Validasi
    if config.WORLD == "" then
        LogToConsole("`4World name harus diisi!")
        return
    end
    if config.MAG_X == 0 or config.MAG_Y == 0 then
        LogToConsole("`4Koordinat magplant harus diisi!")
        return
    end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runPTHT)
    LogToConsole("PTHT started")
end

local function stopPTHT()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_CONFIG.txt", "w")
    if file then
        for k, v in pairs(config) do
            if type(v) == "boolean" then
                file:write(k .. "=" .. tostring(v) .. "\n")
            elseif type(v) == "number" then
                file:write(k .. "=" .. v .. "\n")
            elseif type(v) == "string" then
                file:write(k .. "=" .. v .. "\n")
            end
        end
        file:close()
        LogToConsole("`2Settings saved.")
    else
        LogToConsole("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_CONFIG.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if value == "true" then
                    config[key] = true
                elseif value == "false" then
                    config[key] = false
                elseif tonumber(value) then
                    config[key] = tonumber(value)
                else
                    config[key] = value
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
AddHook("OnDraw", "PTHTLoaderGUI", function(dt)
    if ImGui.Begin("PTHT Loader - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PTHTTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("General Settings")
                ImGui.Separator()

                local changedWhUse, newWhUse = ImGui.Checkbox("Use Webhook", config.whUse)
                if changedWhUse then config.whUse = newWhUse end

                if config.whUse then
                    local changedWhUrl, newWhUrl = ImGui.InputText("Webhook URL", config.whUrl, 200)
                    if changedWhUrl then config.whUrl = newWhUrl end
                end

                local changedWorld, newWorld = ImGui.InputText("World Name (CAPS)", config.WORLD, 30)
                if changedWorld then config.WORLD = newWorld end

                local changedDelay, newDelay = ImGui.InputInt("Reconnect Delay (ms)", config.delay_reconnect, 100, 1000)
                if changedDelay then config.delay_reconnect = newDelay end

                local changedWait, newWait = ImGui.InputInt("Wait Time (minutes)", config.WAIT_TIME, 1, 10)
                if changedWait then config.WAIT_TIME = newWait end

                local changedMray, newMray = ImGui.Checkbox("MRAY", config.MRAY)
                if changedMray then config.MRAY = newMray end

                local changedCollect, newCollect = ImGui.InputInt("Collect Gems (1=yes,2=no)", config.COLLECT_GEMS, 1, 1)
                if changedCollect then config.COLLECT_GEMS = newCollect end

                local changedItem, newItem = ImGui.InputInt("Item ID (Seed)", config.ITEM_ID, 1, 100)
                if changedItem then config.ITEM_ID = newItem end

                local changedTotal, newTotal = ImGui.InputInt("Total PTHT (0 = infinite)", config.TOTAL_PTHT, 1, 10)
                if changedTotal then config.TOTAL_PTHT = newTotal end

                ImGui.Text("Magplant Position:")
                local changedMagX, newMagX = ImGui.InputInt("Mag X", config.MAG_X, 1, 10)
                if changedMagX then config.MAG_X = newMagX end
                local changedMagY, newMagY = ImGui.InputInt("Mag Y", config.MAG_Y, 1, 10)
                if changedMagY then config.MAG_Y = newMagY end

                local changedDelayH, newDelayH = ImGui.InputInt("Harvest Delay", config.DELAY_HARVEST, 1, 10)
                if changedDelayH then config.DELAY_HARVEST = newDelayH end
                local changedDelayP, newDelayP = ImGui.InputInt("Plant Delay", config.DELAY_PLANT, 1, 10)
                if changedDelayP then config.DELAY_PLANT = newDelayP end

                local changedPlatform, newPlatform = ImGui.InputInt("Platform ID", config.PLATFORM_ID, 1, 100)
                if changedPlatform then config.PLATFORM_ID = newPlatform end

                local changedIgnore, newIgnore = ImGui.Checkbox("Ignore Unharvested After Punch", config.IGNORE_UNHARVESTED_AFTER_PUNCH)
                if changedIgnore then config.IGNORE_UNHARVESTED_AFTER_PUNCH = newIgnore end

                local changedPeople, newPeople = ImGui.InputInt("People Hide (0/1)", config.PEOPLEHIDE, 1, 1)
                if changedPeople then config.PEOPLEHIDE = newPeople end
                local changedDrop, newDrop = ImGui.InputInt("Drop Hidden (0/1)", config.DROPHIDDEN, 1, 1)
                if changedDrop then config.DROPHIDDEN = newDrop end

                ImGui.Text("Remove Animation Settings:")
                local changedAnim1, newAnim1 = ImGui.Checkbox("Remove Collected", config.removeAnimationCollected)
                if changedAnim1 then config.removeAnimationCollected = newAnim1 end
                local changedAnim2, newAnim2 = ImGui.Checkbox("Remove Bubble Talk", config.removeAnimationbubbletalk)
                if changedAnim2 then config.removeAnimationbubbletalk = newAnim2 end
                local changedAnim3, newAnim3 = ImGui.Checkbox("Remove SDB", config.removeSDB)
                if changedAnim3 then config.removeSDB = newAnim3 end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start PTHT", 120, 30) then
                        startPTHT()
                    end
                else
                    if ImGui.Button("Stop PTHT", 120, 30) then
                        stopPTHT()
                    end
                end
                ImGui.SameLine()
                if ImGui.Button("Save Settings", 120, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load Settings", 120, 30) then LoadSettings() end

                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("World: " .. (GetWorld() and GetWorld().name or "None"))
                ImGui.Text("PTHT Count: " .. pthtCount .. " / " .. (config.TOTAL_PTHT == 0 and "∞" or config.TOTAL_PTHT))
                ImGui.Text("UWS: " .. GetItemCount(12600))
                ImGui.Text("Remote: " .. GetItemCount(5640))
                if running and startTime > 0 then
                    local elapsed = os.time() - startTime
                    ImGui.Text("Uptime: " .. FORMAT_TIME(elapsed))
                end
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

-- Load settings otomatis saat start
LoadSettings()
LogToConsole("PTHT Loader ready. Use GUI to start.")
