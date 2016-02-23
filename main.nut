import("util.superlib", "SuperLib", 39);
RoadBuilder <- SuperLib.RoadBuilder;
Road        <- SuperLib.Road;
Helper      <- SuperLib.Helper;
Log         <- SuperLib.Log;
OrderList   <- SuperLib.OrderList;
Money       <- SuperLib.Money;
Vehicle     <- SuperLib.Vehicle;

require("utilities.nut");
require("line.nut");

class robotAI2 extends AIController
{
    
    ServicedTowns = null;
    ServicedTownStations = null;
    ServicedTownDepots = null;
    UnservicedTowns = null;
    PAXCargo = null;
    Lines = null;
    BestVehicle = null;
    BestVehicleDate = null;
    LastRouteExpansion = null;
    LastLineMaintenanceDate = null;
    OldVehicleGroup = null;
    
    constructor()
    {
        ServicedTowns = AIList();
        ServicedTownStations = AIList();
        ServicedTownDepots = AIList();
        UnservicedTowns = AIList();
        Lines = [];
    }
    
    function Initialize()
    {
        Log.Info("Initializing robotAI2", Log.LVL_DEBUG);
        if (!AICompany.SetName("robotAI2")) {
            local i = 2;
               while (!AICompany.SetName("robotAI2 #" + i)) {
                  i = i + 1;
            }
        }
        UnservicedTowns = AITownList();
        if (UnservicedTowns.IsEmpty())
        {
            Log.Error("No towns in game.", Log.LVL_INFO);
            return false;
        } else {
            Log.Info(UnservicedTowns.Count() + " towns in game", 
                     Log.LVL_DEBUG);
        }
        PAXCargo = Helper.GetPAXCargo();
        if (PAXCargo == null)
        {
            Log.Error("No passenger cargo in game.", Log.LVL_INFO);
            return false;
        }
        if (Vehicle.GetVehiclesLeft(AIVehicle.VT_ROAD) <= 0)
        {
            Log.Error("Can't build road vehicles.", Log.LVL_INFO);
            return false;
        }
        BestVehicle = Utilities.GetBestRoadVehicle(AIRoad.ROADTYPE_ROAD,
                                                   PAXCargo, 1, 1);
        BestVehicleDate = AIDate.GetCurrentDate();
        
        if (BestVehicle == null)
        {
            return false;
        }
        
        OldVehicleGroup = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
        AIGroup.SetName(OldVehicleGroup, "Old Vehicles");
        
        return true;
    }
    
    /*     
        To manage unserviced towns, rebuild the list after appending any new
        service to ServicedTowns. This way, list will capture new towns that
        are established (if any).
    */
    function RebuildUnservicedTownList()
    {
        UnservicedTowns = AITownList();
        UnservicedTowns.RemoveList(ServicedTowns);
    }
    
