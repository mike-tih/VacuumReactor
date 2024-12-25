local config = require("config")
local f = require("functions")
local component = require("component")
local computer = require('computer')
local event = require("event")
local rs = component.redstone

rs.setWakeThreshold(1)

local needPower = false
local switch = false

local transposers = {}
local reactorInvSides = {}
local aeInterfaceInvSides = {}
local idsToSetup = {}

-- INIT transposers --

print("Initialising...")

for id, _ in component.list("transposer") do
    transposers[id] = component.proxy(id)

    local reactorInv

    for side = 0, 5 do
        if transposers[id].getInventoryName(side) == "blockReactorChamber" then
            reactorInvSides[id] = side
            reactorInv = transposers[id].getAllStacks(side).getAll()
            print("Found reactor inventory...")
        elseif transposers[id].getInventoryName(side) == "tile.appliedenergistics2.BlockInterface" then
            aeInterfaceInvSides[id] = side
            print("Found inventory with new fuel rods...")
        end
    end

    -- if empty
    if (not f.countItemsInInventory(reactorInv, config.coolantItemSearchString) & not f.countItemsInInventory(reactorInv, config.fuelRodSearchString)) then
        table.insert(idsToSetup, id)
        print("Found empty reactor")
    end

    if not (reactorInvSides[id] and aeInterfaceInvSides[id]) then
        f.shutOff(rs, config.workingFrequency, "The transposer was not able to locate the reactor or AE interface. Please, check the setup. Performing emergency turn off.")
    end
end

-- SET reactors --
if #idsToSetup > 0 then
    print("Setting up new reactors...")
    for _, id in ipairs(idsToSetup) do

        -- Putting Coolants
        for index, item in ipairs(config.reactorPattern) do
            ::restart::
            if item == 0 then
                local aeInterfaceInv = transposers[id].getAllStacks(aeInterfaceInvSides[id]).getAll()
                local aeInterfaceCoolantCellsCount = aeInterfaceInv[config.coolantCellsInvSlot].size -- does not work with any slot rn
                
                if aeInterfaceCoolantCellsCount == 0 then
                    print("No coolant, waiting " .. config.waitTime .. " seconds...")
                    f.sleep(config.waitTime)
                    goto restart
                end
                
                transposers[id].transferItem(aeInterfaceInvSides[id], reactorInvSides[id], 1, config.coolantCellsInvSlot + 1, index)
            end
        end

        -- Putting Rods
        for index, item in ipairs(config.reactorPattern) do
            ::restart::
            if item == 1 then
                local aeInterfaceInv = transposers[id].getAllStacks(aeInterfaceInvSides[id]).getAll()
                local aeInterfaceRodsCount = aeInterfaceInv[config.fuelRodsInvSlot].size -- does not work with any slot rn

                if aeInterfaceRodsCount == 0 then
                    print("No rods, waiting " .. config.waitTime .. " seconds...")
                    f.sleep(config.waitTime)
                    goto restart
                end
                
                transposers[id].transferItem(aeInterfaceInvSides[id], reactorInvSides[id], 1, config.fuelRodsInvSlot + 1, index)
            end
        end
    end
end

-- LAUNCH --

repeat
    for id, transposer in transposers do
        local coolantsToReplace = {}
        local rodsToReplace = {}
        local reactorInv

        -- Checking for alarms (turn off the program)
        if computer.energy() / computer.maxEnergy() < config.minChargeThreshold then
            f.shutOff(rs, config.workingFrequency, "The chanrge of this computer got lower than " .. tostring(config.minChargeThreshold * 100) .. "%, performing emergency turn off")
        end

        -- Checking for interruptions
        local interrupted = event.pull(0.01, "interrupted")
        if interrupted then
            f.shutOff(rs, config.workingFrequency, "Shutting down gracefully on request...")
        end

        -- Do we need the power?
        needPower = f.getWirelessRedstone(rs, config.needPowerFrequency)

        -- Switch on?
        switch = f.getWirelessRedstone(rs, config.switchFrequency)

        -- Turning on
        if (needPower & switch) then
            f.setWirelessRedstone(rs, config.workingFrequency, 1)
        else
            f.setWirelessRedstone(rs, config.workingFrequency, 0)
        end
        
        reactorInv = transposer.getAllStacks(reactorInvSides[id]).getAll()

        -- Replace overheated coolant cells
        coolantsToReplace = f.getCoolantsToReplacePositions(reactorInv, config.coolantItemSearchString, config.coolantDamageThreshold)
        if #coolantsToReplace > 0 then
            f.sleep(0.1)
            print("Found " .. #coolantsToReplace .. " overheated coolant cells, replacing...")
            for _, position in ipairs(coolantsToReplace) do
                ::restart::
                local aeInterfaceInv = transposer.getAllStacks(aeInterfaceInvSides[id]).getAll()
                local aeInterfaceCoolantCellsCount = aeInterfaceInv[config.coolantCellsInvSlot].size -- does not work with any slot rn

                local aeInterfaceEmptySlot = f.findFirstEmptySlot(aeInterfaceInv)

                if (aeInterfaceEmptySlot == nil or aeInterfaceCoolantCellsCount == 0) then
                    print("AE interface is full or the coolant is over, waiting " .. config.waitTime .. " seconds...")
                    f.sleep(config.waitTime)
                    
                    local interrupted = event.pull(0.01, "interrupted")
                    if interrupted then
                        f.shutOff(rs, config.workingFrequency, "Shutting down gracefully on request...")
                    end
                    goto restart
                end

                transposer.transferItem(reactorInvSides[id], aeInterfaceInvSides[id], 1, position + 1, aeInterfaceEmptySlot + 1)
                transposer.transferItem(aeInterfaceInvSides[id], reactorInvSides[id], 1, config.coolantCellsInvSlot + 1, position + 1)
            end
            print("Done!")
        end

        -- Replace depleted fuel rods
        rodsToReplace = f.getRodsToReplacePositions(reactorInv, config.depletedFuelRodSearchString)
        if #rodsToReplace > 0 then
            print("Found " .. #rodsToReplace .. " depleted fuel rods, replacing...")
            for _, position in ipairs(rodsToReplace) do
                ::restart::
                local aeInterfaceInv = transposer.getAllStacks(aeInterfaceInvSides[id]).getAll()
                local aeInterfaceRodsCount = aeInterfaceInv[config.fuelRodsInvSlot].size -- does not work with any slot rn

                local aeInterfaceEmptySlot = f.findFirstEmptySlot(aeInterfaceInv)

                if (aeInterfaceEmptySlot == nil or aeInterfaceRodsCount == 0) then
                    print("AE interface is full or the new fuel rods is over, waiting " .. config.waitTime .. " seconds...")
                    f.sleep(config.waitTime)

                    local interrupted = event.pull(0.01, "interrupted")
                    if interrupted then
                        f.shutOff(rs, config.workingFrequency, "Shutting down gracefully on request...")
                    end
                    goto restart
                end

                transposer.transferItem(reactorInvSides[id], aeInterfaceInvSides[id], 1, position + 1, aeInterfaceEmptySlot + 1)
                transposer.transferItem(aeInterfaceInvSides[id], reactorInvSides[id], 1, config.fuelRodsInvSlot + 1, position + 1)
            end
            print("Done!")
        end
        
    end

until false