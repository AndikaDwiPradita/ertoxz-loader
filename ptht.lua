-- ==================== PTHT SCRIPT (Dengan GUI) ====================
Settings = {
    whUse = true,
    Webhook = "Webook",
    StartingPos = {0, 192}, -- (x, y)
    MagBG = 284, -- Magplant Background
    SeedID = 15461,
    TotalPTHT = 20,
    MaxTree = 17000,
    SecondAcc = false,
    DelayPT = 25,
    DelayHT = 200,
    DelayAfterPT = 8000,
    DelayAfterUWS = 2500,
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Variabel internal
t = 0
plant = true
harvest = false
World = GetWorld().name
C = 1
Mag = {}
limit = 0

function Hah4(str)
    str = str:gsub("``", "")
    str = str:gsub("`.", "")
    str = str:gsub("@", ""):gsub(" of Legend", ""):gsub("%[BOOST%]", "")
    str = str:gsub("%[ELITE%]", ""):gsub(" ", "")
    return str
end

GrowID = Hah4(GetLocal().name)

function Log(x)
    LogToConsole("`0[`9PTHT`0] " .. x)
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

function inv(id)
    local count = 0
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            count = count + item.amount
        end
    end
    return count
end

function SendWebhook(url, data)
    MakeRequest(url, "POST", { ["Content-Type"] = "application/json" }, data)
end

function GetTree()
    local Tree = 0
    for y = Settings.StartingPos[2], 0, -1 do
        for x = Settings.StartingPos[1], 199, 1 do
            if GetTile(x, y).fg == Settings.SeedID then
                Tree = Tree + 1
            end
        end
    end
    return Tree
end

function GetHarvest()
    local Harvest = 0
    for y = Settings.StartingPos[2], 0, -1 do
        for x = Settings.StartingPos[1], 199, 1 do
            local tile = GetTile(x, y)
            if tile.fg == Settings.SeedID and tile.extra and tile.extra.progress == 1 then
                Harvest = Harvest + 1
            end
        end
    end
    return Harvest
end

function GetMagplant()
    local Found = {}
    for x = 0, 199 do
        for y = 0, 199 do
            local tile = GetTile(x, y)
            if tile and tile.fg == 5638 and tile.bg == Settings.MagBG then
                table.insert(Found, {x, y})
            end
        end
    end
    return Found
end

function TakeMagplant()
    Mag = GetMagplant()
    if #Mag == 0 then
        Log("Magplant tidak ditemukan!")
        return
    end
    Raw(0, 0, 0, Mag[C][1], Mag[C][2])
    Sleep(300)
    Raw(3, 0, 32, Mag[C][1], Mag[C][2])
    Sleep(300)
    SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. Mag[C][1] .. "|\ny|" .. Mag[C][2] .. "|\nbuttonClicked|getRemote")
    Sleep(500)
end

function chgmode()
    if plant then
        plant = false
        if GetTree() >= Settings.MaxTree and not Settings.SecondAcc then
            harvest = true
            SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
            Sleep(Settings.DelayAfterUWS)
            Log("Harvesting....")
            harvest = true
        elseif GetTree() >= Settings.MaxTree and Settings.SecondAcc then
            Sleep(Settings.DelayAfterPT * 2)
            plant = true
            Log("Planting....")
        elseif GetTree() < Settings.MaxTree then
            plant = true
            Log("Re-Planting....")
        end
        Sleep(2000)
    elseif harvest then
        harvest = false
        if GetHarvest() < 500 and not Settings.SecondAcc then
            Log("Planting...")
            plant = true
        elseif GetHarvest() > 0 and not Settings.SecondAcc then
            harvest = true
            Log("Re-Harvesting....")
        end
        Sleep(2000)
    end
end

