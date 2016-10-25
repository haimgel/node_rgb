--[[
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

-- How often the values are updated during fading in/out. 25 times per second is a good value.
LED_TIMER_HZ = 25

-- *** GLOBAL VARIABLES BEGIN ***
-- variables used to store the state, the brightness and the color of the light
ledState = default_state
ledBrightness = default_brightness
ledRed = default_red
ledGreen = default_green
ledBlue = default_blue
-- How long should it take to change from current to target value, in ms.
ledFadeTime = default_fadetime
-- *** GLOBAL VARIABLES END ***

local ledTarget = { r=0, g=0, b=0 }
local ledCurrent = { r=0, g=0, b=0 }
local ledSteps = { r=0, g=0, b=0 }
local ledTimer;

-- Returns true of two RGB triplets are equal
local function equalRGB(v1, v2)
    return ((v1.r == v2.r) and (v1.g == v2.g) and (v1.b == v2.b))
end

local function isZeroRGB(val)
    return ((val.r == 0) and (val.g == 0) and (val.b == 0))
end

-- Setup LED pins, timer, etc.
function ledsSetup()
    -- 120hz frequency for PWM is good enough, I think.
    pwm.setup(pin_red, 120, 0)
    pwm.setup(pin_green, 120, 0)
    pwm.setup(pin_blue, 120, 0)
    ledTimer = tmr.create()
    ledTimer:register(1000 / LED_TIMER_HZ, tmr.ALARM_AUTO, ledsTimerFunc)
end

-- Turn the PWM on/off, used internally onyl
local function ledsSwitch(on_off)
    if on_off then
        pwm.start(pin_red)
        pwm.start(pin_green)
        pwm.start(pin_blue)
        debugPrint(3, "LEDs: switched ON")
    else
        pwm.stop(pin_red)
        pwm.stop(pin_green)
        pwm.stop(pin_blue)
        debugPrint(3, "LEDs: switched OFF")
    end
end

-- Move the ledCurrent one step
function ledsMoveStep()
    if math.abs(ledCurrent.r - ledTarget.r) > math.abs(ledSteps.r) then
      ledCurrent.r = ledCurrent.r + ledSteps.r
    else
      ledCurrent.r = ledTarget.r
    end
    if math.abs(ledCurrent.g - ledTarget.g) > math.abs(ledSteps.g) then
        ledCurrent.g = ledCurrent.g + ledSteps.g
    else
        ledCurrent.g = ledTarget.g
    end
    if math.abs(ledCurrent.b - ledTarget.b) > math.abs(ledSteps.b) then
        ledCurrent.b = ledCurrent.b + ledSteps.b
    else
        ledCurrent.b = ledTarget.b
    end
    debugPrint(5, "LEDs: ledsMoveStep, current=" .. ledsFormat(ledCurrent) .. ", target=" .. ledsFormat(ledTarget))
end

-- Format RGB triplet for printing
function ledsFormat(val)
    return string.format("%d,%d,%d", val.r, val.g, val.b)
end

-- Calculate how many steps are needed to move from current to target
function ledsCalculateSteps()
    -- We are using 25hz update timer, so we have secs*25 discrete change steps.
    local steps = ledFadeTime * LED_TIMER_HZ / 1000
    debugPrint(3, string.format("LEDs: Discrete steps: %d", steps))
    ledSteps.r = (ledTarget.r - ledCurrent.r) / steps;
    if (ledSteps.r == 0) and (ledTarget.r ~= ledCurrent.r) then
      ledSteps.r = math.sign(ledTarget.r - ledCurrent.r)
    end
    ledSteps.g = (ledTarget.g - ledCurrent.g) / steps;
    if (ledSteps.g == 0) and (ledTarget.g ~= ledCurrent.g) then
        ledSteps.g = math.sign(ledTarget.g - ledCurrent.g)
    end
    ledSteps.b = (ledTarget.b - ledCurrent.b) / steps;
    if (ledSteps.b == 0) and (ledTarget.b ~= ledCurrent.b) then
        ledSteps.b = math.sign(ledTarget.b - ledCurrent.b)
    end
    debugPrint(3, "LEDs: Calculated steps: " .. ledsFormat(ledSteps))
end

-- "Raw" RGB values are in 0-256*1024 range, and PWM is in 0-1023!
local function ledsSetRawRGB(r,g,b)
    pwm.setduty(pin_red, r/256)
    pwm.setduty(pin_green, g/256)
    pwm.setduty(pin_blue, b/256)
end

-- Timer function for LED brightness change
function ledsTimerFunc()
    if not equalRGB(ledTarget, ledCurrent) then
        ledsMoveStep()
        ledsSetRawRGB(ledCurrent.r, ledCurrent.g, ledCurrent.b)
    else
        debugPrint(2, "LEDs: Reached target: " .. ledsFormat(ledCurrent))
        ledTimer:stop()
        if isZeroRGB(ledCurrent) then
            -- If we reached the "off" state, turn the PWM off completely.
            ledsSwitch(false)
        end
    end
end

-- Raw r, g, b values are in 256*1024 range (while input r, g, b are in 0-256, and brightness is 0-100)
local function ledsSetLedTarget()
    if ledState then
        ledTarget.r = ledRed * 1024 * ledBrightness / 100;
        ledTarget.g = ledGreen * 1024 * ledBrightness / 100;
        ledTarget.b = ledBlue * 1024 * ledBrightness / 100;
    else
        ledTarget.r = 0
        ledTarget.g = 0
        ledTarget.b = 0
    end
end

-- Update LEDs raw values and start the timer, if needed
function ledsUpdate()
    ledsSetLedTarget()
    debugPrint(2, "LEDs: Set target=" .. ledsFormat(ledTarget) .. ", current=" .. ledsFormat(ledCurrent))
    if not equalRGB(ledTarget, ledCurrent) then
        ledsCalculateSteps()
        if isZeroRGB(ledCurrent) then
            -- If we're moving out of total "off" state, turn the PWM on.
            ledsSwitch(true)
        end
        ledTimer:start()
    end
end

