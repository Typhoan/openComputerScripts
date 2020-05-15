local term = require("term")
local os = require("os")
local component = require('component')
local computer = require('computer')
local coroutine = require('coroutine')
local event = require('event')
local filesystem = require('filesystem')
local serialization = require('serialization')
local thread = require('thread')
local tty = require('tty')
local unicode = require('unicode')
local GUI = require('GUI')
local internet = require("internet")
local minitel = require("minitel")
 
 -----------------------GUI ELEMENT COLORS---------------------------
local C_BACKGROUND = 0x3C3C3C
local C_STATUS_BAR = 0xC3C3C3
local C_STATUS_TEXT = 0x1E1E1E
local C_STATUS_PRESSED = 0xFFFF00
local C_BADGE = 0xD2D2D2
local C_BADGE_ERR = 0xFF4900 --0xFFB6FF
local C_BADGE_BUSY = 0x336DFF
local C_BADGE_SELECTED = 0xFFAA00
local C_BADGE_TEXT = 0x1E1E1E
local C_INPUT = 0xFFFFFF
local C_INPUT_TEXT = 0x1E1E1E
local C_SCROLLBAR = C_BADGE_SELECTED
local C_SCROLLBAR_BACKGROUND = 0xFFFFFF
local C_REACTOR_LASER_CHARGE_LOW = 0xFD0000
local C_REACTOR_LASER_CHARGE_MEDIUM = 0xFDFD00
local C_REACTOR_LASER_CHARGE_HIGH = 0x1AAE00
local C_REACTOR_LASER_TEXT = 0x000000
local C_REACTOR_LASER_SECONDARY = 0xEEEEEE
local C_REACTOR_IGNITE_BACKGROUND = 0xFD0000
local C_REACTOR_IGNITE_TEXT = 0x000000
local C_REACTOR_IGNITE_BACKGROUND_PUSHED = 0xB00101
local C_REACTOR_HOHLRAUM_BACKGROUND = 0x760E7A
local C_REACTOR_HOHLRAUM_TEXT = 0x000000
local C_REACTOR_HOHLRAUM_BACKGROUND_PUSHED = 0x5F0C62
local C_REACTOR_INJECTION_RATE_BACKGROUND = 0xA3A2A3
local C_REACTOR_INJECTION_RATE_BACKGROUND_PUSHED = 0x6E6D6E
local C_REACTOR_INJECTION_RATE__TEXT = 0x000000
----------------------------------------------------------------------------

local REACTOR_INJECTION_RATE = 0

local proxy
local quit = false
 
status = {}

local chargePercent = 0

local ReactorStats = {
  injectionRate = 0,
  active = false,
  energyProducing = 0,
  hasHohlraum = false,
  deuterium = 0,
  tritium = 0,
  canIgnite = {ready = false, error = "injection rate = 0"}
}
 
function status.main(args)
  minitel.rsend("Reactor", port, serialization.serialize({event = "ReactorStatusUpdate"}))
  resetBColor, resetFColor = tty.gpu().getBackground(), tty.gpu().getForeground()  
 
  local app = buildGui()
  app:draw(true)

  local background = {}
  table.insert(background, event.listen("key_up", 
    function(key, address, char)
      if char == string.byte('q') then 
        event.push('exit')
      end
    end
  ))

  table.insert(background, event.listen("ignite", function()
    minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "Ignite"} ))
  end
  ))

  table.insert(background, event.listen("transfer", function()
    minitel.rsend("Reactor", port, serialization.serialize({event = "TransferHohlraum"}))
  end
  ))

  table.insert(background, event.listen("setInjectionRate", function()
    minitel.rsend("Reactor", port, serialization.serialize({event = "SetInjectionRate", result = REACTOR_INJECTION_RATE}))
  end
  ))

  table.insert(background, thread.create(
    function()
      os.sleep(1)
      minitel.rsend("Reactor", port, serialization.serialize({event = "ReactorStatusUpdate"}))
      minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "GetLaserCharge"}))
      updateReactorStatus()
    end
  ))

  table.insert(background, thread.create(failFast(function() app:start() end)))

  local _, err = event.pull('exit')

  app:stop()

  for _, b in ipairs(background) do
    if type(b) == 'table' and b.kill then
      b:kill()
    else
      event.cancel(b)
    end
  end

  tty.gpu().setBackground(resetBColor)
  tty.gpu().setForeground(resetFColor)
  tty.clear()

  if err then
    io.stderr:write(err)
    os.exit(1)
  else
    os.exit(0)
  end