    /* logic for building first line is a bit different from subsequent ones,
       so it gets it's own function */
    function BuildFirstLine()
    {
        Money.MaxLoan();
        
        // get the biggest town, and remove it from the list
        UnservicedTowns.Valuate(Utilities.GetRandomizedPopulation, 300);
        local town1 = UnservicedTowns.Begin();
        Log.Info("Biggest town: " + AITown.GetName(town1), 
                 Log.LVL_SUB_DECISIONS);
                 
        local town1_location = AITown.GetLocation(town1);
        UnservicedTowns.RemoveItem(town1);
        
        // get the best town
        UnservicedTowns.Valuate(Utilities.GetDeviationFromIdealDistance, 
                                town1_location, BestVehicle, 100);
        UnservicedTowns.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
        local town2 = UnservicedTowns.Begin();
        Log.Info("Ideal town is " + AITown.GetName(town2), 
                 Log.LVL_SUB_DECISIONS);
        
        Log.Info("Building route from " + AITown.GetName(town1) + " to " 
                 + AITown.GetName(town2), Log.LVL_INFO);
        
        // build road stations in the two towns
        AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
    
        local town1_result = Road.BuildStopInTown(town1, 
                                                  AIRoad.ROADVEHTYPE_BUS, 
                                                  PAXCargo, PAXCargo);
        local town2_result = Road.BuildStopInTown(town2, 
                                                  AIRoad.ROADVEHTYPE_BUS, 
                                                  PAXCargo, PAXCargo);
        
        if (town1_result == null || town2_result == null)
        {
            Log.Error("Failed to build station.", Log.LVL_INFO);
            
            // cleanup by removing stations and repaying loan
            if (town1_result != null)
            {
                AIRoad.RemoveRoadStation(town1_result);
            }
            
            if (town2_result != null)
            {
                AIRoad.RemoveRoadStation(town2_result);
            }
            
            Money.MakeMaximumPayback();
            return null;
        }
        
        // build a depot in the first town
        local depot = Road.BuildDepotNextToRoad(town1_location, 0, 50);
        if (depot == null)
        {
            Log.Error("Failed to build depot.", Log.LVL_INFO);
            
            // cleanup by removing stations and repaying loan
            AIRoad.RemoveRoadStation(town1_result);
            AIRoad.RemoveRoadStation(town2_result);
            Money.MakeMaximumPayback();
            return null;
        }
        
        // build a road between the two towns
        local roadBuilder = RoadBuilder();

        roadBuilder.Init(town1_result, town2_result);
        roadBuilder.SetLoanLimit(-1);
        
        if (roadBuilder.DoPathfinding())
        {
            local road_builder_result = roadBuilder.ConnectTiles();
            
            if (road_builder_result != RoadBuilder.CONNECT_SUCCEEDED)
            {
                Log.Error("Failed to build road.", Log.LVL_INFO);
                
                // cleanup by removing stations and depot, and repaying loan
                AIRoad.RemoveRoadStation(town1_result);
                AIRoad.RemoveRoadStation(town2_result);
                AIRoad.RemoveRoadDepot(depot);
                Money.MakeMaximumPayback();
                return null;
            }
        } else {
            Log.Error("Failed to find path.", Log.LVL_INFO);
            AIRoad.RemoveRoadStation(town1_result);
            AIRoad.RemoveRoadStation(town2_result);
            AIRoad.RemoveRoadDepot(depot);
            Money.MakeMaximumPayback();
            return null;
        }
        
        local town1_station = AIStation.GetStationID(town1_result);
        local town2_station = AIStation.GetStationID(town2_result);
        
        local orderlist = OrderList();
        orderlist.AddStop(town1_station, AIOrder.OF_NONE);
        orderlist.AddStop(town2_station, AIOrder.OF_NONE);
        
        local vehicle = AIVehicle.BuildVehicle(depot, BestVehicle);
        if (!AIVehicle.IsValidVehicle(vehicle))
        {
            Log.Error("Failed to build vehicle.", Log.LVL_INFO);
            
            // cleanup by removing stations and depot, and repaying loan
            AIRoad.RemoveRoadStation(town1_result);
            AIRoad.RemoveRoadStation(town2_result);
            AIRoad.RemoveRoadDepot(depot);
            Money.MakeMaximumPayback();
            return null;
        }
        
        AIVehicle.RefitVehicle(vehicle, PAXCargo);
        orderlist.ApplyToVehicle(vehicle);
        AIVehicle.StartStopVehicle(vehicle);
        
        local group = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
        local town1_name = AIStation.GetName(town1_station);
        local town2_name = AIStation.GetName(town2_station);
        
        if (town1_name.len() > 14) town1_name = town1_name.slice(0,14);
        if (town2_name.len() > 14) town2_name = town2_name.slice(0,14);
        AIGroup.SetName(group, town1_name + " - " + town2_name);
        AIGroup.MoveVehicle(group, vehicle);
        
        ServicedTowns.AddItem(town1,0);
        ServicedTownStations.AddItem(town1, town1_station);
        ServicedTownStations.AddItem(town2, town2_station);
        ServicedTownDepots.AddItem(town1, depot);
        ServicedTowns.AddItem(town2,0);
        RebuildUnservicedTownList();
        
        Money.MakeMaximumPayback();
        
        local line = Line(town1_station, town2_station, depot, group, 
                          PAXCargo);
        return line;
    }
    
