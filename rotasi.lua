-- ==================== ROTASI PNB/PTHT (Dengan GUI) ====================
Settings = {
  Mode = "PTHT", 
  Webhook = "Webhook",
  UseMneck = false, 
  ConsumableID = {4604, 1474, 1056},
  
  PNB = {
    MagBG = 14, 
    AntiLag = false, 
    RemoveAnimation = false,
    AutoConsume = false,
    AutoCollectGems = true,
    AutoBuyDL = true,
    AutoSuck = false,
    BreakID = 15460, -- tambahkan jika perlu
  },
  
  PTHT = {
    SecondAcc = false,
    StartingPos = { 0, 184 }, 
    MagBG = 284, 
    TotalPTHT = 10, 
    SeedID = 15461, 
    MaxTree = 15000, 
    DelayPT = 25, 
    DelayHT = 200, 
    DelayAfterUWS = 4000,
    DelayAfterPT = 8000, 
  },
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Variabel global yang diperlukan
World = GetWorld().name
GrowID = GetLocal().name
Gems = 0
posx = 0
posy = 0
Facing = "right"
cheat = false
getremote = true
chgremote = false
s = false
ck = 0
t = 0
limit = 0
C1 = 1
C2 = 1
lnm = true
u1sed = 0
ls = 0
Mag1 = {}
Mag2 = {}

-- Fungsi pendukung
function Log(x)
    LogToConsole("`0[`9Rotasi`0] " .. x)
end

function Join(w)
    SendPacket(3, "action|join_request\nname|" .. w .. "|\ninvitedWorld|0")
end

function Raw(t, s, v, x, y)
    SendPacketRaw(false, {
        type = t,
        state = s,
        value = v,
        px = x,
        py = y,
        x = x * 32,
        y = y * 32,
    })
end

function path(a, b, c, d, e)
    SendPacketRaw(false, {
        type = a,
        state = b,
        value = c,
        px = d,
        py = e,
        x = (Settings.UseMneck and d * 32 - 2 or d * 32),
        y = (Settings.UseMneck and e * 32 - 2 or e * 32),
    })
end

function inv(id)
    local count = 0
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            count = count + item.amount
        end
    end
    return count
end

function BuyDL(x, y)
    if inv(1796) >= 100 then
        SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. x .. "|\ny|" .. y .. "|\nbuttonClicked|bglconvert")
        Sleep(50)
    end
    SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. x .. "|\ny|" .. y .. "|\nbuttonClicked|dlconvert")
    Sleep(30)
end

ConsumeTime = os.time() - 60 * 30
function Consume()
    if os.time() - ConsumeTime >= 60 * 30 then
        ConsumeTime = os.time()
        LogToConsole("`wConsuming `9Arroz `wand `2Clover")
        Sleep(250)
        for _, Eat in pairs(Settings.ConsumableID) do
            if inv(Eat) > 0 then
                Raw(3, 0, Eat, posx, posy)
                Sleep(250)
            end
        end
        Sleep(2000)
    end
end

function GetHarvest()
    local Harvest = 0
    for y = Settings.PTHT.StartingPos[2], 0, -1 do
        for x = Settings.PTHT.StartingPos[1], 199, 1 do
            local tile = GetTile(x, y)
            if tile and tile.fg == Settings.PTHT.SeedID and tile.extra and tile.extra.progress == 1 then
                Harvest = Harvest + 1
            end
        end
    end
    return Harvest
end

function GetMagplantPnb()
    local Found = {}
    for x = 0, 199 do
        for y = 0, 199 do
            local tile = GetTile(x, y)
            if tile and tile.fg == 5638 and tile.bg == Settings.PNB.MagBG then
                table.insert(Found, {x, y})
            end
        end
    end
    return Found
end

function GetMagplantPtht()
    local Found = {}
    for x = 0, 199 do
        for y = 0, 199 do
            local tile = GetTile(x, y)
            if tile and tile.fg == 5638 and tile.bg == Settings.PTHT.MagBG then
                table.insert(Found, {x, y})
            end
        end
    end
    return Found
end

