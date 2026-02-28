local script_path = getWorkingDirectory() .. "/K-Kore/Scripts/"
local splash_alpha = 255
local loading_text = "INITIALIZING K-KORE SYSTEM..."
local progress = 0
local plugins_found = 0
local splash_font = renderCreateFont("Georgia", 22, 5)

function draw_splash()
    if splash_alpha > 0 then
        renderDrawBox(0, 0, 1920, 1080, bit.bor(bit.lshift(math.floor(splash_alpha * 0.8), 24), 0x150202))
        renderFontDrawText(splash_font, "K-KORE | DeX OS", 100, 100, bit.bor(bit.lshift(splash_alpha, 24), 0xFF0000))
        renderDrawBox(100, 150, 400, 10, bit.bor(bit.lshift(splash_alpha, 24), 0x330000))
        renderDrawBox(100, 150, progress * 4, 10, bit.bor(bit.lshift(splash_alpha, 24), 0xE60000))
        renderFontDrawText(splash_font, loading_text, 100, 170, bit.bor(bit.lshift(splash_alpha, 24), 0xFFFFFF))
        renderFontDrawText(splash_font, "PLUGINS LOADED: " .. plugins_found, 100, 210, bit.bor(bit.lshift(splash_alpha, 24), 0xAA0000))
    end
end

function main()
    while not isOpcodesAvailable() do wait(100) end
    
    lua_thread.create(function()
        while splash_alpha > 0 do
            wait(0)
            draw_splash()
        end
    end)

    progress = 20
    wait(1000) 

    local handle, file = findFirstFile(script_path .. "*.lua")
    if handle and handle ~= -1 then
        while file do
            -- Safety check for filename
            local name = nil
            if type(file) == "table" and file.filename then
                name = file.filename
            elseif type(file) == "string" then
                name = file
            end

            if name and name ~= "MasterLoader.lua" then
                print("K-Kore: Found plugin " .. name)
                loading_text = "SYNCING: " .. name:upper()
                
                -- FIXED SYNTAX: script.load is the official MoonLoader command
                local status = script.load(script_path .. name)
                if status then plugins_found = plugins_found + 1 end
                
                progress = math.min(progress + 30, 95)
                wait(800) 
            end
            
            local success, nextFile = findNextFile(handle)
            if not success or not nextFile then break end
            file = nextFile
        end
        findClose(handle)
    end
    
    progress = 100
    loading_text = "K-Kore ONLINE."
    wait(1000)

    while splash_alpha > 0 do
        wait(0)
        splash_alpha = splash_alpha - 5
    end
end