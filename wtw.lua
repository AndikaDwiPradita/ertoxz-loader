-- ==================== WORLD TRANSFER (WTW) - DENGAN GUI ====================

-- [ KONFIGURASI AWAL ] --
World = {
  From = "LANTEST777", 
  To = "LANTEST888",
}

ITEM_ID = 10

Mode = {
  From = {
    Vend = false, 
    Mag = false, 
    Drop = true,
  },
  To = {
    Vend = false,
    Mag = false,
    Drop = true,
  },
}

MainSettings = {
  From = {
    MagBG = 14,
    VendPos = { 10, 24 },
  },
  To = {
    MagBG = 14,
    VendPos = { 49, 24}, 
    PosDrop = { 49, 24 },
  },
  Delay = 2000,
}

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi pendukung
function Log(x)
    LogToConsole("`0[`9WTW`0] " .. x)
end

function Join(w)
    SendPacket(3, "action|join_request\nname|" .. w .. "|\ninvitedWorld|0")
end

function inv(id)
    local count = 0
    for _, itm in pairs(GetInventory()) do
        if itm.id == id then
            count = count + itm.amount
        end
    end
    return count
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

function move(tx, ty)
    local function dir(a, b) return (b - a) / math.max(1, math.abs(b - a)) end
    local function ease(t) return t * t * (3 - 2 * t) end

    while not stopRequested do
        local x, y = GetLocal().pos.x // 32, GetLocal().pos.y // 32
        if x == tx and y == ty then break end
        local nx, ny = x + dir(x, tx), y + dir(y, ty)
        FindPath(nx, ny)
        Sleep(30 + ease(math.abs(nx - tx + ny - ty)) * 20)
    end
end

function GetFloat(id)
    for _, itm in pairs(GetObjectList()) do
        if itm.id == id and inv(id) < 50 then
            move(itm.pos.x // 32, itm.pos.y // 32)
            Sleep(500)
            return GetFloat(id)
        end
    end
end

function mag(bg)
    for _, tile in pairs(GetTiles()) do
        if tile.fg == 5638 and tile.bg == bg then
            Raw(0, 0, 0, tile.x, tile.y)
            Sleep(500)
            Raw(3, 0, 32, tile.x, tile.y)
            Sleep(350)
            SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. tile.x .. "|\ny|" .. tile.y .. "|\nbuttonClicked|additems")
        end
    end
end

function mag2(bg)
    for _, tile in pairs(GetTiles()) do
        if tile.fg == 5638 and tile.bg == bg then
            Raw(0, 0, 0, tile.x, tile.y)
            Sleep(500)
            Raw(3, 0, 32, tile.x, tile.y)
            Sleep(350)
            SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. tile.x .. "|\ny|" .. tile.y .. "|\nbuttonClicked|withdraw")
        end
    end
end

function drop()
    for attempts = 0, 6 do
        if inv(ITEM_ID) >= 250 then
            Log("Dropping Attempt: [" .. attempts .. " / 6]")
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ITEM_ID .. "|\nitem_count|" .. inv(ITEM_ID))
            Sleep(300)
        end
    end
    if inv(ITEM_ID) >= 250 then
        MainSettings.To.PosDrop[1] = MainSettings.To.PosDrop[1] + 1
        move(MainSettings.To.PosDrop[1], MainSettings.To.PosDrop[2])
        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ITEM_ID .. "|\nitem_count|" .. inv(ITEM_ID))
        Sleep(400)
    end
end

