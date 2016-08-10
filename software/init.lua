function loadApp()
    require("init2")
end
tmr.alarm(6,10000,tmr.ALARM_SINGLE,loadApp)
