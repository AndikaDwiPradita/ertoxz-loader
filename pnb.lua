-- ==================== PNB SCRIPT (Dengan GUI) ====================
Setting = {
    PNB = {
        WearItem = "Mythical Necklace",
        AutoCollectGems = true,
        AutoChangeRemote = false,
        AutoConsumables = false,
        AutoTelephone = false,
        SendToWebhook = false,
        WebhookURL = "https://discord.com/api/webhook/...",
        WebhookDelay = 300
    },
    PosX = 0, -- Break Pos
    PosY = 0,
    MagplantX = 0,
    MagplantY = 0,
}

worldName = string.upper(GetWorld().name)

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Variabel internal
changeRemote = false
m = false
magplantCount = 1
oldMagplantX = 0
telX = 0
telY = 0
TOP_UP = false
GetPos = false
Magplant = false
BreakPos = false

-- Fungsi Log
function Log(x)
    LogToConsole("`0[`9PNB`0] " .. x)
end

function inv(id)
    local count = 0
    for _, itm in pairs(GetInventory()) do
        if itm.id == id then
            count = count + itm.amount
        end
    end
    return count
end

function Join(w)
    SendPacket(3, "action|join_request\nname|" .. w .. "|\ninvitedWorld|0")
end

function Raw(a, b, c, d, e)
    local x = d * 32
    local y = e * 32
    if TOP_UP then
        x = d * 32 - 2
        y = e * 32 - 2
    end
    SendPacketRaw(false, {
        type = a,
        state = b,
        value = c,
        px = d,
        py = e,
        x = x,
        y = y,
    })
end

function wrench(x, y)
    local pkt = {}
    pkt.type = 3
    pkt.value = 32
    pkt.px = math.floor(GetLocal().pos.x / 32 + x)
    pkt.py = math.floor(GetLocal().pos.y / 32 + y)
    pkt.x = GetLocal().pos.x
    pkt.y = GetLocal().pos.y
    SendPacketRaw(false, pkt)
end

function getRemote()
    if inv(5640) == 0 or changeRemote then
        SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|0\ncheck_bfg|0\ncheck_lonely|0\ncheck_ignoreo|0\ncheck_gems|" .. (Setting.PNB.AutoCollectGems and 1 or 0))
        Sleep(500)
        FindPath(Setting.MagplantX, Setting.MagplantY - 1, 100)
        Sleep(500)
        wrench(0, 1)
        Sleep(500)
        SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. Setting.MagplantX .. "|\ny|" .. Setting.MagplantY .. "|\nbuttonClicked|getRemote")
        changeRemote = false
        m = false
    end
end

function Wear(item)
    if item == "Mythical Necklace" then
        SendPacketRaw(false, { type = 10, value = 15748 })
        TOP_UP = true
    elseif item == "Mythical Infinity Fist" then
        SendPacketRaw(false, { type = 10, value = 15730 })
    elseif item == "Legendary Infinity Fist" then
        SendPacketRaw(false, { type = 10, value = 15694 })
    elseif item == "Legendary Shard Sword" then
        SendPacketRaw(false, { type = 10, value = 15444 })
    end
end

ConsumeTime = os.time() - 60 * 30
function Consume()
    local Consumable = {4604, 528, 1474}
    if os.time() - ConsumeTime >= 60 * 30 then
        ConsumeTime = os.time()
        LogToConsole("`wConsuming `9Arroz `wand `2Clover")
        SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|0\ncheck_bfg|0\ncheck_lonely|0\ncheck_ignoreo|0\ncheck_gems|" .. (Setting.PNB.AutoCollectGems and 1 or 0))
        Sleep(2000)
        for _, Eat in pairs(Consumable) do
            if inv(Eat) > 0 then
                Raw(3, 0, Eat, Setting.PosX, Setting.PosY)
                Sleep(2000)
            end
        end
        SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|1\ncheck_bfg|1\ncheck_lonely|0\ncheck_ignoreo|0\ncheck_gems|" .. (Setting.PNB.AutoCollectGems and 1 or 0))
        Sleep(2000)
    end
end

