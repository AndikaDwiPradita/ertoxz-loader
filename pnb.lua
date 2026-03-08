-- ==================== PNB BOT 3.0 LOADER (DENGAN GUI) ====================

-- Konfigurasi awal (dapat diedit melalui GUI)
Settings = {
    WebhookLink = "",
    WebhookDelay = 60,
    DiscordID = 0,
    Mneck = false,
    BreakID = 15460,
    MagBG = 14,
    ConsumableID = {4604, 1474, 1056},
    AntiLag = true,
    TakeGems = true,
    AutoBuyDL = true,
    AutoBuyBGL = false,
    AutoDeposit = true,
    AutoSuck = false,
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"
local scriptStartTime = 0
local LastWebhook = 0
local ConsumeTime = 0
local Gems = 0
local DL = 0
local BGL = 0
local ConvertedGems = 0
local EarnedGems = 0
local EarnedDL = 0
local EarnedBGL = 0
local RemoteEmpty = true
local RadioActive = false
local GhostMode = true
local Cheat = false
local Limit = 0
local Now = 1
local Mag = {}
local telx, tely = 0, 0
local posx, posy = 0, 0
local isLeft = false
local World = ""
local GrowID = ""

-- Fungsi pendukung (sama dengan asli)
function log(x)
    LogToConsole("`9[`cPNB`9]`0 "..x)
end

function overlay(x)
    SendVariantList({ [0]= "OnTextOverlay", [1] = x})
end

function join(world)
    SendPacket(3, "action|join_request\nname|"..world.."|\ninvitedWorld|0")
end

function talk(text)
    SendPacket(2, "action|input\ntext|"..text)
end

function formatGems(number)
    return tostring(number):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function SendWebhook(url, data)
    MakeRequest(url, "POST", { ["Content-Type"] = "application/json" }, data)
end

function inv(id)
    for _, itm in pairs(GetInventory()) do
        if itm.id == id then
            return itm.amount
        end
    end
    return 0
end

function GetDroppedCount(id)
    for _, obj in pairs(GetObjectList()) do
        if obj.id == id then
            return obj.amount
        end
    end
    return 0
end

function Raw(t, s, v, x, y)
    SendPacketRaw(false, {
        type = t,
        state = s,
        value = v,
        px = x, 
        py = y,
        x = x * 32,
        y = y * 32
    })
end

function path(a, b, c, d, e)
    SendPacketRaw(false, {
        type = a,
        state = b,
        value = c,
        px = d,
        py = e,
        x = (Settings.Mneck and d * 32 - 2 or d * 32),
        y = (Settings.Mneck and e * 32 - 2 or e * 32),
    })
end

function GetMag(x, y)
    local Found = {}
    for x = 0, x do
        for y = 0, y do
            local tile = GetTile(x,y)
            if (tile and tile.fg == 5638) and (tile.bg == Settings.MagBG) then
                table.insert(Found, {x, y})
            end
        end
    end
    return Found
end

function TakeMag()
    Raw(0, 0, 0, Mag[Now][1], Mag[Now][2])
    Sleep(300)
    Raw(3, 0, 32, Mag[Now][1], Mag[Now][2])
    Sleep(300)
    SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. Mag[Now][1] .. "|\ny|" .. Mag[Now][2] .. "|\nbuttonClicked|getRemote")
    Sleep(300)
end

function Consume()
    if os.time() - ConsumeTime >= 60 * 30 then
        ConsumeTime = os.time()
        overlay("`9Consume Time")
        log("`9Consume Time")
        Sleep(500)
        for _, Eat in pairs(Settings.ConsumableID) do
            if inv(Eat) > 0 then
                Raw(3, 0, Eat, posx, posy)
                Sleep(500)
            end
        end
        Sleep(500)
    end
end

