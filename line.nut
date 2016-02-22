class Line
{
    Station1 = null;
    Station2 = null;
    Depot = null;
    Group = null;
    Cargo = null;
    LastUpdateDate = null;
    
    constructor(station1_id, station2_id, depot_tile, group_id, cargo)
    {
        Station1 = station1_id;
        Station2 = station2_id;
        Depot = depot_tile;
        Group = group_id;
        Cargo = cargo;
        LastUpdateDate = AIDate.GetCurrentDate();
    }
    
    function GetAverageStationRating()
    {
        return (AIStation.GetCargoRating(Station1, Cargo) + 
               AIStation.GetCargoRating(Station2, Cargo)) / 2;
    }

}