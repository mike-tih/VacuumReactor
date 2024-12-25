local func = {}

function func.sleep(seconds)
    os.execute("sleep " .. tostring(seconds))
end

function func.setWirelessRedstone(rs, frequency, value)
    rs.setWirelessFrequency(frequency)
    return rs.setWirelessOutput(value)
end

function func.getWirelessRedstone(rs, frequency)
    rs.setWirelessFrequency(frequency)
    return rs.getWirelessOutput()
end

function func.shutOff(rs, workingFrequency, message)
    rs.setWirelessFrequency(workingFrequency)
    rs.setWirelessOutput(0)
    print(message)
    os.exit()
end

function func.getCoolantsToReplacePositions(inventory, coolantItemSearchString, coolantDamageThreshold)
    local toReplace = {}

    for i = 0, #inventory do
        local item = inventory[i]

        if (string.find(item.name, coolantItemSearchString) and item.damage > coolantDamageThreshold) then
            table.insert(toReplace, i)
        end
    end

    return toReplace
end

function func.getRodsToReplacePositions(inventory, depletedFuelRodSearchString)
    local toReplace = {}

    for i = 0, #inventory do
        local item = inventory[i]

        if string.find(item.name, depletedFuelRodSearchString) then
            table.insert(toReplace, i)
        end
    end

    return toReplace
end

function func.countItemsInInventory(inventory, searchString)
    local number = 0

    for i = 0, #inventory do
        local item = inventory[i]

        if string.find(item.name, searchString) then
            number = number + tonumber(item.size)
        end
    end

    return number
end

function func.findFirstEmptySlot(inventory)
    local slot

    for i = 0, #inventory do
        if not inventory[i].name then
            slot = i
            break
        end
    end

    return slot
end

return func