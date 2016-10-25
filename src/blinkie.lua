
--[[

  Blinks on-board LED to indicate current status:

  Every 10-second blink: OK
  rapid blink: not connected to MQTT, or some other connectivity problem.
  Two blinks on every MQTT command receipt.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

 ]]

PIN_BLINKIE = 0
BLINKIE_TIMER_HZ = 10

blinkieFault = true
local blinkieTimer
local blinkieState = false
local blinkieCountdown = 0

-- Set on-board LED to either ON or OFF state
local function blinkieSet(value)
    if value then
        gpio.write(PIN_BLINKIE, gpio.LOW)
    else
        gpio.write(PIN_BLINKIE, gpio.HIGH)
    end
end

-- Flash the LED once (this does not actually flash, just makes sure the timer flashes on next run).
function blinkieFlash()
    blinkieState = false
    blinkieCountdown = 0
end

-- Setup the blinking on-board LED
function blinkieSetup()
    blinkieFault = true
    blinkieTimer = tmr.create()
    blinkieTimer:alarm(1000 / BLINKIE_TIMER_HZ, tmr.ALARM_AUTO, blinkieTimerFunc)
    gpio.mode(PIN_BLINKIE, gpio.OUTPUT)
    blinkieSet(false)
end

-- Update the blinking LED state (on/off) - timer function
function blinkieTimerFunc()
    if blinkieState then
        blinkieState = false
        if blinkieFault then
            blinkieCountdown = 1
        else
            blinkieCountdown = BLINKIE_TIMER_HZ * 10
        end
    else
        if blinkieCountdown > 0 then
            blinkieCountdown = blinkieCountdown - 1
        else
            blinkieState = true
        end
    end
    blinkieSet(blinkieState)
end
