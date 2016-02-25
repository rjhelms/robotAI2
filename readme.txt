robotAI2, version 1
(c) 2016 Rob Hailman

ABOUT
=======================================

Welcome to robotAI2! robotAI2 is an AI which focuses on building a
network of bus lines connecting every town on the map.

GitHub: https://github.com/rjhelms/robotAI2
TT-Forum: 
Twitter: @rjhelms

robotAI2 is licensed under the GNU GPLv2. See license.txt for the
full text of the the license.

LIMITATIONS
=======================================

At the present time, robotAI2 does not support articulated vehicles
or trams. As such, if the newGRFs loaded do not include any "plain
ol' busses", the AI will not get anywhere.

Additionally, while the AI attempts to optimize route lengths for
the vehicles available, in extreme circumstances this is not always
successful. For example, using eGRVTS, robotAI2 will quickly go
bankrupt in games starting before 1900 or so.

SETTINGS
=======================================

Where multiple defaults appear, they are for easy/medium/hard 
difficulty.

Use signs for debug information
  Default: Off
	
  Whether robotAI2 will place signs on the map for debug purposes. 
  The map can get cluttered with a lot of signs, especially in towns, 
  if this is set to "On."
	
Logging
  Default: Info only
	
  How much robotAI2 writes to the AI/Game Script Debug log. 
  "Sub-decisions" writes a bit more information about what's happening
  under the hood, while "Debug" chatters a lot.
  
Duration (in days) between vehicle list refresh
  Default: 365/180/90
  
  How frequently robotAI2 checks evaluates the performance of new
  vehicles. Higher settings means that new vehicle types will take
  longer to enter service.
  
Time (in days) between building new routes
  Default: 90/60/30
  
  How long robotAI2 waits between constructing new routes. Higher
  settings make for a less competitive AI, while setting this value
  too low can mean the AI spends too much time pathfinding opposed
  to maintaining existing routes.
  
Time (in days) between maintaining existing lines
  Default: 180/60/45
  
  How frequently robotAI2 checks lines to determine if new vehicles
  are needed, or if old vehicles should be sold off. Setting this
  too low can result in the AI spamming lines with vehicles, as it
  won't wait long enough between passes to see the effect of the last
  purchase.
  
Minimum station rating considered acceptable
  Default: 30/45/55
  
  The station rating robotAI2 targets at a minimum. Lines with
  stations below this value with receive new vehicles.
  
Number of vehicles for each bus stop
  Default: 20/10/5
  
  How many vehicles use a bus stop before robotAI2 tries to expand
  it. Lower settings prevent traffic jams, but can cause excessive
  station growth.
  
Minimum money for building new routes
  Default: 50000
  
  How much money robotAI2 must have before it begins construction
  of a new route. This amount is adjusted for inflation as the game
  progresses.
  
Minimum money for buying new vehicles
  Default: 20000
  
  How much money robotAI2 must have in order to purchase new
  vehicles. This amount is adjusted for inflation as the game 
  progresses.

ACKNOWLEDGEMENTS
=======================================

This project owes a debt of gratitude to Zuu for the SuperLib
library, which saved a great deal of time and effort in managing
the basic tasks every AI needs to take care of.