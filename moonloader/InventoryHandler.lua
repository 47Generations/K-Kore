local imgui = require 'mimgui'
local vkeys = require 'vkeys'

local settings = { haloJumpEnabled = false } 
local show_inventory = imgui.new.bool(false)
local pizza_texture = nil 
local initialized = false 
-- FIX: Added the font here!
local cash_font = renderCreateFont("Arial", 12, 5)

function apply_ruby_theme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.ImVec4
    colors[imgui.Col.WindowBg] = clr(0.15, 0.02, 0.02, 0.90)
    colors[imgui.Col.TitleBg] = clr(0.50, 0.00, 0.00, 1.00)
    colors[imgui.Col.TitleBgActive] = clr(0.80, 0.00, 0.00, 1.00)
    colors[imgui.Col.Button] = clr(0.40, 0.00, 0.00, 0.60)
    colors[imgui.Col.ButtonHovered] = clr(0.70, 0.00, 0.00, 1.00)
end

function main()
    while not isOpcodesAvailable() do wait(100) end
    while true do
        wait(0)
        if isKeyJustPressed(vkeys.VK_I) then
            show_inventory[0] = not show_inventory[0]
            showCursor(show_inventory[0])
            setPlayerControl(PLAYER_HANDLE, not show_inventory[0])
        end
        -- Drawing cash with the new font
        local playerMoney = getPlayerMoney(PLAYER_HANDLE)
        renderFontDrawText(cash_font, string.format("RP CASH: $%d", playerMoney), 20, 10, 0xFF00FF00)
    end
end

imgui.OnFrame(function() return show_inventory[0] end, function(player)
    if not initialized then
        apply_ruby_theme()
        local pizza_path = getWorkingDirectory() .. "/K-Kore/Sprites/Pizza.png"
        if doesFileExist(pizza_path) then
            pizza_texture = imgui.CreateTextureFromFile(pizza_path)
        end
        initialized = true
    end

    imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.FirstUseEver)
    imgui.Begin("K-Kore DeX System", show_inventory)
    
    if imgui.BeginTabBar("Tabs") then
        if imgui.BeginTabItem("Inventory") then
            imgui.Text("Your items will appear here.")
            imgui.EndTabItem()
        end
        imgui.EndTabBar()
    end
    imgui.End()
end)

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        if pizza_texture then
            -- This releases the image from your RAM/GPU
            pizza_texture = nil 
        end
    end
end