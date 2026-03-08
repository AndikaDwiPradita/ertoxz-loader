-- ==================== SURGERY AUTO - DENGAN GUI ====================

Toool = { 1270, 1240, 1256, 1258, 1260, 1262, 1264, 1266, 1268 }

-- Variabel global
surgid = nil
surging = false
t = false
mvp = false
Totalsurg = 0
tool = ""

-- Variabel kontrol
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi pendukung
function Log(x)
    LogToConsole("`0[`9Surg`0] " .. x)
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

function Trash(ID)
    SendPacket(2, "action|dialog_return\ndialog_name|trash\nitem_trash|" .. ID .. "|\nitem_count|" .. inv(ID) - 80 .. "\n")
end

function BuyPack()
    for _, to in pairs(Toool) do
        local co = inv(to)
        if t and co > 240 then
            Sleep(200)
            Trash(to)
            Sleep(500)
            return BuyPack()
        end
    end
    for _, t0 in pairs(Toool) do
        if inv(t0) < 150 then
            SendPacket(2, "action|buy\nitem|buy_surgkit")
            Sleep(75)
            return BuyPack()
        end
    end
end

function auto()
    local tools_map = {
        Sponge = "command_0",
        Scalpel = "command_1",
        Anesthetic = "command_2",
        Antiseptic = "command_3",
        Antibiotics = "command_4",
        Splint = "command_5",
        Stitches = "command_6",
        ["Fix It!"] = "command_7"
    }
    local cmd = tools_map[tool]
    if cmd then
        SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|" .. cmd)
        Log("Used " .. tool)
    end
end

function cleanNickname(nickname)
    nickname = nickname:gsub("[%d+_`#w@]", "")
    nickname = nickname:gsub("%[.-%]", "")
    nickname = nickname:match("^%s*(.-)%s*$")
    return nickname
end

-- Fungsi utama yang dijalankan di thread
local function runSurg()
    while running and not stopRequested do
        Sleep(1000)
        if inv(1270) < 40 and not surging or t then
            BuyPack()
            t = false
        end

        if not surging and surgid then
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. surgid .. "|\nbuttonClicked|surgery")
            surging = true
        end
    end
    running = false
    currentStatus = "Stopped"
    Log("Surgery stopped")
end

local function startSurg()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Running"
    RunThread(runSurg)
    Log("Surgery started")
end

local function stopSurg()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== HOOKS ====================
AddHook("onsendpacket", "surg_hook", function(type, packet)
    if packet:find("action|input\n|text|/bp") then
        Log("Buying Surgical Pack...")
        t = true
        return true
    end
    if packet:find("action|wrench\n|netid|(%d+)") then
        surgid = packet:match("action|wrench\n|netid|(%d+)")
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. surgid .. "|\nbuttonClicked|surgery")
        surging = true
        return true
    end
    return false
end)

AddHook("OnVariant", "surg_variant", function(var)
    if var[0] == "OnNameChanged" then
        local j = cleanNickname(var[1])
        if j == cleanNickname(GetLocal().name) then
            mvp = true
        end
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("You are not") then
        RunThread(function()
            Sleep(500)
            Log("Failed")
            if mvp then
                SendPacket(2, "action|input\n|text|/modage 999")
            elseif not mvp then
                Raw(10, 0, 3172, 0, 0)
            end
            surging = false
            Sleep(2000)
        end)
        return true
    elseif var[0] == "OnDialogRequest" and var[1]:find("Anatomical") then
        local x = var[1]:match("|x|(%d+)")
        local y = var[1]:match("|y|(%d+)")
        SendPacket(2, "action|dialog_return\n|dialog_name|surge_edit\nx|" .. x .. "|\ny|" .. y .. "|")
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("`4You can't see what you are doing") and var[1]:find("command_0") then
        tool = "Sponge"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("`6It is becoming hard to see your work") and var[1]:find("command_0") then
        tool = "Sponge"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Patient's fever is `3slowly rising") and var[1]:find("command_4") then
        tool = "Antibiotics"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Patient's fever is `6climbing") and var[1]:find("command_4") then
        tool = "Antibiotics"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Incisions: `60") and var[1]:find("command_7") then
        tool = "Fix It!"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Incisions: `30") and var[1]:find("command_7") then
        tool = "Fix It!"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("command_7") and not var[1]:find("Incisions: 0") then
        tool = "Fix It!"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Operation site: `4Unsanitary") and var[1]:find("command_3") then
        tool = "Antiseptic"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Status: `4Awake!") and var[1]:find("command_2") then
        tool = "Anesthetic"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Patient is losing blood `4very quickly!") and var[1]:find("command_6") then
        tool = "Stitches"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Patient is losing blood `3slowly") and var[1]:find("command_6") then
        tool = "Stitches"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("Patient is `6losing blood!") and var[1]:find("command_6") then
        tool = "Stitches"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("command_7") and var[1]:find("command_6") then
        tool = "Stitches"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("command_7") and var[1]:find("Incisions: 0") then
        tool = "Stitches"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("command_7") and var[1]:find("command_1") then
        tool = "Scalpel"
        auto()
        return true
    elseif var[0]:find("OnDialogRequest") and var[1]:find("command_1") then
        tool = "Scalpel"
        auto()
        return true
    end
    if var[0] == "OnTalkBubble" and var[1] == GetLocal().netid then
        surging = false
        Totalsurg = (Totalsurg or 0) + 1
        Log("Surgery completed. Total: " .. Totalsurg)
        return true
    end
    return false
end)

-- ==================== GUI ====================
AddHook("OnDraw", "SurgGUI", function(dt)
    if ImGui.Begin("Surgery Auto - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("SurgTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                if not running then
                    if ImGui.Button("Start Surgery", 150, 30) then
                        startSurg()
                    end
                else
                    if ImGui.Button("Stop Surgery", 150, 30) then
                        stopSurg()
                    end
                end
                ImGui.EndTabItem()
            end

            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                ImGui.Text("Total Surgeries: " .. Totalsurg)
                ImGui.Text("Surging: " .. tostring(surging))
                ImGui.Text("Current Tool: " .. tool)
                ImGui.Text("Inventory 1270: " .. inv(1270))
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("Surgery script loaded. Use GUI to start.")
