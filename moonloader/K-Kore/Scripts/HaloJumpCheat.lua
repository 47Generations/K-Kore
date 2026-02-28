local vkeys = require 'vkeys'

-- Variables (Local to this script, but toggled by the functions below)
local haloActive = false
local x2Enabled = false
local jumpedTwice = false

-- THE EXPORTS: This is what CommandHandler will "see"

function main()
    while not isOpcodesAvailable() do wait(100) end
    
    while true do
        wait(0)
        if haloActive then
            -- Fall Proof
            setCharProofs(PLAYER_PED, false, false, false, true, false) 

            if isKeyJustPressed(vkeys.VK_LSHIFT) and not isCharInAnyCar(PLAYER_PED) then
                if not isCharInAir(PLAYER_PED) then
                    local x, y, z = getCharVelocity(PLAYER_PED)
                    setCharVelocity(PLAYER_PED, x, y, 0.5) 
                    jumpedTwice = false
                elseif x2Enabled and not jumpedTwice then
                    local x, y, z = getCharVelocity(PLAYER_PED)
                    setCharVelocity(PLAYER_PED, x, y, 0.45)
                    jumpedTwice = true
                end
            end
        else
            -- Reset proofs when OFF
            setCharProofs(PLAYER_PED, false, false, false, false, false)
        end
    end
end


exports = {
    toggleHalo = function()
        haloActive = not haloActive
        x2Enabled = false
        printStringNow("HALO JUMP: " .. (haloActive and "~G~ON" or "~R~OFF"), 2000)
        return haloActive
    end,
    toggleHaloX2 = function()
        x2Enabled = not x2Enabled
        haloActive = x2Enabled
        printStringNow("HALO X2: " .. (x2Enabled and "~G~ON" or "~R~OFF"), 2000)
        return x2Enabled
    end
}