LastConvertTime = os.time() - 10
function Convert()
    local now = os.time()
    if now - LastConvertTime >= 10 then
        LastConvertTime = now
        if inv(1796) >= 100 then
            SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. telX .. "|\ny|" .. telY .. "|\nbuttonClicked|bglconvert")
            Sleep(50)
        end
        SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. telX .. "|\ny|" .. telY .. "|\nbuttonClicked|dlconvert")
        Sleep(30)
    end
end

function SendWebhook(url, data)
    if Setting.PNB.SendToWebhook then
        MakeRequest(url, "POST", { ["Content-Type"] = "application/json" }, data)
    end
end

-- Fungsi utama yang akan dijalankan di thread
local function runPNB()
    while running and not stopRequested do
        if GetWorld() == nil then
            Join(worldName)
            Sleep(5000)
            getRemote()
        end

        if changeRemote then
            SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|0\ncheck_bfg|0\ncheck_lonely|0\ncheck_ignoreo|0\ncheck_gems|" .. (Setting.PNB.AutoCollectGems and 1 or 0))
            -- Logika ganti remote (sederhana)
            if Setting.magplantX and Setting.magplantY and GetTile(Setting.magplantX + 1, Setting.magplantY).fg == 5638 then
                Setting.magplantX = Setting.magplantX + 1
                magplantCount = magplantCount + 1
                LogToConsole("`wMagplant `4Empty`w. Change to `2Next")
            else
                LogToConsole("`wMagplant `4Empty`w. Change to `2First")
                magplantCount = 1
                Setting.magplantX = oldMagplantX
            end
            getRemote()
            Sleep(1200)
        end

        if GetWorld().name ~= worldName or GetWorld() == nil then
            Join(worldName)
            Sleep(5000)
            getRemote()
        end

        getRemote()
        Sleep(2000)

        if inv(5640) == 1 and not m then
            Sleep(3000)
            FindPath(Setting.PosX, Setting.PosY, 100)
            Sleep(1500)
            SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|1\ncheck_bfg|1\ncheck_lonely|0\ncheck_ignoreo|0\ncheck_gems|" .. (Setting.PNB.AutoCollectGems and 1 or 0))
            Sleep(2000)
            m = true
        end

        if GetWorld().name ~= worldName or GetWorld() == nil then
            Join(worldName)
            Sleep(5000)
            getRemote()
        end

        if Setting.PNB.AutoConsumables then
            Consume()
        end

        if Setting.PNB.AutoTelephone then
            Convert()
        end

        -- Webhook (contoh)
        local playerName = GetLocal().name
        playerName = string.gsub(playerName, "#", "")
        playerName = string.gsub(playerName, "`", "")
        playerName = string.gsub(playerName, "b", "")
        local positioningBreak = "X: " .. Setting.PosX .. ", Y: " .. Setting.PosY
        local dlCount = inv(1796)
        local bglCount = inv(7188)
        local arrozCount = inv(4604)
        local cloverCount = inv(528)
        local songpyeonCount = inv(1056)
        local myData = string.format([[
        {
          "embeds": [
            {
              "title": "Information Webhook",
              "fields": [
                { "name": "Player Name", "value": "%s", "inline": false },
                { "name": "World Name", "value": "%s", "inline": true },
                { "name": "Positioning Break", "value": "%s", "inline": true },
                { "name": "DL Count", "value": "%d", "inline": true },
                { "name": "BGL Count", "value": "%d", "inline": true },
                { "name": "Arroz", "value": "%d", "inline": true },
                { "name": "Clover", "value": "%d", "inline": true },
                { "name": "Songpyeon", "value": "%d", "inline": true }
              ],
              "color": 16711680
            }
          ]
        }
        ]], playerName, worldName, positioningBreak, dlCount, bglCount, arrozCount, cloverCount, songpyeonCount)
        SendWebhook(Setting.PNB.WebhookURL, myData)

        Sleep(300)
    end
    running = false
    currentStatus = "Stopped"
    Log("PNB stopped")
end

-- Fungsi start/stop
local function startPNB()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runPNB)
    Log("PNB started")
end

