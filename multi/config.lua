local config = {   
    coolantItemSearchString = "Coolantcell",
    fuelRodSearchString = "Quad",
    depletedFuelRodSearchString = "Quaddepleted",

    fuelRodsInvSlot = 0,
    coolantCellsInvSlot = 1,

    coolantDamageThreshold = 75, -- Must align with AE level emitter you use
    waitTime = 5,
    minChargeThreshold = 0.9, -- Do not change!

    needPowerFrequency = 100,
    switchFrequency = 708,
    workingFrequency = 777,

    reactorPattern = {0, 1, 1, 1, 0, 1, 1, 0, 1,
                      1, 1, 0, 1, 1, 1, 1, 0, 1,
                      0, 1, 1, 1, 1, 0, 1, 1, 1,
                      1, 1, 1, 0, 1, 1, 1, 1, 0,
                      1, 0, 1, 1, 1, 1, 0, 1, 1,
                      1, 0, 1, 1, 0, 1, 1, 1, 0}
}

return config