    function EvaluateCandidateExpansionRoutes()
    {
    	ServicedTowns.Sort(AIList.SORT_BY_ITEM, AIList.SORT_ASCENDING);
        local this_town = ServicedTowns.Begin();
        local candidate_towns = AIList();
        do {
            UnservicedTowns.Valuate(Utilities.GetDeviationFromIdealDistance, 
                                    AITown.GetLocation(this_town), BestVehicle,
                                    100);
            UnservicedTowns.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
            local closest_town = UnservicedTowns.Begin();
            Log.Info("Ideal town from " + AITown.GetName(this_town) + ": " +
                     AITown.GetName(closest_town), Log.LVL_DEBUG);
            candidate_towns.AddItem(closest_town, 
                                    Utilities.
                                        GetRandomizedPopulation(closest_town, 
                                                                300)); 
            this_town = ServicedTowns.Next();
        } while (!ServicedTowns.IsEnd())
        
        candidate_towns.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
        
        // don't use randomization here, as candidate list is random enough
        ServicedTowns.Valuate(Utilities.GetDeviationFromIdealDistance, 
                              AITown.GetLocation(candidate_towns.Begin()), 
                              BestVehicle, 0);
        ServicedTowns.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
        
        Log.Info("Next expansion: " + AITown.GetName(ServicedTowns.Begin()) + 
                 " to " + AITown.GetName(candidate_towns.Begin()), 
                 Log.LVL_SUB_DECISIONS);
        
        return [ServicedTowns.Begin(), candidate_towns.Begin()];
    }
    
    function BuildNewLine()
    {
        Money.MaxLoan();
        
        // get towns to for new route
        local towns = EvaluateCandidateExpansionRoutes();
        Log.Info("Building route from " + AITown.GetName(towns[0]) + " to " 
                 + AITown.GetName(towns[1]), Log.LVL_INFO);
        
        AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
        
        // build a station in the new town
        local town2_result = Road.BuildStopInTown(towns[1], 
                             AIRoad.ROADVEHTYPE_BUS, PAXCargo, PAXCargo);
        
        if (town2_result == null)
        {
            Log.Error("Failed to build station", Log.LVL_INFO);
            Money.MakeMaximumPayback();
            return null;
        }
        
        
        local depot = null;
        local depot_town = null;
        
        /* check if there is a depot in the either town, and build one 
           if none exists */
        if (ServicedTownDepots.HasItem(towns[0]))
        {
            depot = ServicedTownDepots.GetValue(towns[0]);
            depot_town = towns[0];
        } else if (ServicedTownDepots.HasItem(towns[1]))
        {
            depot = ServicedTownDepots.GetValue(towns[1]);
            depot_town = towns[1];
        } else {
            
            // try to build a depot in the first town
            depot = Road.BuildDepotNextToRoad(AITown.GetLocation(towns[0]), 0,
                                              50);
            if (depot != null)
            {
                depot_town = towns[0];
            } else {
                /* if building depot in the first town failed, build a depot
                   in the second town */ 
                depot = Road.BuildDepotNextToRoad(AITown.GetLocation(towns[1]),
                                                  0, 50);
                depot_town = towns[1];
            }
        }
        
        // if we still don't have a depot, route construction fails
        if (depot == null)
        {
            Log.Error("Failed to build depot", Log.LVL_INFO);
            
            // cleanup - remove constructed station and repay loan
            AIRoad.RemoveRoadStation(town2_result);
            Money.MakeMaximumPayback();
            return null;
        }
        
        // build the road
        local roadBuilder = RoadBuilder();

        roadBuilder.Init(AIStation.GetLocation
                         (ServicedTownStations.GetValue(towns[0])), 
                         town2_result);
                          
        roadBuilder.SetLoanLimit(-1);
        
        if (roadBuilder.DoPathfinding())
        {
           local road_builder_result = roadBuilder.ConnectTiles();
           
           // road building failed, abort
           if (road_builder_result != RoadBuilder.CONNECT_SUCCEEDED)
          {
              Log.Error("Failed to build road.", Log.LVL_INFO);
              
              // cleanup - remove constructed station and repay loan
              AIRoad.RemoveRoadStation(town2_result);
              Money.MakeMaximumPayback();
              
              // we can keep the depot, though
              ServicedTownDepots.AddItem(depot_town, depot);
              return null;
           }
        } else {
            Log.Error("Failed to find path.", Log.LVL_INFO);
            // cleanup - remove constructed station and repay loan
            AIRoad.RemoveRoadStation(town2_result);
            Money.MakeMaximumPayback();
            
            // we can keep the depot, though
            ServicedTownDepots.AddItem(depot_town, depot);
            return null;
        }
        
        local town1_station = ServicedTownStations.GetValue(towns[0]);
        local town2_station = AIStation.GetStationID(town2_result);
        
        local orderlist = OrderList();
        orderlist.AddStop(town1_station, AIOrder.OF_NONE);
        orderlist.AddStop(town2_station, AIOrder.OF_NONE);
        
        local vehicle = AIVehicle.BuildVehicle(depot, BestVehicle);
        if (!AIVehicle.IsValidVehicle(vehicle))
        {
            Log.Error("Failed to build vehicle.", Log.LVL_INFO);
            Money.MakeMaximumPayback();
            return null;
        }
        
        AIVehicle.RefitVehicle(vehicle, PAXCargo);
        orderlist.ApplyToVehicle(vehicle);
        AIVehicle.StartStopVehicle(vehicle);
        
        local group = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
        
        local town1_name = AIStation.GetName(town1_station);
        local town2_name = AIStation.GetName(town2_station);
        
        if (town1_name.len() > 14) town1_name = town1_name.slice(0,14);
        if (town2_name.len() > 14) town2_name = town2_name.slice(0,14);
        AIGroup.SetName(group, town1_name + " - " + town2_name);
        AIGroup.MoveVehicle(group, vehicle);
        
        ServicedTowns.AddItem(towns[0],0);
        ServicedTowns.AddItem(towns[1],0);
        ServicedTownStations.AddItem(towns[0], town1_station);
        ServicedTownStations.AddItem(towns[1], town2_station);
        ServicedTownDepots.AddItem(depot_town, depot);
        RebuildUnservicedTownList();
        
        Money.MakeMaximumPayback();
        
        local line = Line(town1_station, town2_station, depot, group, 
                          PAXCargo);
        return line;
    }
    
