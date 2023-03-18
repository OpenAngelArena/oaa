Welcome to Big Mode.
==========================================================
Features:
- Bigger map (128 tiles²) - More bigger is more good?
- Organic map (Organic symmetry & fractal geometry)
- Intelligent map (Human-centeric design & UX optimization)
- Optimized map (Arena integration & tileset management)

OAA map measurements:
Object	# of x	 	   Units	256-Tiles	   Tile (Area)
----------------------------------------------------------
Team-bases	 2		 3,600u²	14 tiles²	  196sq tiles
Arenas		 6		 3,000u²	12 tiles²	  144sq tiles
Bosspits	10 		 1,280u²	 5 tiles²	   25sq tiles
Spawns		 2 		 1,024u²	 4 tiles²	   16sq tiles
Camps		37 +/-	   512u² 	 2 tiles²	    4sq tiles
Stairs		 ?		   512u²	 2 tiles²	    4sq tiles
Misc		 ?		   256u²	 1 tiles²	    1sq tiles
Trees		 ?		    64u²   1/4 tiles²	 1/16sq tiles

Map area comparison:
----------------------------------------------------------
Dota.vmap     		16,384u²	 64 tiles²	 4,096sq tiles
Vertical range: 256 (256-0)
Elevations: 3
Note: 
- River, main area, and highground elevations.
----------------------------------------------------------
OAA-Seasonal.vmap   20,480u²	 80 tiles²	 6,400sq tiles
Vertical range: 384 (384-0)
Elevations: 4
Note:
- More elevations = more good. 
- Camera distance of 384 feels very close
----------------------------------------------------------
OAA-Bigmode.vmap    32,768u²	128 tiles²	16,384sq tiles
Pathing height ceiling: 768 (384-(-384))
Elevations: 7
Note:
- More elevations = more good.
- Camera distance of -384 feels very far
----------------------------------------------------------
Proposed change:
Pathing height ceiling: 768 (384-(-256))
Elevations: 6
Rationale: Reduce camera target distance.
----------------------------------------------------------