-- ==================== SPECIAL PTHT - DENGAN GUI ====================

Settings = {
  lineY = 192,
  amtseed = 2000,
  FirstSeed = 117,
  delayPlant = 150,
  UseUws = false,
  delayHarvest = 250,
  FirstMagplant = {3, 191},
  TwoMagplant = {2, 191},
  World = "island"
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi pendukung
function Log(x)
    LogToConsole("`0[`9SPTHT`0] " .. x)
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

function IsReady(tile)
    return tile and tile.extra and tile.extra.progress == 1.0
end

function magplant(x, y, button)
    Raw(0, 0, 0, x, y)
    Sleep(300)
    Raw(3, 0, 32, x, y + 1)
    Sleep(300)
    SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. x .. "|\ny|" .. y + 1 .. "|\nbuttonClicked|getRemote")
    Sleep(300)
end

function TakeMagplant(pos, btn)
    Raw(0, 0, 0, pos[1], pos[2])
    Sleep(100)
    magplant(pos[1], pos[2], btn)
    Sleep(1000)
end

function checkseed()
    local count = 0
    for y = 0, Settings.lineY do
        for x = 0, 199 do
            local tile = GetTile(x, y)
            if IsReady(tile) then
                count = count + 1
            end
        end
    end
    return count
end

function plantLine(x, splice)
    for y = Settings.lineY, 0, -1 do
        local tile = GetTile(x, y)
        if tile and (tile.fg == 0 or (splice and tile.fg == Settings.FirstSeed)) then
            LogToConsole("Planting On X: " .. x)
            Raw(0, 32, 0, x, y)
            Raw(0, 32, 0, x, y)
            Sleep(100)
            Raw(3, 0, 5640, x, y)
            Sleep(Settings.delayPlant)
        end
    end
end

function doPlanting(startX, endX)
    for x = startX, endX, 10 do
        if stopRequested then return end
        TakeMagplant(Settings.FirstMagplant, "getRemote")
        TakeMagplant(Settings.FirstMagplant, "getRemote")
        plantLine(x, false)
        plantLine(x, false)
        Sleep(200)

        TakeMagplant(Settings.TwoMagplant, "getRemote")
        TakeMagplant(Settings.TwoMagplant, "getRemote")
        plantLine(x, true)
        plantLine(x, true)
        Sleep(200)
    end
end

function UseUws()
    if Settings.UseUws then
        SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
        Sleep(5000)
    end
end

function harvest()
    if checkseed() > Settings.amtseed then
        local maxX = (Settings.World == "normal" and 99 or 199)
        for y = Settings.lineY, 0, -1 do
            for x = 0, maxX do
                if stopRequested then return end
                local tile = GetTile(x, y)
                if IsReady(tile) then
                    Raw(0, 32, 0, x, y)
                    Sleep(Settings.delayHarvest)
                    Raw(3, 0, 18, x, y)
                    Sleep(Settings.delayHarvest)
                end
            end
        end
    end
end

-- Fungsi utama
local function runSPTHT()
    while running and not stopRequested do
        harvest()
        Sleep(1500)
        if stopRequested then break end
        if Settings.World == "normal" then
            doPlanting(0, 100)
        elseif Settings.World == "island" then
            doPlanting(0, 190)
        end
        Sleep(1000)
        if stopRequested then break end
        UseUws()
        Sleep(5000)
    end
    running = false
    currentStatus = "Stopped"
    Log("SPTHT stopped")
end

local function startSPTHT()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runSPTHT)
    Log("SPTHT started")
end

local function stopSPTHT()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "SPTHTGUI", function(dt)
    if ImGui.Begin("Special PTHT - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("SPTHTTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()

                local changedLineY, newLineY = ImGui.InputInt("Line Y", Settings.lineY, 1, 10)
                if changedLineY then Settings.lineY = newLineY end

                local changedAmt, newAmt = ImGui.InputInt("Seed Amount", Settings.amtseed, 100, 1000)
                if changedAmt then Settings.amtseed = newAmt end

                local changedFirstSeed, newFirstSeed = ImGui.InputInt("First Seed ID", Settings.FirstSeed, 1, 100)
                if changedFirstSeed then Settings.FirstSeed = newFirstSeed end

                local changedDelayPlant, newDelayPlant = ImGui.InputInt("Delay Plant", Settings.delayPlant, 1, 10)
                if changedDelayPlant then Settings.delayPlant = newDelayPlant end

                local changedDelayHarvest, newDelayHarvest = ImGui.InputInt("Delay Harvest", Settings.delayHarvest, 1, 10)
                if changedDelayHarvest then Settings.delayHarvest = newDelayHarvest end

                local changedUseUws, newUseUws = ImGui.Checkbox("Use UWS", Settings.UseUws)
                if changedUseUws then Settings.UseUws = newUseUws end

                local changedWorld, newWorld = ImGui.InputText("World Type", Settings.World, 30)
                if changedWorld then Settings.World = newWorld end

                ImGui.Text("Magplant Positions:")
                local changedFMX, newFMX = ImGui.InputInt("First Mag X", Settings.FirstMagplant[1], 1, 10)
                if changedFMX then Settings.FirstMagplant[1] = newFMX end
                local changedFMY, newFMY = ImGui.InputInt("First Mag Y", Settings.FirstMagplant[2], 1, 10)
                if changedFMY then Settings.FirstMagplant[2] = newFMY end
                local changedTMX, newTMX = ImGui.InputInt("Second Mag X", Settings.TwoMagplant[1], 1, 10)
                if changedTMX then Settings.TwoMagplant[1] = newTMX end
                local changedTMY, newTMY = ImGui.InputInt("Second Mag Y", Settings.TwoMagplant[2], 1, 10)
                if changedTMY then Settings.TwoMagplant[2] = newTMY end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start SPTHT", 150, 30) then
                        startSPTHT()
                    end
                else
                    if ImGui.Button("Stop SPTHT", 150, 30) then
                        stopSPTHT()
                    end
                end

                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Ready Seeds: " .. checkseed())
                ImGui.EndTabItem()
            end

            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Lantas")
                ImGui.Text("Modified by Ertoxz")
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("SPTHT script loaded. Use GUI to start.")