    function DoNewLineConstruction()
    {
        if (Vehicle.GetVehiclesLeft(AIVehicle.VT_ROAD) <= 0)
        {
            Log.Info("Deferring line construction, vehicle limit reached.",
                     Log.LVL_SUB_DECISIONS);
            LastRouteExpansion = AIDate.GetCurrentDate();
            return;
        }
        
        // check if there's enough money on hand before building
        local current_money = Money.GetMaxSpendingAmount();
        local target_money = Money.Inflate(GetSetting("min_cash_new_route"));
        
        if (current_money < target_money)
        {
            Log.Info("Deferring line construction. " + current_money + 
                     " available, " + target_money + " needed", 
                     Log.LVL_SUB_DECISIONS);
            
            LastRouteExpansion = AIDate.GetCurrentDate();
            return;
        }
        
        /* if we've got the money and there's unserviced towns, try to build a
           route */
        if (UnservicedTowns.Count() > 0)
        {
            Log.Info("Building new line.", Log.LVL_INFO);
            local new_line = BuildNewLine();
            if (new_line != null)
            {
                LastRouteExpansion = AIDate.GetCurrentDate();
                Lines.append(new_line);
                Log.Info("New line construction successful.", 
                         Log.LVL_INFO);
                Log.Info(Lines.len() + " lines in service.", Log.LVL_INFO);
                Log.Info(ServicedTowns.Count() + " serviced towns.", 
                         Log.LVL_DEBUG);
                Log.Info(UnservicedTowns.Count() + " unserviced towns.", 
                         Log.LVL_DEBUG);
            } else {
                Log.Error("Failed to build new line, error: " + 
                          AIError.GetLastErrorString(), Log.LVL_INFO);
            }
        } else {
            Log.Info("All towns connected!", Log.LVL_INFO);
            LastRouteExpansion = AIDate.GetCurrentDate();
            RebuildUnservicedTownList();
        }
    }
    
