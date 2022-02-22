Weather = {}
Weather.WeatherInterval = {min = 1000 * 60 * 10, max = 1000 * 60 * 30}
Weather.NextWeatherUpdate = 0
Weather.LastWeatherUpdate = 0
Weather.CurrentTime = {hour = math.floor((((os.time(os.date("!*t")) / 2 + 360) + 0) / 60) % 24), minute = math.floor(((os.time(os.date("!*t")) / 2 + 360) + 0) % 60)}
Weather.CurrentTimeOffSet = 0
Weather.current = "EXTRASUNNY"
Weather.blackout = false
Weather.DoSyncTime = true
Weather.DoWeatherSync = true

Weather.List = {
    EXTRASUNNY = {
        {name = "CLEAR", chances = 20},
        {name = "FOGGY", chances = 20},
        {name = "OVERCAST", chances = 20},
        {name = "CLOUDS", chances = 20},
        {name = "EXTRASUNNY", chances = 20}
    },

    CLEAR = {
        {name = "EXTRASUNNY", chances = 20},
        {name = "FOGGY", chances = 20},
        {name = "OVERCAST", chances = 20},
        {name = "CLOUDS", chances = 20}  
    },

    FOGGY = {
        {name = "CLEAR", chances = 20},
        {name = "FOGGY", chances = 20},
        {name = "OVERCAST", chances = 20},
        {name = "CLOUDS", chances = 20},
        {name = "EXTRASUNNY", chances = 20}
    },

    OVERCAST = {
        {name = "FOGGY", chances = 20},
        {name = "OVERCAST", chances = 20},
        {name = "CLOUDS", chances = 20},
        {name = "CLEAR", chances = 20}
    },

    CLOUDS = {
        {name = "FOGGY", chances = 20},
        {name = "OVERCAST", chances = 20},
        {name = "CLOUDS", chances = 20},
    },

    CLEARING = {
        {name = "FOGGY", chances = 20},
        {name = "CLOUDS", chances = 20},
    },

    NEUTRAL = {
        {name = "OVERCAST", chances = 20},
        {name = "FOGGY", chances = 20},
        {name = "CLOUDS", chances = 20}
    },

    THUNDER = {
        {name = "OVERCAST", chances = 20},
        {name = "CLOUDS", chances = 20},
        {name = "FOGGY", chances = 20}
    },

    RAIN = {
        {name = "RAIN", chances = 20},
        {name = "OVERCAST", chances = 20},
        {name = "CLOUDS", chances = 20},
        {name = "FOGGY", chances = 20}
    },

    XMAS = {
        {name = "XMAS", chances = 20},
        {name = "SNOWLIGHT", chances = 20},
        {name = "BLIZZARD", chances = 20},
        {name = "SNOW", chances = 20}
    },

    SNOWLIGHT = {
        {name = "XMAS", chances = 20},
        {name = "SNOWLIGHT", chances = 20},
        {name = "BLIZZARD", chances = 20},
        {name = "SNOW", chances = 20}
    },

    BLIZZARD = {
        {name = "XMAS", chances = 20},
        {name = "SNOWLIGHT", chances = 20},
        {name = "BLIZZARD", chances = 20},
        {name = "SNOW", chances = 20}
    },

    SNOW = {
        {name = "XMAS", chances = 20},
        {name = "SNOWLIGHT", chances = 20},
        {name = "BLIZZARD", chances = 20},
        {name = "SNOW", chances = 20}
    }
}

function Weather:SetWeather(weather)
    if not self.List[weather:upper()] then
        return
    end

    self.current = weather:upper()

    GlobalState.Weather = self.current
end

function Weather:NextWeather()
    if self.DoWeatherSync then
        local init = os.time()
        local avaibleWeathers = self.List[self.current]
        local timesDone = 1
        local finished = false
        local used_index = {}

        repeat
            local index = nil

            repeat
                index = math.random(1,#self.List[self.current])
            until not used_index[tostring(index)] or os.time() - init > 100 

            if not index then
                break
            end

            used_index[tostring(index)] = true

            local randi = math.random(0,100)

            if randi <= self.List[self.current][index].chances then
                finished = true
                self.current = self.List[self.current][index].name
            end

            timesDone = timesDone + 1
        until timesDone >= #avaibleWeathers or os.time() - init > 1000 or finished
    end

    GlobalState.Weather = self.current
end

function Weather:SetBlackout(state)
    self.blackout = state
    GlobalState.Blackout = self.blackout
end

function Weather:SetTime(hour,minute)
    local hour = hour and math.floor(hour)
    local minute = minute and math.floor(minute)

    if hour >= 0 and hour <= 24 then
        self.CurrentTime.hour = hour
    end

    if minute >= 0 and minute <= 60 then
        self.CurrentTime.minute = minute
    end

    GlobalState.Time = {hour = self.CurrentTime.hour, minute = self.CurrentTime.minute}
end

function Weather:SyncTime()
    if self.DoSyncTime then
        if self.CurrentTime.minute + 2 > 60 then
            self.CurrentTime.hour = self.CurrentTime.hour + 1 <= 24 and self.CurrentTime.hour + 1 or 0
        end

        self.CurrentTime.minute = self.CurrentTime.minute + 2 <= 60 and self.CurrentTime.minute + 2 or 0
    end

    GlobalState.Time = {hour = self.CurrentTime.hour, minute = self.CurrentTime.minute}
end

function Weather:Start()
    self:SetBlackout(false)
    self:NextWeather()

    CreateThread(function()
        self.NextWeatherUpdate = math.random(self.WeatherInterval.min, self.WeatherInterval.max)

        while true do
            local time = os.time()
            
            if time - self.LastWeatherUpdate > self.NextWeatherUpdate then
                self.NextWeatherUpdate = math.random(self.WeatherInterval.min, self.WeatherInterval.max)
                self.LastWeatherUpdate = time
                self:NextWeather()
            end

            self:SyncTime()

            Wait(5000)
        end
    end)
end

CreateThread(function()
    Weather:Start()
end)