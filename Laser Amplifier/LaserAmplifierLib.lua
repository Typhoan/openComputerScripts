local component = require("component")
local sides = require("sides")

laserAmp = {}

local laser = component.laser_amplifier
local redstone = component.redstone

--configure side to emit redstone signal
local _redstoneSignalLaserSide = "right"
local _redstoneSignalPowerSide = "left"

laserAmp.chargePercent = false
laserAmp.laserSide = false
laserAmp.powerSide = false

function laserAmp.getLaserCharge()
	local val = laser.getEnergy() / laser.getMaxEnergy() * 100
	if val >= 40 then 
		stopChargingLasers()
	end
    return  val
end


function laserAmp.setRedstoneOutputSide(redstoneSignalSide)
	if redstoneSignalSide == "front" then return sides.front end
	if redstoneSignalSide == "back" then return  sides.back end
	if redstoneSignalSide == "left" then return sides.left end
	if redstoneSignalSide == "right" then return sides.right end
	if redstoneSignalSide == "top" then return sides.top end
	if redstoneSignalSide == "bottom" then return sides.bottom end
	
	return false
end

function laserAmp.startChargingLasers()
	redstone.setOutput(powerSide, 16)
end

function laserAmp.stopChargingLasers()
	redstone.setOutput(powerSide, 0)
end

function laserAmp.fireLaser()
	if laserAmp.chargePercent >= 40 then
		stopChargingLasers()
		redstone.setOutput(laserSide, 16)
		sleep(500)
		redstone.setOutput(laserSide, 0)
	end
end 
 
laserAmp.laserSide = setRedstoneOutputSide(_redstoneSignalLaserSide)
laserAmp.powerSide = setRedstoneOutputSide(_redstoneSignalPowerSide)
laserAmp.chargePercent = getLaserCharge()

return laserAmp