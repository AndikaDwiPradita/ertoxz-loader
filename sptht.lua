-- ==================== SPTHT SCRIPT (FIXED) ====================

Settings = {
  lineY = 192,
  amtseed = 2000,
  FirstSeed = 117,
  delayPlant = 150,
  UseUws = false,
  delayHarvest = 250,
  FirstMagplant = {3, 191},
  TwoMagplant = {2, 191},
  World = "island"
}

-- Variabel global
y1 = 0
y2 = Settings.lineY

-- Variabel kontrol
local running = true  -- Script berjalan saat di-load
local stopRequested = false

-- Fungsi-fungsi dasar
function IsReady(tile)
  return tile and tile.extra and tile.extra.progress == 1.0
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

function magplant(x, y, button)
  Raw(0, 0, 0, x, y)
  Sleep(300)
  Raw(3, 0, 32, x, y + 1)
  Sleep(300)
  SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. x .. "|\ny|".. y + 1 .. "|\nbuttonClicked|getRemote")
  Sleep(300)
end

function TakeMagplant(pos, btn)
  Raw(0, 0, 0, pos[1], pos[2])
  Sleep(100)
  magplant(pos[1], pos[2], btn)
  Sleep(1000)
end

function checkseed()
  local count = 0
  for y = y1, y2 do
    for x = 0, 199 do
      local tile = GetTile(x, y)
      if tile and IsReady(tile) then
        count = count + 1
      end
    end
  end
  return count
end

function plantLine(x, splice)
  for y = y2, y1, -1 do
    local tile = GetTile(x, y)
    if tile and (tile.fg == 0 or (splice and tile.fg == Settings.FirstSeed)) then
      LogToConsole("Planting On X: "..x.." Y: "..y)
      Raw(0, 32, 0, x, y)
      Raw(0, 32, 0, x, y)
      Sleep(100)
      Raw(3, 0, 5640, x, y)
      Sleep(Settings.delayPlant)
    end
  end
end

function doPlanting(startX, endX)
  for x = startX, endX, 10 do
    if not running or stopRequested then return end
    TakeMagplant(Settings.FirstMagplant, "getRemote")
    TakeMagplant(Settings.FirstMagplant, "getRemote")
    plantLine(x, false)
    plantLine(x, false)
    Sleep(200)

    TakeMagplant(Settings.TwoMagplant, "getRemote")
    TakeMagplant(Settings.TwoMagplant, "getRemote")
    plantLine(x, true)
    plantLine(x, true)
    Sleep(200)
  end
end

function UseUws()
  if Settings.UseUws then
    SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
    Sleep(5000)
  end
end

function harvest()
  if checkseed() > Settings.amtseed then
    local maxX = (Settings.World == "normal" and 99 or 199)
    for y = y2, y1, -1 do
      for x = 0, maxX do
        if not running or stopRequested then return end
        local tile = GetTile(x, y)
        if tile and IsReady(tile) then
          Raw(0, 32, 0, x, y)
          Sleep(Settings.delayHarvest)
          Raw(3, 0, 18, x, y)
          Sleep(Settings.delayHarvest)
        end
      end
    end
  end
end

-- Fungsi utama
function main()
  while running and not stopRequested do
    harvest()
    if stopRequested then break end
    Sleep(1500)
    
    if Settings.World == "normal" then
      doPlanting(0, 100)
    elseif Settings.World == "island" then
      doPlanting(0, 190)
    end
    
    if stopRequested then break end
    Sleep(1000)
    UseUws()
    Sleep(5000)
  end
  LogToConsole("SPTHT stopped")
end

-- Mulai script
LogToConsole("SPTHT started")
main()