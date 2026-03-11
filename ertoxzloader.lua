-- ERTOXZ Loader - Super Simple (FIXED)
-- Simpan sebagai "ertoxz_loader.lua", lalu jalankan.

-- Fungsi untuk mengambil dan menjalankan script dari URL
local function run(url)
    -- Jalankan di thread agar tidak mengganggu GUI
    RunThread(function()
        local response = MakeRequest(url, "GET", {["User-Agent"] = "Mozilla/5.0"})
        if response and response.status == 200 then
            local func, err = loadstring(response.content)
            if func then
                pcall(func)
            else
                LogToConsole("`4Error: " .. tostring(err))
            end
        else
            LogToConsole("`4Gagal mengambil script dari: " .. url)
        end
    end)
end

AddHook("OnDraw", "ErtoxzGUI", function()
    if ImGui.Begin("ERTOXZ Loader") then
        ImGui.Text("Pilih fitur:")
        ImGui.Separator()
        
        if ImGui.Button("PUT / BREAK PLAT", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/putbreak.lua")
        end
        if ImGui.Button("AUTO PTHT", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/ptht.lua")
        end
        if ImGui.Button("AUTO GEIGER", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/geiger.lua")
        end
        if ImGui.Button("AUTO GRINDER", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/grinder.lua")
        end
        if ImGui.Button("AUTO COMBINE", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/combine.lua")
        end
        if ImGui.Button("AUTO HT PROVIDER", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/harvestprovider.lua")
        end
        if ImGui.Button("AUTO SB", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/sb.lua")
        end
        if ImGui.Button("AUTO SHATTER", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/shatter.lua")
        end
        if ImGui.Button("AUTO SURG", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/surg.lua")
        end
        if ImGui.Button("AUTO COOK ARROZ", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/arroz.lua")
        end
        if ImGui.Button("AUTO PnB", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/pnb.lua")
        end
        if ImGui.Button("AUTO SPTHT", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/sptht.lua")
        end
    end
    ImGui.End()
end)

LogToConsole("ERTOXZ Loader siap. Klik tombol untuk menjalankan fitur.")