function TakeMagplant()
    Mag1 = GetMagplantPnb()
    Mag2 = GetMagplantPtht()
    if Settings.Mode == "PNB" and #Mag1 > 0 then
        if C1 > #Mag1 then C1 = 1 end
        Raw(0, 32, 0, Mag1[C1][1], Mag1[C1][2])
        Sleep(500)
        Raw(3, 0, 32, Mag1[C1][1], Mag1[C1][2])
        Sleep(500)
        SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. Mag1[C1][1] .. "|\ny|" .. Mag1[C1][2] .. "|\nbuttonClicked|getRemote")
        Sleep(500)
        getremote = false
    elseif Settings.Mode == "PTHT" and #Mag2 > 0 then
        if C2 > #Mag2 then C2 = 1 end
        Raw(0, 0, 0, Mag2[C2][1], Mag2[C2][2])
        Sleep(300)
        Raw(3, 0, 32, Mag2[C2][1], Mag2[C2][2])
        Sleep(300)
        SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. Mag2[C2][1] .. "|\ny|" .. Mag2[C2][2] .. "|\nbuttonClicked|getRemote")
        Sleep(500)
        getremote = false
        lnm = true
    end
end

function GetTree()
    local Tree = 0
    for y = Settings.PTHT.StartingPos[2], 0, -1 do
        for x = Settings.PTHT.StartingPos[1], 199, 1 do
            local tile = GetTile(x, y)
            if tile and tile.fg == Settings.PTHT.SeedID then
                Tree = Tree + 1
            end
        end
    end
    return Tree
end

plant = true
harvest = false

function chgmode()
    if plant then
        plant = false
        if GetTree() >= Settings.PTHT.MaxTree and not Settings.PTHT.SecondAcc then
            harvest = true
            SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
            Sleep(Settings.PTHT.DelayAfterUWS)
            Log("Harvesting....")
        elseif GetTree() >= Settings.PTHT.MaxTree and Settings.PTHT.SecondAcc then
            Sleep(Settings.PTHT.DelayAfterPT * 2)
            plant = true
            Log("Planting....")
        elseif GetTree() < Settings.PTHT.MaxTree then
            plant = true
            Log("Re-Planting....")
        end
        Sleep(2000)
    elseif harvest then
        harvest = false
        if GetHarvest() < 500 and not Settings.PTHT.SecondAcc then
            Log("Planting...")
            plant = true
        elseif GetHarvest() > 0 and not Settings.PTHT.SecondAcc then
            harvest = true
            Log("Re-Harvesting....")
        end
        Sleep(2000)
    end
end