local function stopPNB()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "Pro", function()
    local open = ImGui.Begin("The Continental - PNB (Ertoxz)", true)
    if open then
        if ImGui.BeginTabBar("MainTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Wear Item:")
                local items = {
                    "Mythical Necklace",
                    "Mythical Infinity Fist",
                    "Legendary Infinity Fist",
                    "Legendary Shard Sword"
                }
                for i, item in ipairs(items) do
                    if ImGui.Selectable(item, Setting.PNB.WearItem == item) then
                        Setting.PNB.WearItem = item
                        Log("Wearing `2" .. item)
                        Wear(item)
                    end
                end

                ImGui.Spacing()
                ImGui.Text("Options:")
                local settingsList = {
                    { key = "AutoCollectGems", label = "Auto Collect Gems" },
                    { key = "AutoChangeRemote", label = "Auto Change Remote" },
                    { key = "AutoConsumables", label = "Auto Consume" },
                    { key = "AutoTelephone", label = "Auto Telephone" },
                    { key = "SendToWebhook", label = "Send to Webhook" }
                }
                for _, setting in ipairs(settingsList) do
                    local checked = Setting.PNB[setting.key]
                    if ImGui.Checkbox(setting.label, checked) then
                        Setting.PNB[setting.key] = not checked
                        local status = Setting.PNB[setting.key] and "Enable" or "Disable"
                        Log("`2Cheat " .. setting.label .. ": " .. status)
                    end
                end

                ImGui.Spacing()
                if ImGui.Button("Set Magplant Pos", 200, 50) then
                    Log("Setting Magplant Position...")
                    GetPos = true
                    Magplant = true
                end
                ImGui.SameLine()
                if ImGui.Button("Set Farming Pos", 200, 50) then
                    Log("Setting Farming Position...")
                    GetPos = true
                    BreakPos = true
                end

                ImGui.Spacing()
                if not running then
                    if ImGui.Button("Start PNB", -1, 65) then
                        startPNB()
                    end
                else
                    if ImGui.Button("Stop PNB", -1, 65) then
                        stopPNB()
                    end
                end

                ImGui.Spacing()
                if ImGui.Button("Save Settings", -1, 65) then
                    SaveSettings()
                end
                if ImGui.Button("Load Settings", -1, 65) then
                    LoadSettings()
                end

                ImGui.EndTabItem()
            end

            -- SETTINGS TAB
            if ImGui.BeginTabItem("Settings") then
                ImGui.Text("Webhook URL:")
                local changed, newURL = ImGui.InputText("##WebhookURL", Setting.PNB.WebhookURL, 256)
                if changed then Setting.PNB.WebhookURL = newURL end

                ImGui.Spacing()
                if ImGui.Button("Set Webhook", 200, 45) then
                    Log("Webhook Set: " .. Setting.PNB.WebhookURL)
                end
                ImGui.SameLine()
                if ImGui.Button("Test Webhook", 200, 45) then
                    Log("Testing Webhook...")
                end

                ImGui.Spacing()
                ImGui.Text("Webhook Delay (seconds):")
                if ImGui.Button("-##WebhookDelay") then Setting.PNB.WebhookDelay = Setting.PNB.WebhookDelay - 1 end
                ImGui.SameLine()
                local changedDelay, newDelay = ImGui.InputInt("##WebhookDelay", Setting.PNB.WebhookDelay)
                if changedDelay then Setting.PNB.WebhookDelay = newDelay end
                ImGui.SameLine()
                if ImGui.Button("+##WebhookDelay") then Setting.PNB.WebhookDelay = Setting.PNB.WebhookDelay + 1 end

                ImGui.Spacing()
                if ImGui.Button("Set Webhook Delay", -1, 45) then
                    Log("Webhook Delay Set: " .. Setting.PNB.WebhookDelay .. " seconds")
                end

                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Magplant Pos: " .. Setting.MagplantX .. ", " .. Setting.MagplantY)
                ImGui.Text("Farming Pos: " .. Setting.PosX .. ", " .. Setting.PosY)
                ImGui.Text("Remote Count: " .. inv(5640))
                ImGui.Text("DL: " .. inv(1796) .. " | BGL: " .. inv(7188))
                ImGui.Text("Arroz: " .. inv(4604) .. " | Clover: " .. inv(528))
                ImGui.EndTabItem()
            end

            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Lantas & Intevoir")
                ImGui.Text("Modified by Ertoxz")
                ImGui.Text("GUI by Ertoxz")
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

