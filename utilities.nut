import("util.superlib", "SuperLib", 39);
Result      <- SuperLib.Result;
Road        <- SuperLib.Road;

class Utilities
{
    static function EngineChoiceHeuristic(engineID, speedWeight, 
                                          capacityWeight)
    {
        local score = AIEngine.GetMaxSpeed(engineID) * speedWeight + 
                      AIEngine.GetCapacity(engineID) * capacityWeight;
        Log.Info("Engine " + AIEngine.GetName(engineID) + ": score " + score, 
                 Log.LVL_DEBUG);
        
        return score;
    }

    static function ExpandRoadStation(station_id, station_type)
    {
        local result = Road.GrowStationParallel(station_id, station_type);
        if (Result.IsSuccess(result))
        {
            return true;
        }
        
        if (AIGameSettings.GetValue("distant_join_stations") != 0)
        {
            Log.Info(AIStation.GetName(station_id) + 
                     ": Parallel expansions failed, trying non-parallel",
                     Log.LVL_SUB_DECISIONS);
            result = Road.GrowStation(station_id, station_type);
        }
        
        if (Result.IsSuccess(result))
        {
            return true;
        }
        
        Log.Warning("Failed to expand " + AIStation.GetName(station_id),
                    Log.LVL_INFO);
        return false;
    }
    
    static function GetRandomizedPopulation(town_id, random_range)
    {
        local population_actual = AITown.GetPopulation(town_id);
        local population_randomized = population_actual - (random_range/2) +
                                      AIBase.RandRange(random_range);
        Log.Info("Population of " + AITown.GetName(town_id) + ": " + 
                 population_actual + " randomized to " + population_randomized,
                 Log.LVL_DEBUG);
        return population_randomized;
    }

    static function GetRandomizedTownDistance(town_id, tile_id, random_range)
    {
        local distance_actual = AITown.GetDistanceManhattanToTile(town_id, 
                                                                  tile_id);
        local distance_randomized = distance_actual - (random_range/2) + 
                                    AIBase.RandRange(random_range);
        Log.Info("Distance " + AITown.GetName(town_id) + " to " + tile_id + 
                 ": " + distance_actual + ", randomized to " + 
                 distance_randomized, Log.LVL_DEBUG);
        return distance_randomized;
    }

    static function GetBestRoadVehicle(road_type, cargo, speed_weight, 
                                       capacity_weight)
    {
        Log.Info("Getting best vehicle for " + AICargo.GetCargoLabel(cargo),
                 Log.LVL_DEBUG);
                 
        // get list of road vehicles
        local engine_list = AIEngineList(AIVehicle.VT_ROAD);
        
        Log.Info("Total vehicles before filtering: " + engine_list.Count(),
                 Log.LVL_DEBUG);
                
        // filter list to buildable engines that match type and cargo
        engine_list.Valuate(AIEngine.GetRoadType);
        engine_list.KeepValue(road_type);
        
        Log.Info("Vehicles of correct type: " + engine_list.Count(),
                 Log.LVL_DEBUG);
                 
        engine_list.Valuate(AIEngine.IsBuildable);
        engine_list.KeepValue(1);
        
        Log.Info("Buildable vehicles: " + engine_list.Count(), Log.LVL_DEBUG);
        
        engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
        engine_list.KeepValue(1);
        
        Log.Info("Refittable to cargo: " + engine_list.Count(), Log.LVL_DEBUG);
        
        /* filter out articulated road vehicles, until support for them is 
           added */
        engine_list.Valuate(AIEngine.IsArticulated);
        engine_list.KeepValue(0);
        
        Log.Info("Total vehicles after filtering: " + engine_list.Count(),
                 Log.LVL_DEBUG);
        
        if (engine_list.Count() == 0)
        {
        	Log.Error("No valid vehicles!", Log.LVL_INFO);
        	return null;
        }
        
        engine_list.Valuate(Utilities.EngineChoiceHeuristic, speed_weight, 
                            capacity_weight);
        engine_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
        
        local best_vehicle = engine_list.Begin();
        Log.Info("Best vehicle: " + AIEngine.GetName(best_vehicle), 
                 Log.LVL_SUB_DECISIONS);
        return best_vehicle;
    }
    
    function GetVehiclesPerStationTile(station_id, station_type, multiplier)
    {
        local station_tile_count = AITileList_StationType
                                    (station_id, station_type).Count();
        local station_vehicle_count = AIVehicleList_Station(station_id).Count();
        return (station_vehicle_count * multiplier) / station_tile_count;
    }
}