/**
* Name: Buildings
* Based on the internal empty template. 
* Author: mpizi
* Tags: 
*/


model Map

/* Insert your model definition here */

//define the building species
species building {
	string type; 
	rgb color <- #gray  ; //the color of each building
	
	aspect base {
		draw shape color: color border: #black;
	}
}

//define the road species
species road skills: [skill_road] {
	string type; 
	//rgb color <- #black ; //the color of each road
	
	//we will simulate traffeic with road_destruction
	//float destruction_coeff <- 1.0 max 2.0;
    //int colorValue <- int(255*(destruction_coeff - 1)) update: int(255*(destruction_coeff - 1));
    rgb color <- #gamagreen;
	
	aspect base {
		draw shape color: color ;
	}
}



species osm_agent {
	string highway_str;
	string building_str;
} 

species node_agent {
	string type;
	aspect default { 
		draw square(3) color: #red ;
	}
} 

