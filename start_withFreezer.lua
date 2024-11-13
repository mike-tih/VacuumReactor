-- local config = require("config")
local component = require("component")
local computer = require('computer')
local event = require("event")

local transposer = component.transposer
local reactor = component.reactor_chamber
local rs = component.redstone

local coolantItemName = "gregtech:gt.360k_Helium_Coolantcell"
local fuelRodItemName = "gregtech:gt.reactorUraniumQuad"
local depletedFuelRodItemName = "IC2:reactorUraniumQuaddepleted"

local coolantDamageThreshold = 40
local waitTime = 5
local minChargeThreshold = 0.9 -- Do not change!
local newFuelRodsInvSlot = 0
local newCoolantInvSlot = 1

local needPowerFrequency = 100
local switchFrequency = 1000

local reactorInvSide
local reactorInv
local reactorInitialTemperature
local reactorInitialRodsCount
local reactorInitialCoolantsCount

local freezerInvSide
local freezerInv
local freezerEmptySlot

local newCoolantInvSide
local newCoolantInv
local newCoolantInvCount

local newFuelRodsInvSide
local newFuelRodsInv
local newFuelRodsInvCount
local newFuelRodsEmptySlot

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
    elseif transposer.getInventoryName(side) == "gt.blockmachines" then
        freezerInvSide = side
        print("Found freezer inventory...")
    elseif transposer.getInventoryName(side) == "tile.blockbarrel" then
        newCoolantInvSide = side
        print("Found inventory with chilly coolant cells...")
    elseif transposer.getInventoryName(side) == "tile.appliedenergistics2.BlockInterface" then
        newFuelRodsInvSide = side
        print("Found inventory with new fuel rods...")
    end
end

if not (reactorInvSide and freezerInvSide and newCoolantInvSide and newFuelRodsInvSide) then
    shutOff("The transposer was not able to locate all required inventories. Please, check the setup. Performing emergency turn off.")
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
reactorInitialRodsCount = countItemsInInventory(reactorInv, fuelRodItemName)
reactorInitialCoolantsCount = countItemsInInventory(reactorInv, coolantItemName)
print("Reactor is set with " .. tostring(reactorInitialRodsCount) .. " fuel rods and " .. tostring(reactorInitialCoolantsCount) .. " coolant cells. Memorizing it...")

-- LAUNCH --

repeat
    -- Fetch reactor inventory
    reactorInv = transposer.getAllStacks(reactorInvSide).getAll()
    
    -- Do we need the power?
    rs.setWirelessFrequency(needPowerFrequency)
    needPower = rs.getWirelessInput()

    rs.setWirelessFrequency(switchFrequency)
    switch = rs.getWirelessInput()

    -- Replace overheated coolant cells
    coolantsToReplace = getCoolantsToReplacePositions(reactorInv, coolantItemName, coolantDamageThreshold)
    if #coolantsToReplace > 0 then
        reactor.setActive(false)
        print("Found " .. #coolantsToReplace .. " overheated coolant cells, replacing...")
        for index, position in ipairs(coolantsToReplace) do
            ::restart::
            newCoolantInv = transposer.getAllStacks(newCoolantInvSide).getAll()
            newCoolantInvCount = newCoolantInv[newCoolantInvSlot].size -- does not work with any slot rn

            freezerInv = transposer.getAllStacks(freezerInvSide).getAll()
            table.remove(freezerInv)
            freezerEmptySlot = findFirstEmptySlot(freezerInv)

            if (freezerEmptySlot == nil or newCoolantInvCount == 0) then
                print("Freezer is full or processed coolant is over, waiting " .. freezerWaitTime .. " seconds...")
                sleep(freezerWaitTime)
                
                local id = event.pull(0.01, "interrupted")
                if id then
                    shutOff("Shutting down gracefully on request...")
                end
                goto restart
            end

            transposer.transferItem(reactorInvSide, freezerInvSide, 1, position + 1, freezerEmptySlot + 1)
            transposer.transferItem(newCoolantInvSide, reactorInvSide, 1, newCoolantInvSlot + 1, position + 1)
        end
        print("Done!")
    end

    -- Replace depleted fuel rods
    rodsToReplace = getRodsToReplacePositions(reactorInv, depletedFuelRodItemName)
    if #rodsToReplace > 0 then
        reactor.setActive(false)
        print("Found " .. #rodsToReplace .. " depleted fuel rods, replacing...")
        for index, position in ipairs(rodsToReplace) do
            ::restart::
            newFuelRodsInv = transposer.getAllStacks(newFuelRodsInvSide).getAll()
            newFuelRodsInvCount = newFuelRodsInv[newFuelRodsInvSlot].size -- does not work with any slot rn

            newFuelRodsEmptySlot = findFirstEmptySlot(newFuelRodsInv)

            if (newFuelRodsEmptySlot == nil or newFuelRodsInvCount == 0) then
                print("No new fuel rods available, or no space for depleted ones, waiting " .. rodsWaitTime .. " seconds...")
                sleep(rodsWaitTime)

                local id = event.pull(0.01, "interrupted")
                if id then
                    shutOff("Shutting down gracefully on request...")
                end
                goto restart
            end

            transposer.transferItem(reactorInvSide, newFuelRodsInvSide, 1, position + 1, newFuelRodsEmptySlot + 1)
            transposer.transferItem(newFuelRodsInvSide, reactorInvSide, 1, newFuelRodsInvSlot + 1, position + 1)
        end
        print("Done!")
    end

    -- Checking for alarms (turn off the program)
    if reactor.getHeat() > reactorInitialTemperature then
        shutOff("The reactor is gaining heat, performing emergency turn off")
    end

    if computer.energy() / computer.maxEnergy() < minChargeThreshold then
        shutOff("The chanrge of this computer got lower than " .. tostring(minChargeThreshold * 100) .. "%, performing emergency turn off")
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