function Ptht()
    for x = (Settings.PTHT.SecondAcc and 199 or Settings.PTHT.StartingPos[1]), (Settings.PTHT.SecondAcc and Settings.PTHT.StartingPos[1] or 199), (Settings.PTHT.SecondAcc and -10 or 10) do
        if stopRequested then return end
        Log("`2" .. (plant and "Planting on X: " .. x or "Harvesting"))
        for i = 1, 2 do
            if stopRequested then return end
            for y = Settings.PTHT.StartingPos[2], 0, -2 do
                if stopRequested then return end
                local tile = GetTile(x, y)
                if (plant and tile and tile.fg == 0 and GetTile(x, y + 1).fg ~= 0) or
                   (harvest and tile and tile.fg == Settings.PTHT.SeedID and tile.extra and tile.extra.progress == 1) then
                    Raw(0, (Settings.PTHT.SecondAcc and 48 or 32), 0, x, y)
                    Raw(0, (Settings.PTHT.SecondAcc and 48 or 32), 0, x, y)
                    Sleep(50)
                    Raw(3, 0, (plant and 5640 or 18), x, y)
                    Sleep(plant and Settings.PTHT.DelayPT or Settings.PTHT.DelayHT)
                    local px = x + 1
                    if GetTile(px, y + 2).fg == Settings.PTHT.SeedID then
                        limit = 0
                    else
                        limit = limit + 1
                    end
                end
                if limit >= 200 then
                    C2 = (C2 >= #Mag2 and 1 or C2 + 1)
                    limit = 0
                    chgremote = true
                    return
                end
            end
        end
    end
    if not stopRequested then
        chgmode()
        if plant and t < Settings.PTHT.TotalPTHT then
            t = t + 1
            if Settings.Webhook ~= "" then
                local payload = string.format([[
                {
                    "embeds": [{
                        "title": "PTHT Rotasi",
                        "color": 65362,
                        "fields": [
                            {"name": "Account", "value": "%s", "inline": true},
                            {"name": "World", "value": "%s", "inline": true},
                            {"name": "Status", "value": "%d/%d", "inline": true},
                            {"name": "UWS", "value": "%d", "inline": true}
                        ]
                    }]
                }
                ]], GrowID, World, t, Settings.PTHT.TotalPTHT, inv(12600))
                MakeRequest(Settings.Webhook, "POST", {["Content-Type"]="application/json"}, payload)
            end
            Log("Done")
        end
    end
end

function Pnb()
    if stopRequested then return end
    if not cheat then
        path(0, (Facing == "right" and 32 or 48), 0, posx, posy)
        Sleep(400)
        SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|1\ncheck_bfg|1\ncheck_lonely|" .. (Settings.PNB.AntiLag and 1 or 1) .. "\ncheck_gems|" .. (Settings.PNB.AutoCollectGems and 1 or 0))
        Sleep(400)
        cheat = true
    end
    if Settings.PNB.AutoBuyDL and GetPlayerInfo().gems >= Gems + 110000 then
        BuyDL(posx, posy)
        Sleep(400)
        Gems = GetPlayerInfo().gems
    end
    if Settings.PNB.AutoConsume then
        Consume()
    end
    local targetTile = GetTile(posx + (Facing == "right" and 1 or -1), posy + (Settings.UseMneck and 1 or 0))
    if targetTile and targetTile.fg == Settings.PNB.BreakID then
        limit = 0
    else
        limit = limit + 1
    end
    if limit >= 30 then
        chgremote = true
        limit = 0
        return
    end
end

function chgstatus()
    if Settings.Mode == "PNB" and ck == 2 then
        Settings.Mode = "PTHT"
        getremote = true
        chgremote = false
        ck = 0
        Log("Changing status to " .. Settings.Mode)
    elseif Settings.Mode == "PTHT" and t >= Settings.PTHT.TotalPTHT then
        Settings.Mode = "PNB"
        getremote = true
        chgremote = false
        u1sed = 0
        Log("Changing status to " .. Settings.Mode)
    end
end

-- Fungsi utama yang dijalankan di thread
local function runRotation()
    while running and not stopRequested do
        Sleep(2000)

        if GetWorld() == nil or GetWorld().name ~= World then
            Join(World)
            Sleep(5000)
            getremote = true
            cheat = false
            chgremote = false
        end

        Sleep(2000)

        if getremote and GetWorld() and GetWorld().name == World then
            SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|0\ncheck_bfg|0\ncheck_lonely|0\ncheck_ignoreo|0/ncheck_ignoref|0\ncheck_gems|" .. (Settings.PNB.AutoCollectGems and 1 or 0))
            Sleep(400)
            cheat = false
            TakeMagplant()
            Sleep(400)
        end

        Sleep(2000)

        if chgremote and GetWorld() and GetWorld().name == World then
            if Settings.Mode == "PNB" then
                C1 = C1 + 1
            elseif Settings.Mode == "PTHT" then
                C2 = C2 + 1
            end
            SendPacket(2, "action|dialog_return\ndialog_name|cheats\ncheck_autofarm|0\ncheck_bfg|0\ncheck_lonely|0\ncheck_ignoreo|0/ncheck_ignoref|0\ncheck_gems|" .. (Settings.PNB.AutoCollectGems and 1 or 0))
            Sleep(400)
            TakeMagplant()
            Sleep(400)
            cheat = false
            chgremote = false
        end

        Sleep(2000)

        if Settings.Mode == "PTHT" and GetWorld() and GetWorld().name == World then
            if Settings.UseMneck then
                Raw(10, 0, 15748, 0, 0)
                Sleep(300)
                Raw(10, 0, 15748, 0, 0)
                Sleep(300)
                Raw(10, 0, 15730, 0, 0)
                Sleep(300)
                Raw(10, 0, 15730, 0, 0)
                Sleep(300)
            end
            Ptht()
            Sleep(300)
            if t >= Settings.PTHT.TotalPTHT and GetWorld() and GetWorld().name == World then
                chgstatus()
            end
        end

        if Settings.Mode == "PNB" and GetWorld() and GetWorld().name == World then
            if ck == 2 then
                chgstatus()
            end
            if not s then
                posx = GetLocal().pos.x // 32
                posy = GetLocal().pos.y // 32
                Facing = GetLocal().isleft and "left" or "right"
                s = true
            end
            Pnb()
            Sleep(1500)
        end
    end
    running = false
    currentStatus = "Stopped"
    Log("Rotation stopped")
end

local function startRotation()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runRotation)
    Log("Rotation started")
end

