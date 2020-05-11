component = require("component")
event = require("event")

reactor = component.reactor_logic_adapter

tankDeuterium = nil
tankTritium = nil

active = nil
injectionRate = 0
energyProducing = false

reactorDeuterium = false
reactorTritium = false
reactorTransposer = false

sideReactor = false
sideStorage = false

hasHohlraum = false

function getHohlraum(side)
    for i=1,transposer.getInventorySize(side) do
        slotData = transposer.getStackInSlot(side, i)
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

function transferHohlraum()
    if hasHohlraum then
        transposer.transferItem(sideReactor, sideStorage, 1)
    else
        data = getHohlraum(sideStorage)
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

    hasHohlraum = getHohlraum(sideReactor) ~= false
end