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
        engine_list.Valuate(AIEngine.IsBuildable);
        engine_list.KeepValue(1);
        engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
        engine_list.KeepValue(1);
    
        Log.Info("Total vehicles after filtering: " + engine_list.Count(),
                 Log.LVL_DEBUG);
             
        engine_list.Valuate(Utilities.EngineChoiceHeuristic, speed_weight, 
                            capacity_weight);
        engine_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
        
        local best_vehicle = engine_list.Begin();
        Log.Info("Best vehicle: " + AIEngine.GetName(best_vehicle), 
                 Log.LVL_SUB_DECISIONS);
        return best_vehicle;
    }
}