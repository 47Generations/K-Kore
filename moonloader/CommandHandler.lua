local imgui = require 'mimgui'
local ffi = require 'ffi'
local vkeys = require 'vkeys'

-- Config
local username = "CJ"
local folder_path = getWorkingDirectory() .. "/K-Kore"
local tp_file = folder_path .. "/Teleports/teleports.txt"

-- Variables
local show_chat = imgui.new.bool(false)
local chat_input = imgui.new.char[256]('')
local chat_log = {}
local chat_cooldown = false 
local chat_font = renderCreateFont("Arial", 10, 5)

local initialized = false

function main()
    while not isOpcodesAvailable() do wait(100) end
    
    -- Ensure folder exists on startup
    if not doesDirectoryExist(folder_path) then createDirectory(folder_path) end

    add_to_log("K-Kore Ready. Commands: /setusername, /savetp, /tp", 0xd60027AA)

    while true do
        wait(0)
        draw_chat_log()
        
        if isKeyJustPressed(vkeys.VK_T) and not show_chat[0] and not chat_cooldown then
            consumeWindowMessage(0x0100, 0) 
            consumeWindowMessage(0x0102, 0)
            show_chat[0] = true
            showCursor(true)
            setPlayerControl(PLAYER_HANDLE, false)
        end
    end
end

function apply_ruby_theme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.ImVec4

    colors[imgui.Col.WindowBg] = clr(0.15, 0.02, 0.02, 0.90)   -- Dark Ruby background
    colors[imgui.Col.TitleBg] = clr(0.50, 0.00, 0.00, 1.00)    -- Deep Red header
    colors[imgui.Col.TitleBgActive] = clr(0.80, 0.00, 0.00, 1.00) -- Bright Ruby when active
    colors[imgui.Col.Button] = clr(0.40, 0.00, 0.00, 0.60)     -- Muted red buttons
    colors[imgui.Col.ButtonHovered] = clr(0.70, 0.00, 0.00, 1.00) -- Bright red on hover
    colors[imgui.Col.FrameBg] = clr(0.25, 0.05, 0.05, 1.00)    -- Input box dark red
end

-- THE COMMAND CENTER
function handle_cmd(text)
    local cmd, args = text:match("^/(%S+)%s*(.*)$")
    if not cmd then return false end
    cmd = cmd:lower() -- THIS ensures case-insensitivity

    if cmd == "setusername" and #args > 0 then
        username = args
        add_to_log("Name updated to: " .. username, 0xFF00FF00)
        return true

    elseif cmd == "savetp" and #args > 0 then
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local f = io.open(tp_file, "a")
        if f then
            f:write(string.format("%s %.2f %.2f %.2f\n", args, x, y, z))
            f:close()
            add_to_log("Saved location: " .. args, 0xFFFFFF00)
        end
        return true

    elseif cmd == "tp" and #args > 0 then
        local f = io.open(tp_file, "r")
        if f then
            for line in f:lines() do
                local n, tx, ty, tz = line:match("(%S+)%s+(%-?%d+%.%d+)%s+(%-?%d+%.%d+)%s+(%-?%d+%.%d+)")
                if n and n:lower() == args:lower() then
                    setCharCoordinates(PLAYER_PED, tonumber(tx), tonumber(ty), tonumber(tz))
                    add_to_log("Teleported to " .. n, 0xFF00FF00)
                    f:close() return true
                end
            end
            f:close()
        end
        add_to_log("TP Location not found!", 0xFFFF0000)
        return true
    elseif cmd == "v" or cmd == "spawnvehicle" then -- /v [ID]
        local modelId = tonumber(args)
        if modelId and modelId >= 400 and modelId <= 611 then
            lua_thread.create(function()
                add_to_log("Requesting vehicle " .. modelId .. "...", 0xFFFFFF00)
                
                -- 1. Load the model into memory
                requestModel(modelId)
                while not hasModelLoaded(modelId) do wait(0) end
                
                -- 2. Get CJ's position and heading
                local x, y, z = getCharCoordinates(PLAYER_PED)
                local angle = getCharHeading(PLAYER_PED)
                
                -- 3. Create the vehicle
                local veh = createCar(modelId, x + 3, y + 3, z)
                setCarHeading(veh, angle)
                
                -- 4. Clean up memory
                markModelAsNoLongerNeeded(modelId)
                
                add_to_log("Vehicle spawned!", 0xFF00FF00)
            end)
        else
            add_to_log("Usage: /v [400-611]", 0xFFFF0000)
        end
        return true

    elseif cmd == "halojump" then
        local found = false
        for _, s in ipairs(script.list()) do
            if s.name:find("Halo") then
                -- pcall (Protected Call) tries to run the code 
                -- It returns 'true' if it worked, 'false' if it failed (instead of crashing)
                local status = pcall(function() s.exports.toggleHalo() end)
                if status then
                    add_to_log("DeX OS: Halo Physics Synchronized", 0xFF00FFFF)
                    found = true
                    break
                end
            end
        end
        if not found then add_to_log("Error: Halo Plugin not responsive!", 0xFFFF0000) end
        return true

    elseif cmd == "halo2" then
        local found = false
        for _, s in ipairs(script.list()) do
            if s.name:find("Halo") then
                local status = pcall(function() s.exports.toggleHaloX2() end)
                if status then
                    add_to_log("DeX OS: Halo X2 Synchronized", 0xFF00FFFF)
                    found = true
                    break
                end
            end
        end
        if not found then add_to_log("Error: Halo Plugin not responsive!", 0xFFFF0000) end
        return true
    end
    return false