local function stopRotation()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "RotasiGUI", function(dt)
    if ImGui.Begin("Rotasi PNB/PTHT - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("RotasiTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()

                -- Mode
                local changedMode, newMode = ImGui.InputText("Mode (PNB/PTHT)", Settings.Mode, 10)
                if changedMode then Settings.Mode = newMode end

                ImGui.Text("PNB Settings:")
                local changedPNBMag, newPNBMag = ImGui.InputInt("PNB Magplant BG", Settings.PNB.MagBG, 1, 100)
                if changedPNBMag then Settings.PNB.MagBG = newPNBMag end
                local changedBreak, newBreak = ImGui.InputInt("PNB Break ID", Settings.PNB.BreakID, 1, 100)
                if changedBreak then Settings.PNB.BreakID = newBreak end
                local changedAnti, newAnti = ImGui.Checkbox("PNB Anti Lag", Settings.PNB.AntiLag)
                if changedAnti then Settings.PNB.AntiLag = newAnti end
                local changedRemove, newRemove = ImGui.Checkbox("Remove Animation", Settings.PNB.RemoveAnimation)
                if changedRemove then Settings.PNB.RemoveAnimation = newRemove end
                local changedAutoConsume, newAutoConsume = ImGui.Checkbox("Auto Consume", Settings.PNB.AutoConsume)
                if changedAutoConsume then Settings.PNB.AutoConsume = newAutoConsume end
                local changedCollect, newCollect = ImGui.Checkbox("Auto Collect Gems", Settings.PNB.AutoCollectGems)
                if changedCollect then Settings.PNB.AutoCollectGems = newCollect end
                local changedBuy, newBuy = ImGui.Checkbox("Auto Buy DL", Settings.PNB.AutoBuyDL)
                if changedBuy then Settings.PNB.AutoBuyDL = newBuy end

                ImGui.Text("PTHT Settings:")
                local changedPTHTMag, newPTHTMag = ImGui.InputInt("PTHT Magplant BG", Settings.PTHT.MagBG, 1, 100)
                if changedPTHTMag then Settings.PTHT.MagBG = newPTHTMag end
                local changedSeed, newSeed = ImGui.InputInt("Seed ID", Settings.PTHT.SeedID, 1, 100)
                if changedSeed then Settings.PTHT.SeedID = newSeed end
                local changedTotal, newTotal = ImGui.InputInt("Total PTHT", Settings.PTHT.TotalPTHT, 1, 10)
                if changedTotal then Settings.PTHT.TotalPTHT = newTotal end
                local changedMax, newMax = ImGui.InputInt("Max Tree", Settings.PTHT.MaxTree, 100, 1000)
                if changedMax then Settings.PTHT.MaxTree = newMax end
                local changedSecond, newSecond = ImGui.Checkbox("Second Account", Settings.PTHT.SecondAcc)
                if changedSecond then Settings.PTHT.SecondAcc = newSecond end
                local changedDelayPT, newDelayPT = ImGui.InputInt("Delay Plant", Settings.PTHT.DelayPT, 1, 10)
                if changedDelayPT then Settings.PTHT.DelayPT = newDelayPT end
                local changedDelayHT, newDelayHT = ImGui.InputInt("Delay Harvest", Settings.PTHT.DelayHT, 1, 10)
                if changedDelayHT then Settings.PTHT.DelayHT = newDelayHT end
                local changedDelayUWS, newDelayUWS = ImGui.InputInt("Delay After UWS", Settings.PTHT.DelayAfterUWS, 100, 1000)
                if changedDelayUWS then Settings.PTHT.DelayAfterUWS = newDelayUWS end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Rotation", 150, 30) then
                        startRotation()
                    end
                else
                    if ImGui.Button("Stop Rotation", 150, 30) then
                        stopRotation()
                    end
                end

                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Current Mode: " .. Settings.Mode)
                ImGui.Text("PTHT Progress: " .. t .. "/" .. Settings.PTHT.TotalPTHT)
                ImGui.Text("Trees: " .. GetTree())
                ImGui.Text("Harvest Ready: " .. GetHarvest())
                ImGui.Text("UWS: " .. inv(12600))
                ImGui.Text("PNB Limit: " .. limit)
                ImGui.Text("C1: " .. C1 .. " | C2: " .. C2)
                ImGui.EndTabItem()
            end

            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Lantas")
                ImGui.Text("Modified by Ertoxz")
                ImGui.Text("GUI by Ertoxz")
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

AddHook("onprocesstankupdatepacket", "L", function(pkt)
    if Settings.PNB.RemoveAnimation and Settings.Mode == "PNB" then
        if pkt.type == 3 or pkt.type == 8 or pkt.type == 17 then
            return true
        end
    end
end)

Log("Rotasi script loaded. Use GUI to start.")
