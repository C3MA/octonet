--allow easy dev flash
tmr.stop(0)
tmr.stop(1)
tmr.stop(2)
tmr.stop(3)
tmr.stop(4)
tmr.stop(5)
tmr.stop(6)

require("tableutil")

local octoprint1 = "10.23.42.33/api/"
local octoprint1Key="?apikey=BDF6EAA71A08438EB8CE209F18F448DB"

local selectedOctoPrint = octoprint1;
local selectedOctoPrintKey = octoprint1Key;
 
local FIND_WLAN = 0;
local BASIC_CONN_OCTO = 1;
local READY = 3;

translate ={}
translate[2]=4
translate[4]=2
translate[5]=1
translate[9]=11
translate[12]=6 
translate[13]=7
translate[14]=5
translate[16]=0

--init pins and librarys  
local rows = {4,5,12}
local columns = {13,14,16,2}

ws2812.init();
ws2812.write(string.char(0,0,0):rep(5))
wifi.setmode(wifi.STATION)
 
state = FIND_WLAN;

local requestRunning = false;
function doRequest(api,callback,delay,post)
    if(delay == nil or delay < 10)then
        delay = 10
    end
   
    requestRunning=true
    local answer = function(code,data)
        local delayedAnswer = function()  
            if(api~="printer")then
                print(data)
            end
            requestRunning=false;
            if(callback ~= nil)then
                local success,tableAnswer = pcall(cjson.decode,data);
                if(success)then
                    callback(tableAnswer)  
                end
            else
                print("JsonError cannot parse \n" .. data)
                state = FIND_WLAN
            end
        end
        tmr.alarm(6,delay,tmr.ALARM_SINGLE,delayedAnswer)
    end
    if(post)then
        local encoded = cjson.encode(post)
        print("Requesting " .. api .. " " .. encoded)
        http.post("http://"..selectedOctoPrint.. api ..selectedOctoPrintKey , 'Content-Type: application/json\r\n',encoded,answer)
    else
        if(api~="printer")then
            print("Requesting " .. api)
        end
        http.get("http://"..selectedOctoPrint.. api ..selectedOctoPrintKey , nil,answer)
    end
end

function octoPrintReadyCallback(tableAnswer)
    if(tableAnswer.state.flags.ready)then
        state = READY
    else
        state = FIND_WLAN
    end
end

function watchConnection()
    if(state ~= FIND_WLAN)then
        if(not requestRunning)then
            doRequest("printer",octoPrintReadyCallback,nil)
        end
    end
end

function doWlanStuff()
    if(state ~= FIND_WLAN and wifi.sta.getip() == nil) then
        state = FIND_WLAN
    end
    if(state == FIND_WLAN and wifi.sta.getip() ~= nil) then
        state=BASIC_CONN_OCTO;
    end
end

function dutyCycle()
    --clear charge and set mode
    for _,column in ipairs(columns) do
        gpio.mode(translate[column],gpio.OUTPUT)
        gpio.write(translate[column],gpio.LOW);
    end

    for _,row in ipairs(rows) do
        gpio.mode(translate[row],gpio.INPUT)
        gpio.write(translate[row],gpio.LOW);
    end
    --pll the matrix
    for _,column in ipairs(columns) do      
        gpio.write(translate[column],gpio.HIGH);
        for _,row in ipairs(rows) do
            local isPressed = gpio.read(translate[row]);
            if(isPressed == 1)then
                if(row==12 and column==16)then
                    local request = {}
                    request.command="home"
                    request.axes={"x","y"}
                    doRequest("printer/printhead",nil,100,request)
                end
                print(row .. " " .. column .. " pressed " .. isPressed)
            end
        end
        gpio.write(translate[column],gpio.LOW);
    end
    --reinit ws2812
    ws2812.init()
end


local tick = false;
function initSequence()
    tick = not tick
    doWlanStuff()
    if(node.heap() < 33000)then
        print(node.heap())
    end

   
 
    if state ~= READY then
        if(tick)then
            ws2812.write(string.char(0,0,100):rep(state) .. string.char(100,0,0):rep(1))
        else
            ws2812.write(string.char(0,0,100):rep(state) .. string.char(0,0,0):rep(1))
        end
    else
        if(requestRunning)then
            ws2812.write(string.char(0,50,0):rep(5))
        else
            dutyCycle()
            --todo here intelligent state info
            ws2812.write(string.char(20,0,0):rep(5))
        end
    end
end

--init work cycle
tmr.alarm(0,100,tmr.ALARM_AUTO,initSequence)
--init web refresh worker
tmr.alarm(1,2000,tmr.ALARM_AUTO,watchConnection)
-- startSystem
wifi.sta.config("C3MA","chaosimquadrat",true)