function GetTelephonePosition()
    local p = {GetLocal().pos.x//32, GetLocal().pos.y//32}
    for x = p[1] - 4, p[1] + 4, 1 do
        for y = p[2] - 1, p[2] + 1, 1 do
            if GetTile(x, y) and GetTile(x, y).fg == 3898 then
                telx = x
                tely = y
                overlay("`2Locked Telephone Position: `0["..telx..", "..tely.."`0]")
            end
        end
    end
end

function ConvertGems(x, y)
    if inv(1796) >= 100 then
        SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|"..x.."|\ny|"..y.."|\nbuttonClicked|bglconvert")
    end
    if inv(7188) >= 100 and not Settings.AutoDeposit then
        SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
    elseif inv(7188) >= 5 and Settings.AutoDeposit then
        SendPacket(2, "action|dialog_return\ndialog_name|bank_deposit\nbgl_count|".. inv(7188))
    end
    if Settings.AutoBuyDL then
        SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|"..x.."|\ny|"..y.."|\nbuttonClicked|dlconvert")
        Sleep(50)
    elseif Settings.AutoBuyBGL then
        SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|"..x.."|\ny|"..y.."|\nbuttonClicked|bglconvert2")
        Sleep(50)
    end
end

function SendWH()
    local uptimeSeconds = (scriptStartTime and os.time() - scriptStartTime) or 0
    local uptimeMinutes = math.floor(uptimeSeconds / 60)
    local uptimeHours = math.floor(uptimeMinutes / 60)
    local uptimeDisplay = string.format("%02d Hours %02d Minutes", uptimeHours, uptimeMinutes % 60)
    local EarnedGems = not Settings.AutoBuyDL and (GetPlayerItems().gems - Gems) or 0
    local payload = [[
{
  "content": "PNB Status Update",
  "embeds": [
    {
      "title": "PNB Status",
      "fields": [
        {
          "name": "Username",
          "value": "]]..GrowID..[[",
          "inline": true
        },
        {
          "name": "Locked World Name",
          "value": "World: ]]..World..[[",
          "inline": true
        },
        {
          "name": "Locked Break Position",
          "value": "X: ]]..posx..[[ Y: ]]..posy..[[",
          "inline": true
        },
        {
          "name": "Telephone Position",
          "value": "X: ]]..telx..[[ Y: ]]..tely..[[",
          "inline": true
        },
        {
          "name": "Magplant Count",
          "value": "]]..#Mag..[[",
          "inline": true
        },
        {
          "name": "Current Remote",
          "value": "Current Remote: ]]..Now..[[",
          "inline": true
        },
        {
          "name": "Consumable",
          "value": "Configured ]]..#Settings.ConsumableID..[[ Consumable ID\nArroz: ]]..inv(4604)..[[\nClover: ]]..inv(528)..[[\nSongPyeon: ]]..inv(1056)..[[\nEggs Benedict: ]]..inv(1474)..[[",
          "inline": false
        },
        {
          "name": "World",
          "value": "Start Gems: ]]..formatGems(Gems)..[[\nEarned Gems: ]]..EarnedGems..[[\nConverted Gems: ]]..ConvertedGems..[[",
          "inline": false
        },
        {
          "name": "Total Lock",
          "value": "Current Diamond Lock: ]]..inv(1796)..[[\nCurrent Blue Gem Lock: ]]..inv(7188)..[[",
          "inline": false
        },
        {
          "name": "Earned Locks",
          "value": "Earn DL: ]]..EarnedDL..[[\nEarn BGL: ]]..EarnedBGL..[[",
          "inline": false
        },
        {
          "name": "Dropped Items",
          "value": "Black Gems: ]]..GetDroppedCount(15670)..[[\nPink Gem Stone: ]]..GetDroppedCount(15422)..[[",
          "inline": false
        },
        {
          "name": "Uptime",
          "value": "Time: ]]..uptimeDisplay..[[",
          "inline": false
        }
      ],
      "footer": {
        "text": "#Continental"
      },
      "color": 5814783
    }
  ]
}
]]
    SendWebhook(Settings.WebhookLink, payload)
end

-- Fungsi utama yang dijalankan di thread
local function runPNB()
    -- Inisialisasi ulang variabel setiap start
    GrowID = GetLocal().name:gsub("`(%S)", ""):match("%S+") or ""
    World = GetWorld().name or ""
    posx, posy = GetLocal().pos.x//32, GetLocal().pos.y//32
    isLeft = GetLocal().isleft and true or false
    scriptStartTime = os.time()
    LastWebhook = os.time()
    ConsumeTime = os.time() - 60 * 30 
    Gems = GetPlayerItems().gems or 0
    DL = inv(1796)
    BGL = inv(7188)
    ConvertedGems = 0
    EarnedGems = 0
    EarnedDL = 0
    EarnedBGL = 0
    RemoteEmpty = true
    RadioActive = false
    GhostMode = true
    Cheat = false
    Limit = 0
    Now = 1
    Mag = {}

    -- Deteksi ukuran world dan dapatkan magplant
    if GetTile(203, 0) then
        Mag = GetMag(203, 203)
        overlay("`2Total Magplant In This World: `0[`c"..#Mag.."`0]")
    elseif GetTile(199, 0) then
        Mag = GetMag(199, 199)
        overlay("`2Total Magplant In This World: `0[`c"..#Mag.."`0]")
    elseif GetTile(99, 0) then
        Mag = GetMag(99, 53)
        overlay("`2Total Magplant In This World: `0[`c"..#Mag.."`0]")
    elseif GetTile(29, 0) then
        Mag = GetMag(29, 29)
        overlay("`2Total Magplant In This World: `0[`c"..#Mag.."`0]")
    end

    GetTelephonePosition()

    -- Loop utama PNB
    while running and not stopRequested do
        Sleep(500)

        -- Cek koneksi world
        if not GetWorld() then
            join(World)
            log("Reconnecting...")
            overlay("Reconnecting...")
            RemoteEmpty = true
            RadioActive = true
            Cheat = false
            Sleep(5000)
            goto continue
        elseif GetWorld().name ~= World then
            join(World)
            log("Re-Joining to world `0[`c".. World .."`0]")
            overlay("Re-Joining to world `0[`c".. World .."`0]")
            Sleep(5000)
            RemoteEmpty = true
            GhostMode = false
            Cheat = false
            goto continue
        end

        if RadioActive then
            SendPacket(2, "action|input\n|text|/radio")
            RadioActive = false
            Sleep(400)
        end

        if not GhostMode then
            SendPacket(2, "action|input\n|text|/ghost")
            GhostMode = true
            Sleep(400)
        end

        if RemoteEmpty then
            overlay("Taking Magplant `2#"..Now)
            log("Taking Magplant `2#"..Now)
            TakeMag()
            RemoteEmpty = false
            Sleep(400)
        end

        -- Kembali ke posisi awal jika bergeser
        if (GetLocal().pos.x//32 ~= posx) or (GetLocal().pos.y//32 ~= posy) then
            path(0, (isLeft and 48 or 32), 0, posx, posy)
        end

        -- Perbaiki arah jika berubah
        if (isLeft and not GetLocal().isleft) or (not isLeft and GetLocal().isleft) then
            path(0, (isLeft and 48 or 32), 0, posx, posy)
        end

        -- Aktifkan cheat jika belum
        if not Cheat then
            path(0, (isLeft and 48 or 32), 0, posx, posy)
            Sleep(200)
            SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|1\ncheck_bfg|1\ncheck_lonely|".. (Settings.AntiLag and 1 or 1) .."\ncheck_gems|".. (Settings.TakeGems and 1 or 0))
            Cheat = true
            Sleep(400)
        end

        -- Konsumsi periodik
        if os.time() - ConsumeTime >= 60 * 30 then
            Consume()
            Sleep(400)
        end

        -- Konversi gems
        if Settings.AutoBuyDL and GetPlayerItems().gems >= Gems + 10000 then
            log("`2Buying `1Diamond Lock(s)")
            ConvertGems(telx, tely)
            ConvertedGems = ConvertedGems + (GetPlayerItems().gems - Gems)
            EarnedDL = EarnedDL + (inv(1796) - DL)
            EarnedBGL = EarnedBGL + (inv(7188) - BGL)
            Sleep(400)
        end
        if Settings.AutoBuyBGL and GetPlayerItems().gems >= Gems + 10000000 then
            log("`2Buying `cBlue Gem Lock(s)")
            ConvertGems(telx, tely)
            ConvertedGems = ConvertedGems + (GetPlayerItems().gems - Gems)
            EarnedDL = EarnedDL + (inv(1769) - DL)
            EarnedBGL = EarnedBGL + (inv(7188) - BGL)
            Sleep(400)
        end

        -- Auto suck BGEMS
        if Settings.AutoSuck and GetDroppedCount(15670) >= 1000 then
            SendPacket(2, "action|dialog_return\ndialog_name|social\nbuttonClicked|bgem_suckall\n\n")
            Sleep(50)
        end

        -- Kirim webhook
        if Settings.WebhookLink ~= "" and os.time() - LastWebhook >= Settings.WebhookDelay then
            SendWH()
            Sleep(400)
            LastWebhook = os.time()
        end

        -- Cek block di samping
        local targetX = posx + ((not Settings.Mneck and (isLeft and 0 or 1)) or 0)
        local targetY = posy + ((Settings.Mneck and 1) or 0)
        local tile = GetTile(targetX, targetY)
        if tile and tile.fg == Settings.BreakID then
            Limit = 0
        else
            Limit = Limit + 1
        end

        -- Jika limit tercapai, ganti remote
        if Limit >= 50 then
            Now = Now >= #Mag and 1 or Now + 1
            Sleep(300)
            SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|0\ncheck_bfg|0\ncheck_lonely|".. (Settings.AntiLag and 1 or 1) .."\ncheck_gems|".. (Settings.TakeGems and 1 or 0))
            Cheat = false
            RemoteEmpty = true
            Limit = 0
        end

        ::continue::
    end

    running = false
    currentStatus = "Stopped"
    log("PNB stopped")
end

-- Fungsi start/stop
local function startPNB()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runPNB)
    log("PNB started")
end

local function stopPNB()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PNB3_SETTINGS.txt", "w")
    if file then
        file:write("WebhookLink=" .. Settings.WebhookLink .. "\n")
        file:write("WebhookDelay=" .. Settings.WebhookDelay .. "\n")
        file:write("DiscordID=" .. Settings.DiscordID .. "\n")
        file:write("Mneck=" .. tostring(Settings.Mneck) .. "\n")
        file:write("BreakID=" .. Settings.BreakID .. "\n")
        file:write("MagBG=" .. Settings.MagBG .. "\n")
        file:write("ConsumableID=" .. table.concat(Settings.ConsumableID, ",") .. "\n")
        file:write("AntiLag=" .. tostring(Settings.AntiLag) .. "\n")
        file:write("TakeGems=" .. tostring(Settings.TakeGems) .. "\n")
        file:write("AutoBuyDL=" .. tostring(Settings.AutoBuyDL) .. "\n")
        file:write("AutoBuyBGL=" .. tostring(Settings.AutoBuyBGL) .. "\n")
        file:write("AutoDeposit=" .. tostring(Settings.AutoDeposit) .. "\n")
        file:write("AutoSuck=" .. tostring(Settings.AutoSuck) .. "\n")
        file:close()
        log("`2Settings saved.")
    else
        log("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PNB3_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "WebhookLink" then Settings.WebhookLink = value
                elseif key == "WebhookDelay" then Settings.WebhookDelay = tonumber(value)
                elseif key == "DiscordID" then Settings.DiscordID = tonumber(value)
                elseif key == "Mneck" then Settings.Mneck = (value == "true")
                elseif key == "BreakID" then Settings.BreakID = tonumber(value)
                elseif key == "MagBG" then Settings.MagBG = tonumber(value)
                elseif key == "ConsumableID" then
                    local ids = {}
                    for id in string.gmatch(value, "%d+") do
                        table.insert(ids, tonumber(id))
                    end
                    Settings.ConsumableID = ids
                elseif key == "AntiLag" then Settings.AntiLag = (value == "true")
                elseif key == "TakeGems" then Settings.TakeGems = (value == "true")
                elseif key == "AutoBuyDL" then Settings.AutoBuyDL = (value == "true")
                elseif key == "AutoBuyBGL" then Settings.AutoBuyBGL = (value == "true")
                elseif key == "AutoDeposit" then Settings.AutoDeposit = (value == "true")
                elseif key == "AutoSuck" then Settings.AutoSuck = (value == "true")
                end
            end
        end
        file:close()
        log("`2Settings loaded.")
    else
        log("`3No settings file found, using defaults.")
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "PNBGUI", function(dt)
    if ImGui.Begin("PNB Bot 3.0 - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PNBTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("PNB Settings")
                ImGui.Separator()

                local changedWeb, newWeb = ImGui.InputText("Webhook URL", Settings.WebhookLink, 200)
                if changedWeb then Settings.WebhookLink = newWeb end
                local changedDelay, newDelay = ImGui.InputInt("Webhook Delay (s)", Settings.WebhookDelay, 1, 10)
                if changedDelay then Settings.WebhookDelay = newDelay end
                local changedDisc, newDisc = ImGui.InputInt("Discord ID", Settings.DiscordID, 1, 100)
                if changedDisc then Settings.DiscordID = newDisc end

                local changedMneck, newMneck = ImGui.Checkbox("Mneck Mode", Settings.Mneck)
                if changedMneck then Settings.Mneck = newMneck end
                local changedBreak, newBreak = ImGui.InputInt("Break ID", Settings.BreakID, 1, 100)
                if changedBreak then Settings.BreakID = newBreak end
                local changedMag, newMag = ImGui.InputInt("Magplant BG", Settings.MagBG, 1, 100)
                if changedMag then Settings.MagBG = newMag end

                ImGui.Text("Consumable IDs (pisah koma):")
                local consumableStr = table.concat(Settings.ConsumableID, ",")
                local changedCons, newCons = ImGui.InputText("##Consumable", consumableStr, 100)
                if changedCons then
                    local ids = {}
                    for id in string.gmatch(newCons, "%d+") do
                        table.insert(ids, tonumber(id))
                    end
                    if #ids > 0 then Settings.ConsumableID = ids end
                end

                local changedAnti, newAnti = ImGui.Checkbox("Anti Lag", Settings.AntiLag)
                if changedAnti then Settings.AntiLag = newAnti end
                local changedTake, newTake = ImGui.Checkbox("Take Gems", Settings.TakeGems)
                if changedTake then Settings.TakeGems = newTake end
                local changedBuyDL, newBuyDL = ImGui.Checkbox("Auto Buy DL", Settings.AutoBuyDL)
                if changedBuyDL then Settings.AutoBuyDL = newBuyDL end
                local changedBuyBGL, newBuyBGL = ImGui.Checkbox("Auto Buy BGL", Settings.AutoBuyBGL)
                if changedBuyBGL then Settings.AutoBuyBGL = newBuyBGL end
                local changedDeposit, newDeposit = ImGui.Checkbox("Auto Deposit", Settings.AutoDeposit)
                if changedDeposit then Settings.AutoDeposit = newDeposit end
                local changedSuck, newSuck = ImGui.Checkbox("Auto Suck", Settings.AutoSuck)
                if changedSuck then Settings.AutoSuck = newSuck end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start PNB", 150, 30) then
                        startPNB()
                    end
                else
                    if ImGui.Button("Stop PNB", 150, 30) then
                        stopPNB()
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
                ImGui.Text("Position: " .. posx .. ", " .. posy)
      
