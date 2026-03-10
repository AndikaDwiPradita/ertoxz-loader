-- ==================== SPTHT LOADER (DENGAN MANAJEMEN MAGPLANT PINTAR) ====================

-- === KONFIGURASI ===
Settings = {
  lineY = 192,
  amtseed = 2000,
  FirstSeed = 117,
  delayPlant = 150,
  UseUws = false,
  delayHarvest = 250,
  MagBG = 284,           -- Background ID magplant
  World = "island",
  plantLimit = 30        -- Jumlah maksimal penanaman sebelum ganti remote
}

-- === VARIABEL GLOBAL ===
y1 = 0
y2 = Settings.lineY
Mag = {}                 -- Menyimpan semua magplant yang ditemukan
currentMagIndex = 1      -- Index magplant yang sedang digunakan
magLimits = {}           -- Menyimpan limit per magplant
currentX = 0             -- Posisi X terakhir yang ditanami
currentY = y2            -- Posisi Y terakhir yang ditanami
currentDirection = 1     -- 1 = kiri ke kanan, -1 = kanan ke kiri
maxX = 199               -- Akan disesuaikan dengan world type
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

-- Mengambil remote magplant berdasarkan index
function TakeMagplant(index)
  if #Mag == 0 then
    LogToConsole("Tidak ada magplant ditemukan!")
    return false
  end
  
  if index > #Mag then index = 1 end
  local m = Mag[index]
  
  LogToConsole("Mengambil remote magplant #" .. index .. " di (" .. m[1] .. "," .. m[2] .. ")")
  Raw(0, 0, 0, m[1], m[2])
  Sleep(300)
  Raw(3, 0, 32, m[1], m[2])
  Sleep(300)
  SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. m[1] .. "|\ny|" .. m[2] .. "|\nbuttonClicked|getRemote")
  Sleep(500)
  return true
end

-- Inisialisasi ulang posisi penanaman
function resetPlantingPosition()
  currentX = 0
  currentY = y2
  currentDirection = 1
end

-- Mendapatkan tile berikutnya berdasarkan posisi saat ini
function getNextTile()
  if currentY < y1 then
    return nil -- Semua tile sudah diproses
  end
  
  local nextX = currentX + currentDirection
  local nextY = currentY
  
  -- Cek apakah perlu pindah baris
  if (currentDirection == 1 and nextX > maxX) or (currentDirection == -1 and nextX < 0) then
    nextY = currentY - 1
    if nextY < y1 then
      return nil -- Habis
    end
    currentDirection = currentDirection * -1
    nextX = (currentDirection == 1 and 0 or maxX)
  end
  
  currentX = nextX
  currentY = nextY
  
  return {x = currentX, y = currentY}
end

-- Menanam di satu tile
function plantAt(x, y)
  if stopRequested then return false end
  local tile = GetTile(x, y)
  if tile and tile.fg == 0 then
    LogToConsole("Planting at ("..x..","..y..")")
    FindPath(x, y, 520)
    Sleep(100)
    Raw(0, 32, 0, x, y)
    Raw(0, 32, 0, x, y)
    Sleep(100)
    Raw(3, 0, 5640, x, y)
    Sleep(Settings.delayPlant)
    return true
  elseif tile and tile.fg == Settings.FirstSeed then
    -- Tile sudah ada seed, lewati
    return false
  end
  return false
end

