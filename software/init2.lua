
local translate ={}
translate[2]=4
translate[4]=2
translate[5]=1
translate[9]=11
translate[12]=6
translate[13]=7
translate[14]=5
translate[16]=0

local rows = {4,5,12}
local columns = {13,14,16,2}

for _,row in ipairs(rows) do
    gpio.mode(translate[row],gpio.OUTPUT)
end
for _,column in ipairs(columns) do
    gpio.write(translate[column],gpio.LOW);
    gpio.mode(translate[column],gpio.INPUT)
end


function doStuff()
      
      for _,row in ipairs(rows) do
        gpio.write(translate[row],gpio.HIGH);
        for _,column in ipairs(columns) do
            local isPressed = gpio.read(translate[column]);
            print(row .. " " .. column .. " pressed " .. isPressed)
        end
        gpio.write(translate[row],gpio.LOW);
      end

      for _,column in ipairs(columns) do
        gpio.write(translate[column],gpio.LOW);
      end
    print(node.heap());
end


tmr.alarm(0,1000,tmr.ALARM_AUTO,doStuff)