-- Fungsi-fungsi mode
function drop_setting()
    if Mode.From.Drop and Mode.To.Drop then
        if GetWorld().name == World.From then
            Sleep(MainSettings.Delay)
            GetFloat(ITEM_ID)
            Sleep(300)
            GetFloat(ITEM_ID)
            Sleep(700)
            Join(World.To)
            Sleep(MainSettings.Delay)
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            Sleep(250)
            move(MainSettings.To.PosDrop[1], MainSettings.To.PosDrop[2])
            Sleep(250)
            drop()
            Sleep(250)
            Join(World.From)
            Sleep(MainSettings.Delay)
        else
            Join(World.To)
            Sleep(MainSettings.Delay)
        end
    end
    if Mode.From.Drop and Mode.To.Mag then
        if GetWorld().name == World.From then
            Sleep(MainSettings.Delay)
            GetFloat(ITEM_ID)
            Sleep(700)
            Join(World.To)
            Sleep(MainSettings.Delay)
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            if inv(ITEM_ID) > 0 then
                Sleep(400)
                mag(MainSettings.To.MagBG)
                Sleep(200)
                Join(World.From)
                Sleep(MainSettings.Delay)
            end
        else
            Join(World.To)
            Sleep(MainSettings.Delay)
        end
    end
    if Mode.From.Drop and Mode.To.Vend then
        if GetWorld().name == World.From then
            Sleep(MainSettings.Delay)
            GetFloat(ITEM_ID)
            Sleep(500)
            if inv(ITEM_ID) > 0 then
                Join(World.To)
                Sleep(MainSettings.Delay)
            end
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            Sleep(MainSettings.Delay)
            local tile = GetTile(MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
            if tile and (tile.fg == 2978 or tile.fg == 9268) then
                move(MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
                Sleep(300)
                Raw(3, 0, 32, MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
                Sleep(200)
                SendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|" .. MainSettings.To.VendPos[1] .. "|\ny|" .. MainSettings.To.VendPos[2] .. "|\nbuttonClicked|addstock")
                Sleep(350)
                Join(World.From)
                Sleep(MainSettings.Delay)
            else
                LogToConsole("`2PLEASE PUT CORRECT CORD OF VENDING MACHINE")
            end
        else
            if GetWorld().name ~= World.To then
                Join(World.To)
                Sleep(MainSettings.Delay)
            end
        end
    end
end

function vend_setting()
    if Mode.From.Vend and Mode.To.Drop then
        if GetWorld().name == World.From then
            local tile = GetTile(MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
            if tile and (tile.fg == 2978 or tile.fg == 9268) then
                Sleep(MainSettings.Delay)
                move(MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
                Sleep(300)
                Raw(3, 0, 32, MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
                Sleep(200)
                SendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|" .. MainSettings.From.VendPos[1] .. "|\ny|" .. MainSettings.From.VendPos[2] .. "|\nbuttonClicked|pullstock")
                Sleep(200)
                Join(World.To)
                Sleep(MainSettings.Delay)
            else
                LogToConsole("`bPlease Put Correct Cord Of Vending Machine")
            end
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            Sleep(450)
            move(MainSettings.To.PosDrop[1], MainSettings.To.PosDrop[2])
            Sleep(200)
            drop()
            Sleep(200)
            Join(World.From)
            Sleep(MainSettings.Delay)
        else
            Join(World.To)
            Sleep(MainSettings.Delay)
        end
    end
    if Mode.From.Vend and Mode.To.Vend then
        if GetWorld().name == World.From then
            local tile = GetTile(MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
            if tile and (tile.fg == 2978 or tile.fg == 9268) then
                Sleep(500)
                move(MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
                Sleep(300)
                Raw(3, 0, 32, MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
                Sleep(200)
                SendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|" .. MainSettings.From.VendPos[1] .. "|\ny|" .. MainSettings.From.VendPos[2] .. "|\nbuttonClicked|pullstock")
                Sleep(200)
                Join(World.To)
                Sleep(MainSettings.Delay)
            else
                LogToConsole("`bPLEASE PUT CORRECT CORD OF VENDING MACHINE")
            end
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            local tile = GetTile(MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
            if tile and (tile.fg == 2978 or tile.fg == 9268) then
                move(MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
                Sleep(300)
                Raw(3, 0, 32, MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
                Sleep(200)
                SendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|" .. MainSettings.To.VendPos[1] .. "|\ny|" .. MainSettings.To.VendPos[2] .. "|\nbuttonClicked|addstock")
                Sleep(200)
                Join(World.From)
                Sleep(MainSettings.Delay)
            else
                LogToConsole("`bPLEASE PUT CORRECT CORD OF VENDING MACHINE")
            end
        else
            if GetWorld().name ~= World.To then
                Join(World.To)
                Sleep(MainSettings.Delay)
            end
        end
    end
    if Mode.From.Vend and Mode.To.Mag then
        if GetWorld().name == World.From then
            local tile = GetTile(MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
            if tile and (tile.fg == 2978 or tile.fg == 9268) then
                move(MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
                Sleep(300)
                Raw(3, 0, 32, MainSettings.From.VendPos[1], MainSettings.From.VendPos[2])
                Sleep(200)
                SendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|" .. MainSettings.From.VendPos[1] .. "|\ny|" .. MainSettings.From.VendPos[2] .. "|\nbuttonClicked|pullstock")
                Sleep(200)
                Join(World.To)
                Sleep(MainSettings.Delay)
            else
                LogToConsole("`bPLEASE PUT CORRECT CORD OF VENDING MACHINE")
            end
        else
            if GetWorld().name ~= World.From then
                Join(World.From)
                Sleep(MainSettings.Delay)
            end
        end
        if GetWorld().name == World.To then
            Sleep(300)
            mag(MainSettings.To.MagBG)
            Sleep(300)
            Join(World.From)
            Sleep(MainSettings.Delay)
        else
            Join(World.To)
            Sleep(MainSettings.Delay)
        end
    end
end

function mag_setting()
    if Mode.From.Mag and Mode.To.Drop then
        if GetWorld().name == World.From then
            Sleep(MainSettings.Delay)
            mag2(MainSettings.From.MagBG)
            Sleep(200)
            Join(World.To)
            Sleep(MainSettings.Delay)
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            Sleep(MainSettings.Delay)
            move(MainSettings.To.PosDrop[1], MainSettings.To.PosDrop[2])
            Sleep(200)
            drop()
            Sleep(250)
            Join(World.From)
            Sleep(MainSettings.Delay)
        else
            Join(World.To)
            Sleep(MainSettings.Delay)
        end
    end
    if Mode.From.Mag and Mode.To.Vend then
        if GetWorld().name == World.From then
            Sleep(MainSettings.Delay)
            mag2(MainSettings.From.MagBG)
            Sleep(200)
            Join(World.To)
            Sleep(MainSettings.Delay)
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            Sleep(MainSettings.Delay)
            local tile = GetTile(MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
            if tile and (tile.fg == 2978 or tile.fg == 9268) then
                move(MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
                Sleep(300)
                Raw(3, 0, 32, MainSettings.To.VendPos[1], MainSettings.To.VendPos[2])
                Sleep(200)
                SendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|" .. MainSettings.To.VendPos[1] .. "|\ny|" .. MainSettings.To.VendPos[2] .. "|\nbuttonClicked|addstock")
                Sleep(200)
                Join(World.From)
            else
                LogToConsole("`bPLEASE PUT CORRECT CORD OF VENDING MACHINE")
            end
        else
            Join(World.To)
            Sleep(MainSettings.Delay)
        end
    end
    if Mode.From.Mag and Mode.To.Mag then
        if GetWorld().name == World.From then
            Sleep(MainSettings.Delay)
            mag2(MainSettings.From.MagBG)
            Sleep(200)
            Join(World.To)
            Sleep(MainSettings.Delay)
        else
            Join(World.From)
            Sleep(MainSettings.Delay)
        end
        if GetWorld().name == World.To then
            Sleep(MainSettings.Delay)
            mag(MainSettings.To.MagBG)
            Sleep(200)
            Join(World.From)
            Sleep(MainSettings.Delay)
        else
            Join(World.To)
            Sleep(MainSettings.Delay)
        end
    end
end

-- Fungsi utama yang dijalankan di thread
local function runWTW()
    while running and not stopRequested do
        Sleep(200)
        drop_setting()
        vend_setting()
        mag_setting()
    end
    running = false
    currentStatus = "Stopped"
    Log("WTW stopped")
end

local function startWTW()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runWTW)
    Log("WTW started")
end

local function stopWTW()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "WTWGUI", function(dt)
    if ImGui.Begin("World Transfer - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("WTWTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()

                ImGui.Text("World Names:")
                local changedFrom, newFrom = ImGui.InputText("From World", World.From, 30)
                if changedFrom then World.From = newFrom end
                local changedTo, newTo = ImGui.InputText("To World", World.To, 30)
                if changedTo then World.To = newTo end

                ImGui.Text("Item ID:")
                local changedItem, newItem = ImGui.InputInt("Item ID", ITEM_ID, 1, 100)
                if changedItem then ITEM_ID = newItem end

                ImGui.Text("Delay (ms):")
                local changedDelay, newDelay = ImGui.InputInt("Delay", MainSettings.Delay, 10, 100)
                if changedDelay then MainSettings.Delay = newDelay end

                ImGui.Text("From World Settings:")
                local changedFromMag, newFromMag = ImGui.InputInt("From Magplant BG", MainSettings.From.MagBG, 1, 100)
                if changedFromMag then MainSettings.From.MagBG = newFromMag end
                local changedFromVendX, newFromVendX = ImGui.InputInt("From Vend X", MainSettings.From.VendPos[1], 1, 10)
                if changedFromVendX then MainSettings.From.VendPos[1] = newFromVendX end
                local changedFromVendY, newFromVendY = ImGui.InputInt("From Vend Y", MainSettings.From.VendPos[2], 1, 10)
                if changedFromVendY then MainSettings.From.VendPos[2] = newFromVendY end

                ImGui.Text("To World Settings:")
                local changedToMag, newToMag = ImGui.InputInt("To Magplant BG", MainSettings.To.MagBG, 1, 100)
                if changedToMag then MainSettings.To.MagBG = newToMag end
                local changedToVendX, newToVendX = ImGui.InputInt("To Vend X", MainSettings.To.VendPos[1], 1, 10)
                if changedToVendX then MainSettings.To.VendPos[1] = newToVendX end
                local changedToVendY, newToVendY = ImGui.InputInt("To Vend Y", MainSettings.To.VendPos[2], 1, 10)
                if changedToVendY then MainSettings.To.VendPos[2] = newToVendY end
                local changedDropX, newDropX = ImGui.InputInt("Drop X", MainSettings.To.PosDrop[1], 1, 10)
                if changedDropX then MainSettings.To.PosDrop[1] = newDropX end
                local changedDropY, newDropY = ImGui.InputInt("Drop Y", MainSettings.To.PosDrop[2], 1, 10)
                if changedDropY then MainSettings.To.PosDrop[2] = newDropY end

                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start WTW", 150, 30) then
                        startWTW()
                    end
                else
                    if ImGui.Button("Stop WTW", 150, 30) then
                        stopWTW()
                    end
                end

                ImGui.EndTabItem()
            end

            -- MODE TAB
            if ImGui.BeginTabItem("Mode") then
                ImGui.Text("From World Modes:")
                local changedFromVend, newFromVend = ImGui.Checkbox("From Vend", Mode.From.Vend)
                if changedFromVend then Mode.From.Vend = newFromVend end
                local changedFromMag, newFromMagMode = ImGui.Checkbox("From Mag", Mode.From.Mag)
                if changedFromMag then Mode.From.Mag = newFromMagMode end
                local changedFromDrop, newFromDrop = ImGui.Checkbox("From Drop", Mode.From.Drop)
                if changedFromDrop then Mode.From.Drop = newFromDrop end

                ImGui.Text("To World Modes:")
                local changedToVend, newToVend = ImGui.Checkbox("To Vend", Mode.To.Vend)
                if changedToVend then Mode.To.Vend = newToVend end
                local changedToMag, newToMagMode = ImGui.Checkbox("To Mag", Mode.To.Mag)
                if changedToMag then Mode.To.Mag = newToMagMode end
                local changedToDrop, newToDrop = ImGui.Checkbox("To Drop", Mode.To.Drop)
                if changedToDrop then Mode.To.Drop = newToDrop end

                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Current World: " .. (GetWorld() and GetWorld().name or "nil"))
                ImGui.Text("Item Count: " .. inv(ITEM_ID))
                ImGui.EndTabItem()
            end

            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Script by Lantas")
                ImGui.Text("Modified by Ertoxz")
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("WTW script loaded. Use GUI to start.")
