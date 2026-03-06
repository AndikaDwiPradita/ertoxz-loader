-- ==================== SCRIPT ASLI RECIPE PROCESSOR ====================
Recipes = {1828, 1096, 1098}
Item = 1056
DropPos = {27, 24}
Delay = 500

function Punch()
    ch()
    h = {}
    h.type = 3
    h.px = GetLocal().pos.x // 32 + ((Direction == "Right") and 1 or -1)
    h.py = GetLocal().pos.y // 32
    h.value = 18
    h.x = GetLocal().pos.x
    h.y = GetLocal().pos.y
    SendPacketRaw(false, h)
    ch()
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

function Reconnect()
    LogToConsole("Disconnected or moved... reconnecting!")
    SendPacket(3, "action|join_request\nname|" .. World)
    Sleep(3000)
    while GetWorld() == nil or GetWorld().name:lower() ~= World:lower() do
        Sleep(1000)
        SendPacket(3, "action|join_request\nname|" .. World)
    end
    LogToConsole("Reconnected to " .. World)
end

function GetItemCount(id)
    for _, itm in pairs(GetInventory()) do
        if itm.id == id then
            return itm.amount
        end
    end
    return 0
end

function GetDroppedCount(x, y)
    for _, obj in pairs(GetObjectList()) do
        if (obj.pos.x // 32 == x) and (obj.pos.y // 32 == y) then
            return obj.amount
        end
    end
    return 0
end

function Dropp()
    for i = 1, 12 do
        ch()
        if GetItemCount(Item) >= 250 then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..Item.."|\nitem_count|" .. GetItemCount(Item))
            Sleep(400)
        end
    end
    
    if GetItemCount(Item) >= 250 then
        dropy = dropy - 1
        Sleep(500)
        Raw(0, (Direction == "Right" and 32 or 48), 0, dropx, dropy)
        Sleep(300)
        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..Item.."|\nitem_count|" .. GetItemCount(Item))
    end
end

function move(tx, ty)
  local function dir(a, b) return (b - a) / math.max(1, math.abs(b - a)) end
  local function ease(t) return t * t * (3 - 2 * t) end  

  while true do
    ch()
    local p = GetLocal().pos
    local x, y = p.x // 32, p.y // 32
    if x == tx and y == ty then break end

    local nx, ny = x + dir(x, tx), y + dir(y, ty)
    FindPath(nx, ny)
    Sleep(30 + ease(math.abs(nx - tx + ny - ty)) * 20)
  end
end

function GetDropped()
    for _, id in pairs(Recipes) do
        ch()
        if GetItemCount(id) < 100 then
            for _, obj in pairs(GetObjectList()) do
                ch()
                if obj.id == id then
                    ch()
                    move(obj.pos.x // 32, obj.pos.y // 32)
                    Sleep(Delay)
                    return GetDropped()
                end
            end
        end
    end
end

function DropRecipes()
  for _, id in pairs(Recipes) do
    local count = GetItemCount(id)
    if count > 100 then
      SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. id .. "|\nitem_count|" .. count)
      Sleep(Delay)
    end
  end
end

function ch()
    if GetWorld() == nil or GetWorld().name:lower() ~= World:lower() then
        Reconnect()
    end
end

World = GetWorld().name
dropx, dropy = DropPos[1], DropPos[2]
Direction = (GetLocal().isleft and "Left" or "Right")
Player = {GetLocal().pos.x // 32, GetLocal().pos.y // 32}
Combiner = {GetLocal().pos.x // 32 + (Direction == "Right" and 1 or -1), GetLocal().pos.y // 32}

function Main()
    ch()
    move(Player[1], Player[2])
    Sleep(Delay)
    DropRecipes()
    Sleep(Delay)
    Punch()
    Sleep(500)
    Punch()
    Sleep(500)
    FindPath(Combiner[1], Combiner[2])
    Sleep(1000)
    move(dropx, dropy)
    Sleep(500)
    Dropp()
end

-- ==================== GUI & KONTROL ====================
local running = false
local stopRequested = false
local currentStatus = "Idle"

local function startProcess()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(function()
        while running and not stopRequested do
            ch()
            GetDropped()
            Sleep(700)
            if running and not stopRequested then
                Main()
            end
        end
        running = false
        currentStatus = "Stopped"
    end)
end

local function stopProcess()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

AddHook("OnDraw", "RecipeGUI", function(dt)
    if ImGui.Begin("Recipe Processor - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("RecipeTabs") then
            
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                
                ImGui.Text("Recipes IDs:")
                for i, id in ipairs(Recipes) do
                    local changed, newID = ImGui.InputInt("Recipe " .. i, id, 1, 100)
                    if changed then Recipes[i] = newID end
                end
                
                local changedItem, newItem = ImGui.InputInt("Item ID", Item, 1, 100)
                if changedItem then Item = newItem end
                
                ImGui.Text("Drop Position:")
                local changedDropX, newDropX = ImGui.InputInt("Drop X", DropPos[1], 1, 10)
                if changedDropX then DropPos[1] = newDropX end
                local changedDropY, newDropY = ImGui.InputInt("Drop Y", DropPos[2], 1, 10)
                if changedDropY then DropPos[2] = newDropY end
                
                local changedDelay, newDelay = ImGui.InputInt("Delay (ms)", Delay, 10, 100)
                if changedDelay then Delay = newDelay end
                
                ImGui.Text("Direction: " .. Direction)
                
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Process", 150, 30) then
                        startProcess()
                    end
                else
                    if ImGui.Button("Stop Process", 150, 30) then
                        stopProcess()
                    end
                end
                
                ImGui.EndTabItem()
            end
            
            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                
                ImGui.Text("Inventory:")
                ImGui.Columns(3, "invCols")
                ImGui.Text("Item ID"); ImGui.NextColumn()
                ImGui.Text("Name"); ImGui.NextColumn()
                ImGui.Text("Jumlah"); ImGui.NextColumn()
                ImGui.Separator()
                
                for _, id in ipairs(Recipes) do
                    local info = GetItemByIDSafe(id)
                    local name = info and info.name or "Unknown"
                    ImGui.Text(tostring(id)); ImGui.NextColumn()
                    ImGui.Text(name); ImGui.NextColumn()
                    ImGui.Text(tostring(GetItemCount(id))); ImGui.NextColumn()
                end
                
                local info = GetItemByIDSafe(Item)
                local name = info and info.name or "Unknown"
                ImGui.Text(tostring(Item)); ImGui.NextColumn()
                ImGui.Text(name); ImGui.NextColumn()
                ImGui.Text(tostring(GetItemCount(Item))); ImGui.NextColumn()
                
                ImGui.Columns(1)
                
                ImGui.Separator()
                ImGui.Text("Position: " .. GetLocal().pos.x // 32 .. ", " .. GetLocal().pos.y // 32)
                
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Recipe Processor Script")
                ImGui.Text("Original by Unknown")
                ImGui.Text("Modified by Ertoxz")
                ImGui.Text("GUI by Ertoxz")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

-- Hapus loop while true do yang asli, karena sudah diganti dengan kontrol GUI
LogToConsole("Recipe Processor GUI loaded. Use GUI to start/stop.")
