local component = require("component")

lib = {}

lib.reactor = component.reactor_logic_adapter

lib.tankDeuterium = nil
lib.tankTritium = nil

lib.active = nil
lib.injectionRate = 0
lib.energyProducing = false

local transposer = false
local reactorTransposer = false

local sideReactor = false
local sideStorage = false

lib.chargePercent = false

local hasHohlraum = false

local tankName = "ultimate_gas_tank"

function lib.format(val)
    if val > 1000000000000 then return (math.floor(val/100000000000)/10) .. "T"
    elseif val > 1000000000 then return (math.floor(val/100000000)/10) .. "G"
    elseif val > 1000000 then return (math.floor(val/100000)/10) .. "M"
    elseif val > 1000 then return (math.floor(val/100)/10) .. "k"
    else return math.floor(val*10)/10; end
end

function lib.getHohlraum(side)
    for i=1,transposer.getInventorySize(side) do
        local slotData = transposer.getStackInSlot(side, i)
        if slotData ~= nil and slotData.name == "mekanismgenerators:hohlraum" then
            return { slot = i, stack = slotData }
        end
    end
    return false
end

function lib.getHohlraumLabel()
    if lib.hasHohlraum then return "eject hohlraum"
    else return "load hohlraum"; end
end

function lib.setInjectionRate(rate)
    lib.reactor.setInjectionRate(rate)
end

function lib.transferHohlraum()
    if hasHohlraum then
        transposer.transferItem(sideReactor, sideStorage, 1)
    else
        local data = lib.getHohlraum(sideStorage)
        if not data then return false; end
        transposer.transferItem(sideStorage, sideReactor, 1, data.slot)
    end

    hasHohlraum = lib.getHohlraum(sideReactor) ~= false

    return hasHohlraum
end

function lib.isReactorTransposer(transposer)
    for i=0,#sides-1 do
        if transposer.getInventoryName(i) == "mekanismgenerators:reactor" then
            return true
        end
    end
    return false
end

function lib.canIgnite()
    
    if lib.injectionRate == 0 then return { ready = false, error = "injection rate is 0" }; end
    if lib.chargePercent < 40 then return { ready = false, error = "laser not charged" }; end
    if lib.reactor.getDeuterium() < 500 then return { ready = false, error = "<500mB deuterium" }; end
    if lib.reactor.getTritium() < 500 then return { ready = false, error = "<500mB tritium" }; end
    if not lib.hasHohlraum then return { ready = false, error = "missing hohlraum" }; end

    return { ready = true }
end

function lib.initializeReactor()
    for address,type in pairs(component.list(tankName)) do
        local tank = component.proxy(address)
        local gas = tank.getGas()
        if gas.name == "tritium" then
            lib.tankTritium = tank
        elseif gas.name == "deuterium" then
            lib.tankDeuterium = tank
        end
    end

    for address, type in pairs(component.list("transposer")) do
        if lib.isReactorTransposer(component.proxy(address)) then
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

    lib.injectionRate = lib.reactor.getInjectionRate()
    lib.active = lib.reactor.getProducing() > 0
    lib.energyProducing = lib.format(lib.reactor.getProducing())
    lib.hasHohlraum = lib.getHohlraum(sideReactor) ~= false

    return true
end

return lib