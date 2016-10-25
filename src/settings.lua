
-- Wi-Fi connection settings
ap_ssid="MODIFY-ME"
ap_pass="my-secret-wifi-password"

-- MQTT connnection settings
mqtt_server="my-mqtt.example.com"
mqtt_port=1883
mqtt_user_name=""
mqtt_password=""
mqtt_timeout=30

-- Modify these to uniquely identify each instance
mqtt_client_id="bedroom_bed"
mqtt_topic_root="bedroom/bed"

-- default settings
default_state = false
default_red = 255
default_green = 255
default_blue = 255
default_brightness = 100
-- How long should it take to change from current to target value, in ms.
default_fadetime = 2000

-- debugPrint with level above this won't be printed
debuglevel = 3


--[[
  Pin configuration
  =================

  Usage        Board marking (NodeMCU index)     Internal name
  -----        -----------------------------     -------------
  Red          D6 (6)                            GPIO14
  Green        D5 (5)                            GPIO12
  Blue         D7 (7)                            GPIO13
  Builtin-led  -  (0)                            GPIO16

  References:
      https://github.com/esp8266/Arduino/blob/master/variants/nodemcu/pins_arduino.h#L37-L59
      https://nodemcu.readthedocs.io/en/master/en/modules/gpio

]]

pin_red = 6
pin_green = 5
pin_blue = 7
