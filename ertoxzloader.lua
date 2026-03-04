-- ERTOXZ Loader - Main Loader (dengan link langsung)

local function loadAndRunScript(fullUrl)
    LogToConsole("`2Mengambil script dari: " .. fullUrl)
    
    local response = MakeRequest(fullUrl, "GET", {["User-Agent"] = "Mozilla/5.0"})
    
    if response and response.status == 200 then
        local scriptCode = response.content
        if scriptCode and scriptCode ~= "" then
            local func, err = loadstring(scriptCode)
            if func then
                LogToConsole("`2Script berhasil dimuat. Menjalankan...")
                pcall(func)
            else
                LogToConsole("`4Gagal memuat: " .. tostring(err))
            end
        else
            LogToConsole("`4Konten kosong!")
        end
    else
        LogToConsole("`4Gagal mengambil URL (status: " .. tostring(response and response.status or "no response") .. ")")
    end
end

AddHook("OnDraw", "ErtoxzLoaderGUI", function(dt)
    if ImGui.Begin("ERTOXZ Loader", nil, ImGuiWindowFlags_NoCollapse) then
        ImGui.Text("Pilih fitur:")
        ImGui.Separator()
        
        if ImGui.Button("PUT / BREAK PLAT", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/refs/heads/main/putbreak.lua")
        end
        if ImGui.Button("AUTO PTHT", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/refs/heads/main/ptht.lua")
        end
        if ImGui.Button("AUTO GEIGER", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/refs/heads/main/geiger.lua")
        end
        if ImGui.Button("AUTO GRINDER", 200, 40) then
            loadAndRunScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/refs/heads/main/grinder.lua")
        end
    end
    ImGui.End()
end)

LogToConsole("`2ERTOXZ Loader siap. Klik tombol.")
