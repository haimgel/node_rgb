
--[[
  The code below is based upon the following blog post:
  https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/
  ]]

uart.setup(0,115200,8,0,1,1)

function abortInit()
    -- initailize abort boolean flag
    init_abort_flag = false
    print('Press ENTER to abort startup ...')
    -- if <CR> is pressed, call abortTest
    uart.on('data', '\r', abortTest, 0)
    -- start timer to execute startup function in 5 seconds
    tmr.alarm(0,5000,0,startup)
end

function abortTest(data)
    -- user requested abort
    init_abort_flag = true
    -- turns off uart scanning
    uart.on('data')
end

function startup()
    uart.on('data')
    -- if user requested abort, exit
    if init_abort_flag == true then
        print('Startup aborted')
        return
    end
    -- otherwise, start up
    print('In startup')
    require('main')
end

tmr.alarm(0,1000,0,abortInit)