function Ptht()
    for x = (Settings.SecondAcc and 199 or Settings.StartingPos[1]), (Settings.SecondAcc and Settings.StartingPos[1] or 199), (Settings.SecondAcc and -10 or 10) do
        if stopRequested then return end
        Log("`2" .. (plant and "Planting on X: " .. x or "Harvesting"))
        for i = 1, 2 do
            if stopRequested then return end
            for y = Settings.StartingPos[2], 0, -2 do
                if stopRequested then return end
                local tile = GetTile(x, y)
                if (plant and tile.fg == 0 and GetTile(x, y + 1).fg ~= 0) or (harvest and tile.fg == Settings.SeedID and tile.extra and tile.extra.progress == 1) then
                    Raw(0, (Settings.SecondAcc and 48 or 32), 0, x, y)
                    Raw(0, (Settings.SecondAcc and 48 or 32), 0, x, y)
                    Sleep(50)
                    Raw(3, 0, (plant and 5640 or 18), x, y)
                    Sleep(plant and Settings.DelayPT or Settings.DelayHT)
                    local px = x + 1
                    if GetTile(px, y + 2).fg == Settings.SeedID then
                        limit = 0
                    else
                        limit = limit + 1
                    end
                end
                if limit >= 200 then
                    C = (C < #Mag and C + 1 or 1)
                    limit = 0
                    return
                end
            end
        end
    end
    chgmode()
    if plant and t < Settings.TotalPTHT then
        t = t + 1
        if Settings.whUse then
            local payload = string.format([[
            {
                "embeds": [{
                    "title": "PTHT 2.0 BY LANTAS CONTINENTAL",
                    "color": 65362,
                    "fields": [
                        { "name": "📜 Account", "value": "%s", "inline": false },
                        { "name": "🌍 World", "value": "%s", "inline": true },
                        { "name": "🔮 Magplant", "value": "%d of %d Done", "inline": true },
                        { "name": "🌾 Status", "value": "%d / %d", "inline": true },
                        { "name": "🔐 UWS", "value": "%d PCs", "inline": true }
                    ],
                    "footer": { "text": "Updated: %s" }
                }]
            }
            ]], GrowID, World, C, #Mag, t, Settings.TotalPTHT, inv(12600), os.date("%Y-%m-%d %H:%M:%S"))
            SendWebhook(Settings.Webhook, payload)
        end
        Log("Done")
    end
end

-- Fungsi utama yang dijalankan di thread
local function runPTHT()
    while running and not stopRequested do
        if GetWorld() == nil or GetWorld().name ~= World then
            Join(World)
            Sleep(5000)
        else
            TakeMagplant()
            Ptht()
        end
        Sleep(2000)
    end
    running = false
    currentStatus = "Stopped"
    Log("PTHT stopped")
end

local function startPTHT()
    if running then return end
    t = 0
    plant = true
    harvest = false
    C = 1
    limit = 0
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runPTHT)
    Log("PTHT started")
end

local function stopPTHT()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "PTHTGUI", function(dt)
    if ImGui.Begin("AUTO PTHT - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PTHTTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                
                local changedX, newX = ImGui.InputInt("Start X", Settings.StartingPos[1], 1, 10)
                if changedX then Settings.StartingPos[1] = newX end
                local changedY, newY = ImGui.InputInt("Start Y", Settings.StartingPos[2], 1, 10)
                if changedY then Settings.StartingPos[2] = newY end
                
                local changedSeed, newSeed = ImGui.InputInt("Seed ID", Settings.SeedID, 1, 100)
                if changedSeed then Settings.SeedID = newSeed end
                
                local changedMagBG, newMagBG = ImGui.InputInt("Magplant BG", Settings.MagBG, 1, 100)
                if changedMagBG then Settings.MagBG = newMagBG end
                
                local changedTotal, newTotal = ImGui.InputInt("Total PTHT", Settings.TotalPTHT, 1, 10)
                if changedTotal then Settings.TotalPTHT = newTotal end
                
                local changedMax, newMax = ImGui.InputInt("Max Tree", Settings.MaxTree, 100, 1000)
                if changedMax then Settings.MaxTree = newMax end
                
                local changedSecond, newSecond = ImGui.Checkbox("Second Account", Settings.SecondAcc)
                if changedSecond then Settings.SecondAcc = newSecond end
                
                ImGui.Separator()
                ImGui.Text("Delays (ms):")
                local changedDPT, newDPT = ImGui.InputInt("Delay Plant", Settings.DelayPT, 1, 10)
                if changedDPT then Settings.DelayPT = newDPT end
                local changedDHT, newDHT = ImGui.InputInt("Delay Harvest", Settings.DelayHT, 1, 10)
                if changedDHT then Settings.DelayHT = newDHT end
                local changedDAP, newDAP = ImGui.InputInt("Delay After PT", Settings.DelayAfterPT, 100, 1000)
                if changedDAP then Settings.DelayAfterPT = newDAP end
                local changedDAU, newDAU = ImGui.InputInt("Delay After UWS", Settings.DelayAfterUWS, 100, 1000)
                if changedDAU then Settings.DelayAfterUWS = newDAU end
                
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start PTHT", 150, 30) then
                        startPTHT()
                    end
                else
                    if ImGui.Button("Stop PTHT", 150, 30) then
                        stopPTHT()
                    end
                end
                
                ImGui.EndTabItem()
            end
            
            -- SETTINGS TAB (webhook)
            if ImGui.BeginTabItem("Settings") then
                local changedWH, newWH = ImGui.Checkbox("Use Webhook", Settings.whUse)
                if changedWH then Settings.whUse = newWH end
                
                local changedWeb, newWeb = ImGui.InputText("Webhook URL", Settings.Webhook, 200)
                if changedWeb then Settings.Webhook = newWeb end
                
                ImGui.EndTabItem()
            end
            
            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Trees: " .. GetTree())
                ImGui.Text("Harvest Ready: " .. GetHarvest())
                ImGui.Text("UWS: " .. inv(12600))
                ImGui.Text("Current Magplant Index: " .. C)
                ImGui.Text("Loop Count: " .. t .. "/" .. Settings.TotalPTHT)
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("PTHT 2.0 by Lantas Continental")
                ImGui.Text("Modified by Ertoxz")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("PTHT script loaded. Use GUI to start.")
