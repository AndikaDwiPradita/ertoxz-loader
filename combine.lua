-- Tambahkan di bagian atas script (setelah variabel global)
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi untuk memulai proses
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

-- ==================== GUI ====================
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
                
                -- Tampilkan inventory
                ImGui.Text("Inventory:")
                ImGui.Columns(3, "invCols")
                ImGui.Text("Item ID"); ImGui.NextColumn()
                ImGui.Text("Name"); ImGui.NextColumn()
                ImGui.Text("Jumlah"); ImGui.NextColumn()
                ImGui.Separator()
                
                -- Tampilkan Recipes
                for _, id in ipairs(Recipes) do
                    local info = GetItemByIDSafe(id)
                    local name = info and info.name or "Unknown"
                    ImGui.Text(tostring(id)); ImGui.NextColumn()
                    ImGui.Text(name); ImGui.NextColumn()
                    ImGui.Text(tostring(GetItemCount(id))); ImGui.NextColumn()
                end
                
                -- Tampilkan Item utama
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

-- Modifikasi loop utama (ganti bagian while true do ... end)
-- Hapus atau komentari loop yang lama, lalu gunakan ini:
-- while true do
--     ch()
--     if running and not stopRequested then
--         GetDropped()
--         Sleep(700)
--         if running and not stopRequested then
--             Main()
--         end
--     else
--         Sleep(1000)
--     end
-- end

Log("Recipe Processor GUI loaded. Use GUI to start/stop.")