-- Fungsi utama penanaman dengan manajemen magplant
function plantWithMagplantManagement()
  -- Reset posisi jika memulai dari awal
  if currentX == 0 and currentY == y2 and currentDirection == 1 then
    -- Ini awal, tidak perlu reset
  end
  
  local magplantChanged = false
  local tilesPlanted = 0
  
  while not stopRequested do
    -- Cek apakah masih ada tile yang perlu ditanami
    local nextTile = getNextTile()
    if nextTile == nil then
      LogToConsole("Semua tile telah ditanami")
      break
    end
    
    -- Cek limit magplant saat ini
    if magLimits[currentMagIndex] == nil then
      magLimits[currentMagIndex] = 0
    end
    
    if magLimits[currentMagIndex] >= Settings.plantLimit then
      -- Ganti ke magplant berikutnya
      local oldIndex = currentMagIndex
      currentMagIndex = currentMagIndex + 1
      if currentMagIndex > #Mag then
        currentMagIndex = 1
      end
      
      LogToConsole("Limit magplant #" .. oldIndex .. " habis, beralih ke magplant #" .. currentMagIndex)
      
      -- Ambil remote magplant baru
      if not TakeMagplant(currentMagIndex) then
        LogToConsole("Gagal mengambil remote magplant #" .. currentMagIndex)
        break
      end
      
      -- Reset limit untuk magplant baru
      magLimits[currentMagIndex] = 0
      magplantChanged = true
      
      -- Lanjutkan ke tile berikutnya (tidak reset posisi)
    end
    
    -- Tanam di tile saat ini
    local planted = plantAt(nextTile.x, nextTile.y)
    if planted then
      tilesPlanted = tilesPlanted + 1
      magLimits[currentMagIndex] = magLimits[currentMagIndex] + 1
    end
    
    -- Jika magplant baru saja diganti, kita sudah lanjut, jadi tidak perlu reset
  end
  
  LogToConsole("Selesai menanam " .. tilesPlanted .. " tile")
end

function UseUws()
  if Settings.UseUws then
    SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
    Sleep(5000)
  end
end

function checkseed()
  local count = 0
  for y = y1, y2 do
    for x = 0, maxX do
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
    for y = y2, y1, -1 do
      for x = 0, maxX do
        if stopRequested then return end
        local tile = GetTile(x, y)
        if tile and IsReady(tile) then
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

-- === FUNGSI UTAMA ===
local function runSPTHT()
    -- Inisialisasi
    y1 = 0
    y2 = Settings.lineY
    World = GetWorld().name
    maxX = (Settings.World == "normal" and 99 or 199)
    
    -- Dapatkan semua magplant
    Mag = GetMagplant()
    if #Mag == 0 then
        LogToConsole("Tidak ada magplant ditemukan!")
        running = false
        return
    end
    LogToConsole("Ditemukan " .. #Mag .. " magplant")
    
    -- Inisialisasi limit untuk setiap magplant
    for i = 1, #Mag do
        magLimits[i] = 0
    end
    
    -- Ambil remote magplant pertama
    currentMagIndex = 1
    if not TakeMagplant(currentMagIndex) then
        LogToConsole("Gagal mengambil remote magplant pertama")
        running = false
        return
    end
    
    -- Reset posisi penanaman
    resetPlantingPosition()
    
    while running and not stopRequested do
        -- Panen jika perlu
        harvest()
        if stopRequested then break end
        Sleep(1500)
        
        -- Tanam dengan manajemen magplant pintar
        plantWithMagplantManagement()
        if stopRequested then break end
        
        -- Gunakan UWS jika diaktifkan
        UseUws()
        Sleep(5000)
        
        -- Reset posisi untuk siklus berikutnya
        resetPlantingPosition()
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
        file:write("plantLimit=" .. Settings.plantLimit .. "\n")
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
                elseif key == "plantLimit" then Settings.plantLimit = tonumber(value)
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
        for x = 0, maxX do
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
                
                local changedLimit, newLimit = ImGui.InputInt("Plant Limit per Magplant", Settings.plantLimit, 1, 10)
                if changedLimit then Settings.plantLimit = newLimit end

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
                ImGui.Text("Current Magplant: " .. currentMagIndex)
                if magLimits[currentMagIndex] then
                    ImGui.Text("Current Limit: " .. magLimits[currentMagIndex] .. "/" .. Settings.plantLimit)
                end
                ImGui.Text("Current Position: (" .. currentX .. "," .. currentY .. ")")
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