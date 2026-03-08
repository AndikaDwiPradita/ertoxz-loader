-- ==================== AUTO COOKING OVEN (DENGAN GUI) ====================

Settings = {
    DropPos = {52, 19},
    MoveDelay = 30,          -- delay dasar untuk movement (ms)
    PlaceDelay = 120,        -- delay antar place ingredient (ms)
    Place2Delay = 70,        -- delay untuk place2 ingredient (ms)
    OpenDelay = 85,          -- delay buka oven (ms)
    CheckInterval = 3000,    -- interval pengecekan utama (ms)
}

-- Variabel internal (jangan diubah)
World = GetWorld().name
ingredients = {4602, 962, 3472, 4570, 4568, 4588}
ovenid = {
    [952] = true,
    [4498] = true,
    [4618] = true,
    [4620] = true,
    [8586] = true,
    [8938] = true,
    [10820] = true
}
Oven = {}
posx, posy = 0, 0
dc = false

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi asli (dengan modifikasi delay menggunakan Settings)
function Drop(id)
    SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. id .. "|\nitem_count|250")
end

function Open(x, y, z, t)
    SendPacket(2, "action|dialog_return\ndialog_name|homeoven_edit\nx|"..x.."|\ny|"..y.."|\ncookthis|"..z.."|\nbuttonClicked|"..t)
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

