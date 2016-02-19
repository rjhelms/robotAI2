import("util.superlib", "SuperLib", 39);
RoadBuilder <- SuperLib.RoadBuilder;
Road <- SuperLib.Road;
Helper <- SuperLib.Helper;
Log <- SuperLib.Log;
OrderList <- SuperLib.OrderList;
Money <- SuperLib.Money;

require("utilities.nut");
require("line.nut");

class robotAI2 extends AIController
{
	
	ServicedTowns = null;
	UnservicedTowns = null;
	PAXCargo = null;
	Lines = null;
	BestVehicle = null;
	BestVehicleDate = null;
	
	constructor()
	{
		ServicedTowns = AIList();
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
  		BestVehicle = Utilities.GetBestRoadVehicle(AIRoad.ROADTYPE_ROAD,
												   PAXCargo, 1, 1);
		BestVehicleDate = AIDate.GetCurrentDate();
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
	
	function BuildFirstLine()
	{
		local line = null;
		// get the biggest town, and remove it from the list
		UnservicedTowns.Valuate(Utilities.GetRandomizedPopulation, 300);
		local town1 = UnservicedTowns.Begin();
		Log.Info("Biggest town: " + AITown.GetName(town1), 
				 Log.LVL_SUB_DECISIONS);
				 
		local town1_location = AITown.GetLocation(town1);
		UnservicedTowns.RemoveItem(town1);
		
		// get the closest town
		UnservicedTowns.Valuate(Utilities.GetRandomizedTownDistance, 
								town1_location, 100);
		UnservicedTowns.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
		local town2 = UnservicedTowns.Begin();
		Log.Info("Closest town is " + AITown.GetName(town2), 
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
			return line;
		}
		
		// build a depot in the first town
		local depot = Road.BuildDepotNextToRoad(town1_location, 0, 10);
		if (depot == null)
		{
			Log.Error("Failed to build depot.", Log.LVL_INFO);
			return line;
		}
		
		// build a road between the two towns
		local roadBuilder = RoadBuilder();

		roadBuilder.Init(town1_result, town2_result);
		roadBuilder.SetLoanLimit(-1);
		//roadBuilder.DoPathfinding();
		local road_builder_result = roadBuilder.ConnectTiles();		
		
		if (road_builder_result != RoadBuilder.CONNECT_SUCCEEDED)
		{
			Log.Error("Failed to build road.", Log.LVL_INFO);
			return line;
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
			return line;
		}
		
		AIVehicle.RefitVehicle(vehicle, PAXCargo);
		orderlist.ApplyToVehicle(vehicle);
		AIVehicle.StartStopVehicle(vehicle);
		
		local group = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
		AIGroup.SetName(group, AIStation.GetName(town1_station) + " - " + 
						AIStation.GetName(town2_station));
		AIGroup.MoveVehicle(group, vehicle);
		
		ServicedTowns.AddItem(town1,0);
		ServicedTowns.AddItem(town2,0);
		RebuildUnservicedTownList();
		
		line = Line(town1_station, town2_station, depot, group);
		return line;
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
		
		Money.MaxLoan();
		local first_line = BuildFirstLine();
		Money.MakeMaximumPayback();
		if (first_line != null)
		{
			first_line_built = true;
			Lines.append(first_line);
			Log.Info("Initial line construction successful.", Log.LVL_INFO);
			Log.Info(Lines.len() + " lines in service.", Log.LVL_INFO);
			Log.Info(ServicedTowns.Count() + " serviced towns.", 
					 Log.LVL_DEBUG);
			Log.Info(UnservicedTowns.Count() + " unserviced towns.", 
					 Log.LVL_DEBUG);
		} else {
			Log.Error("Failed to build initial line, error: " + 
					  AIError.GetLastErrorString(), Log.LVL_INFO);
		}
		
		while (true) {
			this.Sleep(50);
			if (!first_line_built)
			{
				Log.Info("Reattempting construction of inital line.", 
						 Log.LVL_INFO);
				Money.MaxLoan();
				first_line = BuildFirstLine();
				Money.MakeMaximumPayback();
				if (first_line != null)
				{
					first_line_built = true;
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
			}
			if ((AIDate.GetCurrentDate() - BestVehicleDate) > 
				GetSetting("vehicle_refresh"))
			{
				Log.Info("Rebuilding list of vehicles.", Log.LVL_INFO);
		  		BestVehicle = Utilities.GetBestRoadVehicle(AIRoad.ROADTYPE_ROAD,
										   				   PAXCargo, 1, 1);
				BestVehicleDate = AIDate.GetCurrentDate();
			}
		}
	}
}

