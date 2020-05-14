local event = require("event")
local serialization = require("serialization")
local minitel = require("minitel")
local BaseStats = require("BaseStatsLib")

function eventHandler(_, from, port, rawData)
    local data = serialization.unserialize(rawData)
    if data.event == "ReactorStatusUpdate" then
        local statusUpdate = data.result
        BaseStats.setReactorStatus(statusUpdate)
    end
end

event.listen("net_msg", eventHandler)

BaseStats.main()