    // logic for adding a new vehicle to an existing line
    function AddVehicleToLine(line)
    {
        local line_name = AIGroup.GetName(line.Group);
        
        if (Vehicle.GetVehiclesLeft(AIVehicle.VT_ROAD) <= 0)
        {
            Log.Info(line_name + 
                     ": deferring new vehicle, vehicle limit reached",
                     Log.LVL_SUB_DECISIONS);
            line.LastUpdateDate = AIDate.GetCurrentDate();
            return;
        }
        
        Log.Info(line_name + ": needs new vehicle.", 
                 Log.LVL_SUB_DECISIONS);
        Money.MaxLoan();
        local vehicle = AIVehicle.BuildVehicle(line.Depot, 
                                               BestVehicle);
        if (AIVehicle.IsValidVehicle(vehicle))
        {
            AIVehicle.RefitVehicle(vehicle, PAXCargo);
            AIOrder.ShareOrders(vehicle, 
                                AIVehicleList_Group(line.Group)
                                    .Begin());
            AIGroup.MoveVehicle(line.Group, vehicle);
            AIVehicle.StartStopVehicle(vehicle);
            line.LastUpdateDate = AIDate.GetCurrentDate();
            
            // multiple by 10 to fudge integer arithmetic
            if (Utilities.GetVehiclesPerStationTile(line.Station1, 
                                                    AIStation.STATION_BUS_STOP,
                                                    10) >=
                (GetSetting("vehicles_per_stop") * 10))
            {
                Log.Info(AIStation.GetName(line.Station1) + ": needs new stop",
                         Log.LVL_SUB_DECISIONS);
                Utilities.ExpandRoadStation(line.Station1, 
                                            AIStation.STATION_BUS_STOP);
            }
            if (Utilities.GetVehiclesPerStationTile(line.Station2, 
                                                    AIStation.STATION_BUS_STOP,
                                                    10) >=
                (GetSetting("vehicles_per_stop") * 10))
            {
                Log.Info(AIStation.GetName(line.Station2) + ": needs new stop",
                         Log.LVL_SUB_DECISIONS);
                Utilities.ExpandRoadStation(line.Station2, 
                                            AIStation.STATION_BUS_STOP);
            }
            
        } else 
        {
            Log.Error(line_name + ": error adding vehicle: " + 
                      AIError.GetLastErrorString(), Log.LVL_INFO);
        }
        Money.MakeMaximumPayback();
    }
    
    function HandleOldVehicles(line)
    {
        local line_name = AIGroup.GetName(line.Group);
        local vehicle_list = AIVehicleList_Group(line.Group);
        
        local total_vehicles = vehicle_list.Count();
        Log.Info(line_name + ": total vehicles " + total_vehicles,
                 Log.LVL_DEBUG);
        
        if (total_vehicles > 1)
        {
            vehicle_list.Valuate(AIVehicle.GetAgeLeft);
            vehicle_list.RemoveAboveValue(0);
            if (vehicle_list.Count() > 0)
            {
                Log.Info(line_name + ": has old vehicles", 
                         Log.LVL_SUB_DECISIONS);
                Log.Info(line_name + ": old vehicles " + 
                         vehicle_list.Count(), Log.LVL_DEBUG);
                vehicle_list.Valuate(AIVehicle.GetAge);
                vehicle_list.Sort(AIList.SORT_BY_VALUE, 
                                  AIList.SORT_DESCENDING);
                local old_vehicle = vehicle_list.Begin();
                
                do
                {
                    AIGroup.MoveVehicle(OldVehicleGroup, old_vehicle);
                    Vehicle.SendVehicleToDepotForSelling(old_vehicle, 
                                                         line.Depot);
                    old_vehicle = vehicle_list.Next();
                    total_vehicles -= 1;
                    if (!vehicle_list.IsEnd() && total_vehicles == 1)
                    {
                        Log.Info(line_name + 
                                 ": only one vehicle left, aborting sell-off",
                                 Log.LVL_SUB_DECISIONS);
                    }
                } while (!vehicle_list.IsEnd() && total_vehicles > 1);
                line.LastUpdateDate = AIDate.GetCurrentDate();
            }
        }
        
        Vehicle.SellVehiclesInDepot(line.Depot);
    }
    
