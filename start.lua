local config = require("config")
local f = require("functions")
local component = require("component")
local computer = require('computer')
local event = require("event")

local transposer = component.transposer
local reactor = component.reactor_chamber
local rs = component.redstone

rs.setWakeThreshold(1)

local reactorInvSide
local reactorInv
local reactorInitialTemperature
local reactorInitialRodsCount
local reactorInitialCoolantsCount

local aeInterfaceInvSide
local aeInterfaceInv
local aeInterfaceRodsCount
local aeInterfaceCoolantCellsCount
local aeInterfaceEmptySlot

local coolantsToReplace = {}
local rodsToReplace = {}
local needPower = false
local switch = false

print("Initialising...")

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

if not (reactorInvSide and aeInterfaceInvSide) then
    f.shutOff(reactor, "The transposer was not able to locate the reactor or AE interface. Please, check the setup. Performing emergency turn off.")
end

-- Checking reactor activeness
reactorInitialTemperature = reactor.getHeat()

if reactor.producesEnergy() == false then
    print("Memorising the initial internal temperature of " .. tostring(reactorInitialTemperature))
else
    reactor.setActive(false)
    print("Turned off the reactor to finish the Initialisation.")
end

-- Countying rods and coolants
reactorInv = transposer.getAllStacks(reactorInvSide).getAll()
reactorInitialRodsCount = f.countItemsInInventory(reactorInv, config.fuelRodItemName)
reactorInitialCoolantsCount = f.countItemsInInventory(reactorInv, config.coolantItemName)
print("Reactor is set with " .. tostring(reactorInitialRodsCount) .. " fuel rods and " .. tostring(reactorInitialCoolantsCount) .. " coolant cells. Memorizing it...")

-- LAUNCH --

repeat
    -- Fetch reactor inventory
    reactorInv = transposer.getAllStacks(reactorInvSide).getAll()
    
    -- Do we need the power?
    rs.setWirelessFrequency(config.needPowerFrequency)
    needPower = rs.getWirelessInput()

    rs.setWirelessFrequency(config.switchFrequency)
    switch = rs.getWirelessInput()

    -- Replace overheated coolant cells
    coolantsToReplace = f.getCoolantsToReplacePositions(reactorInv, config.coolantItemName, config.coolantDamageThreshold)
    if #coolantsToReplace > 0 then
        reactor.setActive(false)
        print("Found " .. #coolantsToReplace .. " overheated coolant cells, replacing...")
        for index, position in ipairs(coolantsToReplace) do
            ::restart::
            aeInterfaceInv = transposer.getAllStacks(aeInterfaceInvSide).getAll()
            aeInterfaceCoolantCellsCount = aeInterfaceInv[config.coolantCellsInvSlot].size -- does not work with any slot rn

            aeInterfaceEmptySlot = f.findFirstEmptySlot(aeInterfaceInv)

            if (aeInterfaceEmptySlot == nil or aeInterfaceCoolantCellsCount == 0) then
                print("AE interface is full or the coolant is over, waiting " .. config.waitTime .. " seconds...")
                f.sleep(config.waitTime)
                
                local id = event.pull(0.01, "interrupted")
                if id then
                    f.shutOff(reactor, "Shutting down gracefully on request...")
                end
                goto restart
            end

            transposer.transferItem(reactorInvSide, aeInterfaceInvSide, 1, position + 1, aeInterfaceEmptySlot + 1)
            transposer.transferItem(aeInterfaceInvSide, reactorInvSide, 1, config.coolantCellsInvSlot + 1, position + 1)
        end
        print("Done!")
    end

    -- Replace depleted fuel rods
    rodsToReplace = f.getRodsToReplacePositions(reactorInv, config.depletedFuelRodItemName)
    if #rodsToReplace > 0 then
        reactor.setActive(false)
        print("Found " .. #rodsToReplace .. " depleted fuel rods, replacing...")
        for index, position in ipairs(rodsToReplace) do
            ::restart::
            aeInterfaceInv = transposer.getAllStacks(aeInterfaceInvSide).getAll()
            aeInterfaceRodsCount = aeInterfaceInv[config.fuelRodsInvSlot].size -- does not work with any slot rn

            aeInterfaceEmptySlot = f.findFirstEmptySlot(aeInterfaceInv)

            if (aeInterfaceEmptySlot == nil or aeInterfaceRodsCount == 0) then
                print("AE interface is full or the new fuel rods is over, waiting " .. config.waitTime .. " seconds...")
                f.sleep(config.waitTime)

                local id = event.pull(0.01, "interrupted")
                if id then
                    f.shutOff(reactor, "Shutting down gracefully on request...")
                end
                goto restart
            end

            transposer.transferItem(reactorInvSide, aeInterfaceInvSide, 1, position + 1, aeInterfaceEmptySlot + 1)
            transposer.transferItem(aeInterfaceInvSide, reactorInvSide, 1, config.fuelRodsInvSlot + 1, position + 1)
        end
        print("Done!")
    end

    -- Checking for alarms (turn off the program)
    if reactor.getHeat() > reactorInitialTemperature then
        f.shutOff(reactor, "The reactor is gaining heat, performing emergency turn off")
    end

    if computer.energy() / computer.maxEnergy() < config.minChargeThreshold then
        f.shutOff(reactor, "The chanrge of this computer got lower than " .. tostring(config.minChargeThreshold * 100) .. "%, performing emergency turn off")
    end

    local id = event.pull(0.01, "interrupted")
    if id then
        f.shutOff(reactor, "Shutting down gracefully on request...")
    end

    -- Finally turning ON and OFF
    if (needPower and switch) then
        f.keepActive(reactor)
    else
        reactor.setActive(false)
    end

until false