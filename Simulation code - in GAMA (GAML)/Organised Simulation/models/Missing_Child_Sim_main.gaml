/**
* Name: MissingChildSimmain
* A simulation framework to study the search of missing children 
* Author: mpizi
* Tags: 
*/



model MissingChildSimMain

import "./../models/Missing_Person.gaml"
import "./../models/Map.gaml"
import "./../models/People_Agents.gaml"
import "./../models/Parameters.gaml"

global {
	float dist_helper;
	
	date true_date <- #now;
	int year_missing <- true_date.year;
	int month_missing <- true_date.month;
	int day_missing <- true_date.day;
	int hour_missing <- true_date.hour;
	int minute_missing <- true_date.minute;
	date starting_date <- date([year_missing,month_missing,day_missing,hour_missing,minute_missing,0]); //[Year, Month, Day, Hour, Minute, Sec]
	
	
	//Boolean that determines wheter or not the current day of the simulation is Friday, Saturday, or Monday
	reflex weekend when: current_date.day_of_week = 6 or current_date.day_of_week = 7 or current_date.day_of_week = 1{
		 if(current_date.day_of_week = 1){
		 	weekend_bool <- false;
		 	if(current_date.day_of_week = 1 and current_hour = 0 and current_min = 0){
		 		write "End of weekend, start of Week";
		 	}
		 }
		 else{
		 	weekend_bool <- true;
		 	if(current_date.day_of_week = 6 and current_hour = 0 and current_min = 0){
		 		write "Start of Weekend";
		 	}
		 }
		
	} 

    //GIS Input//
	//map used to filter the object to build from the OSM file according to attributes. for an exhaustive list, see: http://wiki.openstreetmap.org/wiki/Map_Features
	//map filtering <- (["highway"::["primary", "secondary", "tertiary", "motorway", "living_street","residential", "unclassified"], "building"::["yes"]]);
	
	//map used to filter the object to build from the OSM file according to attributes. for an exhaustive list, see: http://wiki.openstreetmap.org/wiki/Map_Features
	map filtering <- (["highway"::["primary", "secondary", "tertiary", "motorway", "living_street","residential", "unclassified", "service", "secondary_link", "pedestrian", "footway", "steps"],
	"building"::["yes", "house","dormitory", "university grounds","university", "church", "office", "residential", "commercial", "house", "hotel", "apartments", "industrial", "retail", "hospital", "government"]]);

	//map filtering <- (["highway"::["primary", "secondary", "tertiary", "motorway", "living_street","residential", "unclassified", "service", "secondary_link", "pedestrian", "footway", "steps"],
	//"building"::["university", "yes"],
	//"amenity"::["laboratory"]]);
	
	
	//OSM file to load
	file<geometry> osmfile <-  file<geometry>(osm_file("../includes/Maps/athens_centre_wind.osm", filtering))  ;
	//file<geometry> osmfile <-  file<geometry>(osm_file("../includes/map(6).osm"))  ;
	
	//compute the size of the environment from the envelope of the OSM file
	geometry shape <- envelope(osmfile);
	
	//GIS Input//
	//map used to filter the object to build from the OSM file according to attributes. for an exhaustive list, see: http://wiki.openstreetmap.org/wiki/Map_Features
	//map filtering <- (["highway"::["primary", "secondary", "tertiary", "motorway", "living_street","residential", "unclassified", "service", "secondary_link", "pedestrian", "footway", "steps"],
	//"building"::["yes", "house","dormitory", "university grounds","university", "church", "office", "residential", "commercial", "house", "hotel", "apartments", "industrial", "retail", "hospital", "government"]]);
	
	
	init {
		
		//for the m/s parameters
		min_walking_speed_meters_per_s <- min_walking_speed#m/#s;
		max_walking_speed_meters_per_s <- max_walking_speed#m/#s;
		
		if(demographic_driving != 0.0 or demographic_walking != 0.0) {
			demographic_bool <- true;
			if(demographic_driving = 0.0) {
				demographic_driving <- 100 - demographic_walking;
			}
			else {
				demographic_walking <- 100 - demographic_driving;
			}
		}
		else {demographic_bool <- false;}
		
		//possibility to load all of the attibutes of the OSM data: for an exhaustive list, see: http://wiki.openstreetmap.org/wiki/Map_Features
		create osm_agent from:osmfile with: [highway_str::string(read("highway")), building_str::string(read("building"))];
		
		//from the created generic agents, creation of the selected agents
		ask osm_agent {
			if (length(shape.points) = 1 and highway_str != nil ) {
				create node_agent with: [shape ::shape, type:: highway_str]; 
			} else {
				if (highway_str != nil ) {
					create road with: [shape ::shape, type:: highway_str];
				}
				else if (building_str != nil){
					create building with: [shape ::shape];
				
				}
			}
			//do the generic agent die
			do die;
		}

		
        //map<road,float> weights_map <- road as_map (each:: (each.destruction_coeff * each.shape.perimeter));
        //the_graph <- as_edge_graph(road) with_weights weights_map; //create the graph initialized above as an edge graph with weights
		
		//graph without traffic:
		the_graph <- as_edge_graph(road); //create the graph initialized above as an edge graph
		
		
		//the function that creates the people agents
		create people number: nb_people {
			
			//define start and end work time that each agent will have.
			//these values are random so it will be different in each simulation
			
			dist_helper <- gamma_rnd(2519.91,1.15) -2189; // min:6.0 max:10.0; 
			start_work_hour <- int(dist_helper/60);
			start_work_min <- int(dist_helper - start_work_hour*60);
			dist_helper <- gamma_rnd(5.56, 30.81) + 954.96;
			end_work_hour <- int(dist_helper/60);
			end_work_min <- int(dist_helper - end_work_hour*60);
			
			//start_work_hour <- min_work_start + rnd (max_work_start - min_work_start) ;
			//start_work_min <- rnd(0,59);
			//end_work_hour <- min_work_end + rnd (max_work_end - min_work_end) ;
			//end_work_min <- rnd(0,59);
			
			
			//define a living and a working place for each agent from the imported buildings
			living_place <- one_of(building) ;
			working_place <- one_of(building) ;
			
			//define specific spot inside building where agent resides or works
			home_spot <- any_location_in (living_place);
			work_spot <- any_location_in (working_place);

			if (demographic_bool){
				if(flip(demographic_driving/100)) {
					//write("local demo driving = true");
					local_demo_driving <- true;
				}
				else {
					//write("local demo walking = true");
					local_demo_driving <- false;
				}
			}
			
			if (flip(0.1)) {
				weekend_worker <- true;
			}
			else {
				weekend_worker <- false;
			}
			
			float i <- rnd(0.0,1.0);
			//First Condition for Work Days and Weekends with Work, Second for Free Weekends
			if (!weekend_bool or weekend_worker) {
				if(i < 0.4){
					agenda_0 <- true;
				}
				else if (i< 0.8) {
					agenda_1 <- true;
				}
				else {
					agenda_2 <- true;
				}
			}
			else {
				agenda_0 <- true;
				if (i < 0.2) {
					free_agenda_0 <- true;
				}
				else if (i< 0.7) {
					free_agenda_1 <- true;
				}
				else {
					free_agenda_2 <- true;
				}
			}	
			
			dont_go_home_from_leisure <- false;
   	
			//depending on the starting time of the simulation, the agent's starting location is either their
			//home or their workplace. Depending on where they are, the objective will either be working or resting.
			//write(current_hour);
			if((current_hour > start_work_hour and current_hour < end_work_hour) or (current_hour = start_work_hour and current_min > start_work_min) or 
				(current_hour = end_work_hour and current_min < end_work_min))
			{
				//write("LOCATION WORK"); 
				objective <- "working";
				location <- work_spot;
			}
			else {
				//write("LOCATION HOME"); 
				objective <- "resting";
				location <- home_spot;
			}
			
			driving_bool <- false;
			walking_bool <- false;			
		}
		
		//the function that creates the missing person agent
		create missing_person number: nb_missing {
			
			speed <- min_speed_missing + rnd (max_speed_missing- min_speed_missing) ;		
			
			people_nearby <- agents_at_distance(5);
			if (MP_Starting_Pos_name != nil){
				ask building.population {
					if (name = MP_Starting_Pos_name) {
						MP_Starting_Pos <- location;
						write "Starting Position of type Building\n Coordinates";
						write MP_Starting_Pos;
						//myself.living_place <- self;
						myself.input_flag <- true;
						self.color <- #maroon;
					}
					
				} 
				
				ask road.population {
					if (name = MP_Starting_Pos_name) {
						MP_Starting_Pos <- location;
						write "Starting Position of type Road\n Coordinates";
						write MP_Starting_Pos;
						//myself.living_place <- one_of(building);
						myself.input_flag <- true;
						self.color <- #maroon;
					}
				}
				
				if(!input_flag) {
					write "Wrong Input Starting Position";
					//living_place <- one_of(building) ;
					location <- any_location_in (one_of(building));
				}
				else {
					location <- MP_Starting_Pos;
				}
				
			}
			else{
				//living_place <- one_of(building) ;
				location <- any_location_in (one_of(building)); 
			}
			objective <- "running";
			
			
			if(Point_of_Interest1_name != nil and Point_of_Interest2_name = nil) { 
				ask building.population {
					if (name = Point_of_Interest1_name) {
						Point_of_Interest1 <- location;
						write Point_of_Interest1;
						myself.input_flag <- true;
						self.color <- #gamablue;
						how_many_PoIs <- 1;
					}
				}	
				if(!input_flag) {
					write "Wrong Input PoI, no PoI added";
					//Point_of_Interest1_name <- nil;				
					
				} 
			}
			else if (Point_of_Interest1_name != nil and Point_of_Interest2_name != nil){
				ask building.population {
					if (name = Point_of_Interest1_name) {
						Point_of_Interest1 <- location;
						write Point_of_Interest1;
						myself.input_flag <- true;
						self.color <- #gamablue;
						how_many_PoIs <- how_many_PoIs + 1;
					}
					else if (name = Point_of_Interest2_name) {
						Point_of_Interest2 <- location;
						write Point_of_Interest2;
						myself.input_flag <- true;
						self.color <- #gamablue;
						how_many_PoIs <- how_many_PoIs + 2;
					}
				}
				if(how_many_PoIs = 1){
					write "PoI2 false input";
					
				}
				else if(how_many_PoIs = 2){
					write "PoI1 false input";
				}
				else if(how_many_PoIs = 3){
					write "Success 2 PoIs";
				}
				else {
					write"Wrong Input for both PoIs";
				}
			}
			
			
		
		}
	
		}

//the following stops the simulation when the missing person is found
reflex stop_simulation when: (times_found = 1 or error_flag = true) {
		do pause;
	}
	
}



