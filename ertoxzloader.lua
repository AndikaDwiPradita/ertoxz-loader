-- ERTOXZ Loader - Super Simple
-- Simpan sebagai "ertoxz_loader.lua", lalu jalankan.

local function run(url)
    -- Jalankan di thread agar tidak mengganggu GUI
    RunThread(function()
        load(MakeRequest(url).content)()
    end)
end

AddHook("OnDraw", "ErtoxzGUI", function()
    if ImGui.Begin("ERTOXZ Loader") then
        ImGui.Text("Pilih fitur:")
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
        if ImGui.Button("AUTO ARROZ", 200, 40) then
            run("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/arroz.lua")
        end
            
    end
    ImGui.End()
end)

LogToConsole("Loader siap. Klik tombol untuk menjalankan fitur.")
