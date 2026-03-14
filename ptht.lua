-- ==================== PTHT 2.0 DENGAN PILIHAN WORLD TYPE ====================

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
  
  -- Tambahan pilihan world
  WorldType = "island" -- "normal", "island", "nether"
}

-- Variabel global
y1 = 0
y2 = Settings.StartingPos[2]
local maxX = 199  -- default untuk island
local maxY = 199  -- default untuk island

-- Fungsi untuk mendapatkan ukuran world berdasarkan WorldType
local function getWorldSize()
    if Settings.WorldType == "normal" then
        return 100, 60
    elseif Settings.WorldType == "nether" then
        return 150, 150
    else -- island
        return 200, 200
    end
end

-- Update maxX dan maxY berdasarkan WorldType
maxX, maxY = getWorldSize()
maxX = maxX - 1
maxY = maxY - 1

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"
local thread = nil

-- Fungsi Hah4 (sama seperti asli)
function Hah4(str)
	str = str:gsub("``", "")
	str = str:gsub("`.", "")
	str = str:gsub("@", ""):gsub(" of Legend", ""):gsub("%[BOOST%]", "")
	str = str:gsub("%[ELITE%]", ""):gsub(" ", "")
	return str
end

GrowID = Hah4(GetLocal().name)
t = 0
chgremote = true
plant = true
harvest = false
World = GetWorld().name
Mag = {}
C = 1
limit = 0

function Log(x)
	LogToConsole("`0[`9PTHT`0] "..x)
end

function Join(w)
	SendPacket(3, "action|join_request\nname|".. w .."|\ninvitedWorld|0")
end
 