-- ==================== HOOKS ====================
AddHook("onsendpacketraw", "pro", function(pkt)
    if pkt.value == 18 and GetPos then
        if Magplant then
            Setting.MagplantX = pkt.px
            Setting.MagplantY = pkt.py
            oldMagplantX = Setting.MagplantX
            Log("Magplant Pos : " .. Setting.MagplantX .. ", " .. Setting.MagplantY)
            Magplant = false
            GetPos = false
            return true
        end
        if BreakPos then
            Setting.PosX = pkt.px
            Setting.PosY = pkt.py
            telX = pkt.px
            telY = pkt.py
            BreakPos = false
            GetPos = false
            Log("Farming Pos : " .. Setting.PosX .. ", " .. Setting.PosY)
            return true
        end
        return true
    end
    return false
end)

AddHook("OnVariant", "pRo", function(var)
    if var[0] == "OnSDBroadcast" then
        return true
    end
    if var[0] == "OnDialogRequest" and var[1]:find("MAGPLANT 5000") then
        if var[1]:find("The machine is currently empty!") then
            changeRemote = true
        end
        return true
    end
    if var[0] == "OnDialogRequest" and var[1]:find("The BGL Bank") then
        return true
    end
    if var[0] == "OnDialogRequest" and var[1]:find("The Black Backpack") then
        return true
    end
    if var[0] == "OnDialogRequest" and var[1]:find("Diamond Lock") then
        return true
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("Disconnected?! Will attempt to reconnect...") then
        return true
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("Where would you like to go?") then
        return true
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("Applying cheats...") then
        return true
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("Cheat Active") then
        return true
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("Whoa, calm down toggling cheats on/off...") then
        return true
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("You earned") then
        return true
    end
    if var[0] == "OnTalkBubble" and var[2]:find("You got `$Diamond Lock") then
        return true
    end
    if var[0] == "OnTalkBubble" and var[2]:match("Xenonite") then
        return true
    end
    if var[0] == "OnTalkBubble" and var[2]:find("The MAGPLANT 5000 is empty.") then
        changeRemote = true
        return true
    end
    return false
end)

-- ==================== SAVE/LOAD SETTINGS ====================
function SaveSettings()
    Log("`2Saving The Configuration...")
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PNB_SETTINGS.txt", "w")
    if file then
        for k, v in pairs(Setting.PNB) do
            file:write("PNB." .. k .. "=" .. tostring(v) .. "\n")
        end
        file:write("Setting.PosX=" .. tostring(Setting.PosX) .. "\n")
        file:write("Setting.PosY=" .. tostring(Setting.PosY) .. "\n")
        file:write("Setting.MagplantX=" .. tostring(Setting.MagplantX) .. "\n")
        file:write("Setting.MagplantY=" .. tostring(Setting.MagplantY) .. "\n")
        file:close()
        Log("`2Configuration Saved Successfully!")
    else
        LogToConsole("`4Failed to Save Configuration!")
    end
end

function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PNB_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local section, key, value = line:match("([^%.]+)%.([^=]+)=(.+)")
            if section and key and value then
                if value == "true" then value = true
                elseif value == "false" then value = false
                elseif tonumber(value) then value = tonumber(value) end
                if section == "PNB" then
                    Setting.PNB[key] = value
                elseif section == "Setting" then
                    Setting[key] = value
                end
            end
        end
        file:close()
        Log("`2Configuration Loaded Successfully!")
    else
        LogToConsole("`3No Previous Configuration Found. Using Default Settings.")
    end
end

-- Cek API
if not io or not MakeRequest or not ImGui then
    LogToConsole("Turn On Io, MakeRequest, and ImGui on API List")
end

Log("PNB script loaded. Use GUI to start.")
