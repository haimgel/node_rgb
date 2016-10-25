
# NodeRGB MQTT LED Strip Controller

This software lets you control an RGB led strip via a MQTT-compatible home automation controller.

## Notable features

 * Automatic re-connection to Wi-Fi or MQTT if disconnected.
 * Gradual change during on/off, color or brightness changes, with customizable fade period.
 * Reporting of current state back to MQTT server.

## Hardware needed

 1. NodeMCU board (a cheap ESP8266 WiFi SOC). Any NodeMCU-compatible board would do, as only 3 digital outputs are needed.
 2. Means to interface NodeMCU to a LED strip. I've ordered this [MOSFET breakout module](https://www.ebay.com/itm/301357646243)
    from eBay, but of course it could be easily and cheaply done on a prototype board. Note that relay output won't do,
    since we're doing fade in/fade out here, need MOSFETs for switching.
 3. Means to power NodeMCU from 12V power source. There are many DC-DC step down power adapters on eBay,
    available for a couple dollars each.
 4. An enclosure to store the boards. Just keep the USB port accessible, in case you need to change your Wi-Fi
    password or MQTT server address.
 5. 5050-type (non-addressable) RGB LEDs strip, or similar. Any RGB LEDs strip that accepts R, G, B and +12V input will
    do, just make sure that it's total wattage is within limits of your MOSFET driver and your power supply.
 6. 12V power brick. Be sure it's powerful enough for your LED strip, plus some safety margin.

## Customizing software

See `settings.lua` for all cusomizable settings. You need to provide your Wi-Fi connection paramters, MQTT server address
and username/password if needed, and make sure the pin numbers for Red, Green and Blue match your setup. No other files
need to be modified.

## Uploading software to NodeMCU

  1. Upload NodeMCU firmware. I've used `integer` firmware, `master` branch from 2016/10/12, with the following modules:
     `gpio, mqtt, net, node, pwm, tmr, uart, wifi`. Get yours at https://nodemcu-build.com/
  2. Upload NodeRGB software (make sure you customized `settings.lua` first). Use [esplorer](http://esp8266.ru/esplorer)
     or any other similar tool of your choice, and upload *all* files in the `src` subdirectory.
  3. Connect to NodeMCU with your terminal software (115200bps, 8N1), reset the module and see that it functions
     correctly: connects to MQTT, accepts commands, etc.

## Indication LED

  The on-board LED will flash rapidly if the software is **not** properly connected to either Wi-Fi or MQTT server,
  and will blink once every 10 seconds if the module is connected and functioning properly. It will also blink once
  every time an MQTT command is received.

## MQTT commands and status updates

Suppose the MQTT root topic is set to `bedroom/bed` in `settings.lua`. Then, the following commands will be accepted by NodeRGB:

 * `bedroom/bed/light/set`: payload is either `on` or `off`, turns the light on and off.
 * `bedroom/bed/brightness/set`: payload is an integer from 0 to 100.
 * `bedroom/bed/rgb/set`: payload is a comma-separated triplet of integer values from 0 to 255. For example, 255,0,0 set the light color to red.
 * `bedroom/bed/fadetime/set`: payload is an integer from 0 to 3600000, set the fade-in/fade-out time in milliseconds. Default is 2000, or 2 seconds.

NodeRGB reports back the following topics:

  * `bedroom/bed/status`: payload is either `connected` or `disconnected`, `disconnected` is set via Last Will and Testament.
  * `bedroom/bed/light/status`: the payload reflects the commands specified above.
  * `bedroom/bed/brightness/status`: same as above.
  * `bedroom/bed/rgb/status`: same as above.
  * `bedroom/bed/fadetime/status` same as above.

NodeRGB sets the `retain` flag on, so if your home-automation controller is restarted, it will
receive the current data from MQTT server upon reconnection.

## Setting up Home Assistant

Set up your Home Assistant like this:

~~~~
 light:
   - platform: mqtt
     name: 'Master Bedroom Bed Light'
     state_topic: 'bedroom/bed/light/status'
     command_topic: 'bedroom/bed/light/set'
     brightness_state_topic: 'bedroom/bed/brightness/status'
     brightness_command_topic: 'bedroom/bed/brightness/set'
     rgb_state_topic: 'bedroom/bed/rgb/status'
     rgb_command_topic: 'bedroom/bed/rgb/set'
     brightness_scale: 100
     optimistic: false
     retain: true
     qos: 1
~~~~

Setting `retain` flag to `on` allows NodeRGB to re-acquire needed settings in case mains power was lost, or the module is
rebooted for any other reason.

## License

This software is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.