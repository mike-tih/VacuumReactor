local func = {}

function func.sleep(seconds)
    os.execute("sleep " .. tostring(seconds))
end

function func.keepActive(r)
    if r.producesEnergy() == false then
        r.setActive(true)
    end
end

function func.shutOff(r, message)
    r.setActive(false)
    print(message)
    os.exit()
end

function func.getCoolantsToReplacePositions(inventory, coolantItemName, coolantDamageThreshold)
    local toReplace = {}

    for i = 0, #inventory do
        local item = inventory[i]

        if (item.name == coolantItemName and item.damage > coolantDamageThreshold) then
            table.insert(toReplace, i)
        end
    end

    return toReplace
end

function func.getRodsToReplacePositions(inventory, depletedFuelRodItemName)
    local toReplace = {}

    for i = 0, #inventory do
        local item = inventory[i]

        if (item.name == depletedFuelRodItemName) then
            table.insert(toReplace, i)
        end
    end

    return toReplace
end

function func.countItemsInInventory(inventory, itemName)
    local number = 0

    for i = 0, #inventory do
        local item = inventory[i]

        if item.name == itemName then
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