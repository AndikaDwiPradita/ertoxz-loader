-- ==================== PTHT DENGAN SISTEM PENANAMAN SPTHT (GUI PTHT STANDAR) ====================

-- === KONFIGURASI (SAMA DENGAN PTHT ASLI) ===
Settings = {
  whUse = true,
  Webhook = "Webook",
  
  StartingPos = {0, 192}, -- ( x, y ) --
  MagBG = 284, -- (Magplant Background ) --
  SeedID = 15461, 
  TotalPTHT = 20, 
  MaxTree = 17000, 
  
  SecondAcc = false,
  -- true = planting from right, not harvesting, not using uws
  DelayPT = 25, -- ( Delay Planting ) --
  DelayHT = 200, -- ( Delay Harvesting ) --
  DelayAfterPT = 8000, -- ( Delay after planting for second account ) --
  DelayAfterUWS = 2500, -- ( Delay after using uws ) --
}

-- === KONSTANTA SPTHT (HARDCODED, TIDAK MUNCUL DI GUI) ===
local SPTHT_CONFIG = {
  World = "island",      -- "normal", "island", "nether"
  plantLimit = 30,       -- jumlah tanam per magplant sebelum ganti remote
  useZigzag = true,      -- true = pola zigzag, false = pola baris biasa
}

-- === VARIABEL GLOBAL ===
GrowID = ""
t = 0
chgremote = true
plant = true
harvest = false
World = ""
Mag = {}                 -- Menyimpan semua magplant
C = 1                    -- Index magplant saat ini
magLimits = {}           -- Limit per magplant
limit = 0

-- Variabel untuk penanaman zigzag
local y1 = 0
local y2 = Settings.StartingPos[2]
local targetX = 0
local targetY = y2
local targetDirection = 1      -- 1 = kiri ke kanan, -1 = kanan ke kiri
local maxX = (SPTHT_CONFIG.World == "normal" and 99 or 199)

-- === VARIABEL KONTROL ===
local running = false
local stopRequested = false
local currentStatus = "Idle"
local thread = nil

-- === FUNGSI-FUNGSI DASAR ===
function Hah4(str)
	str = str:gsub("``", "")
	str = str:gsub("`.", "")
	str = str:gsub("@", ""):gsub(" of Legend", ""):gsub("%[BOOST%]", "")
	str = str:gsub("%[ELITE%]", ""):gsub(" ", "")
	return str
end

function Log(x)
	LogToConsole("`0[`9PTHT`0] "..x)
end

function Join(w)
	SendPacket(3, "action|join_request\nname|".. w .."|\ninvitedWorld|0")
end
 
function Raw(t, s, v, x, y)
  local pkt = {
    type = t,
    state = s,
    value = v,
    px = x, 
    py = y,
    x = x * 32,
    y = y * 32
  }
  SendPacketRaw(false, pkt)
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
  MakeRequest(url, "POST", {["Content-Type"] = "application/json"}, data)
end

-- === FUNGSI DARI PTHT ASLI ===
function GetTree()
	local Tree = 0
	for y = Settings.StartingPos[2], 0, -1 do
	  for x = Settings.StartingPos[1], 199, 1 do
	    if (GetTile(x,y).fg == Settings.SeedID) then
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
	    if (GetTile(x,y).fg == Settings.SeedID and GetTile(x,y).extra.progress == 1) then
		    Harvest = Harvest + 1
	    end
	  end
  end
  return Harvest
end

-- === FUNGSI DARI SPTHT ===
function GetMagplant()
  local Found = {}
  local sizeX, sizeY = (SPTHT_CONFIG.World == "normal" and 100 or 200), (SPTHT_CONFIG.World == "normal" and 60 or 200)
  for x = 0, sizeX - 1 do
    for y = 0, sizeY - 1 do
      local tile = GetTile(x, y)
      if tile and tile.fg == 5638 and tile.bg == Settings.MagBG then
        table.insert(Found, {x, y})
      end
    end
  end
  return Found
end

function TakeMagplant(index)
  Mag = GetMagplant()
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

