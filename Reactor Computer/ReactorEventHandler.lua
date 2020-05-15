local event = require("event")
local serialization = require("serialization")
local ReactorLib = require("ReactorLib")
local minitel = require("minitel")

ReactorLib.initializeReactor()

function updateStatus()
    local status = {
        injectionRate = ReactorLib.reactor.getInjectionRate(),
        active = ReactorLib.isActive(),
        energyProducing = ReactorLib.getEnergyProducing(),
        hasHohlraum = ReactorLib.hasHohlraum(),
        deuterium = ReactorLib.tankDeuterium.getStoredGas(),
        tritium = ReactorLib.tankTritium.getStoredGas(),
        canIgnite = ReactorLib.canIgnite()
    }
    local result = {event = "ReactorStatusUpdate", result = status}
    return serialization.serialize(result)
end 

function eventHandler(_, from, port, rawData)
    local data = serialization.unserialize(rawData)
    print("Recived Event: ", data["event"])

    if data["event"] == "ReactorStatusUpdate" then
        minitel.send("HAL9000", port, updateStatus())
    elseif data["event"] == "TransferHohlraum" then
        ReactorLib.transferHohlraum()
    elseif data["event"] == "SetInjectionRate" then
        ReactorLib.setInjectionRate(data["result"])
    elseif data["event"] == "ChargeLasers" then
        minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "ChargeLasers"}))
    elseif data["event"] == "StopChargingLasers" then
        minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "StopChargingLasers"}))
    end
    print("Finished Event: ", data["event"])
end

event.listen("net_msg", eventHandler)
