-- ERTOXZ Loader dengan login internal
local users = {
    { username = "admin", password = "12345" }
    -- tambahkan user lain sesuai kebutuhan
}

local loggedIn = false
local loginUsername = ""
local loginPassword = ""
local loginError = ""
local isLoading = false

local function checkLogin(username, password)
    if isLoading then return end
    isLoading = true
    loginError = "Memproses login..."
    
    -- Cek kecocokan
    local found = false
    for _, user in ipairs(users) do
        if user.username == username and user.password == password then
            found = true
            break
        end
    end
    
    if found then
        loggedIn = true
        loginError = ""
    else
        loginError = "Username atau password salah"
    end
    isLoading = false
end

AddHook("OnDraw", "ErtoxzLoader", function()
    if not loggedIn then
        if ImGui.Begin("Login - ERTOXZ Loader", nil, ImGuiWindowFlags_NoCollapse) then
            ImGui.Text("Masukkan username dan password")
            ImGui.Separator()
            
            local changedUser, newUser = ImGui.InputText("Username", loginUsername, 50)
            if changedUser then loginUsername = newUser end
            
            local changedPass, newPass = ImGui.InputText("Password", loginPassword, 50, ImGuiInputTextFlags_Password)
            if changedPass then loginPassword = newPass end
            
            if ImGui.Button("Login", 100, 30) then
                checkLogin(loginUsername, loginPassword)
            end
            
            if loginError ~= "" then
                ImGui.TextColored(1, 0, 0, 1, loginError)
            end
            
            ImGui.End()
        end
    else
        -- ==================== GUI UTAMA LOADER ====================
        if ImGui.Begin("ERTOXZ Loader", nil, ImGuiWindowFlags_NoCollapse) then
            ImGui.Text("Pilih fitur:")
            ImGui.Separator()
            
            local function runScript(url)
    -- Jalankan di thread agar tidak mengganggu GUI
    RunThread(function()
        load(MakeRequest(url).content)()
    end)
end
            
            -- Tombol-tombol fitur (sesuaikan URL dengan repo kamu)
            if ImGui.Button("PUT / BREAK PLAT", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/putbreak.lua")
            end
            if ImGui.Button("AUTO PTHT", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/ptht.lua")
            end
            if ImGui.Button("AUTO GEIGER", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/geiger.lua")
            end
            if ImGui.Button("AUTO GRINDER", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/grinder.lua")
            end
            if ImGui.Button("AUTO COMBINE", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/combine.lua")
            end
            if ImGui.Button("AUTO HT PROVIDER", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/harvestprovider.lua")
            end
            if ImGui.Button("AUTO SB", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/sb.lua")
            end
            if ImGui.Button("AUTO SHATTER", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/shatter.lua")
            end
            if ImGui.Button("AUTO SURG", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/surg.lua")
            end
            if ImGui.Button("AUTO COOK ARROZ", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/arroz.lua")
            end
            if ImGui.Button("AUTO PnB", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/pnb.lua")
            end
            if ImGui.Button("AUTO SPTHT", 200, 40) then
                runScript("https://raw.githubusercontent.com/AndikaDwiPradita/ertoxz-loader/main/sptht.lua")
            end
        end
        ImGui.End()
    end
end)

LogToConsole("ERTOXZ Loader dengan login internal siap. Silakan login.")
