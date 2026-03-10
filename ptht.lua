-- ==================== SPTHT DENGAN SISTEM PTHT ====================

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
  mray = true,           -- Mode MRAY (true = 10 tile per step)
  SecondAcc = false,     -- Jika true, mulai dari kanan
  plantLimit = 200       -- Limit per magplant
}

-- === VARIABEL GLOBAL ===
y1 = 0
y2 = Settings.lineY
Mag = {}                 -- Menyimpan semua magplant yang ditemukan
currentMagIndex = 1      -- Index magplant yang sedang digunakan
magLimits = {}           -- Menyimpan limit per magplant
World = ""
plant = true             -- Mode plant
harvest = false          -- Mode harvest

-- === VARIABEL KONTROL ===
local running = false
local stopRequested = false
local currentStatus = "Idle"
local thread = nil

-- === FUNGSI-FUNGSI ===
function IsReady(tile)
  return tile and tile.extra and tile.extra.progress == 1.0
end

function Log(x)
    LogToConsole("`0[`9SPTHT`0] "..x)
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
  local maxX = (Settings.World == "normal" and 99 or 199)
  for x = 0, maxX do
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
    Log("Tidak ada magplant ditemukan!")
    return false
  end
  
  if index > #Mag then index = 1 end
  local m = Mag[index]
  
  Log("Mengambil remote magplant #" .. index .. " di (" .. m[1] .. "," .. m[2] .. ")")
  Raw(0, 0, 0, m[1], m[2])
  Sleep(300)
  Raw(3, 0, 32, m[1], m[2])
  Sleep(300)
  SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. m[1] .. "|\ny|" .. m[2] .. "|\nbuttonClicked|getRemote")
  Sleep(500)
  return true
end

-- Fungsi menanam dengan sistem PTHT
function plantPTHT()
    local sizeX = (Settings.World == "normal" and 100 or 200)
    local put = Settings.mray and 10 or 1
    local startX, endX, stepX
    
    -- Tentukan arah berdasarkan SecondAcc
    if Settings.SecondAcc then
        startX = 199
        endX = 0
        stepX = -10
    else
        startX = 0
        endX = 199
        stepX = 10
    end
    
    for x = startX, endX, stepX do
        if stopRequested then return end
        
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
            
            Log("Limit magplant #" .. oldIndex .. " habis, beralih ke #" .. currentMagIndex)
            
            if not TakeMagplant(currentMagIndex) then
                Log("Gagal mengambil remote magplant #" .. currentMagIndex)
                return
            end
            magLimits[currentMagIndex] = 0
        end
        
        -- Loop 2 kali untuk setiap X (seperti PTHT)
        for loop = 1, 2 do
            if stopRequested then return end
            for y = Settings.lineY, 0, -2 do
                if stopRequested then return end
                local tile = GetTile(x, y)
                if tile and tile.fg == 0 then
                    Log("Planting at X:"..x.." Y:"..y)
                    FindPath(x, y - 1, 520)
                    Sleep(1)
                    Raw(0, (Settings.SecondAcc and 48 or 32), 0, x, y)
                    Sleep(1)
                    Raw(3, 0, 5640, x, y)
                    Sleep(Settings.delayPlant)
                    magLimits[currentMagIndex] = magLimits[currentMagIndex] + 1
                end
            end
        end
    end
end

-- Fungsi panen (mirip PTHT)
function harvestPTHT()
    local sizeX = (Settings.World == "normal" and 100 or 200)
    local put = Settings.mray and 10 or 1
    local startX, endX, stepX
    
    if Settings.SecondAcc then
        startX = 199
        endX = 0
        stepX = -10
    else
        startX = 0
        endX = 199
        stepX = 10
    end
    
    for x = startX, endX, stepX do
        if stopRequested then return end
        for loop = 1, 2 do
            if stopRequested then return end
            for y = Settings.lineY, 0, -2 do
                if stopRequested then return end
                local tile = GetTile(x, y)
                if tile and tile.fg == Settings.FirstSeed and IsReady(tile) then
                    Log("Harvesting at X:"..x.." Y:"..y)
                    FindPath(x, y, 520)
                    Sleep(1)
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

