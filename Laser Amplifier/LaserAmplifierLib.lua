local component = require("component")
local sides = require("sides")

local laser = component.laser_amplifier
local redstone = component.redstone

--configure side to emit redstone signal
local _redstoneSignalLaserSide = "right"
local _redstoneSignalPowerSide = "left"

local chargePercent = false
local laserSide = false
local powerSide = false


function getLaserCharge()
	local val = laser.getEnergy() / laser.getMaxEnergy() * 100
	if val >= 40 then 
		stopChargingLasers()
	end
    return  val
end


function setRedstoneOutputSide(redstoneSignalSide)
	if redstoneSignalSide == "front" then return sides.front end
	if redstoneSignalSide == "back" then return  sides.back end
	if redstoneSignalSide == "left" then return sides.left end
	if redstoneSignalSide == "right" then return sides.right end
	if redstoneSignalSide == "top" then return sides.top end
	if redstoneSignalSide == "bottom" then return sides.bottom end
	
	return false
end

function startChargingLasers()
	redstone.setOutput(powerSide, 16)
end

function stopChargingLasers()
	redstone.setOutput(powerSide, 0)
end

function fireLaser()
	if chargePercent >= 40 then
		stopChargingLasers()
		redstone.setOutput(laserSide, 16)
		sleep(500)
		redstone.setOutput(laserSide, 0)
	end
end 
 
laserSide = setRedstoneOutputSide(_redstoneSignalLaserSide)
powerSide = setRedstoneOutputSide(_redstoneSignalPowerSide)
chargePercent = getLaserCharge()