-- Manajemen posisi penanaman zigzag
local function resetTargetPosition()
  targetX = 0
  targetY = Settings.StartingPos[2]
  targetDirection = 1
  maxX = (SPTHT_CONFIG.World == "normal" and 99 or 199)
end

local function getCurrentTarget()
  return {x = targetX, y = targetY}
end

local function advanceToNextTile()
  local nextX = targetX + targetDirection
  local nextY = targetY
  
  if (targetDirection == 1 and nextX > maxX) or (targetDirection == -1 and nextX < 0) then
    nextY = targetY - 1
    if nextY < 0 then
      return false
    end
    targetDirection = targetDirection * -1
    nextX = (targetDirection == 1 and 0 or maxX)
  end
  
  targetX = nextX
  targetY = nextY
  return true
end

-- Penanaman per tile
local function plantAt(x, y)
  if stopRequested then return false end
  local tile = GetTile(x, y)
  if tile and tile.fg == 0 then
    LogToConsole("Planting at ("..x..","..y..")")
    FindPath(x, y, 520)
    Sleep(100)
    Raw(0, 32, 0, x, y)
    Raw(0, 32, 0, x, y)
    Sleep(50)
    Raw(3, 0, 5640, x, y)
    Sleep(Settings.DelayPT)
    return true
  end
  return false
end

-- Fungsi penanaman utama
local function plantWithMagplantManagement()
  if plant == false then return end
  
  local tilesPlanted = 0
  
  while not stopRequested and plant do
    if targetY < 0 then
      Log("Semua tile telah ditanami")
      break
    end
    
    local currentTile = getCurrentTarget()
    
    if magLimits[C] == nil then
      magLimits[C] = 0
    end
    
    if magLimits[C] >= SPTHT_CONFIG.plantLimit then
      local oldC = C
      C = C + 1
      if C > #Mag then
        C = 1
      end
      
      Log("Limit magplant #" .. oldC .. " habis, beralih ke #" .. C)
      
      if not TakeMagplant(C) then
        Log("Gagal mengambil remote magplant #" .. C)
        break
      end
      
      magLimits[C] = 0
    end
    
    local planted = plantAt(currentTile.x, currentTile.y)
    if planted then
      tilesPlanted = tilesPlanted + 1
      magLimits[C] = magLimits[C] + 1
      if not advanceToNextTile() then
        break
      end
    else
      if not advanceToNextTile() then
        break
      end
    end
  end
  
  Log("Selesai menanam " .. tilesPlanted .. " tile")
end

-- Fungsi harvest (dari PTHT asli)
function DoHarvest()
  if harvest == false then return end
  
  for x = (Settings.SecondAcc and 199 or Settings.StartingPos[1]), 
          (Settings.SecondAcc and Settings.StartingPos[1] or 199), 
          (Settings.SecondAcc and -10 or 10) do
    if stopRequested then return end
    Log("`2Harvesting on X: "..x)
    for y = Settings.StartingPos[2], 0, -2 do
      if stopRequested then return end
      local tile = GetTile(x, y)
      if tile and tile.fg == Settings.SeedID and tile.extra and tile.extra.progress == 1 then
        FindPath(x, y, 520)
        Sleep(100)
        Raw(0, 32, 0, x, y)
        Sleep(Settings.DelayHT)
        Raw(3, 0, 18, x, y)
        Sleep(Settings.DelayHT)
      end
    end
  end
end

-- Mode switching (dari PTHT asli)
function chgmode()
  if plant then
    plant = false
    if GetTree() >= Settings.MaxTree and not Settings.SecondAcc then
      harvest = true
      SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
      Sleep(Settings.DelayAfterUWS)
      Log("Harvesting....")
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

