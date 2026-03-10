-- ==================== SPTHT LOADER (TANPA UBAH SCRIPT ASLI) ====================

-- === KONFIGURASI (SAMA PERSIS DENGAN SCRIPT ASLI) ===
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

-- === VARIABEL GLOBAL YANG DIPERLUKAN SCRIPT ASLI ===
y1 = 0
y2 = Settings.lineY

-- === VARIABEL KONTROL ===
local running = false
local stopRequested = false
local currentStatus = "Idle"
local thread = nil

-- === FUNGSI ASLI (DISALIN PERSIS) ===
function IsReady(tile)
  return tile and tile.extra and tile.extra.progress == 1.0
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

function magplant(x, y, button)
  Raw(0, 0, 0, x, y)
  Sleep(300)
  Raw(3, 0, 32, x, y + 1)
  Sleep(300)
  SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. x .. "|\ny|".. y + 1 .. "|\nbuttonClicked|getRemote")
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
  for y = y1, y2 do
    for x = 0, 199 do
      local tile = GetTile(x, y)
      if tile and IsReady(tile) then
        count = count + 1
      end
    end
  end
  return count
end

function plantLine(x, splice)
  for y = y2, y1, -1 do
    local tile = GetTile(x, y)
    if tile and (tile.fg == 0 or (splice and tile.fg == Settings.FirstSeed)) then
      LogToConsole("Planting On X: "..x)
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
    for y = y2, y1, -1 do
      for x = 0, maxX do
        if stopRequested then return end
        local tile = GetTile(x, y)
        if tile and IsReady(tile) then
          Raw(0, 32, 0, x, y)
          Sleep(Settings.delayHarvest)
          Raw(3, 0, 18, x, y)
          Sleep(Settings.delayHarvest)
        end
      end
    end
  end
end

-- === FUNGSI UTAMA YANG DIJALANKAN DI THREAD ===
local function runSPTHT()
    -- Reset variabel
    y1 = 0
    y2 = Settings.lineY
    
    while running and not stopRequested do
        harvest()
        if stopRequested then break end
        Sleep(1500)
        
        if stopRequested then break end
        if Settings.World == "normal" then
            doPlanting(0, 100)
        elseif Settings.World == "island" then
            doPlanting(0, 190)
        end
        
        if stopRequested then break end
        Sleep(1000)
        UseUws()
        Sleep(5000)
    end
    
    running = false
    currentStatus = "Stopped"
    LogToConsole("SPTHT stopped")
end

-- === FUNGSI START/STOP ===
local function startSPTHT()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    thread = RunThread(runSPTHT)
    LogToConsole("SPTHT started")
end

local function stopSPTHT()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- === FUNGSI SAVE/LOAD ===
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/SPTHT_SETTINGS.txt", "w")
    if file then
        file:write("lineY=" .. Settings.lineY .. "\n")
        file:write("amtseed=" .. Settings.amtseed .. "\n")
        file:write("FirstSeed=" .. Settings.FirstSeed .. "\n")
        file:write("delayPlant=" .. Settings.delayPlant .. "\n")
        file:write("UseUws=" .. tostring(Settings.UseUws) .. "\n")
        file:write("delayHarvest=" .. Settings.delayHarvest .. "\n")
        file:write("FirstMagplantX=" .. Settings.FirstMagplant[1] .. "\n")
        file:write("FirstMagplantY=" .. Settings.FirstMagplant[2] .. "\n")
        file:write("TwoMagplantX=" .. Settings.TwoMagplant[1] .. "\n")
        file:write("TwoMagplantY=" .. Settings.TwoMagplant[2] .. "\n")
        file:write("World=" .. Settings.World .. "\n")
        file:close()
        LogToConsole("`2Settings saved.")
    else
        LogToConsole("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/SPTHT_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "lineY" then Settings.lineY = tonumber(value)
                elseif key == "amtseed" then Settings.amtseed = tonumber(value)
                elseif key == "FirstSeed" then Settings.FirstSeed = tonumber(value)
                elseif key == "delayPlant" then Settings.delayPlant = tonumber(value)
                elseif key == "UseUws" then Settings.UseUws = (value == "true")
                elseif key == "delayHarvest" then Settings.delayHarvest = tonumber(value)
                elseif key == "FirstMagplantX" then Settings.FirstMagplant[1] = tonumber(value)
                elseif key == "FirstMagplantY" then Settings.FirstMagplant[2] = tonumber(value)
                elseif key == "TwoMagplantX" then Settings.TwoMagplant[1] = tonumber(value)
                elseif key == "TwoMagplantY" then Settings.TwoMagplant[2] = tonumber(value)
                elseif key == "World" then Settings.World = value
                end
            end
        end
        file:close()
        LogToConsole("`2Settings loaded.")
    else
        LogToConsole("`3No settings file found.")
    end
end

-- === FUNGSI UNTUK MENDAPATKAN JUMLAH SEED SIAP PANEN ===
local function getReadyCount()
    local count = 0
    for y = y1, y2 do
        for x = 0, 199 do
            local tile = GetTile(x, y)
            if tile and IsReady(tile) then
                count = count + 1
            end
        end
    end
    return count
end

-- === GUI ===
AddHook("OnDraw", "SPTHTGUI", function(dt)
    if ImGui.Begin("SPTHT Loader - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("SPTHTTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("SPTHT Settings")
                ImGui.Separator()

                local changedLineY, newLineY = ImGui.InputInt("Line Y", Settings.lineY, 1, 10)
                if changedLineY then Settings.lineY = newLineY y2 = newLineY end

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

                local changedWorld, newWorld = ImGui.InputText("World Type (normal/island)", Settings.World, 30)
                if changedWorld then Settings.World = newWorld end

                ImGui.Text("First Magplant Position:")
                local changedFMX, newFMX = ImGui.InputInt("First Mag X", Settings.FirstMagplant[1], 1, 10)
                if changedFMX then Settings.FirstMagplant[1] = newFMX end
                local changedFMY, newFMY = ImGui.InputInt("First Mag Y", Settings.FirstMagplant[2], 1, 10)
                if changedFMY then Settings.FirstMagplant[2] = newFMY end

                ImGui.Text("Second Magplant Position:")
                local changedTMX, newTMX = ImGui.InputInt("Second Mag X", Settings.TwoMagplant[1], 1, 10)
                if changedTMX then Settings.TwoMagplant[1] = newTMX end
                local changedTMY, newTMY = ImGui.InputInt("Second Mag Y", Settings.TwoMagplant[2], 1, 10)
                if changedTMY then Settings.TwoMagplant[2] = newTMY end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start SPTHT", 120, 30) then
                        startSPTHT()
                    end
                else
                    if ImGui.Button("Stop SPTHT", 120, 30) then
                        stopSPTHT()
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
                ImGui.Text("Ready Seeds: " .. getReadyCount())
                ImGui.Text("First Mag: (" .. Settings.FirstMagplant[1] .. ", " .. Settings.FirstMagplant[2] .. ")")
                ImGui.Text("Second Mag: (" .. Settings.TwoMagplant[1] .. ", " .. Settings.TwoMagplant[2] .. ")")
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

-- Load settings saat start
LoadSettings()
LogToConsole("SPTHT Loader ready. Use GUI to start.")