    function DoLineMaintenance()
    {
        Log.Info("Maintaining lines.", Log.LVL_INFO);
        for (local i = 0; i < Lines.len(); i += 1)
        {
            local current_money = Money.GetMaxSpendingAmount();
            local target_money = Money.Inflate
                                        (GetSetting("min_cash_new_vehicle"));
            
            // if we're out of money, end the maintenance routine early
            if (current_money < target_money)
            {
                Log.Info("Deferring maintenance: " + current_money + 
                         " available, " + target_money + " needed", 
                         Log.LVL_SUB_DECISIONS);
              
              LastLineMaintenanceDate = AIDate.GetCurrentDate();
              return;
            }
            
            // Each line is only maintained once every two update intervals
            if (AIDate.GetCurrentDate() - (Lines[i].LastUpdateDate) > 
                (GetSetting("line_maintenance_time") * 2))
            {
                local line_rating = Lines[i].GetAverageStationRating();
                local line_name = AIGroup.GetName(Lines[i].Group);
                Log.Info(line_name + ": station rating " + 
                         line_rating, Log.LVL_DEBUG);
                         
                if (line_rating < GetSetting("minimum_station_rating"))
                {
                    AddVehicleToLine(Lines[i]);
                }
                HandleOldVehicles(Lines[i]);
            } else {
                Log.Info(AIGroup.GetName(Lines[i].Group) +
                         ": maintenance unneeded", Log.LVL_DEBUG);
            }
        }
        LastLineMaintenanceDate = AIDate.GetCurrentDate();
    }
    
    function Start()
    {
        if (!Initialize())
        {
            Log.Error("Error initializing. Aborting AI");
            return;
        }
          
        local first_line_built = false;
          
        Log.Info("Initialized!", Log.LVL_INFO);
        
        // try to build the first line as soon as AI is awake
        
        while (!first_line_built)
        {
            local first_line = BuildFirstLine();
            if (first_line != null)
            {
                first_line_built = true;
                LastRouteExpansion = AIDate.GetCurrentDate();
                LastLineMaintenanceDate = AIDate.GetCurrentDate();
                Lines.append(first_line);
                Log.Info("Initial line construction successful.",
                         Log.LVL_INFO);
                Log.Info(Lines.len() + " lines in service.", Log.LVL_INFO);
                Log.Info(ServicedTowns.Count() + " serviced towns.", 
                        Log.LVL_DEBUG);
                Log.Info(UnservicedTowns.Count() + " unserviced towns.", 
                        Log.LVL_DEBUG);
            } else {
                Log.Error("Failed to build initial line, error: " + 
                        AIError.GetLastErrorString(), Log.LVL_INFO);
            }
            this.Sleep(50);
        }
        
        // after first line is built, enter main maintenance/expansion loop
        while (true) {
            
            /* only attempt expansion and maintenance while there's a valid 
               vehicle */
            if (BestVehicle != null)
            {
                if ((AIDate.GetCurrentDate() - LastRouteExpansion) > 
                    GetSetting("new_route_time"))
                {
                    DoNewLineConstruction();
                }
                
                if ((AIDate.GetCurrentDate() - LastLineMaintenanceDate) >
                    GetSetting("line_maintenance_time"))
                {
                    DoLineMaintenance()
                }
                
            }
            
            if ((AIDate.GetCurrentDate() - BestVehicleDate) > 
                GetSetting("vehicle_refresh"))
            {
                Log.Info("Rebuilding list of vehicles.", Log.LVL_INFO);
                BestVehicle = Utilities.GetBestRoadVehicle
                                            (AIRoad.ROADTYPE_ROAD, PAXCargo, 
                                             1, 1);
                BestVehicleDate = AIDate.GetCurrentDate();
            }
        }
    }
}

