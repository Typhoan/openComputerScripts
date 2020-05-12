local event = require("event")
local serialization = require("serialization")
local reactorLib = require("ReactorLib")
local minitel = require("minitel")

reactorLib.initializeReactor()

function updateStatus(){
    minitel.rsend("LaserAmplifier", httpPort, {event = "GetLaserCharge"})

    local status = {
        injectionRate = reactorLib.injectionRate,
        active = reactorLib.active,
        energyProducing = reactorLib.energyProducing,
        hasHohlraum = reactorLib.hasHohlraum,
        chargePercent = reactorLib.chargePercent,
        deuterium = reactorLib.tankDeuterium.getStoredGas(),
        tritium = reactorLib.tankTritium.getStoredGas(),
        canIgnite = reactorLib.canIgnite()
    }
    local result = {event = "ReactorStatusUpdate", result = status}
    return serialization.serialize(result)
}

function eventHandler(_, from, port, rawData)
    local data = serialization.unserialize(rawData)
    print("Recived Event: ", data["event"])

    if data["event"] == "ReactorStatusUpdate" then
        minitel.rsend("HAL9000", port, updateStatus())
    elseif data["event"] == "LaserChargeUpdate" then
        reactorLib.chargePercent = data["result"]
    elseif data["event"] == "TransferHohlraum" then
        reactorLib.transferHohlraum()
    elseif data["event"] == "SetInjectionRate" then
        reactorLib.setInjectionRate()
    elseif data["event"] == "ChargeLasers" then
        minitel.rsend("LaserAmplifier", port, {event = "ChargeLasers"})
    elseif data["event"] == "StopChargingLasers" then
        minitel.rsend("LaserAmplifier", port, {event = "StopChargingLasers"})
    elseif data["event"] == "Ignite" then
        minitel.rsend("LaserAmplifier", port, {event = "Ignite"} )
    end
    print("Finished Event: ", data["event"])
end

event.listen("net_msg", eventHandler)
