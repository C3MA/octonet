function loadApp()
    require("init2")
end
tmr.alarm(6,5000,tmr.ALARM_SINGLE,loadApp)