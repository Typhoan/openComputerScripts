local event = require("event")
local LaserAmplifier = require("LaserAmplifierLib")
local minitel = require("minitel")
local serialization = require("serialization")

function eventHandler(_, from, port, rawData)
    local data = serialization.unserialize(rawData)
    
    print("Recived Event: ", data["event"])
    if data["event"] == "GetLaserCharge" then
        minitel.rsend("Reactor", port, serialization.serialize({ event = "LaserChargeUpdate", result = LaserAmplifier.chargePercent }))
    elseif data["event"] == "ChargeLasers" then
        LaserAmplifier.startChargingLasers()
    elseif data["event"] == "StopChargingLasers" then
        LaserAmplifier.stopChargingLasers()
    elseif data["event"] == "Ignite" then
        LaserAmplifier.fireLaser()
    end
    print("Finished Event: ", data["event"])
end

event.listen("net_msg", eventHandler)
