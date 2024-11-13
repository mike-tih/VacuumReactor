local config = require("config")
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

-- Functions

local function sleep(seconds)
    os.execute("sleep " .. tostring(seconds))
end

local function keepActive()
    if reactor.producesEnergy() == false then
        reactor.setActive(true)
    end
end

local function shutOff(message)
    reactor.setActive(false)
    print(message)
    os.exit()
end

local function getCoolantsToReplacePositions(inventory, coolantItemName, coolantDamageThreshold)
    local toReplace = {}

    for i = 0, #inventory do
        local item = inventory[i]

        if (item.name == coolantItemName and item.damage > coolantDamageThreshold) then
            table.insert(toReplace, i)
        end
    end

    return toReplace
end

local function getRodsToReplacePositions(inventory, depletedFuelRodItemName)
    local toReplace = {}

    for i = 0, #inventory do
        local item = inventory[i]

        if (item.name == depletedFuelRodItemName) then
            table.insert(toReplace, i)
        end
    end

    return toReplace
end

local function countItemsInInventory(inventory, itemName)
    local number = 0

    for i = 0, #inventory do
        local item = inventory[i]

        if item.name == itemName then
            number = number + tonumber(item.size)
        end
    end

    return number
end

local function findFirstEmptySlot(inventory)
    local slot

    for i = 0, #inventory do
        if not inventory[i].name then
            slot = i
            break
        end
    end

    return slot
end

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
    shutOff("The transposer was not able to locate the reactor or AE interface. Please, check the setup. Performing emergency turn off.")
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
reactorInitialRodsCount = countItemsInInventory(reactorInv, config.fuelRodItemName)
reactorInitialCoolantsCount = countItemsInInventory(reactorInv, config.coolantItemName)
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
    coolantsToReplace = getCoolantsToReplacePositions(reactorInv, config.coolantItemName, config.coolantDamageThreshold)
    if #coolantsToReplace > 0 then
        reactor.setActive(false)
        print("Found " .. #coolantsToReplace .. " overheated coolant cells, replacing...")
        for index, position in ipairs(coolantsToReplace) do
            ::restart::
            aeInterfaceInv = transposer.getAllStacks(aeInterfaceInvSide).getAll()
            aeInterfaceCoolantCellsCount = aeInterfaceInv[config.coolantCellsInvSlot].size -- does not work with any slot rn

            aeInterfaceEmptySlot = findFirstEmptySlot(aeInterfaceInv)

            if (aeInterfaceEmptySlot == nil or aeInterfaceCoolantCellsCount == 0) then
                print("AE interface is full or the coolant is over, waiting " .. config.waitTime .. " seconds...")
                sleep(config.waitTime)
                
                local id = event.pull(0.01, "interrupted")
                if id then
                    shutOff("Shutting down gracefully on request...")
                end
                goto restart
            end

            transposer.transferItem(reactorInvSide, aeInterfaceInvSide, 1, position + 1, aeInterfaceEmptySlot + 1)
            transposer.transferItem(aeInterfaceInvSide, reactorInvSide, 1, config.coolantCellsInvSlot + 1, position + 1)
        end
        print("Done!")
    end

    -- Replace depleted fuel rods
    rodsToReplace = getRodsToReplacePositions(reactorInv, config.depletedFuelRodItemName)
    if #rodsToReplace > 0 then
        reactor.setActive(false)
        print("Found " .. #rodsToReplace .. " depleted fuel rods, replacing...")
        for index, position in ipairs(rodsToReplace) do
            ::restart::
            aeInterfaceInv = transposer.getAllStacks(aeInterfaceInvSide).getAll()
            aeInterfaceRodsCount = aeInterfaceInv[config.fuelRodsInvSlot].size -- does not work with any slot rn

            aeInterfaceEmptySlot = findFirstEmptySlot(aeInterfaceInv)

            if (aeInterfaceEmptySlot == nil or aeInterfaceRodsCount == 0) then
                print("AE interface is full or the new fuel rods is over, waiting " .. config.waitTime .. " seconds...")
                sleep(config.waitTime)

                local id = event.pull(0.01, "interrupted")
                if id then
                    shutOff("Shutting down gracefully on request...")
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
        shutOff("The reactor is gaining heat, performing emergency turn off")
    end

    if computer.energy() / computer.maxEnergy() < config.minChargeThreshold then
        shutOff("The chanrge of this computer got lower than " .. tostring(config.minChargeThreshold * 100) .. "%, performing emergency turn off")
    end

    local id = event.pull(0.01, "interrupted")
    if id then
        shutOff("Shutting down gracefully on request...")
    end

    -- Finally turning ON and OFF
    if (needPower and switch) then
        keepActive()
    else
        reactor.setActive(false)
    end

until false