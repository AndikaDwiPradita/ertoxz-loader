-- ==================== AUTO HARVEST PROVIDER (DENGAN SAVE/LOAD) ====================

Settings = {
  ProviderID = 928
}

if type(GetTile(199,99)) == "table" then
  x, y = 199, 199
else
  x, y = 99, 53
end

state = { 4196896, 16779296 }

-- Variabel kontrol
local running = false
local stopRequested = false
local harvestCount = 0
local currentStatus = "Idle"

-- Fungsi-fungsi asli (tidak diubah)
function PathFind(x, y)
  local PX = math.floor(GetLocal().pos.x / 32)
  local PY = math.floor(GetLocal().pos.y / 32)

  while math.abs(y - PY) > 6 do
    PY = PY + (y - PY > 0 and 6 or -6)
    FindPath(PX, PY)
    Sleep(400)
  end

  while math.abs(x - PX) > 6 do
    PX = PX + (x - PX > 0 and 6 or -6)
    FindPath(PX, PY)
    Sleep(400)
  end

  FindPath(x, y)
  Sleep(200)
end

function Punch(x, y) 
  pkt = {} 
  pkt.px = math.floor(GetLocal().pos.x / 32 + x)
  pkt.py = math.floor(GetLocal().pos.y / 32 + y)
  pkt.type = 3 
  pkt.value = 18 
  pkt.x = GetLocal().pos.x 
  pkt.y = GetLocal().pos.y
  SendPacketRaw(false, pkt)
  state = {4196896,16779296}
  for _, st in ipairs(state) do
      hld = {} 
      hld.px = x 
      hld.py = y 
      hld.type = 0 
      hld.value = 0 
      hld.x = GetLocal().pos.x
      hld.y = GetLocal().pos.y 
      hld.state = st
      SendPacketRaw(false,hld)
      Sleep(100)
  end
  Sleep(100)
end

-- Fungsi Save/Load Settings
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/HARVEST_SETTINGS.txt", "w")
    if file then
        file:write("ProviderID=" .. Settings.ProviderID .. "\n")
        file:close()
        LogToConsole("`2Settings saved.")
    else
        LogToConsole("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/HARVEST_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "ProviderID" then
                    Settings.ProviderID = tonumber(value) or Settings.ProviderID
                end
            end
        end
        file:close()
        LogToConsole("`2Settings loaded.")
    else
        LogToConsole("`3No settings file found.")
    end
end

-- Fungsi utama yang dijalankan di thread
local function runHarvest()
    while running and not stopRequested do
        for tileY = y, 0, -1 do
            if not running or stopRequested then break end
            for tileX = 0, x do
                if not running or stopRequested then break end
                local tile = GetTile(tileX, tileY)
                if tile and tile.fg == Settings.ProviderID and tile.extra and tile.extra.progress == 1.00 then
                    PathFind(tileX, tileY)
                    if not running or stopRequested then break end
                    Punch(0, 0)
                    harvestCount = harvestCount + 1
                    Sleep(100)
                end
            end
        end
        if not stopRequested then
            Sleep(1000) -- jeda antar siklus
        end
    end
    running = false
    currentStatus = "Stopped"
    LogToConsole("Harvest provider stopped")
end

-- Fungsi start/stop
local function startHarvest()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runHarvest)
    LogToConsole("Harvest provider started")
end

local function stopHarvest()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "ProviderGUI", function(dt)
    if ImGui.Begin("Provider Harvester - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("ProviderTabs") then
            
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                
                local changedID, newID = ImGui.InputInt("Provider ID", Settings.ProviderID, 1, 100)
                if changedID then Settings.ProviderID = newID end
                
                ImGui.Text("World Size: " .. (x+1) .. " x " .. (y+1))
                
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Harvest", 150, 30) then
                        startHarvest()
                    end
                else
                    if ImGui.Button("Stop Harvest", 150, 30) then
                        stopHarvest()
                    end
                end
                
                ImGui.Spacing()
                if ImGui.Button("Save Settings", 150, 30) then
                    SaveSettings()
                end
                ImGui.SameLine()
                if ImGui.Button("Load Settings", 150, 30) then
                    LoadSettings()
                end
                
                ImGui.EndTabItem()
            end
            
            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Harvest Count: " .. harvestCount)
                if running then
                    ImGui.TextColored(0, 255, 0, 255, "● Running")
                else
                    ImGui.TextColored(255, 0, 0, 255, "● Stopped")
                end
                ImGui.EndTabItem()
            end
            
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

LogToConsole("Provider Harvester loaded. Use GUI to start/stop.")