end

imgui.OnFrame(function() return show_chat[0] end, function(player)
        -- INITIALIZE EVERYTHING HERE (Safe Zone)
    if not initialized then
        apply_ruby_theme() -- Apply theme ONCE
        initialized = true
    end

    imgui.SetNextWindowPos(imgui.ImVec2(20, 280), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(500, 60), imgui.Cond.Always)
    imgui.Begin("Chat", show_chat, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)

    imgui.SetKeyboardFocusHere() 
    imgui.InputText("##in", chat_input, 256)

    -- The "Works Everytime" Release Logic
if imgui.IsKeyReleased(vkeys.VK_RETURN) then
        local text = ffi.string(chat_input)
        if #text > 0 then
            -- This is the critical part!
            if text:sub(1,1) == "/" then
                -- This calls the handle_cmd function below
                if not handle_cmd(text) then 
                    add_to_log("Unknown Command: " .. text, 0xFFFF0000) 
                end
            else
                add_to_log(username .. ": " .. text, 0xFFFFFFFF)
            end
        end
        ffi.copy(chat_input, "")
        close_chat_box()
    end

    if imgui.IsKeyPressed(vkeys.VK_ESCAPE) then close_chat_box() end
    imgui.End()
end)

function close_chat_box()
    show_chat[0] = false
    showCursor(false)
    setPlayerControl(PLAYER_HANDLE, true)
    chat_cooldown = true
    lua_thread.create(function()
        wait(400)
        chat_cooldown = false
    end)
end

function add_to_log(msg, clr)
    -- We store the time the message was created
    table.insert(chat_log, {
        text = msg, 
        color = clr, 
        time = os.clock(), -- The "Birth" time
        alpha = 255        -- Start fully visible
    })
    if #chat_log > 10 then table.remove(chat_log, 1) end
end

function draw_chat_log()
    local current_time = os.clock()
    for i, entry in ipairs(chat_log) do
        local age = current_time - entry.time
        
        -- After 10 seconds, start fading
        if age > 10 then
            entry.alpha = entry.alpha - 2 -- Gradually lower alpha
        end

        if entry.alpha > 0 then
            -- We must "mix" the alpha into the hex color
            -- This takes your color (like 0xFFFFFFFF) and adjusts the first 'FF'
            local alpha_hex = bit.lshift(math.floor(entry.alpha), 24)
            local visible_color = bit.bor(bit.band(entry.color, 0x00FFFFFF), alpha_hex)
            
            renderFontDrawText(chat_font, entry.text, 20, 40 + (i * 20), visible_color)
        end
    end
end