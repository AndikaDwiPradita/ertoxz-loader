-- ==================== SHATTER CRYSTAL - DENGAN GUI ====================

local ID = { 858, 5746, 460, 4, 6030, 822, 4634 }
local ID1, ID2, ID3, ID4, ID5, ID6, ID7 = 858, 5746, 460, 4, 6030, 822, 4634
local R, G, B, W = 2242, 2244, 2246, 2248

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"
local posx, posy = 0, 0

-- Fungsi pendukung
function Log(x)
    LogToConsole("`0[`9Shatter`0] " .. x)
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

function raw(t, s, v, x, y)
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

function find()
    for _, cr in pairs(ID) do
        local co = inv(cr)
        if co < 10 then
            SendPacket(2, "action|dialog_return\ndialog_name|item_search\n" .. cr .. "|1")
            Sleep(300)
            return find()
        end
    end
end

function shatter()
    find()
    Sleep(300)
    raw(0, 32, 0, posx, posy - 2)
    Sleep(150)
    raw(3, 0, ID4, posx - 1, posy - 1)
    Sleep(150)
    raw(3, 0, ID1, posx, posy - 1)
    Sleep(150)
    raw(3, 0, ID6, posx, posy - 1)
    Sleep(150)
    raw(3, 0, ID7, posx + 1, posy - 1)
    Sleep(150)
    raw(3, 0, ID2, posx + 1, posy - 2)
    Sleep(150)
    raw(3, 0, ID6, posx + 1, posy - 2)
    Sleep(150)
    raw(3, 0, ID2, posx + 1, posy - 3)
    Sleep(150)
    raw(3, 0, ID6, posx + 1, posy - 3)
    Sleep(150)
    raw(3, 0, ID4, posx, posy - 3)
    Sleep(150)
    raw(3, 0, ID6, posx, posy - 3)
    Sleep(150)
    raw(3, 0, ID3, posx - 1, posy - 3)
    Sleep(150)
    raw(3, 0, ID6, posx - 1, posy - 3)
    Sleep(150)
    raw(3, 0, ID3, posx - 1, posy - 2)
    Sleep(150)
    raw(3, 0, ID5, posx - 1, posy - 2)
    Sleep(150)
    raw(3, 0, 18, posx, posy - 2)
    Sleep(150)
end

-- Fungsi utama (dipanggil oleh thread)
local function runShatter(mode)
    posx = GetLocal().pos.x // 32
    posy = GetLocal().pos.y // 32
    Log("Making " .. (mode == 1 and "Crystal Gate" or "Shifty Block"))
    Sleep(500)
    if mode == 1 then
        raw(3, 0, R, posx, posy - 2)
        Sleep(150)
        raw(3, 0, R, posx, posy - 2)
        Sleep(150)
        raw(3, 0, R, posx, posy - 2)
        Sleep(150)
        raw(3, 0, B, posx, posy - 2)
        Sleep(150)
        raw(3, 0, W, posx, posy - 2)
        Sleep(300)
        shatter()
    elseif mode == 2 then
        raw(3, 0, W, posx, posy - 2)
        Sleep(150)
        raw(3, 0, R, posx, posy - 2)
        Sleep(150)
        raw(3, 0, R, posx, posy - 2)
        Sleep(150)
        raw(3, 0, G, posx, posy - 2)
        Sleep(150)
        raw(3, 0, B, posx, posy - 2)
        Sleep(300)
        shatter()
    end
end

-- Fungsi start/stop (sebenarnya tidak perlu thread karena satu kali eksekusi, tapi kita beri kontrol)
local function startShatter(mode)
    if running then return end
    running = true
    currentStatus = "Running"
    RunThread(function()
        runShatter(mode)
        running = false
        currentStatus = "Finished"
    end)
end

local function stopShatter()
    if running then
        stopRequested = true
        -- Tidak bisa menghentikan proses yang sedang berjalan, tapi kita set running false
        running = false
        currentStatus = "Stopped"
    end
end

-- ==================== HOOKS ====================
AddHook("onsendpacket", "shatter_hook", function(type, packet)
    if packet:find("action|input\n|text|/1") then
        startShatter(1)
        return true
    end
    if packet:find("action|input\n|text|/2") then
        startShatter(2)
        return true
    end
    return false
end)

-- ==================== GUI ====================
AddHook("OnDraw", "ShatterGUI", function(dt)
    if ImGui.Begin("Shatter Crystal - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("ShatterTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Manual Execution")
                ImGui.Separator()
                if ImGui.Button("Make Crystal Gate (/1)", 200, 30) then
                    startShatter(1)
                end
                if ImGui.Button("Make Shifty Block (/2)", 200, 30) then
                    startShatter(2)
                end
                if running then
                    if ImGui.Button("Stop", 200, 30) then
                        stopShatter()
                    end
                end
                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Position: " .. posx .. ", " .. posy)
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

Log("Shatter script loaded. Use GUI or /1 /2 commands.")