-- === FUNGSI UTAMA ===
local function runPTHT()
    GrowID = Hah4(GetLocal().name)
    World = GetWorld().name
    y1 = 0
    y2 = Settings.StartingPos[2]
    maxX = (SPTHT_CONFIG.World == "normal" and 99 or 199)
    
    if Settings.SecondAcc then
        plant = true
        harvest = false
    else
        plant = true
        harvest = false
    end
    
    t = 0
    C = 1
    limit = 0
    chgremote = true
    
    Mag = GetMagplant()
    if #Mag == 0 then
        Log("Tidak ada magplant ditemukan!")
        running = false
        return
    end
    Log("Ditemukan " .. #Mag .. " magplant")
    
    for i = 1, #Mag do
        magLimits[i] = 0
    end
    
    if not TakeMagplant(C) then
        Log("Gagal mengambil remote pertama")
        running = false
        return
    end
    
    resetTargetPosition()
    
    while running and not stopRequested do
        if plant then
            plantWithMagplantManagement()
            
            if not stopRequested then
                chgmode()
                t = t + 1
                
                if Settings.whUse then
                    local payload = string.format([[
{
  "embeds": [
    {
      "title": "PTHT 2.0 BY LANTAS CONTINENTAL",
      "color": 65362,
      "fields": [
        {"name": "📜 Account", "value": "%s", "inline": false},
        {"name": "🌍 World", "value": "%s", "inline": true},
        {"name": "🔮 Magplant", "value": "%d of %d Done", "inline": true},
        {"name": "🌾 Status", "value": "%d / %d", "inline": true},
        {"name": "🔐 UWS", "value": "%d PCs", "inline": true}
      ],
      "footer": {"text": "Updated: %s"}
    }
  ]
}
]], GrowID, World, C, #Mag, t, Settings.TotalPTHT, inv(12600), os.date("%Y-%m-%d %H:%M:%S"))
                    SendWebhook(Settings.Webhook, payload)
                end
                
                Log("Done")
            end
            
        elseif harvest then
            DoHarvest()
            if not stopRequested then
                chgmode()
            end
        end
        
        Sleep(1000)
    end
    
    running = false
    currentStatus = "Stopped"
    Log("PTHT stopped")
end

-- === FUNGSI START/STOP ===
local function startPTHT()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    thread = RunThread(runPTHT)
    Log("PTHT started")
end

local function stopPTHT()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- === FUNGSI SAVE/LOAD (SAMA PERSIS DENGAN PTHT ASLI) ===
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_SETTINGS.txt", "w")
    if file then
        file:write("whUse=" .. tostring(Settings.whUse) .. "\n")
        file:write("Webhook=" .. Settings.Webhook .. "\n")
        file:write("StartingPosX=" .. Settings.StartingPos[1] .. "\n")
        file:write("StartingPosY=" .. Settings.StartingPos[2] .. "\n")
        file:write("MagBG=" .. Settings.MagBG .. "\n")
        file:write("SeedID=" .. Settings.SeedID .. "\n")
        file:write("TotalPTHT=" .. Settings.TotalPTHT .. "\n")
        file:write("MaxTree=" .. Settings.MaxTree .. "\n")
        file:write("SecondAcc=" .. tostring(Settings.SecondAcc) .. "\n")
        file:write("DelayPT=" .. Settings.DelayPT .. "\n")
        file:write("DelayHT=" .. Settings.DelayHT .. "\n")
        file:write("DelayAfterPT=" .. Settings.DelayAfterPT .. "\n")
        file:write("DelayAfterUWS=" .. Settings.DelayAfterUWS .. "\n")
        file:close()
        LogToConsole("`2Settings saved.")
    else
        LogToConsole("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "whUse" then Settings.whUse = (value == "true")
                elseif key == "Webhook" then Settings.Webhook = value
                elseif key == "StartingPosX" then Settings.StartingPos[1] = tonumber(value)
                elseif key == "StartingPosY" then Settings.StartingPos[2] = tonumber(value)
                elseif key == "MagBG" then Settings.MagBG = tonumber(value)
                elseif key == "SeedID" then Settings.SeedID = tonumber(value)
                elseif key == "TotalPTHT" then Settings.TotalPTHT = tonumber(value)
                elseif key == "MaxTree" then Settings.MaxTree = tonumber(value)
                elseif key == "SecondAcc" then Settings.SecondAcc = (value == "true")
                elseif key == "DelayPT" then Settings.DelayPT = tonumber(value)
                elseif key == "DelayHT" then Settings.DelayHT = tonumber(value)
                elseif key == "DelayAfterPT" then Settings.DelayAfterPT = tonumber(value)
                elseif key == "DelayAfterUWS" then Settings.DelayAfterUWS = tonumber(value)
                end
            end
        end
        file:close()
        LogToConsole("`2Settings loaded.")
    else
        LogToConsole("`3No settings file found.")
    end
end

-- === GUI (SAMA PERSIS DENGAN PTHT ASLI) ===
AddHook("OnDraw", "PTHTGUI", function(dt)
    if ImGui.Begin("PTHT 2.0 Loader - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("PTHTTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("PTHT 2.0 Settings")
                ImGui.Separator()

                local changedWh, newWh = ImGui.Checkbox("Use Webhook", Settings.whUse)
                if changedWh then Settings.whUse = newWh end

                local changedWeb, newWeb = ImGui.InputText("Webhook URL", Settings.Webhook, 200)
                if changedWeb then Settings.Webhook = newWeb end

                local changedStartX, newStartX = ImGui.InputInt("Starting Pos X", Settings.StartingPos[1], 1, 10)
                if changedStartX then Settings.StartingPos[1] = newStartX end
                local changedStartY, newStartY = ImGui.InputInt("Starting Pos Y", Settings.StartingPos[2], 1, 10)
                if changedStartY then Settings.StartingPos[2] = newStartY y2 = newStartY end

                local changedMagBG, newMagBG = ImGui.InputInt("Magplant Background", Settings.MagBG, 1, 100)
                if changedMagBG then Settings.MagBG = newMagBG end

                local changedSeed, newSeed = ImGui.InputInt("Seed ID", Settings.SeedID, 1, 100)
                if changedSeed then Settings.SeedID = newSeed end

                local changedTotal, newTotal = ImGui.InputInt("Total PTHT", Settings.TotalPTHT, 1, 10)
                if changedTotal then Settings.TotalPTHT = newTotal end

                local changedMax, newMax = ImGui.InputInt("Max Tree", Settings.MaxTree, 100, 1000)
                if changedMax then Settings.MaxTree = newMax end

                local changedSecond, newSecond = ImGui.Checkbox("Second Account", Settings.SecondAcc)
                if changedSecond then Settings.SecondAcc = newSecond end

                ImGui.Text("Delays (ms):")
                local changedDelayPT, newDelayPT = ImGui.InputInt("Plant Delay", Settings.DelayPT, 1, 10)
                if changedDelayPT then Settings.DelayPT = newDelayPT end
                local changedDelayHT, newDelayHT = ImGui.InputInt("Harvest Delay", Settings.DelayHT, 1, 10)
                if changedDelayHT then Settings.DelayHT = newDelayHT end
                local changedAfterPT, newAfterPT = ImGui.InputInt("Delay After PT", Settings.DelayAfterPT, 100, 1000)
                if changedAfterPT then Settings.DelayAfterPT = newAfterPT end
                local changedAfterUWS, newAfterUWS = ImGui.InputInt("Delay After UWS", Settings.DelayAfterUWS, 100, 1000)
                if changedAfterUWS then Settings.DelayAfterUWS = newAfterUWS end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start PTHT", 120, 30) then
                        startPTHT()
                    end
                else
                    if ImGui.Button("Stop PTHT", 120, 30) then
                        stopPTHT()
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
                ImGui.Text("Mode: " .. (plant and "Plant" or (harvest and "Harvest" or "Idle")))
                ImGui.Text("PTHT Count: " .. t .. " / " .. Settings.TotalPTHT)
                ImGui.Text("Trees: " .. GetTree())
                ImGui.Text("Harvest Ready: " .. GetHarvest())
                ImGui.Text("UWS: " .. inv(12600))
                ImGui.Text("Magplants Found: " .. #Mag)
                ImGui.Text("Current Magplant: " .. C)
                if magLimits[C] then
                    ImGui.Text("Current Limit: " .. magLimits[C] .. "/" .. SPTHT_CONFIG.plantLimit)
                end
                ImGui.Text("Target: (" .. targetX .. "," .. targetY .. ")")
                ImGui.EndTabItem()
            end


            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

-- Load settings saat start
LoadSettings()
LogToConsole("PTHT 2.0 Loader ready. Use GUI to start.")