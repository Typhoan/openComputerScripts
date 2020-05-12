local component = require("component")

local reactor = component.reactor_logic_adapter

local tankDeuterium = nil
local tankTritium = nil

local active = nil
local injectionRate = 0
local energyProducing = false

local reactorTransposer = false

local sideReactor = false
local sideStorage = false

local chargePercent = false

local hasHohlraum = false

local tankName = "ultimate_gas_tank"

function format(val)
    if val > 1000000000000 then return (math.floor(val/100000000000)/10) .. "T"
    elseif val > 1000000000 then return (math.floor(val/100000000)/10) .. "G"
    elseif val > 1000000 then return (math.floor(val/100000)/10) .. "M"
    elseif val > 1000 then return (math.floor(val/100)/10) .. "k"
    else return math.floor(val*10)/10; end
end

function getHohlraum(side)
    for i=1,transposer.getInventorySize(side) do
        local slotData = transposer.getStackInSlot(side, i)
        if slotData ~= nil and slotData.name == "mekanismgenerators:hohlraum" then
            return { slot = i, stack = slotData }
        end
    end
    return false
end

function getHohlraumLabel()
    if hasHohlraum then return "eject hohlraum"
    else return "load hohlraum"; end
end

function setInjectionRate(rate)
    reactor.setInjectionRate(rate)
end

function transferHohlraum()
    if hasHohlraum then
        transposer.transferItem(sideReactor, sideStorage, 1)
    else
        local data = getHohlraum(sideStorage)
        if not data then return false; end
        transposer.transferItem(sideStorage, sideReactor, 1, data.slot)
    end

    hasHohlraum = getHohlraum(sideReactor) ~= false

    return hasHohlraum
end

function isReactorTransposer(transposer)
    for i=0,#sides-1 do
        if transposer.getInventoryName(i) == "mekanismgenerators:reactor" then
            return true
        end
    end
    return false
end

function canIgnite()
    
    if injectionRate == 0 then return { ready = false, error = "injection rate is 0" }; end
    if chargePercent < 40 then return { ready = false, error = "laser not charged" }; end
    if reactor.getDeuterium() < 500 then return { ready = false, error = "<500mB deuterium" }; end
    if reactor.getTritium() < 500 then return { ready = false, error = "<500mB tritium" }; end
    if not hasHohlraum then return { ready = false, error = "missing hohlraum" }; end

    return { ready = true }
end

function initializeReactor()
    for address,type in pairs(component.list(tankName)) do
        local tank = component.proxy(address)
        local gas = tank.getGas()
        if gas.name == "tritium" then
            tankTritium = tank
        elseif gas.name == "deuterium" then
            tankDeuterium = tank
        end
    end

    for address, type in pairs(component.list("transposer")) do
        if isReactorTransposer(component.proxy(address)) then
            transposer = component.proxy(address)
            for i=0,#sides-1 do
                if transposer.getInventoryName(i) == "mekanismgenerators:reactor" then
                    sideReactor = i
                elseif transposer.getInventorySize(i) ~= nil then
                    sideStorage = i
                end
            end
        end
    end

    injectionRate = reactor.getInjectionRate()
    active = reactor.getProducing() > 0
    energyProducing = format(reactor.getProducing())
    hasHohlraum = getHohlraum(sideReactor) ~= false
end