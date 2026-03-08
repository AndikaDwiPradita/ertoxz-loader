-- ==================== AUTO COMBINE (RECIPE PROCESSOR) ====================

Recipes = {1828, 1096, 1098}
Item = 1056
DropPos = {27, 24}
Delay = 500

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"
local World = ""
local dropx, dropy = DropPos[1], DropPos[2]
local Direction = "Right"
local Player = {0, 0}
local Combiner = {0, 0}

-- Fungsi pendukung
function Log(x)
    LogToConsole("`0[`9Combine`0] " .. x)
end

function Join(w)
    SendPacket(3, "action|join_request\nname|" .. w .. "|\ninvitedWorld|0")
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

function ch()
    if GetWorld() == nil or GetWorld().name:lower() ~= World:lower() then
        Reconnect()
    end
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

function move(tx, ty)
    local function dir(a, b) return (b - a) / math.max(1, math.abs(b - a)) end
    local function ease(t) return t * t * (3 - 2 * t) end  

    while not stopRequested do
        ch()
        local p = GetLocal().pos
        local x, y = p.x // 32, p.y // 32
        if x == tx and y == ty then break end

        local nx, ny = x + dir(x, tx), y + dir(y, ty)
        FindPath(nx, ny)
        Sleep(30 + ease(math.abs(nx - tx + ny - ty)) * 20)
    end
end

function Punch()
    if stopRequested then return end
    ch()
    local pkt = {}
    pkt.type = 3
    pkt.px = GetLocal().pos.x // 32 + ((Direction == "Right") and 1 or -1)
    pkt.py = GetLocal().pos.y // 32
    pkt.value = 18
    pkt.x = GetLocal().pos.x
    pkt.y = GetLocal().pos.y
    SendPacketRaw(false, pkt)
    ch()
end

function Dropp()
    for i = 1, 12 do
        if stopRequested then return end
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

function GetDropped()
    for _, id in pairs(Recipes) do
        if stopRequested then return end
        ch()
        if GetItemCount(id) < 100 then
            for _, obj in pairs(GetObjectList()) do
                if stopRequested then return end
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
        if stopRequested then return end
        local count = GetItemCount(id)
        if count > 100 then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. id .. "|\nitem_count|" .. count)
            Sleep(Delay)
        end
    end
end

function Main()
    if stopRequested then return end
    ch()
    move(Player[1], Player[2])
    Sleep(Delay)
    DropRecipes()
    Sleep(Delay)
    Punch()
    Sleep(500)
    Punch()
    Sleep(500)
    if not stopRequested then
        FindPath(Combiner[1], Combiner[2])
        Sleep(1000)
        move(dropx, dropy)
        Sleep(500)
        Dropp()
    end
end

-- Fungsi utama yang dijalankan di thread
local function runCombine()
    -- Inisialisasi variabel
    World = GetWorld().name
    dropx, dropy = DropPos[1], DropPos[2]
    Direction = (GetLocal().isleft and "Left" or "Right")
    Player = {GetLocal().pos.x // 32, GetLocal().pos.y // 32}
    Combiner = {GetLocal().pos.x // 32 + (Direction == "Right" and 1 or -1), GetLocal().pos.y // 32}

    Log("Combine started at " .. World)

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
    Log("Combine stopped")
end

local function startCombine()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runCombine)
end

local function stopCombine()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/COMBINE_SETTINGS.txt", "w")
    if file then
        file:write("Recipes=" .. table.concat(Recipes, ",") .. "\n")
        file:write("Item=" .. Item .. "\n")
        file:write("DropX=" .. DropPos[1] .. "\n")
        file:write("DropY=" .. DropPos[2] .. "\n")
        file:write("Delay=" .. Delay .. "\n")
        file:close()
        Log("`2Settings saved.")
    else
        Log("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/COMBINE_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "Recipes" then
                    local ids = {}
                    for id in string.gmatch(value, "%d+") do
                        table.insert(ids, tonumber(id))
                    end
                    if #ids > 0 then Recipes = ids end
                elseif key == "Item" then Item = tonumber(value)
                elseif key == "DropX" then DropPos[1] = tonumber(value)
                elseif key == "DropY" then DropPos[2] = tonumber(value)
                elseif key == "Delay" then Delay = tonumber(value)
                end
            end
        end
        file:close()
        Log("`2Settings loaded.")
    else
        Log("`3No settings file found.")
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "CombineGUI", function(dt)
    if ImGui.Begin("Auto Combine - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("CombineTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()

                ImGui.Text("Recipe IDs (pisah koma):")
                local recipeStr = table.concat(Recipes, ",")
                local changedRecipe, newRecipe = ImGui.InputText("##Recipes", recipeStr, 100)
                if changedRecipe then
                    local ids = {}
                    for id in string.gmatch(newRecipe, "%d+") do
                        table.insert(ids, tonumber(id))
                    end
                    if #ids > 0 then Recipes = ids end
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

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Combine", 150, 30) then
                        startCombine()
                    end
                else
                    if ImGui.Button("Stop Combine", 150, 30) then
                        stopCombine()
                    end
                end
                ImGui.SameLine()
                if ImGui.Button("Save", 80, 30) then SaveSettings() end
                ImGui.SameLine()
                if ImGui.Button("Load", 80, 30) then LoadSettings() end

                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("World: " .. (GetWorld() and GetWorld().name or "None"))
                ImGui.Text("Direction: " .. Direction)
                ImGui.Text("Player Pos: " .. Player[1] .. ", " .. Player[2])
                ImGui.Text("Combiner Pos: " .. Combiner[1] .. ", " .. Combiner[2])
                ImGui.Text("Item Count: " .. GetItemCount(Item))
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("Combine script loaded. Use GUI to start.")
LoadSettings()
