-- Tambahkan di bagian atas script (setelah Settings, sebelum fungsi-fungsi)
local running = false
local stopRequested = false
local currentStatus = "Idle"

-- Fungsi untuk memulai script
local function startCooking()
    if running then return end
    running = true
    stopRequested = false
    currentStatus = "Starting..."
    RunThread(function()
        -- Loop utama yang dimodifikasi
        while running and not stopRequested do
            if GetWorld() == nil or GetWorld().name ~= World then
                Log("Disconnected!? Trying to reconnect..")
                Join(World)
                Sleep(5000)
                dc = true
            end
            if inv(4604) >= 250 then
                move(Settings.DropPos[1], Settings.DropPos[2])
                Sleep(500)
                DropArroz()
                Sleep(500)
            end
            for _, ing in pairs(ingredients) do
                if not running then break end
                local co = inv(ing)
                if co < 100 and Settings.Ingredient.Take then
                    currentStatus = "Taking dropped ingredients"
                    GetDropped()
                elseif co < 60 and Settings.Ingredient.BuyPack then      
                    currentStatus = "Buying cooking pack"
                    BuyPack()
                elseif co < 100 and Settings.Ingredient.Make then
                    currentStatus = "Making ingredients"
                    MakeIngredient()
                end
                if inv(3472) < 50 then
                    find(3472)
                end
            end
            if dc then
                PlaceIngredient(18, 300)
                Sleep(500)
                dc = false
            end
            Sleep(500)
            move(posx, posy)
            Sleep(450)
            currentStatus = "Cooking"
            Main()
        end
        running = false
        currentStatus = "Stopped"
        Log("Cooking stopped")
    end)
end

local function stopCooking()
    if running then
        stopRequested = true
        currentStatus = "Stopping..."
    end
end

-- ==================== GUI ====================
AddHook("OnDraw", "CookingGUI", function(dt)
    if ImGui.Begin("Auto Cooking - Ertoxz", nil, ImGuiWindowFlags_NoCollapse) then
        if ImGui.BeginTabBar("CookingTabs") then
            -- MAIN TAB
            if ImGui.BeginTabItem("Main") then
                ImGui.Text("Settings")
                ImGui.Separator()
                
                ImGui.Text("Drop Position:")
                local changedDropX, newDropX = ImGui.InputInt("Drop X", Settings.DropPos[1], 1, 10)
                if changedDropX then Settings.DropPos[1] = newDropX end
                local changedDropY, newDropY = ImGui.InputInt("Drop Y", Settings.DropPos[2], 1, 10)
                if changedDropY then Settings.DropPos[2] = newDropY end
                
                ImGui.Separator()
                ImGui.Text("Ingredient Options:")
                
                local changedTake, newTake = ImGui.Checkbox("Auto Take Dropped", Settings.Ingredient.Take)
                if changedTake then Settings.Ingredient.Take = newTake end
                
                local changedBuy, newBuy = ImGui.Checkbox("Auto Buy Cooking Pack", Settings.Ingredient.BuyPack)
                if changedBuy then Settings.Ingredient.BuyPack = newBuy end
                
                local changedMake, newMake = ImGui.Checkbox("Auto Make Ingredient", Settings.Ingredient.Make)
                if changedMake then Settings.Ingredient.Make = newMake end
                
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
                
                ImGui.EndTabItem()
            end
            
            -- SETTINGS TAB (untuk pengaturan lanjutan)
            if ImGui.BeginTabItem("Settings") then
                ImGui.Text("Advanced Settings")
                ImGui.Separator()
                
                -- Tampilkan ID item yang digunakan
                ImGui.Text("Ingredient IDs:")
                for i, id in ipairs(ingredients) do
                    ImGui.Text("  " .. i .. ": " .. id)
                end
                
                ImGui.Text("Trash IDs:")
                for i, id in ipairs(trsh) do
                    ImGui.Text("  " .. i .. ": " .. id)
                end
                
                ImGui.Separator()
                ImGui.Text("Oven IDs:")
                local ovenList = ""
                for id,_ in pairs(ovenid) do
                    ovenList = ovenList .. id .. " "
                end
                ImGui.TextWrapped(ovenList)
                
                ImGui.EndTabItem()
            end
            
            -- STATUS TAB
            if ImGui.BeginTabItem("Status") then
                ImGui.Text("Current Status: " .. currentStatus)
                ImGui.Separator()
                
                -- Tampilkan inventory item-item penting
                ImGui.Text("Inventory:")
                local items = {
                    { name = "Arroz", id = 4604 },
                    { name = "Ingredient 1", id = 4602 },
                    { name = "Ingredient 2", id = 962 },
                    { name = "Rice", id = 3472 },
                    { name = "Ground 1", id = 4570 },
                    { name = "Ground 2", id = 4568 },
                    { name = "Cut", id = 4588 },
                }
                
                ImGui.Columns(2, "invCols")
                ImGui.Text("Item"); ImGui.NextColumn()
                ImGui.Text("Jumlah"); ImGui.NextColumn()
                ImGui.Separator()
                
                for _, item in ipairs(items) do
                    ImGui.Text(item.name); ImGui.NextColumn()
                    ImGui.Text(tostring(inv(item.id))); ImGui.NextColumn()
                end
                ImGui.Columns(1)
                
                ImGui.Separator()
                ImGui.Text("Oven ditemukan: " .. #(GetOven() or {}))
                
                ImGui.EndTabItem()
            end
            
            -- CREDITS TAB
            if ImGui.BeginTabItem("Credits") then
                ImGui.Text("Auto Cooking Script")
                ImGui.Text("Original by Lantas")
                ImGui.Text("Modified by Ertoxz")
                ImGui.Text("GUI by Ertoxz")
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)

Log("Auto Cooking GUI loaded. Use GUI to start/stop.")