function GetOven()
    local found = {}
    local pos = {GetLocal().pos.x // 32, GetLocal().pos.y // 32}
    for y = pos[2] - 6, pos[2] + 6 do
        for x = pos[1] - 6, pos[1] + 6 do
            local tile = GetTile(x, y)
            if tile and ovenid[tile.fg] then
                table.insert(found, {x, y})
                if #found >= 100 then return found end
            end
        end
    end
    return found
end

function PlaceIngredient(id, delay)
    for _, ov in ipairs(Oven) do
        if stopRequested then return end
        if GetWorld() == nil or GetWorld().name ~= World then return end
        FindPath(ov[1], ov[2])
        Sleep(Settings.MoveDelay)
        Raw(3, 16779296, id, ov[1], ov[2])
        Sleep(delay or Settings.PlaceDelay)
    end
end

function Place2Ingredient(id, id2, delay)
    for _, ov in ipairs(Oven) do
        if stopRequested then return end
        if GetWorld() == nil or GetWorld().name ~= World then return end
        FindPath(ov[1], ov[2])
        Sleep(Settings.MoveDelay)
        Raw(3, 0, id, ov[1], ov[2])
        Sleep(70) -- delay tetap untuk antar dua item
        Raw(3, 0, id2, ov[1], ov[2])
        Sleep(delay or Settings.Place2Delay)
    end
end

function Rice()
    for _, ov in ipairs(Oven) do
        if stopRequested then return end
        if GetWorld() == nil or GetWorld().name ~= World then return end
        FindPath(ov[1], ov[2])
        Sleep(Settings.MoveDelay)
        Open(ov[1], ov[2], 3472, "low")
        Sleep(Settings.OpenDelay)
    end
end

function Main()
    if GetWorld() == nil or GetWorld().name ~= World then return end
    Rice()
    PlaceIngredient(4568, Settings.PlaceDelay)
    Sleep(50)
    Place2Ingredient(4602, 4588, Settings.Place2Delay)
    PlaceIngredient(4570, Settings.PlaceDelay)
    Sleep(50)
    PlaceIngredient(962, Settings.PlaceDelay)
    PlaceIngredient(4570, Settings.PlaceDelay)
    Sleep(400)
    PlaceIngredient(18, Settings.PlaceDelay)
end

function inv(id)
    local count = 0
    for _, itm in pairs(GetInventory()) do
        if itm.id == id then count = count + itm.amount end
    end
    return count
end

function move(tx, ty)
    local function dir(a, b) return (b - a) / math.max(1, math.abs(b - a)) end
    local function ease(t) return t * t * (3 - 2 * t) end  

    while true do
        if stopRequested then break end
        local x, y = GetLocal().pos.x // 32, GetLocal().pos.y // 32
        if x == tx and y == ty then break end
        local nx, ny = x + dir(x, tx), y + dir(y, ty)
        FindPath(nx, ny)
        Sleep(Settings.MoveDelay + ease(math.abs(nx - tx + ny - ty)) * 20)
    end
end

function GetDropped()
    for _, id in pairs(ingredients) do
        if inv(id) < 160 then
            for _, obj in pairs(GetObjectList()) do
                if obj.id == id then
                    move(obj.pos.x // 32, obj.pos.y // 32)
                    Sleep(300)
                    return GetDropped()
                end
            end
        end
    end
end

function DropArroz()
    for attempts = 1, 24 do
        if stopRequested then return end
        if inv(4604) >= 250 then
            Log("Dropping Arroz Attempt: ["..attempts.." / 24]")
            Drop(4604)
            Sleep(400)
        else
            return
        end
    end
    if inv(4604) >= 250 then
        Settings.DropPos[2] = Settings.DropPos[2] - 1
        move(Settings.DropPos[1], Settings.DropPos[2])
        Sleep(400)
        Drop(4604)
    end
end

function Log(x)
    LogToConsole("`0[`9Cook`0] "..x)
end

function Join(w)
    SendPacket(3, "action|join_request\nname|".. w .."|\ninvitedWorld|0")
end

-- Fungsi utama yang dijalankan di thread
local function runCooking()
    Oven = GetOven()
    if #Oven == 0 then
        Log("Tidak ada oven ditemukan!")
        running = false
        return
    end
    posx, posy = Oven[1][1], Oven[1][2]
    Log("Ditemukan " .. #Oven .. " oven")

    while running and not stopRequested do
        Sleep(Settings.CheckInterval)

        if GetWorld() == nil or GetWorld().name ~= World then
            Log("Disconnected!? Trying to reconnect..")
            Join(World)
            Sleep(4000)
            dc = true
        end

        if inv(4604) >= 250 then
            move(Settings.DropPos[1], Settings.DropPos[2])
            Sleep(500)
            DropArroz()
            Sleep(500)
            move(posx, posy)
            Sleep(500)
            Main()
            Sleep(300)
        end

        for _, ing in pairs(ingredients) do
            if stopRequested then break end
            local co = inv(ing)
            if co < 148 then
                GetDropped()
            end
        end

        if dc then
            move(posx, posy)
            Sleep(700)
            PlaceIngredient(18, 300)
            Sleep(500)
            Main()
            Sleep(1000)
            dc = false
        end

        if (GetLocal().pos.x // 32 ~= posx) or (GetLocal().pos.y // 32 ~= posy) then
            move(posx, posy)
            Sleep(500)
        end

        Main()
    end

    running = false
    currentStatus = "Stopped"
    Log("Cooking stopped")
end

-- Fungsi start/stop
local function startCooking()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runCooking)
end

local function stopCooking()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- Fungsi Save/Load
local function SaveSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/COOK_SETTINGS.txt", "w")
    if file then
        file:write("DropX=" .. Settings.DropPos[1] .. "\n")
        file:write("DropY=" .. Settings.DropPos[2] .. "\n")
        file:write("MoveDelay=" .. Settings.MoveDelay .. "\n")
        file:write("PlaceDelay=" .. Settings.PlaceDelay .. "\n")
        file:write("Place2Delay=" .. Settings.Place2Delay .. "\n")
        file:write("OpenDelay=" .. Settings.OpenDelay .. "\n")
        file:write("CheckInterval=" .. Settings.CheckInterval .. "\n")
        file:close()
        Log("`2Settings saved.")
    else
        Log("`4Failed to save settings.")
    end
end

local function LoadSettings()
    local file = io.open("storage/emulated/0/android/media/com.rtsoft.growtopia/scripts/COOK_SETTINGS.txt", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                if key == "DropX" then Settings.DropPos[1] = tonumber(value)
                elseif key == "DropY" then Settings.DropPos[2] = tonumber(value)
                elseif key == "MoveDelay" then Settings.MoveDelay = tonumber(value)
                elseif key == "PlaceDelay" then Settings.PlaceDelay = tonumber(value)
                elseif key == "Place2Delay" then Settings.Place2Delay = tonumber(value)
                elseif key == "OpenDelay" then Settings.OpenDelay = tonumber(value)
                elseif key == "CheckInterval" then Settings.CheckInterval = tonumber(value)
                end
            end
        end
        file:close()
        Log("`2Settings loaded.")
    else
        Log("`3No settings file found, using defaults.")
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "CookGUI", function(dt)
    if ImGui.Begin("Auto Cooking Oven - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("CookTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()

                ImGui.Text("Drop Position:")
                local changedDropX, newDropX = ImGui.InputInt("Drop X", Settings.DropPos[1], 1, 10)
                if changedDropX then Settings.DropPos[1] = newDropX end
                local changedDropY, newDropY = ImGui.InputInt("Drop Y", Settings.DropPos[2], 1, 10)
                if changedDropY then Settings.DropPos[2] = newDropY end

                ImGui.Text("Delays (ms):")
                local changedMove, newMove = ImGui.InputInt("Move Delay", Settings.MoveDelay, 1, 10)
                if changedMove then Settings.MoveDelay = newMove end
                local changedPlace, newPlace = ImGui.InputInt("Place Delay", Settings.PlaceDelay, 10, 100)
                if changedPlace then Settings.PlaceDelay = newPlace end
                local changedPlace2, newPlace2 = ImGui.InputInt("Place2 Delay", Settings.Place2Delay, 10, 100)
                if changedPlace2 then Settings.Place2Delay = newPlace2 end
                local changedOpen, newOpen = ImGui.InputInt("Open Delay", Settings.OpenDelay, 10, 100)
                if changedOpen then Settings.OpenDelay = newOpen end
                local changedCheck, newCheck = ImGui.InputInt("Check Interval", Settings.CheckInterval, 100, 1000)
                if changedCheck then Settings.CheckInterval = newCheck end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Cooking", 150, 30) then
                        startCooking()
                    end
                else
                    if ImGui.Button("Stop Cooking", 150, 30) then
                        stopCooking()
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
                ImGui.Text("Oven Ditemukan: " .. #(Oven or {}))
                ImGui.Text("Arroz: " .. inv(4604))
                ImGui.Text("Rice: " .. inv(3472))
                ImGui.Text("Ingredient 4602: " .. inv(4602))
                ImGui.Text("Ingredient 962: " .. inv(962))
                ImGui.Text("Ingredient 4570: " .. inv(4570))
                ImGui.Text("Ingredient 4568: " .. inv(4568))
                ImGui.Text("Ingredient 4588: " .. inv(4588))
                ImGui.EndTabItem()
            end

            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Original script by Lantas")
                ImGui.Text("Modified by Ertoxz")
                ImGui.Text("GUI by Ertoxz")
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

-- Load settings saat start
LoadSettings()
Log("Auto Cooking Oven loaded. Use GUI to start.")
