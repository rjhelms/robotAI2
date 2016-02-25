class robotAI2 extends AIInfo {
    function GetAuthor()        { return "rjhelms"; }
    function GetName()          { return "robotAI2"; }
    function GetDescription()   { return "Oh hello"; }
    function GetVersion()       { return 1; }
    function GetDate()          { return "2016-02-18"; }
    function CreateInstance()   { return "robotAI2"; }
    function GetShortName()     { return "RAI2"; }
    function GetAPIVersion()    { return "1.5"; }
    
    function GetSettings()
    {
        AddSetting({name = "debug_signs",
                    description 
                        = "Use signs for debug infomarion",
                    easy_value = 0,
                    medium_value = 0,
                    hard_value = 0,
                    custom_value = 0,
                    flags = AICONFIG_BOOLEAN | AICONFIG_INGAME});
                    
        AddSetting({name = "log_level",
                    description 
                        = "Logging",
                    min_value = 0,
                    max_value = 3,
                    easy_value = 1,
                    medium_value = 1,
                    hard_value = 1,
                    custom_value = 1,
                    flags = AICONFIG_INGAME});
        
        AddLabels("log_level",
                  {_0 = "Logging disabled",
                   _1 = "Info only",
                   _2 = "Sub-decisions",
                   _3 = "Debug"});
        
        AddSetting({name = "vehicle_refresh",
                    description = 
                        "Duration (in days) between vehicle list refresh",
                    min_value = 30,
                    max_value = 2000,
                    easy_value = 365,
                    medium_value = 180,
                    hard_value = 90,
                    custom_value = 182,
                    flags = AICONFIG_INGAME});
        
        AddSetting({name = "new_route_time",
                    description = 
                        "Time (in days) between building new routes",
                    min_value = 10,
                    max_value = 365,
                    easy_value = 90,
                    medium_value = 60,
                    hard_value = 30,
                    custom_value = 60,
                    flags = AICONFIG_INGAME});
        
        AddSetting({name = "line_maintenance_time",
                    description = 
                        "Time (in days) between maintaining existing lines",
                    min_value = 30,
                    max_value = 2000,
                    easy_value = 180,
                    medium_value = 60,
                    hard_value = 45,
                    custom_value = 60,
                    flags = AICONFIG_INGAME});
        
        AddSetting({name = "minimum_station_rating",
                    description = 
                        "Minimum station rating considered acceptable",
                    min_value = 0,
                    max_value = 100,
                    easy_value = 30,
                    medium_value = 45,
                    hard_value = 55,
                    custom_value = 45,
                    flags = AICONFIG_INGAME});
        
        AddSetting({name = "vehicles_per_stop",
                    description = 
                        "Number of vehicles for each bus stop",
                    min_value = 1,
                    max_value = 100,
                    easy_value = 20,
                    medium_value = 10,
                    hard_value = 5,
                    custom_value = 10,
                    flags = AICONFIG_INGAME});
                    
        AddSetting({name = "min_cash_new_route",
                    description = 
                        "Minimum money for building new routes",
                    min_value = 0,
                    max_value = 1000000,
                    easy_value = 50000,
                    medium_value = 50000,
                    hard_value = 50000,
                    custom_value = 50000,
                    flags = AICONFIG_INGAME});
                    
        AddSetting({name = "min_cash_new_vehicle",
                    description = 
                        "Minimum money for buying nev vehicles",
                    min_value = 0,
                    max_value = 1000000,
                    easy_value = 20000,
                    medium_value = 20000,
                    hard_value = 20000,
                    custom_value = 20000,
                    flags = AICONFIG_INGAME});
    }
}

RegisterAI(robotAI2());
