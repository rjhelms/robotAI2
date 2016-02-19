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
                    description = "Use signs for display of debug infomarion",
                    easy_value = 0,
                    medium_value = 0,
                    hard_value = 0,
                    custom_value = 0,
                    flags = AICONFIG_BOOLEAN | AICONFIG_INGAME});
                    
        AddSetting({name = "log_level",
                    description = "Level of logging to use",
                    min_value = 0,
                    max_value = 3,
                    easy_value = 1,
                    medium_value = 1,
                    hard_value = 1,
                    custom_value = 1,
                    flags = AICONFIG_INGAME});
        
        AddSetting({name = "vehicle_refresh",
                    description = "Duration (in days) between vehicle list refresh",
                    min_value = 30,
                    max_value = 1825,
                    easy_value = 365,
                    medium_value = 182,
                    hard_value = 91,
                    custom_value = 182,
                    flags = AICONFIG_INGAME});
        
        AddLabels("log_level",
                  {_0 = "Logging disabled",
                   _1 = "Info only",
                   _2 = "Sub-decisions",
                   _3 = "Debug"});
    }
}

RegisterAI(robotAI2());
