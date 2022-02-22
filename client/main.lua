Weather = {}
Weather.SyncWeather = true
Weather.SyncTime = true
Weather.ChangingWeather = false
Weather.current = nil
Weather.blackout = false

function Weather:ChangeWeatherSync(state)
    self.SyncWeather = state
end

function Weather:SyncWeather(weather,transitionTime) 
    if not self.SyncWeather or self.ChangingWeather then
        return
    end
    
    if not self.current or self.current ~= weather then
        self.ChangingWeather = true
        
        SetWeatherTypeOverTime(weather, 30.0)
        
        Utils:Timeout(function()
            self.ChangingWeather = false
        end, 30000)
    end

    self.current = weather
end

function Weather:ManageWeather()
    self:SyncWeather(self.current)

    CreateThread(function()
        while true do
            Wait(1000)
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist(self.current)
            SetWeatherTypeNow(self.current)
            SetWeatherTypeNowPersist(self.current)

            if self.current == "XMAS" then
                SetForceVehicleTrails(true)
                SetForcePedFootstepsTracks(true)
            else
                SetForceVehicleTrails(false)
                SetForcePedFootstepsTracks(false)
            end
        end
    end)
end

function Weather:Blackout(state)
    self.blackout = state

    if not self.blackout then
        return
    end

    CreateThread(function()
        while self.blackout do
            SetArtificialLightsState(true)
            SetArtificialLightsStateAffectsVehicles(false)
            Wait(0)
        end

        SetArtificialLightsState(false)
        SetArtificialLightsStateAffectsVehicles(false)
    end)
end

function Weather:ChangeTimeSync(state)
    self.SyncTime = state
end

function Weather:SyncTime(timeData)
    if not self.SyncTime then
        return
    end

    NetworkOverrideClockTime(timeData.hour, timeData.minute, 0)
end

function Weather:Start()
	self.current = GlobalState.Weather
    self.blackout = GlobalState.Blackout

    self:ManageWeather()
    self:Blackout(self.blackout)

    AddStateBagChangeHandler(nil ,nil, function(bagName,key,value,reserved,replicated)
        if bagName == "global" then
            if key == "Weather" then
                self:SyncWeather(value)
            elseif key == "Blackout" then
                self:Blackout(value)
            elseif key == "Time" then
                self:SyncTime(value)
            end
        end
    end)
end

AddEventHandler("ooc_playerloaded", function()
    Weather:Start()
end)