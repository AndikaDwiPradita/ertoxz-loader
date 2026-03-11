-- ==================== SPTHT BARU (SISTEM PER BARIS) ====================

Settings = {
  lineY = 192,
  amtseed = 2000,
  FirstSeed = 117,
  delayPlant = 150,
  UseUws = false,
  delayHarvest = 250,
  
  -- Koordinat magplant (seperti PTHT)
  MagX = 3,
  MagY = 191,
  Mag2X = 2,
  Mag2Y = 191,
  
  World = "island"
}

-- Variabel global
y1 = 0
y2 = Settings.lineY

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"
local thread = nil

-- Fungsi-fungsi dasar
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

-- Fungsi mengambil remote magplant (seperti PTHT)
function TakeMagplant(x, y)
  LogToConsole("Mengambil remote magplant di ("..x..","..y..")")
  Raw(0, 0, 0, x, y)
  Sleep(300)
  Raw(3, 0, 32, x, y)
  Sleep(300)
  SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. x .. "|\ny|" .. y .. "|\nbuttonClicked|getRemote")
  Sleep(500)
end

-- Fungsi menanam di tile tertentu
function plantTile(x, y, isSplice)
  if stopRequested then return false end
  local tile = GetTile(x, y)
  if tile and (tile.fg == 0 or (isSplice and tile.fg == Settings.FirstSeed)) then
    LogToConsole("Planting at ("..x..","..y..")")
    FindPath(x, y, 520)  -- Teleport ke tile
    Sleep(100)
    Raw(0, 32, 0, x, y)
    Raw(0, 32, 0, x, y)
    Sleep(50)
    Raw(3, 0, 5640, x, y)  -- Place seed
    Sleep(Settings.delayPlant)
    return true
  end
  return false
end

-- Fungsi menanam dalam satu baris X
function plantLine(x)
  if stopRequested then return end
  
  -- Ambil remote magplant pertama
  TakeMagplant(Settings.MagX, Settings.MagY)
  
  -- Tanam seed biasa (bukan splice) di semua tile di baris ini
  for y = y2, y1, -1 do
    if stopRequested then return end
    plantTile(x, y, false)
  end
  
  -- Ambil remote magplant kedua
  TakeMagplant(Settings.Mag2X, Settings.Mag2Y)
  
  -- Tanam seed splice di semua tile di baris yang SAMA
  for y = y2, y1, -1 do
    if stopRequested then return end
    plantTile(x, y, true)
  end
end

-- Fungsi utama penanaman (loop semua baris X)
function doPlanting()
  local maxX = (Settings.World == "normal" and 100 or 200) - 1
  
  for x = 0, maxX do
    if stopRequested then return end
    LogToConsole("Memproses baris X: "..x)
    plantLine(x)
    Sleep(200)  -- Jeda antar baris
  end
end

function checkseed()
  local count = 0
  for y = y1, y2 do
    for x = 0, (Settings.World == "normal" and 99 or 199) do
      local tile = GetTile(x, y)
      if tile and IsReady(tile) then
        count = count + 1
      end
    end
  end
  return count
end

function harvest()
  if checkseed() > Settings.amtseed then
    local maxX = (Settings.World == "normal" and 99 or 199)
    for y = y2, y1, -1 do
      for x = 0, maxX do
        if stopRequested then return end
        local tile = GetTile(x, y)
        if tile and IsReady(tile) then
          LogToConsole("Harvest at ("..x..","..y..")")
          FindPath(x, y, 520)
          Sleep(100)
          Raw(0, 32, 0, x, y)
          Sleep(Settings.delayHarvest)
          Raw(3, 0, 18, x, y)
          Sleep(Settings.delayHarvest)
        end
      end
    end
  end
end

function UseUws()
  if Settings.UseUws then
    SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
    Sleep(5000)
  end
end

-- Fungsi utama yang dijalankan di thread
local function runSPTHT()
  while running and not stopRequested do
    harvest()
    if stopRequested then break end
    Sleep(1500)
    
    doPlanting()
    if stopRequested then break end
    
    Sleep(1000)
    UseUws()
    Sleep(5000)
  end
  
  running = false
  currentStatus = "Stopped"
  LogToConsole("SPTHT stopped")
end

-- Fungsi start/stop
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

-- Fungsi Save/Load
local function SaveSettings()
  local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/SPTHT_SETTINGS.txt", "w")
  if file then
    file:write("lineY=" .. Settings.lineY .. "\n")
    file:write("amtseed=" .. Settings.amtseed .. "\n")
    file:write("FirstSeed=" .. Settings.FirstSeed .. "\n")
    file:write("delayPlant=" .. Settings.delayPlant .. "\n")
    file:write("UseUws=" .. tostring(Settings.UseUws) .. "\n")
    file:write("delayHarvest=" .. Settings.delayHarvest .. "\n")
    file:write("MagX=" .. Settings.MagX .. "\n")
    file:write("MagY=" .. Settings.MagY .. "\n")
    file:write("Mag2X=" .. Settings.Mag2X .. "\n")
    file:write("Mag2Y=" .. Settings.Mag2Y .. "\n")
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
        if key == "lineY" then Settings.lineY = tonumber(value) y2 = tonumber(value)
        elseif key == "amtseed" then Settings.amtseed = tonumber(value)
        elseif key == "FirstSeed" then Settings.FirstSeed = tonumber(value)
        elseif key == "delayPlant" then Settings.delayPlant = tonumber(value)
        elseif key == "UseUws" then Settings.UseUws = (value == "true")
        elseif key == "delayHarvest" then Settings.delayHarvest = tonumber(value)
        elseif key == "MagX" then Settings.MagX = tonumber(value)
        elseif key == "MagY" then Settings.MagY = tonumber(value)
        elseif key == "Mag2X" then Settings.Mag2X = tonumber(value)
        elseif key == "Mag2Y" then Settings.Mag2Y = tonumber(value)
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
        local changedMagX, newMagX = ImGui.InputInt("Mag X", Settings.MagX, 1, 10)
        if changedMagX then Settings.MagX = newMagX end
        local changedMagY, newMagY = ImGui.InputInt("Mag Y", Settings.MagY, 1, 10)
        if changedMagY then Settings.MagY = newMagY end

        ImGui.Text("Second Magplant Position:")
        local changedMag2X, newMag2X = ImGui.InputInt("Mag2 X", Settings.Mag2X, 1, 10)
        if changedMag2X then Settings.Mag2X = newMag2X end
        local changedMag2Y, newMag2Y = ImGui.InputInt("Mag2 Y", Settings.Mag2Y, 1, 10)
        if changedMag2Y then Settings.Mag2Y = newMag2Y end

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
        ImGui.Text("Ready Seeds: " .. checkseed())
        ImGui.Text("First Mag: (" .. Settings.MagX .. ", " .. Settings.MagY .. ")")
        ImGui.Text("Second Mag: (" .. Settings.Mag2X .. ", " .. Settings.Mag2Y .. ")")
        ImGui.EndTabItem()
      end
end

      ImGui.EndTabBar()
    end
    ImGui.End()
  end
end)

-- Load settings saat start
LoadSettings()
LogToConsole("SPTHT Loader ready. Use GUI to start.")