experiment find_missing_person type: gui {
	parameter "Simulation Map (type: .osm)" var: osmfile category: "GIS" ;

	//Determines number of people agents in simulation using globla var nb_people
	parameter "Number of people agents" var: nb_people category: "GIS" ;
	parameter "Time for missing person to rest (hours)" var: time_to_rest_hours min: 0 max: 24 step: 1 category: "Missing_Person" ;
	parameter "Time for missing person to rest (minutes)" var: time_to_rest_min min: 0 max: 60 step: 1 category: "Missing_Person" ;	
	parameter "Probability of finding ms if walking" var: proba_find_walking category: "Probabilities" min: 0.01 max: 1.0;
	parameter "Probability of finding ms if driving" var: proba_find_driving category: "Probabilities" min: 0.01 max: 1.0;
	parameter "Probability of finding ms while resting" var: proba_find_resting category: "Probabilities" min: 0.01 max: 1.0;
	//parameter "PoInterest for missing Person" var: Point_of_Interest1 category: "Missing_Person";
	parameter "PoI building name 1" var: Point_of_Interest1_name category: "Missing_Person";
	parameter "PoI building name 2" var: Point_of_Interest2_name category: "Missing_Person";
	parameter "Starting Position" var:  MP_Starting_Pos_name category: "Missing_Person";
	
	// Category: interactive enable
	// In the following, when a_boolean_to_enable_parameters1 ορ 2 is true, it enables the corresponding parameters 
	//parameter "Start Time" category: "Activate Extended Parameters" var:a_boolean_to_enable_parameters1 enables: [year_missing, month_missing, day_missing, hour_missing, minute_missing];
	//parameter "Demographics" category: "Activate Extended Parameters" var: a_boolean_to_enable_parameters2 enables: [demographic_driving,demographic_walking];
	//parameter "People" category:"Activate Extended Parameters" var:a_boolean_to_enable_parameters3 enables: [min_work_start, max_work_start,
	//	 min_work_end, max_work_end, min_walking_speed, max_walking_speed, min_driving_speed, max_driving_speed];
	//parameter "Missing Person" category:"Activate Extended Parameters" var:a_boolean_to_enable_parameters4 enables: [min_speed_missing, max_speed_missing ];
	
	//Start Time Activatable Parameters
	parameter "Year" var: year_missing category: "Start Time";
	parameter "Month" var: month_missing category: "Start Time";
	parameter "Day" var: day_missing category: "Start Time";
	parameter "Hour" var: hour_missing category: "Start Time";
	parameter "Minute" var: minute_missing category: "Start Time";
	
	//Demographic Data Activatable Parameters
	parameter "Drivers in Area (%) (Fill only one)" var: demographic_driving category: "Demographics";
	parameter "Walkers in Area (%) (Fill only one)" var: demographic_walking category: "Demographics";
	
	//People Activatable Parameters
	parameter "Earliest hour to start work"  category: "People" var: min_work_start min: 2 max: 8 step: 0.5;
    parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 13;
    parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
   	parameter "minimum walking speed (km/h)" var: min_walking_speed category: "People" min: 0.1 max: 5.0 step: 0.1;
	parameter "maximum walking speed (km/h)" var: max_walking_speed category: "People" min: 5.0  #km/#h max: 50 #km/#h step: 1 #km/#h;
	parameter "minimum driving speed (km/h)" var: min_driving_speed category: "People" min: 0.1 #km/#h ;
	parameter "maximum driving speed (km/h)" var: max_driving_speed category: "People" max: 70 #km/#h;
	
	//Missing Person Activatable Parameters
	parameter "minimum speed for missing person (km/h)" var: min_speed_missing category: "Missing_Person Ext" min: 0.1 #km/#h ;
	parameter "maximum speed for missing person (km/h)" var: max_speed_missing category: "Missing_Person Ext" max: 50 #km/#h;
	
	output {
		
		
		
		display chart_display refresh:every(1#cycles) {
			chart "People Status" type: pie style: exploded size: {0.5, 0.5} position: {0, 0.5}{
                data "Working" value: people count (each.objective="working") color: #mediumaquamarine ;
                data "Resting" value: people count (each.objective="resting") color: #lightslategray ;
                data "Leisure" value: people count (each.objective="leisure") color: #black;
                
                //Following two are general travelling to home and work without specifing means of transport and are commented out
                //data "On the way home" value: people count (each.objective="going_home" and each.walking_bool) color: #yellow;
                //data "On the way to Work" value: people count (each.objective="going_to_work") color: #orange;
                
                //Travelling to target invluding means of transport
                data "Walking Home" value: people count (each.objective="going_home" and each.walking_bool) color: #olivedrab;
                data "Driving Home" value: people count (each.objective="going_home" and each.driving_bool) color: #sienna;
                data "Walking Work" value: people count (each.objective="going_to_work" and each.walking_bool) color: #lightgreen;
                data "Driving Work" value: people count (each.objective="going_to_work" and each.driving_bool) color: #darkgoldenrod;
                data "Walking Leisure" value: people count (each.objective="going_for_leisure" and each.walking_bool) color: #purple;
                data "Driving Leisure" value: people count (each.objective="going_for_leisure" and each.driving_bool) color: #darkviolet;
                
            }
            chart "Finding Missing Person" type: series  size: {1, 0.5} position: {0,0} {
                data "Times missing person was found" value: times_found  color: #red;
                data "Times missing person was close to being found" value: close_call color: #green;
            }
            chart "Finding" type: histogram  size: {0.5, 0.5} position: {0.5,0.5} {
        		datalist (distribution_of(people collect each.speed,2,min_walking_speed_meters_per_s, 2) at "legend") 
            	value:(distribution_of(people collect each.speed,2,min_walking_speed_meters_per_s, 2) at "values");      
            }
    
            
        }
        
        display city_display type: opengl {
			
			// refresh is useful in cases of not moving agents, but here for some 
			//reason it messes with the relative positions of agents		
			species building aspect: base; //refresh: false;
			species road aspect: base; // refresh: false;
			//species node_agent aspect: default;
			species missing_person aspect: base ;
			species people aspect: base;	
		}
       
        monitor "Days Missing" value: days_that_is_missing;
        monitor "Hours Missing" value: hours_that_is_missing;
        monitor "Minutes Missing" value: minutes_that_is_missing;
        monitor "Current Date" value: current_date;
        monitor "Close Calls" value: close_call;
        monitor "Times Found" value: times_found;
        monitor "Times Found Walking" value: times_found_walking;
        monitor "Times Found Driving" value: times_found_driving;
        monitor "Times Found Resting" value: times_found_resting;
        monitor "Hour Arrived" value: arrived_hour_mp;
        monitor "Min Arrived" value: arrived_min_mp;
        monitor "M/s" value: min_walking_speed_meters_per_s;
	}
}
