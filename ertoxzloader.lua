-- ERTOXZ Loader - Multi-File Remote Loader
-- Simpan sebagai "ertoxz_loader.lua"

-- ==================== KONFIGURASI ====================
-- GANTI URL INI DENGAN RAW URL REPOSITORY KAMU
local baseUrl = "https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/"

-- ==================== FUNGSI LOADER ====================
local function loadAndRunScript(fileName)
    local url = baseUrl .. fileName
    LogToConsole("`2Mengambil " .. fileName .. " dari server...")
    
    local response = MakeRequest(url, "GET", {["User-Agent"] = "Mozilla/5.0"})
    
    if response and response.status == 200 then
        local scriptCode = response.content
        if scriptCode and scriptCode ~= "" then
            local func, err = loadstring(scriptCode)
            if func then
                LogToConsole("`2" .. fileName .. " berhasil dimuat. Menjalankan...")
                local success, runErr = pcall(func)
                if not success then
                    LogToConsole("`4Error saat menjalankan " .. fileName .. ": " .. tostring(runErr))
                end
            else
                LogToConsole("`4Gagal memuat " .. fileName .. ": " .. tostring(err))
            end
        else
            LogToConsole("`4Konten " .. fileName .. " kosong!")
        end
    else
        local status = response and response.status or "no response"
        LogToConsole("`4Gagal mengambil " .. fileName .. " (status: " .. tostring(status) .. ")")
        LogToConsole("`7Pastikan URL benar: " .. url)
    end
end

-- ==================== GUI UTAMA ====================
AddHook("OnDraw", "ErtoxzLoaderGUI", function(dt)
    if ImGui.Begin("ERTOXZ Loader", nil, ImGuiWindowFlags_NoCollapse) then
        ImGui.Text("Pilih fitur yang akan dijalankan:")
        ImGui.Separator()
        
        -- Tombol untuk setiap fitur
        if ImGui.Button("PUT / BREAK PLAT", 200, 40) then
            loadAndRunScript("putbreak.lua")
        end
        
        if ImGui.Button("AUTO PTHT", 200, 40) then
            loadAndRunScript("ptht.lua")
        end
        
        if ImGui.Button("AUTO GEIGER", 200, 40) then
            loadAndRunScript("geiger.lua")
        end
        
        if ImGui.Button("AUTO GRINDER", 200, 40) then
            loadAndRunScript("grinder.lua")
        end
        
        ImGui.Separator()
        ImGui.Text("Status: " .. (response and "Online" or "Menunggu"))
    end
    ImGui.End()
end)

LogToConsole("`2ERTOXZ Loader siap. Klik tombol untuk menjalankan script.")
LogToConsole("`7Base URL: " .. baseUrl)