function Raw(t, s, v, x, y)
  pkt = {
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

function GetTree()
	local Tree = 0
	for y = Settings.StartingPos[2], 0, -1 do
	  for x = Settings.StartingPos[1], maxX, 1 do
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
	  for x = Settings.StartingPos[1], maxX, 1 do
	    if (GetTile(x,y).fg == Settings.SeedID and GetTile(x,y).extra and GetTile(x,y).extra.progress == 1) then
		    Harvest = Harvest + 1
	    end
	  end
  end
  return Harvest
end

function GetMagplant()
  local Found = {}
  for x = 0, maxX do
    for y = 0, maxY do
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
    Log("Tidak ada magplant ditemukan!")
    return false
  end
  
  if C > #Mag then C = 1 end
  local m = Mag[C]
  
  Log("Mengambil remote magplant #" .. C .. " di (" .. m[1] .. "," .. m[2] .. ")")
  Raw(0, 0, 0, m[1], m[2])
  Sleep(300)
  Raw(3, 0, 32, m[1], m[2])
  Sleep(300)
  SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. m[1] .. "|\ny|" .. m[2] .. "|\nbuttonClicked|getRemote")
  Sleep(500)
  return true
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
  local step = Settings.SecondAcc and -10 or 10
  local startX = Settings.SecondAcc and maxX or Settings.StartingPos[1]
  local endX = Settings.SecondAcc and Settings.StartingPos[1] or maxX
  
  for x = startX, endX, step do
    if GetWorld() == nil or GetWorld().name ~= World or chgremote or stopRequested then
      return
    else
      Log("`2".. (plant and "Planting on X: "..x or "Harvesting"))
      for i = 1, 2 do
        if GetWorld() == nil or GetWorld().name ~= World or chgremote or stopRequested then
          return
        else
          for y = Settings.StartingPos[2], 0, -2 do
            if GetWorld() == nil or GetWorld().name ~= World or chgremote or stopRequested then
              return
            else
              local tile = GetTile(x, y)
              if (plant and tile and tile.fg == 0 and GetTile(x, y+1).fg ~= 0) or 
                 (harvest and tile and tile.fg == Settings.SeedID and tile.extra and tile.extra.progress == 1) then
                Raw(0, (Settings.SecondAcc and 48 or 32), 0, x, y)
                Raw(0, (Settings.SecondAcc and 48 or 32), 0, x, y)
                Sleep(50)
                Raw(3, 0, (plant and 5640 or 18), x, y)
                Sleep(plant and Settings.DelayPT or Settings.DelayHT)
                px = x + 1
                if GetWorld() == nil or GetWorld().name ~= World or chgremote or stopRequested then
                  return
                elseif GetTile(px, y+2).fg == Settings.SeedID then
                  limit = 0
                else
                  limit = limit + 1
                end
              end
              if limit >= 200 then
                C = C < #Mag and C + 1 or 1
                limit = 0
                chgremote = true
                return
              end
            end
          end
        end
      end
    end
  end
  if GetWorld() == nil or GetWorld().name ~= World or chgremote or stopRequested then
    return
  else
    chgmode()
    if plant and t < Settings.TotalPTHT then
      t = t + 1
      if Settings.whUse then
        local payload = string.format([[
{
  "embeds": [
    {
      "title": "PTHT 2.0 BY LANTAS CONTINENTAL",
      "color": 65362,
      "fields": [
        {
          "name": "📜 Account",
          "value": "%s",
          "inline": false
        },
        {
          "name": "🌍 World",
          "value": "%s",
          "inline": true
        },
        {
          "name": "🔮 Magplant",
          "value": "%d of %d Done",
          "inline": true
        },
        {
          "name": "🌾 Status",
          "value": "%d / %d",
          "inline": true
        },
        {
          "name": "🔐 UWS",
          "value": "%d PCs",
          "inline": true
        }
      ],
      "footer": {
        "text": "Updated: %s"
      }
    }
  ]
}
]], GrowID, World, C, #Mag, t, Settings.TotalPTHT, inv(12600), os.date("%Y-%m-%d %H:%M:%S"))
        SendWebhook(Settings.Webhook, payload)
      end
      Log("Done")
    end
  end
end

function reconnect()
  if GetWorld() == nil or GetWorld().name ~= World then
    Join(World)
    Sleep(5000)
    chgremote = true
  else
    if chgremote then
      TakeMagplant()
      chgremote = false
    end
    if not stopRequested then
      Ptht()
    end
  end
end

-- Fungsi utama yang dijalankan di thread
local function runPTHT()
    -- Inisialisasi ulang variabel
    t = 0
    plant = true
    harvest = false
    C = 1
    limit = 0
    chgremote = true
    World = GetWorld().name
    GrowID = Hah4(GetLocal().name)
    
    -- Update ukuran world
    maxX, maxY = getWorldSize()
    maxX = maxX - 1
    maxY = maxY - 1
    
    -- Ambil remote pertama
    if not TakeMagplant() then
        Log("Gagal mengambil remote, script dihentikan")
        running = false
        return
    end

    if type(Settings.TotalPTHT) == "number" then
        while running and not stopRequested and t < Settings.TotalPTHT do
            reconnect()
            Sleep(2000)
        end
    else
        while running and not stopRequested do
            reconnect()
            Sleep(2000)
        end
    end

    running = false
    currentStatus = "Stopped"
    Log("PTHT stopped")
end

-- Fungsi start/stop
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

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT2_SETTINGS.txt", "w")
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
        file:write("WorldType=" .. Settings.WorldType .. "\n")
        file:close()
        LogToConsole("`2Settings saved.")
    else
        LogToConsole("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/PTHT2_SETTINGS.txt", "r")
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
                elseif key == "WorldType" then Settings.WorldType = value
                end
            end
        end
        file:close()
        LogToConsole("`2Settings loaded.")
    else
        LogToConsole("`3No settings file found.")
    end
end

-- ==================== GUI ====================
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

                ImGui.Text("World Type:")
                if ImGui.RadioButton("Normal", Settings.WorldType == "normal") then
                    Settings.WorldType = "normal"
                end
                ImGui.SameLine()
                if ImGui.RadioButton("Island", Settings.WorldType == "island") then
                    Settings.WorldType = "island"
                end
                ImGui.SameLine()
                if ImGui.RadioButton("Nether", Settings.WorldType == "nether") then
                    Settings.WorldType = "nether"
                end

                local changedStartX, newStartX = ImGui.InputInt("Starting Pos X", Settings.StartingPos[1], 1, 10)
                if changedStartX then Settings.StartingPos[1] = newStartX end
                local changedStartY, newStartY = ImGui.InputInt("Starting Pos Y", Settings.StartingPos[2], 1, 10)
                if changedStartY then Settings.StartingPos[2] = newStartY end

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
                ImGui.Text("World Type: " .. Settings.WorldType)
                ImGui.Text("Size: " .. maxX+1 .. " x " .. maxY+1)
                ImGui.Text("Trees: " .. GetTree())
                ImGui.Text("Harvest Ready: " .. GetHarvest())
                ImGui.Text("PTHT Count: " .. t .. " / " .. Settings.TotalPTHT)
                ImGui.Text("UWS: " .. inv(12600))
                ImGui.Text("Magplants Found: " .. #Mag)
                ImGui.Text("Current Magplant: " .. C)
                ImGui.Text("Limit: " .. limit)
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

-- Load settings saat start
LoadSettings()
LogToConsole("PTHT 2.0 Loader with World Type ready. Use GUI to start.")