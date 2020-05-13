local event = require("event")
local serialization = require("serialization")
local ReactorLib = require("ReactorLib")
local minitel = require("minitel")

ReactorLib.initializeReactor()

function updateStatus()
    minitel.rsend("LaserAmplifier", httpPort, {event = "GetLaserCharge"})

    local status = {
        injectionRate = ReactorLib.reactor.getInjectionRate(),
        active = ReactorLib.isActive(),
        energyProducing = ReactorLib.getEnergyProducing(),
        hasHohlraum = ReactorLib.hasHohlraum(),
        chargePercent = ReactorLib.chargePercent,
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
    elseif data["event"] == "LaserChargeUpdate" then
        ReactorLib.chargePercent = data["result"]
    elseif data["event"] == "TransferHohlraum" then
        ReactorLib.transferHohlraum()
    elseif data["event"] == "SetInjectionRate" then
        ReactorLib.setInjectionRate(data["result"])
    elseif data["event"] == "ChargeLasers" then
        minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "ChargeLasers"}))
    elseif data["event"] == "StopChargingLasers" then
        minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "StopChargingLasers"}))
    elseif data["event"] == "Ignite" then
        local canIgnite = ReactorLib.canIgnite()
        if canIgnite.ready == true then
            minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "Ignite"} ))
        else
            minitel.rsend("HAL9000", port, serialization.serialize({event = "IgniteError", error = canIgnite.error} ))
        end
    end
    print("Finished Event: ", data["event"])
end

event.listen("net_msg", eventHandler)