end


function override(object, method, fn)
    local super = object[method] or function() end
    object[method] = function(...)
        fn(super, ...)
    end
end

function getLaserProgressBarColor()
  if chargePercent ~= nil then
    if chargePercent <= 25 then
      return C_REACTOR_LASER_CHARGE_LOW
    elseif chargePercent > 25 and chargePercent  <= 50 then
      return C_REACTOR_LASER_CHARGE_MEDIUM
    else 
      return C_REACTOR_LASER_CHARGE_HIGH
    end
  end
  return C_REACTOR_LASER_CHARGE_LOW
end

function buildGui()
  local app = GUI.application()
  local statusBar = app:addChild(GUI.container(1, 1, app.width, 1))
  local window = app:addChild(GUI.container(1, 1 + statusBar.height, app.width, app.height - statusBar.height))
  window:addChild(GUI.panel(1, 1, window.width, window.height, C_BACKGROUND))

  local columns = math.floor(window.width / 60) + 1

  if ReactorStats["active"] then
    window:addChild(GUI.text(2, 2, C_INPUT, "Active:            True"))
  else
    window:addChild(GUI.text(2, 2, C_INPUT, "Active:            False"))
  end
  window:addChild(GUI.text(2, 3, C_INPUT, "Producing:         "..ReactorStats["energyProducing"]))
  window:addChild(GUI.text(2, 4, C_INPUT, "Injection Rate:    "..ReactorStats["injectionRate"]))

  window:addChild(GUI.Button(4, 4, 30, 8, C_REACTOR_HOHLRAUM_BACKGROUND, C_REACTOR_HOHLRAUM_TEXT, C_REACTOR_HOHLRAUM_BACKGROUND_PUSHED, C_REACTOR_HOHLRAUM_TEXT, '[0]')).onTouch = function(app, object)
    REACTOR_INJECTION_RATE = 0
    event.push('setInjectionRate')
  end

  window:addChild(GUI.Button(5, 4, 30, 8, C_REACTOR_HOHLRAUM_BACKGROUND, C_REACTOR_HOHLRAUM_TEXT, C_REACTOR_HOHLRAUM_BACKGROUND_PUSHED, C_REACTOR_HOHLRAUM_TEXT, '[2]')).onTouch = function(app, object)
    REACTOR_INJECTION_RATE = 2
    event.push('setInjectionRate')
  end

  window:addChild(GUI.Button(6, 4, 30, 8, C_REACTOR_HOHLRAUM_BACKGROUND, C_REACTOR_HOHLRAUM_TEXT, C_REACTOR_HOHLRAUM_BACKGROUND_PUSHED, C_REACTOR_HOHLRAUM_TEXT, '[4]')).onTouch = function(app, object)
    REACTOR_INJECTION_RATE = 4
    event.push('setInjectionRate')
  end

  window:addChild(GUI.Button(7, 4, 30, 8, C_REACTOR_HOHLRAUM_BACKGROUND, C_REACTOR_HOHLRAUM_TEXT, C_REACTOR_HOHLRAUM_BACKGROUND_PUSHED, C_REACTOR_HOHLRAUM_TEXT, '[6]')).onTouch = function(app, object)
    REACTOR_INJECTION_RATE = 6
    event.push('setInjectionRate')
  end

  window:addChild(GUI.Button(8, 4, 30, 8, C_REACTOR_HOHLRAUM_BACKGROUND, C_REACTOR_HOHLRAUM_TEXT, C_REACTOR_HOHLRAUM_BACKGROUND_PUSHED, C_REACTOR_HOHLRAUM_TEXT, '[8]')).onTouch = function(app, object)
    REACTOR_INJECTION_RATE = 8
    event.push('setInjectionRate')
  end

  window:addChild(GUI.text(2, 5, C_INPUT, "Deuterium Gas:     "..ReactorStats["deuterium"]))
  window:addChild(GUI.text(2, 6, C_INPUT, "Tritium Gas:       "..ReactorStats["tritium"]))

  if ReactorStats["active"] == false then
    if ReactorStats["hasHohlraum"] then
      window:addChild(GUI.text(2, 7, C_INPUT, "Hohlraum Inserted"))
    else 
      window:addChild(GUI.text(2, 7, C_INPUT, "Hohlraum Missing"))
      window:addChild(GUI.roundedButton(4, 8, 10, 2, C_REACTOR_HOHLRAUM_BACKGROUND, C_REACTOR_HOHLRAUM_TEXT, C_REACTOR_HOHLRAUM_BACKGROUND_PUSHED, C_REACTOR_HOHLRAUM_TEXT, '[TRANSFER]')).onTouch = function(app, object)
        event.push('transfer')
      end
    end

    if ReactorStats["canIgnite"]["ready"] == true and chargePercent >= 70 then
      window:addChild(GUI.text(2, 8, C_INPUT, "Ready to Ignite:  "))
      window:addChild(GUI.roundedButton(4, 8, 10, 2, C_REACTOR_IGNITE_BACKGROUND, C_REACTOR_IGNITE_TEXT, C_REACTOR_IGNITE_BACKGROUND_PUSHED, C_REACTOR_IGNITE_TEXT, '[IGNITE]')).onTouch = function(app, object)
        event.push('ignite')
      end
      window:addChild(GUI.progressBar(2, 9, 80, getLaserProgressBarColor(), C_REACTOR_LASER_SECONDARY, C_REACTOR_LASER_TEXT, chargePercent, false, true, "Laser Charge: ", ""))
    else 
      local igniteError = ""
      if ReactorStats["canIgnite"].error ~=nill then
        igniteError = ReactorStats["canIgnite"].error
      else
        igniteError = "Lasers arnt Charged"
      end
      window:addChild(GUI.text(2, 9, C_INPUT, "Can't Ignite:  "..igniteError))
    end
  end


  statusBar:addChild(GUI.panel(1, 1, statusBar.width, statusBar.height, C_STATUS_BAR))
  local statusText = statusBar:addChild(GUI.text(2, 1, C_STATUS_TEXT, 'Base Stats'))
  --statusText.eventHandler = function(app, self)
  --    self.text = string.format('AE Management System Free Cpus %d/%d', status.freeCpus, status.totalCpus)
  --end
  --statusText.eventHandler(app, statusText)
  local cfgBtn = statusBar:addChild(GUI.button(statusBar.width - 14, 1, 8, 1, C_STATUS_BAR, C_STATUS_TEXT, C_STATUS_BAR, C_STATUS_PRESSED, '[Config]'))
  cfgBtn.switchMode = true
  cfgBtn.animationDuration = .1
  cfgBtn.onTouch = function(app, object)
      configView.hidden = not object.pressed
  end
 
  statusBar:addChild(GUI.button(statusBar.width - 6, 1, 8, 1, C_STATUS_BAR, C_STATUS_TEXT, C_STATUS_BAR, C_STATUS_PRESSED, '[Exit]')).onTouch = function(app, object)
      event.push('exit')
  end
 
  return app
end
 
function failFast(fn)
    return function(...)
        local res = table.pack(xpcall(fn, debug.traceback, ...))
        if not res[1] then
            event.push('exit', res[2])
        end
        return table.unpack(res, 2)
    end
end

function status.setReactorStatus(statusUpdate)
  ReactorStats = statusUpdate
end

function status.setChargePercent(charge)
   chargePercent = charge
end

function updateReactorStatus()
  thread.create(function()
    os.sleep(5)
    minitel.rsend("Reactor", port, serialization.serialize({event = "ReactorStatusUpdate"}))
    minitel.rsend("LaserAmplifier", port, serialization.serialize({event = "GetLaserCharge"}))
    updateReactorStatus()
  end)
end

return status