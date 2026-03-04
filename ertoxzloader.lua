-- ERTOXZ Loader - Main Loader (dengan thread agar tidak yield di hook)

-- Fungsi untuk mengambil dan menjalankan script dari URL lengkap (dijalankan di thread)
local function loadAndRunScript(fullUrl)
    RunThread(function()
        LogToConsole("`2Mengambil script dari: " .. fullUrl)
        
        local response = MakeRequest(fullUrl, "GET", {["User-Agent"] = "Mozilla/5.0"})
        
        if response and response.status == 200 then
            local scriptCode = response.content
            if scriptCode and scriptCode ~= "" then
                local func, err = loadstring(scriptCode)
                if func then
                    LogToConsole("`2Script berhasil dimuat. Menjalankan...")
                    local success, runErr = pcall(func)
                    if not success then
                        LogToConsole("`4Error saat menjalankan: " .. tostring(runErr))
                    end
                else
                    LogToConsole("`4Gagal memuat script: " .. tostring(err))
                end
            else
                LogToConsole("`4Konten script kosong!")
            end
        else
            local status = response and response.status or "no response"
            LogToConsole("`4Gagal mengambil URL (status: " .. tostring(status) .. ")")
        end
    end)
end

-- GUI utama
AddHook("OnDraw", "ErtoxzLoaderGUI", function(dt)
    if ImGui.Begin("ERTOXZ Loader", nil, ImGuiWindowFlags_NoCollapse) then
        ImGui.Text("Pilih fitur yang akan dijalankan:")
        ImGui.Separator()
        
        -- Tombol untuk setiap fitur dengan URL langsung
        if ImGui.Button("PUT / BREAK PLAT", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/putbreak.lua")
        end
        if ImGui.Button("AUTO PTHT", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/ptht.lua")
        end
        if ImGui.Button("AUTO GEIGER", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/geiger.lua")
        end
        if ImGui.Button("AUTO GRINDER", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/grinder.lua")
        end
    end
    ImGui.End()
end)

LogToConsole("`2ERTOXZ Loader siap. Klik tombol untuk menjalankan script.")
