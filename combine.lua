-- ==================== AUTO COMBINE (RECIPE PROCESSOR) - FINAL FIX ====================

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
local isPaused = false

-- Fungsi logging
function Log(x)
    LogToConsole("`0[`9Combine`0] " .. x)
end

function Join(w)
    SendPacket(3, "action|join_request\nname|" .. w .. "|\ninvitedWorld|0")
end

function GetItemCount(id)
    if not id then return 0 end
    for _, itm in pairs(GetInventory()) do
        if itm.id == id then
            return itm.amount
        end
    end
    return 0
end

function GetDroppedCount(x, y)
    if not x or not y then return 0 end
    local objects = GetObjectList()
    if not objects then return 0 end
    for _, obj in pairs(objects) do
        if obj and obj.pos and (obj.pos.x // 32 == x) and (obj.pos.y // 32 == y) then
            return obj.amount or 1
        end
    end
    return 0
end

function Raw(t, s, v, x, y)
    if not x or not y then return end
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
    if stopRequested then return false end
    local world = GetWorld()
    if not world or world.name:lower() ~= World:lower() then
        Reconnect()
        return false
    end
    return true
end

function Reconnect()
    Log("Disconnected or moved... reconnecting!")
    SendPacket(3, "action|join_request\nname|" .. World)
    Sleep(3000)
    local maxAttempts = 10
    local attempts = 0
    while (GetWorld() == nil or GetWorld().name:lower() ~= World:lower()) and attempts < maxAttempts and not stopRequested do
        Sleep(1000)
        SendPacket(3, "action|join_request\nname|" .. World)
        attempts = attempts + 1
    end
    if GetWorld() and GetWorld().name:lower() == World:lower() then
        Log("Reconnected to " .. World)
    else
        Log("Failed to reconnect after " .. maxAttempts .. " attempts")
    end
end

function move(tx, ty)
    if not tx or not ty then return end
    local function dir(a, b) 
        if a == b then return 0 end
        return (b - a) / math.max(1, math.abs(b - a)) 
    end
    local function ease(t) return t * t * (3 - 2 * t) end  

    local maxSteps = 100
    local steps = 0
    while not stopRequested and steps < maxSteps do
        if not ch() then break end
        local p = GetLocal()
        if not p or not p.pos then break end
        local x, y = p.pos.x // 32, p.pos.y // 32
        if x == tx and y == ty then break end

        local nx, ny = x + dir(x, tx), y + dir(y, ty)
        FindPath(nx, ny)
        Sleep(30 + ease(math.abs(nx - tx + ny - ty)) * 20)
        steps = steps + 1
    end
end

function Punch()
    if stopRequested then return end
    if not ch() then return end
    local p = GetLocal()
    if not p or not p.pos then return end
    local pkt = {}
    pkt.type = 3
    pkt.px = p.pos.x // 32 + ((Direction == "Right") and 1 or -1)
    pkt.py = p.pos.y // 32
    pkt.value = 18
    pkt.x = p.pos.x
    pkt.y = p.pos.y
    SendPacketRaw(false, pkt)
end

function Dropp()
    if stopRequested then return end
    -- Cek apakah perlu drop
    if GetItemCount(Item) < 250 then return end
    
    for i = 1, 12 do
        if stopRequested then return end
        if not ch() then return end
        local count = GetItemCount(Item)
        if count >= 250 then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..Item.."|\nitem_count|" .. count)
            Sleep(400)
        else
            break
        end
    end
    
    if GetItemCount(Item) >= 250 and not stopRequested then
        dropy = math.max(0, dropy - 1) -- tidak boleh kurang dari 0
        if not ch() then return end
        Sleep(500)
        Raw(0, (Direction == "Right" and 32 or 48), 0, dropx, dropy)
        Sleep(300)
        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..Item.."|\nitem_count|" .. GetItemCount(Item))
    end
end

