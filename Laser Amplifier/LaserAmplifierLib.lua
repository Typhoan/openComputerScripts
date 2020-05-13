local component = require("component")
local sides = require("sides")
local os = require("os")
local thread = require("thread")

laserAmp = {}

local laser = component.laser_amplifier
local redstone = component.redstone

--configure side to emit redstone signal
local _redstoneSignalLaserSide = "right"
local _redstoneSignalPowerSide = "left"

laserAmp.chargePercent = false
local laserSide = nil
local powerSide = nil

function laserAmp.getLaserCharge()
    return  (laser.getEnergy() / laser.getMaxEnergy()) * 100
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

function laserAmp.startChargingLasers()
	redstone.setOutput(powerSide, 16)
	local t = thread.create(
		function()
			while laserAmp.getLaserCharge() < 70 and redstone.getOutput(powerSide) ~= 0 do
				os.sleep(30)
			end
			laserAmp.stopChargingLasers()
		end
	)
	
end

function laserAmp.stopChargingLasers()
	redstone.setOutput(powerSide, 0)
end

function laserAmp.fireLaser()
	if laserAmp.chargePercent >= 70 then
		laserAmp.stopChargingLasers()
		redstone.setOutput(laserSide, 16)
		os.sleep(.5)
		redstone.setOutput(laserSide, 0)
		laserAmp.startChargingLasers()
	end
end 
 
laserSide = setRedstoneOutputSide(_redstoneSignalLaserSide)
powerSide = setRedstoneOutputSide(_redstoneSignalPowerSide)
laserAmp.chargePercent = laserAmp.getLaserCharge()

return laserAmp