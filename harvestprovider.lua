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
local running = true  -- Set true agar loop berjalan
local harvestCount = 0

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
                if running then
                    if ImGui.Button("Stop Harvest", 150, 30) then
                        running = false
                    end
                else
                    if ImGui.Button("Start Harvest", 150, 30) then
                        running = true
                    end
                end
                
                ImGui.EndTabItem()
            end
            
            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Harvest Count: " .. harvestCount)
                ImGui.Separator()
                
                if running then
                    ImGui.TextColored(0, 255, 0, 255, "● Running")
                else
                    ImGui.TextColored(255, 0, 0, 255, "● Stopped")
                end
                
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Provider Harvester Script")
                ImGui.Text("Modified by Ertoxz")
                ImGui.Text("GUI by Ertoxz")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

-- Loop utama yang dimodifikasi dengan kontrol running
RunThread(function()
    while true do
        if running then
            for tileY = y, 0, -1 do
                for tileX = 0, x do
                    if not running then break end
                    local tile = GetTile(tileX, tileY)
                    if tile and tile.fg == Settings.ProviderID and tile.extra and tile.extra.progress == 1.00 then
                        PathFind(tileX, tileY)
                        if not running then break end
                        Punch(0, 0)
                        harvestCount = harvestCount + 1
                        Sleep(100)
                    end
                end
                if not running then break end
            end
        else
            Sleep(500) -- tunggu jika sedang stop
        end
        Sleep(100)
    end
end)

Log("Provider Harvester loaded. Use GUI to start/stop.")