-- Fungsi untuk mengecek jumlah seed siap panen
function checkReadySeeds()
    local count = 0
    for y = Settings.lineY, 0, -2 do
        for x = 0, 199 do
            local tile = GetTile(x, y)
            if tile and tile.fg == Settings.FirstSeed and IsReady(tile) then
                count = count + 1
            end
        end
    end
    return count
end

-- === FUNGSI UTAMA ===
local function runSPTHT()
    -- Inisialisasi
    World = GetWorld().name
    
    -- Dapatkan semua magplant
    Mag = GetMagplant()
    if #Mag == 0 then
        Log("Tidak ada magplant ditemukan!")
        running = false
        return
    end
    Log("Ditemukan " .. #Mag .. " magplant")
    
    -- Inisialisasi limit untuk setiap magplant
    for i = 1, #Mag do
        magLimits[i] = 0
    end
    
    -- Ambil remote magplant pertama
    currentMagIndex = 1
    if not TakeMagplant(currentMagIndex) then
        Log("Gagal mengambil remote magplant pertama")
        running = false
        return
    end
    
    while running and not stopRequested do
        -- Mode PLANT
        plant = true
        harvest = false
        Log("Mode: PLANT")
        plantPTHT()
        if stopRequested then break end
        
        Sleep(1000)
        
        -- Mode HARVEST
        plant = false
        harvest = true
        Log("Mode: HARVEST")
        harvestPTHT()
        if stopRequested then break end
        
        -- Gunakan UWS jika diaktifkan
        UseUws()
        Sleep(5000)
        
        -- Reset limit untuk siklus berikutnya (opsional)
        -- for i = 1, #Mag do
        --     magLimits[i] = 0
        -- end
    end
    
    running = false
    currentStatus = "Stopped"
    Log("SPTHT stopped")
end

-- === FUNGSI START/STOP ===
local function startSPTHT()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    thread = RunThread(runSPTHT)
    Log("SPTHT started")
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
        file:write("mray=" .. tostring(Settings.mray) .. "\n")
        file:write("SecondAcc=" .. tostring(Settings.SecondAcc) .. "\n")
        file:write("plantLimit=" .. Settings.plantLimit .. "\n")
        file:close()
        Log("`2Settings saved.")
    else
        Log("`4Failed to save settings.")
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
                elseif key == "mray" then Settings.mray = (value == "true")
                elseif key == "SecondAcc" then Settings.SecondAcc = (value == "true")
                elseif key == "plantLimit" then Settings.plantLimit = tonumber(value)
                end
            end
        end
        file:close()
        Log("`2Settings loaded.")
    else
        Log("`3No settings file found.")
    end
end

-- === GUI ===
AddHook("OnDraw", "SPTHTGUI", function(dt)
    if ImGui.Begin("SPTHT Loader - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("SPTHTTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("SPTHT Settings (PTHT Style)")
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

                local changedMagBG, newMagBG = ImGui.InputInt("Magplant Background", Settings.MagBG, 1, 100)
                if changedMagBG then Settings.MagBG = newMagBG end

                local changedWorld, newWorld = ImGui.InputText("World Type (normal/island)", Settings.World, 30)
                if changedWorld then Settings.World = newWorld end
                
                local changedMray, newMray = ImGui.Checkbox("MRAY Mode", Settings.mray)
                if changedMray then Settings.mray = newMray end
                
                local changedSecond, newSecond = ImGui.Checkbox("Second Account (Start from right)", Settings.SecondAcc)
                if changedSecond then Settings.SecondAcc = newSecond end
                
                local changedLimit, newLimit = ImGui.InputInt("Plant Limit per Magplant", Settings.plantLimit, 10, 100)
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
                ImGui.Text("Ready Seeds: " .. checkReadySeeds())
                ImGui.Text("Magplants Found: " .. #Mag)
                ImGui.Text("Current Magplant: " .. currentMagIndex)
                if magLimits[currentMagIndex] then
                    ImGui.Text("Current Limit: " .. magLimits[currentMagIndex] .. "/" .. Settings.plantLimit)
                end
                ImGui.Text("Mode: " .. (plant and "PLANT" or (harvest and "HARVEST" or "IDLE")))
                ImGui.EndTabItem()
            end

            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("SPTHT Script by Ertoxz")
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