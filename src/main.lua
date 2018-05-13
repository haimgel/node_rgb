--[[
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

require('settings')
require('utils')
require('leds')
require('blinkie')

local tmrReconnect;

-- Publish status to MQTT (just a wrapper with debug output)
local function mqttPublish(topic, payload, qos, retain)
    m:publish(mqtt_topic_root .. topic, payload, qos, retain)
    debugPrint(1, string.format("MQTT: published: %s%s:%s (%d,%d)", mqtt_topic_root, topic, payload, qos, retain))
end

-- Publish the state of the led (on/off)
local function mqttPublishState()
    mqttPublish("/light/status",  bool2str(ledState), 1, 1)
end

-- Publish the brightness of the led (0-100)
local function mqttPublishBrightness()
    mqttPublish("/brightness/status",  string.format("%d", ledBrightness), 1, 1)
end

-- Publish colors of the led (xx(x),xx(x),xx(x))
local function mqttPublishRGB()
    mqttPublish("/rgb/status",  string.format("%d,%d,%d", ledRed, ledGreen, ledBlue), 1, 1)
end

-- Publish how long does it take to change to new color values (in ms)
local function mqttPublishFadeTime()
    mqttPublish("/fadetime/status",  string.format("%d", ledFadeTime), 1, 1)
end

-- Publish all data (called on reconnect)
local function mqttPublishAll()
    mqttPublishState()
    mqttPublishBrightness()
    mqttPublishRGB()
    mqttPublishFadeTime()
    mqttPublish("/status",  "connected", 1, 1)
end

-- Process incoming MQTT messages
local function mqttMessage(conn, topic, data)
    debugPrint(1, "MQTT: message recieved: " .. topic .. ":" .. data)
    _, _, param = string.find(topic, mqtt_topic_root .. "/(%a+)/set")
    if param == "light" then
        ledState = str2bool(data)
        blinkieFlash()
        ledsUpdate()
        mqttPublishState()
    elseif param == "brightness" then
        val = tonumber(data)
        if (val >= 0) and (val <= 100) then
            ledBrightness = val
            blinkieFlash()
            ledsUpdate()
            mqttPublishBrightness()
        end
    elseif param == "fadetime" then
        val = tonumber(data)
        if (val >= 0) and (val <= 60*60*1000) then
            ledFadeTime = val
            blinkieFlash()
            mqttPublishFadeTime()
        end
    elseif param == "rgb" then
        _, _, r, g, b = string.find(data, "(%d+),(%d+),(%d+)")
        r = tonumber(r)
        g = tonumber(g)
        b = tonumber(b)
        if (r ~= nil) and (g ~= nil) and (b ~= nil) and
           (r >= 0) and (g >= 0) and (b >= 0) and
           (r <= 255) and (g <= 255) and (b <= 255) then
            ledRed = r
            ledGreen = g
            ledBlue = b
            blinkieFlash()
            ledsUpdate()
            mqttPublishRGB()
        end
    else
      debugPrint(0, "MQTT: Unknown 'set' parameter: " .. param)
    end
end

-- Schedule MQTT reconnection attempts every 5 seconds
function mqttScheduleReconnect()
    debugPrint(4, "MQTT: mqttScheduleReconnect")
    tmrReconnect:start()
end

-- Subscribe to MQTT commands
local function mqttSubscribe()
    if not m:subscribe(mqtt_topic_root .. "/+/set",0, function(conn)
        debugPrint(1, "MQTT: subscribed to " .. mqtt_topic_root)
    end) then
        debugPrint(1, "MQTT: could not subscribe to " .. mqtt_topic_root)
    end
end

-- Connect to MQTT server (wrapper)
local function mqttConnect()
    if not m:connect(mqtt_server, mqtt_port,
        0, -- Secure
        1, -- Autoreconnect
        function(conn)
            debugPrint(0, "MQTT: connected to " .. mqtt_server)
            mqttSubscribe()
            ledsUpdate()
            mqttPublishAll()
            blinkieFault = false
        end,
        function(conn, reason)
            debugPrint(0, "MQTT: could not connect to " .. mqtt_server .. ": " .. reason .. ", scheduling reconnect")
            blinkieFault = true
            mqttScheduleReconnect()
        end) then
        debugPrint(0, "MQTT: connection to " .. mqtt_server .. " failed, scheduling reconnect")
        mqttScheduleReconnect()
    end
end

-- Try and reconnect to MQTT server
function mqttReconnect()
    debugPrint(4, "MQTT: mqttReconnect started")
    if (m == nil) or (wifi.sta.status() ~= wifi.STA_GOTIP) or (wifi.sta.getip() == nil) then
        mqttScheduleReconnect();
        debugPrint(4, "MQTT: mqttReconnect aborted")
        return;
    end
    local status, errcode = pcall(mqttConnect)
    if not status then
        debugPrint(2, "MQTT: Connection exception: " .. errcode)
    end
    debugPrint(4, "MQTT: mqttReconnect finished")
end

-- Set up MQTT client
local function mqttSetup()
    tmrReconnect = tmr.create()
    tmrReconnect:register(5000, tmr.ALARM_SEMI, mqttReconnect)
    -- More info: https://nodemcu.readthedocs.io/en/master/en/modules/mqtt/
    m = mqtt.Client(mqtt_client_id, mqtt_timeout, mqtt_user_name, mqtt_password)
    m:lwt(mqtt_topic_root .. "/status",  "disconnected", 1, 1)
    m:on("offline", function(con)
        debugPrint(0, "MQTT: offline, will reconnect ...")
        blinkieFault = true
        mqttScheduleReconnect()
    end)
    m:on("message", function(conn, topic, data)
        mqttMessage(conn, topic, data)
    end)
    mqttScheduleReconnect()
end

-- Set up Wi-Fi connection
local function wifiSetup()
    -- More info, see https://nodemcu.readthedocs.io/en/master/en/modules/wifi/
    wifi.setmode(wifi.STATION)
    wifi.setphymode(wifi.PHYMODE_N) -- Least power draw
    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
        debugPrint(0, "Wi-Fi: disconnected.")
        m:close()
        blinkieFault = true
    end)
    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
        debugPrint(0, "Wi-Fi: got IP " .. T.IP)
        mqttScheduleReconnect()
    end)
    wifi.sta.config {ssid=ap_ssid, pwd=ap_pass}
end

-- Main program entry point
function main()
    debugPrint(0, "***** NodeRGB v1.0 startup *****")
    blinkieSetup()
    ledsSetup()
    wifiSetup()
    mqttSetup()
    debugPrint(4, "Main complete")
end

main()
