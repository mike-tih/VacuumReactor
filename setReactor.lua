local config = require("config")
local func = require("functions")
local component = require("component")

local transposer = component.transposer

local reactorInvSide
local aeInterfaceInvSide
local aeInterfaceInv
local aeInterfaceCoolantCellsCount
local aeInterfaceRodsCount

local c = config.coolantItemName
local f = config.fuelRodItemName

local setPattern = {c, f, f, f, c, f, f, c, f,
                    f, f, c, f, f, f, f, c, f,
                    c, f, f, f, f, c, f, f, f,
                    f, f, f, c, f, f, f, f, c,
                    f, c, f, f, f, f, c, f, f,
                    f, c, f, f, c, f, f, f, c}

-- Looking for reactor inventory
for side = 0, 5 do
    if transposer.getInventoryName(side) == "blockReactorChamber" then
        reactorInvSide = side
        print("Found reactor inventory...")
    elseif transposer.getInventoryName(side) == "tile.appliedenergistics2.BlockInterface" then
        aeInterfaceInvSide = side
        print("Found inventory with new fuel rods...")
    end
end

for index, item in ipairs(setPattern) do
    ::restart::
    aeInterfaceInv = transposer.getAllStacks(aeInterfaceInvSide).getAll()
    if item == f then
        aeInterfaceRodsCount = aeInterfaceInv[config.fuelRodsInvSlot].size -- does not work with any slot rn

        if aeInterfaceRodsCount == 0 then
            print("No rods, waiting " .. config.waitTime .. " seconds...")
            func.sleep(config.waitTime)
            goto restart
        end
        
        transposer.transferItem(aeInterfaceInvSide, reactorInvSide, 1, config.fuelRodsInvSlot + 1, index + 1)
    else
        aeInterfaceCoolantCellsCount = aeInterfaceInv[config.coolantCellsInvSlot].size -- does not work with any slot rn
        
        if aeInterfaceCoolantCellsCount == 0 then
            print("No coolant, waiting " .. config.waitTime .. " seconds...")
            func.sleep(config.waitTime)
            goto restart
        end
        
        transposer.transferItem(aeInterfaceInvSide, reactorInvSide, 1, config.coolantCellsInvSlot + 1, index + 1)
    end
end