component = require("component")
sides = require("sides")

laser = component.laser_amplifier
redstone = componenet.redstone
--configure side to emit redstone signal
_redstoneSignalLaserSide = "right"
_redstoneSignalPowerSide = "left"

chargePercent = false
laserSide = false
powerSide = false


function getLaserCharge()
    return laser.getEnergy() / laser.getMaxEnergy() * 100
end

function readyToIgnite()
	if chargePercent < 40 then 
		return { ready = false, error = "laser not charged" }; 
	end
	
	stopChargingLasers()
	return { ready = true }
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
		redstone.setOutput(laserSide, 16)
		sleep(500)
		redstone.setOutput(laserSide, 0)
	end
end 
 
laserSide = setRedstoneOutputSide(_redstoneSignalLaserSide)
powerSide = setRedstoneOutputSide(_redstoneSignalPowerSide)
chargePercent = getLaserCharge()