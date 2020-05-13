local rl = require("ReactorLib")
local minitel = require("minitel")
local os = require("os")
local serialization = require("serialization")

print("Reactor Lib Test Script")

print("Initializing Reactor....")
os.sleep(1)
rl.initializeReactor()
print("Initialized Reactor")
print("")
minitel.rsend("LaserAmplifier", httpPort, serialization.serialize({event = "GetLaserCharge"}))
print("Reactor Statistics:")
print("Active: ", rl.isActive())
print("Energy Producing: ", rl.getEnergyProducing())
print("Deuterium Tank: " , rl.tankDeuterium.getStoredGas())
print("Tritium Tank: " , rl.tankTritium.getStoredGas())
print("Has Hohlraum: ", rl.hasHohlraum())
print("Laser Charge: ", rl.chargePercent)
print("Injection Rate: ", rl.reactor.getInjectionRate())
print("Can Ignite Data: ")
for k, v in pairs(rl.canIgnite()) do
    print(k,v)
end
print("")
os.sleep(1)
print("Setting Injection Rate to 2....")
rl.setInjectionRate(2)
print("Updated Injection Rate: ", rl.reactor.getInjectionRate())
os.sleep(1)
print("")
print("Transfering Hohlraum....")
rl.transferHohlraum()
print("Has Hohlraum: ", rl.hasHohlraum())
os.sleep(1)
print("Can Ignite Data ")
tmp = rl.canIgnite()
for k, v in pairs(tmp) do
    print(k,v)
end
print("")
if(tmp.ready == false) then
    print("Test Complete")
    return
end
print("Igniting Reactor in 5 seconds")
os.sleep(5)
minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "Ignite"}) )
os.sleep(2)

print("")
print("Updated Reactor Statistics:")
print("Active: ", rl.isActive())
print("Energy Producing: ", rl.getEnergyProducing())
print("Deuterium Tank: " , rl.tankDeuterium.getStoredGas())
print("Tritium Tank: " , rl.tankTritium.getStoredGas())
print("Has Hohlraum: ", rl.hasHohlraum())
print("Laser Charge: ", rl.chargePercent)
print("Injection Rate: ", rl.reactor.getInjectionRate())
print("Can Ignite Data ")
tmp = rl.canIgnite()
for k, v in pairs(tmp) do
    print(k,v)
end

os.sleep(2)

print("")
print("Recharging Lasers...")
minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "ChargeLasers"}))
print("Charge Lasers event sent")
print("")

print("Test Complete")