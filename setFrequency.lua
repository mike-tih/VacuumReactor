local component = require("component")
local rs = component.redstone
local args = {...}
local frequency
local value 

-- SAVE
if #args = 2 then
    frequency = args[1]
    value = args[2]
else
    error("2 arguments are required: frequency, value")
end

-- VERIFY
if value > 15 or value < 0 then
    error("Value should stay inside [0, 15]")

-- SET
rs.setWirelessFrequency(frequency)
rs.setWirelessOutput(value)

print("Done")