function GetDropped()
    if stopRequested then return end
    
    for _, id in ipairs(Recipes) do
        if stopRequested then return end
        if not ch() then return end
        
        if GetItemCount(id) < 100 then
            local objects = GetObjectList()
            if not objects then break end
            
            for _, obj in pairs(objects) do
                if stopRequested then return end
                if obj and obj.id == id and obj.pos then
                    if not ch() then return end
                    move(obj.pos.x // 32, obj.pos.y // 32)
                    Sleep(Delay)
                    -- Setelah move, rekursi dengan aman
                    if not stopRequested then
                        GetDropped()
                    end
                    return
                end
            end
        end
    end
end

function DropRecipes()
    if stopRequested then return end
    for _, id in ipairs(Recipes) do
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
    if not ch() then return end
    
    -- Pindah ke posisi player awal
    move(Player[1], Player[2])
    if stopRequested then return end
    Sleep(Delay)
    
    -- Drop recipe yang berlebih
    DropRecipes()
    if stopRequested then return end
    Sleep(Delay)
    
    -- Punch combiner
    Punch()
    if stopRequested then return end
    Sleep(500)
    
    -- Punch lagi untuk memastikan
    Punch()
    if stopRequested then return end
    Sleep(500)
    
    -- Pindah ke combiner
    if not ch() then return end
    FindPath(Combiner[1], Combiner[2])
    Sleep(1000)
    
    -- Pindah ke posisi drop
    if not ch() then return end
    move(dropx, dropy)
    if stopRequested then return end
    Sleep(500)
    
    -- Drop hasil
    Dropp()
end

-- Fungsi utama yang dijalankan di thread
local function runCombine()
    -- Inisialisasi variabel dengan pengecekan nil
    local localPlayer = GetLocal()
    if not localPlayer then
        Log("Error: Cannot get local player")
        running = false
        return
    end
    
    World = GetWorld() and GetWorld().name or "UNKNOWN"
    dropx, dropy = DropPos[1], DropPos[2]
    Direction = (localPlayer.isleft and "Left" or "Right")
    Player = {localPlayer.pos.x // 32, localPlayer.pos.y // 32}
    Combiner = {Player[1] + (Direction == "Right" and 1 or -1), Player[2]}

    Log("Combine started at " .. World)

    local loopCount = 0
    while running and not stopRequested do
        loopCount = loopCount + 1
        if loopCount % 10 == 0 then
            -- Beri jeda untuk cek stopRequested
            Sleep(10)
        end
        
        if not ch() then
            Sleep(1000)
            goto continue
        end
        
        GetDropped()
        if stopRequested then break end
        Sleep(700)
        
        if running and not stopRequested then
            Main()
        end
        
        ::continue::
    end

    running = false
    currentStatus = "Stopped"
    Log("Combine stopped")
end

-- Fungsi start/stop
local function startCombine()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    local success, err = pcall(function()
        RunThread(runCombine)
    end)
    if not success then
        Log("Error starting thread: " .. tostring(err))
        running = false
        currentStatus = "Error"
    end
end

local function stopCombine()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
        -- Beri waktu thread untuk berhenti
        Sleep(500)
    end
end

-- Fungsi Save/Load dengan pengecekan error
local function SaveSettings()
    local success, err = pcall(function()
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
    end)
    if not success then
        Log("`4Error saving settings: " .. tostring(err))
    end
end

local function LoadSettings()
    local success, err = pcall(function()
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
    end)
    if not success then
        Log("`4Error loading settings: " .. tostring(err))
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "CombineGUI", function(dt)
    local success, err = pcall(function()
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
                    
                    local world = GetWorld()
                    ImGui.Text("World: " .. (world and world.name or "None"))
                    
                    local localPlayer = GetLocal()
                    if localPlayer and localPlayer.pos then
                        ImGui.Text("Position: " .. localPlayer.pos.x // 32 .. ", " .. localPlayer.pos.y // 32)
                    end
                    
                    ImGui.Text("Direction: " .. Direction)
                    ImGui.Text("Item Count: " .. GetItemCount(Item))
                    
                    ImGui.EndTabItem()
                end
                ImGui.EndTabBar()
            end
            ImGui.End()
        end
    end)
    
    if not success then
        LogToConsole("Error in GUI: " .. tostring(err))
    end
end)

Log("Combine script loaded. Use GUI to start.")
LoadSettings()
