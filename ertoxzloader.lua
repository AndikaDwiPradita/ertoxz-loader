-- ERTOXZ Loader - Super Simple GUI Loader
-- Simpan sebagai "ertoxz_loader.lua", lalu jalankan.

-- Daftar fitur dan URL-nya
local features = {
    { name = "PUT / BREAK PLAT", url = "https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/putbreak.lua" },
    { name = "AUTO PTHT",         url = "https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/ptht.lua" },
    { name = "AUTO GEIGER",       url = "https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/geiger.lua" },
    { name = "AUTO GRINDER",      url = "https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/grinder.lua" },
}

-- Fungsi untuk mengambil dan menjalankan script
local function runFeature(url)
    RunThread(function()
        LogToConsole("`2Mengambil script...")
        local response = MakeRequest(url, "GET", { ["User-Agent"] = "Mozilla/5.0" })
        if response and response.status == 200 then
            local fn, err = loadstring(response.content)
            if fn then
                pcall(fn)
            else
                LogToConsole("`4Gagal load: " .. tostring(err))
            end
        else
            LogToConsole("`4Gagal ambil script. Status: " .. tostring(response and response.status))
        end
    end)
end

-- GUI
AddHook("OnDraw", "ErtoxzLoader", function(dt)
    if ImGui.Begin("ERTOXZ Loader", nil, ImGuiWindowFlags_NoCollapse) then
        ImGui.Text("Pilih fitur:");
        ImGui.Separator()
        for _, f in ipairs(features) do
            if ImGui.Button(f.name, 200, 40) then
                runFeature(f.url)
            end
        end
    end
    ImGui.End()
end)

LogToConsole("`2ERTOXZ Loader siap. Klik tombol untuk menjalankan script.")
