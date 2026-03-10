-- ==================== SPTHT LOADER (POLA ZIGZAG) ====================

-- === KONFIGURASI ===
Settings = {
  lineY = 192,
  amtseed = 2000,
  FirstSeed = 117,
  delayPlant = 150,
  UseUws = false,
  delayHarvest = 250,
  MagBG = 284,           -- Background ID magplant
  World = "island"
}

-- === VARIABEL GLOBAL ===
y1 = 0
y2 = Settings.lineY
Mag = {}                 -- Menyimpan semua magplant yang ditemukan
C = 1                    -- Index magplant yang sedang digunakan
limit = 0
chgremote = false
World = ""

-- === VARIABEL KONTROL ===
local running = false
local stopRequested = false
local currentStatus = "Idle"
local thread = nil

-- === FUNGSI-FUNGSI ===
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

-- Mendapatkan semua magplant dengan background tertentu
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

-- Mengambil remote magplant
function TakeMagplant()
  Mag = GetMagplant()
  if #Mag == 0 then
    LogToConsole("Tidak ada magplant ditemukan!")
    return false
  end
  
  if C > #Mag then C = 1 end
  local m = Mag[C]
  
  Raw(0, 0, 0, m[1], m[2])
  Sleep(300)
  Raw(3, 0, 32, m[1], m[2])
  Sleep(300)
  SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. m[1] .. "|\ny|" .. m[2] .. "|\nbuttonClicked|getRemote")
  Sleep(500)
  return true
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

-- Menanam di satu tile (teleport dulu baru place seed)
function plantAt(x, y, isSplice)
  if stopRequested then return false end
  local tile = GetTile(x, y)
  if tile and (tile.fg == 0 or (isSplice and tile.fg == Settings.FirstSeed)) then
    LogToConsole("Planting at ("..x..","..y..")")
    FindPath(x, y, 520)  -- Teleport ke tile
    Sleep(100)
    Raw(0, 32, 0, x, y)
    Raw(0, 32, 0, x, y)
    Sleep(100)
    Raw(3, 0, 5640, x, y)  -- Place seed
    Sleep(Settings.delayPlant)
    return true
  end
  return false
end

-- Fungsi menanam dengan pola zigzag
function plantZigzag()
  local maxX = (Settings.World == "normal" and 99 or 199)
  local direction = 1  -- 1 = kiri ke kanan, -1 = kanan ke kiri
  local startX, endX, step
  
  for y = y2, y1, -1 do  -- Dari atas ke bawah
    if stopRequested then return end
    
    -- Tentukan arah berdasarkan baris
    if direction == 1 then
      startX = 0
      endX = maxX
      step = 1
    else
      startX = maxX
      endX = 0
      step = -1
    end
    
    -- Loop setiap tile di baris ini
    for x = startX, endX, step do
      if stopRequested then return end
      
      -- Cek apakah perlu ganti remote
      if chgremote then
        C = (C % #Mag) + 1
        TakeMagplant()
        chgremote = false
        limit = 0
      end
      
      -- Tanam seed biasa
      plantAt(x, y, false)
      
      -- Tanam seed splice (seed kedua)
      plantAt(x, y, true)
      
      -- Update limit
      limit = limit + 1
      if limit >= 30 then
        chgremote = true
      end
    end
    
    -- Balik arah untuk baris berikutnya
    direction = direction * -1
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
          FindPath(x, y, 520)  -- Teleport ke tile untuk harvest
          Sleep(100)
          Raw(0, 32, 0, x, y)
          Sleep(Settings.delayHarvest)
          Raw(3, 0, 18, x, y)  -- Punch dengan fist
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
    World = GetWorld().name
    C = 1
    limit = 0
    chgremote = false
    
    -- Ambil remote pertama
    if not TakeMagplant() then
        LogToConsole("Gagal mengambil remote, script dihentikan")
        running = false
        return
    end
    
    while running and not stopRequested do
        harvest()
        if stopRequested then break end
        Sleep(1500)
        
        if stopRequested then break end
        -- Tanam dengan pola zigzag
        plantZigzag()
        
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
        file:write("MagBG=" .. Settings.MagBG .. "\n")
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
                elseif key == "MagBG" then Settings.MagBG = tonumber(value)
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

                local changedMagBG, newMagBG = ImGui.InputInt("Magplant Background", Settings.MagBG, 1, 100)
                if changedMagBG then Settings.MagBG = newMagBG end

                local changedWorld, newWorld = ImGui.InputText("World Type (normal/island)", Settings.World, 30)
                if changedWorld then Settings.World = newWorld end

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
                ImGui.Text("Magplants Found: " .. #Mag)
                ImGui.Text("Current Magplant: " .. C)
                ImGui.Text("Limit: " .. limit)
                ImGui.EndTabItem()
            end

            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("SPTHT Script by Lantas")
                ImGui.Text("Modified by Ertoxz")
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