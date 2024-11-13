local component = require("component")
local rs = component.redstone
local args = {...}
local frequency
local value

local function toboolean(str)
    return tonumber(str) == "true" or str == "1"
end

-- SAVE
if #args == 2 then
    frequency = tonumber(args[1])
    value = toboolean(args[2])
else
    error("2 arguments are required: frequency, value")
end

-- SET
rs.setWirelessFrequency(frequency)
rs.setWirelessOutput(value)

print("Done")
