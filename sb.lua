-- ==================== SUPER BROADCAST (Dengan GUI + Status) ====================
Settings = {
    SBText = "Lantas Nub",
    WebhookURL = "",
    UseWebhook = false,
    RandEmoji = false,
    RandColor = false,
    BlockSDB = false,
    BoostMode = false,
    SBTime = 0
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"
local TotalSb = 0
local startTimeSB = 0
local endTime = ""

-- Variabel global
worldName = GetWorld().name
nickN = GetLocal().name
HasBoost = Settings.BoostMode
WrenchMode = false
timestop = 0

-- Daftar ID sign dan warna/emoji
SignIDs = {
    20, 24, 26, 28, 226, 608, 780, 986, 1426, 1428,
    1430, 1432, 1446, 1906, 2396, 2414, 2586, 2948, 3690, 3758,
    4470, 4488, 4538, 5622, 6102, 6272, 7456, 9406, 11186, 11234,
    11408, 11412, 11426, 11444, 12204, 12900, 13364, 13676, 13678, 13802,
    13974, 14434, 14436, 14686, 14998, 15516, 15590, 15754, 15758
}

Colors = { "`2", "`9", "`6", "`9", "`5", "`e", "`c", "`^", "`o", "`$" }
Emotes = {
  "(wl)","(yes)","(no)","(love)","(oops)","(shy)","(wink)","(tongue)","(agree)","(sleep)",
  "(punch)","(music)","(build)","(megaphone)","(sigh)","(mad)","(wow)","(dance)","(see-no-evil)",
  "(bheart)","(heart)","(grow)","(gems)","(kiss)","(gtoken)","(lol)","(smile)","(cool)","(cry)",
  "(vend)","(bunny)","(cactus)","(pine)","(peace)","(terror)","(troll)","(evil)","(fireworks)",
  "(football)","(alien)","(party)","(pizza)","(clap)","(song)","(ghost)","(nuke)","(halo)",
  "(turkey)","(gift)","(cake)","(heartarrow)","(lucky)","(shamrock)","(grin)","(ill)","(eyes)",
  "(weary)","(moyai)","(plead)"
}

-- Fungsi pendukung
function Log(x)
    LogToConsole("`0[`9SB`0] " .. x)
end

function Join(w)
    SendPacket(3, "action|join_request\nname|" .. w .. "|\ninvitedWorld|0")
end

function isSignID(id)
    for _, sign in ipairs(SignIDs) do
        if sign == id then return true end
    end
    return false
end

function CopySignText()
    local posX = GetLocal().pos.x // 32
    local posY = GetLocal().pos.y // 32
    for x = posX - 5, posX + 5 do
        for y = posY - 5, posY + 5 do
            local tile = GetTile(x, y)
            if tile and isSignID(tile.fg) then
                local text = tile.extra and tile.extra.label or ""
                Log("Text: `2" .. text)
                Settings.SBText = text
                return
            end
        end
    end
end

function cleanNickname(nickname)
    nickname = nickname:gsub("[%d+`#@]", "")
    nickname = nickname:gsub("%[.-%]", "")
    nickname = nickname:match("^%s*(.-)%s*$")
    return nickname
end

function checkTimeLocal(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    local result = ""
    if hours > 0 then result = result .. hours .. "h " end
    if minutes > 0 then result = result .. minutes .. "m " end
    if secs > 0 then result = result .. secs .. "s" end
    return result
end

function checkCurrentTime(start, totalSeconds)
    local elapsed = os.time() - start
    return checkTimeLocal(elapsed) .. "/" .. checkTimeLocal(totalSeconds)
end

function SendSB()
    if not running or stopRequested then return end
    if HasBoost then
        SendPacket(2, "action|input\n|text|/sb " .. Settings.SBText)
    else
        SendPacket(2, "action|input\n|text|/sb " .. Settings.SBText)
    end
    TotalSb = TotalSb + 1
    Sleep(2500)
    local elapsed = os.time() - startTimeSB
    local remaining = (Settings.SBTime * 3600) - elapsed
    if remaining <= 0 then
        stopRequested = true
        Log("SB finished")
    else
        local msg = string.format("`7Sended [Total:%d] [%s] [Remaining:%s]", TotalSb, checkCurrentTime(startTimeSB, Settings.SBTime * 3600), checkTimeLocal(remaining))
        SendPacket(2, "action|input\n|text|" .. msg)
    end
end

-- Fungsi utama thread
local function runSB()
    startTimeSB = os.time()
    endTime = os.date("%H:%M:%S", startTimeSB + Settings.SBTime * 3600)
    TotalSb = 0
    Log("Auto SB started. End at: " .. endTime)

    while running and not stopRequested do
        -- Cek apakah sudah waktunya berhenti
        if os.time() - startTimeSB >= Settings.SBTime * 3600 then
            stopRequested = true
            break
        end

        -- Kirim SB
        SendSB()

        -- Tunggu 1 menit sebelum next (atau sesuai kebutuhan)
        for i = 1, 60 do
            if stopRequested then break end
            Sleep(1000)
        end
    end

    running = false
    currentStatus = "Stopped"
    Log("Auto SB stopped")
end

local function startSB()
    if running then return end
    if Settings.SBText == "" then
        Log("SB Text tidak boleh kosong")
        return
    end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runSB)
end

local function stopSB()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "SBGUI", function()
    local open = ImGui.Begin("The Continental - SB (Ertoxz)", true)

    if open then
        if ImGui.BeginTabBar("MainTabs") then

            if ImGui.BeginTabItem("Main") then
                ImGui.Text("The Continental - SB")
                ImGui.Spacing()

                ImGui.Text("Status:")
                ImGui.BulletText("SB Text: " .. (Settings.SBText or "Not Set"))
                ImGui.BulletText("Boost Mode: " .. (Settings.BoostMode and "Enabled" or "Disabled"))
                ImGui.BulletText("Webhook: " .. (Settings.WebhookURL ~= "" and "Set" or "Not Set"))
                ImGui.BulletText("Auto-SB Delay: " .. (Settings.SBTime or 0) .. " Hour(s)")

                ImGui.Spacing()
                ImGui.Text("Features:")
                local features = {
                    "Auto Detect Queue Time",
                    "Perfect Super Broadcast",
                    "Auto Reconnect (Can Run 24/7)",
                    "Webhook Support",
                    "Easy Setup",
                    "Using Time Format",
                    "Optional Block SDB"
                }
                for _, feature in ipairs(features) do
                    ImGui.BulletText(feature)
                end

                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Settings") then
                ImGui.Text("Text Settings:")
                if ImGui.Button("Copy Sign", 200, 45) then
                    Log("Copying sign text within radius 5...")
                    CopySignText()
                end
                ImGui.SameLine()
                if ImGui.Button("Copy Sign (Wrench)", 200, 45) then
                    WrenchMode = true
                    Log("Copy sign using wrench enabled")
                end

                ImGui.Spacing()
                ImGui.Text("Custom SB Text (Optional):")
                local changedText, newText = ImGui.InputText("##SBText", Settings.SBText or "", 256)
                if changedText then Settings.SBText = newText end

                ImGui.Spacing()
                ImGui.Text("Webhook:")
                local changedURL, newURL = ImGui.InputText("##WebhookURL", Settings.WebhookURL or "", 256)
                if changedURL then Settings.WebhookURL = newURL end

                if ImGui.Button("Set Webhook", 200, 45) then
                    Log("Webhook Set: " .. Settings.WebhookURL)
                end
                ImGui.SameLine()
                if ImGui.Button("Test Webhook", 200, 45) then
                    Log("Testing Webhook...")
                    if Settings.WebhookURL ~= "" then
                        MakeRequest(Settings.WebhookURL, "POST", {["Content-Type"]="application/json"}, '{"content":"Test"}')
                    end
                end

                ImGui.Spacing()
                ImGui.Text("Auto-SB Settings:")
                local settingsList = {
                    { key = "RandEmoji", label = "Random Emoji" },
                    { key = "RandColor", label = "Random Color" },
                    { key = "BlockSDB", label = "Block SDB" },
                    { key = "UseWebhook", label = "Use Webhook" },
                    { key = "BoostMode", label = "Boost Mode" }
                }
                for _, setting in ipairs(settingsList) do
                    local checked = Settings[setting.key] or false
                    if ImGui.Checkbox(setting.label, checked) then
                        Settings[setting.key] = not checked
                        if setting.key == "BoostMode" then HasBoost = Settings.BoostMode end
                        Log("`2" .. setting.label .. ": " .. (Settings[setting.key] and "Enabled" or "Disabled"))
                    end
                end

                ImGui.Spacing()
                ImGui.Text("Hour(s) To SuperBroadcast:")
                local changedDelay, newDelay = ImGui.InputInt("##SBTime", Settings.SBTime or 1)
                if changedDelay then Settings.SBTime = newDelay timestop = newDelay * 60 end

                ImGui.Spacing()
                if not running then
                    if ImGui.Button("Start Super-Broadcast", -1, 50) then
                        startSB()
                    end
                else
                    if ImGui.Button("Stop Super-Broadcast", -1, 50) then
                        stopSB()
                    end
                end

                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Total SB Sent: " .. TotalSb)
                if running then
                    local elapsed = os.time() - startTimeSB
                    local remaining = (Settings.SBTime * 3600) - elapsed
                    ImGui.Text("Elapsed: " .. checkTimeLocal(elapsed))
                    ImGui.Text("Remaining: " .. checkTimeLocal(remaining))
                    ImGui.Text("End Time: " .. endTime)
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script made by Lantas & Intevoir")
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
AddHook("OnVariant", "B", function(variant)
    if variant[0] == "OnSDBroadcast" and Settings.BlockSDB then
        return true
    end
    if variant[0] == "OnDialogRequest" and variant[1]:find("Sign") and variant[1]:find("display_text") and WrenchMode then
        local text = variant[1]:match("display_text||(.+)|128|")
        if text then
            Settings.SBText = text
            Log("Text: " .. Settings.SBText)
            WrenchMode = false
            return true
        end
        return true
    end
    if variant[0] == "OnConsoleMessage" and variant[1]:find("**from (.+)") and not Settings.BoostMode then
        local Nick = string.match(variant[1], "%((.-)%)")
        if Nick then
            local nick = Nick:gsub("[%d+`]", ""):gsub("#", ""):gsub("@", "")
            local localNick = cleanNickname(nickN)
            if nick == localNick then
                Log("Your SBs:")
                RunThread(function() SendSB() end)
            end
        end
    end
    if variant[0] == "OnConsoleMessage" and variant[1]:find("You can annoy with broadcasts again") and Settings.BoostMode then
        HasBoost = true
        RunThread(function() SendSB() end)
    end
    if variant[0] == "OnConsoleMessage" and variant[1]:find("Broadcast-Queque is full or you already have a pending one.") then
        Log("Your Super-Broadcast got blocked, trying to send another one...")
        RunThread(function() Sleep(5000) SendSB() end)
        return true
    end
    if variant[0] == "OnConsoleMessage" and variant[1]:find("Where would you like to go") then
        RunThread(function()
            Join(worldName)
            Log("Disconnected trying to reconnect")
            Sleep(5000)
        end)
        return true
    end
    return false
end)

Log("Super Broadcast script loaded. Use GUI to start.")
