/**
* Name: SimulationAthensCentre
* Based on the internal empty template. 
* Author: amichal
* Tags: 
*/


model SimulationAthensCentre

global {
	float dist_helper;
	
	date true_date <- #now;
	int year_missing <- true_date.year;
	int month_missing <- true_date.month;
	int day_missing <- true_date.day;
	int hour_missing <- true_date.hour;
	int minute_missing <- true_date.minute;
	date starting_date <- date([year_missing,month_missing,day_missing,hour_missing,minute_missing,0]); //[Year, Month, Day, Hour, Minute, Sec]
	bool error_flag <- false;
	
	//Boolean that determines wheter or not the current day of the simulation is Friday, Saturday, or Monday
	bool weekend_bool <- false;
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
	file<geometry> osmfile <-  file<geometry>(osm_file("../includes/maps/athens_centre_wind.osm", filtering))  ;
	//file<geometry> osmfile <-  file<geometry>(osm_file("../includes/map(6).osm"))  ;
	
	//compute the size of the environment from the envelope of the OSM file
	geometry shape <- envelope(osmfile);
	
	//GIS Input//
	//map used to filter the object to build from the OSM file according to attributes. for an exhaustive list, see: http://wiki.openstreetmap.org/wiki/Map_Features
	//map filtering <- (["highway"::["primary", "secondary", "tertiary", "motorway", "living_street","residential", "unclassified", "service", "secondary_link", "pedestrian", "footway", "steps"],
	//"building"::["yes", "house","dormitory", "university grounds","university", "church", "office", "residential", "commercial", "house", "hotel", "apartments", "industrial", "retail", "hospital", "government"]]);
	
	
	float step <- 1 #minute; //every step is defined as 1 minute
	
	
	int nb_people <- 200; //number of people in the simulation
	int nb_missing <- 1; //number of missing people (It will always be 1 in this simulation)
	int missing -> {length(missing_person)};
	int days_that_is_missing update: int(time / #day);
	int hours_that_is_missing update: int(time / #hour) mod 24;
	int minutes_that_is_missing update: int(time / #minute) mod 60;
	int current_hour <- starting_date.hour update: current_date.hour; //the current hour of the simulation
	int current_min <- starting_date.minute update: current_date.minute; //the current minute
	
	
	//variables concerning the times that people agents go and leave work respectively
	int min_work_start <- 3;
	int max_work_start <- 11;
	//int min_work_end <- 13; 
	//int max_work_end <- 21;
	
	//variables concerning the duration of leisure time of people agents
	
	
	//variables concerning the missing person
	int time_to_rest_hours <- 0;
	int time_to_rest_min <- 30;
	
	int time_to_move_hours <- 0;
	int time_to_move_min <- 0;
	
	//variables concerning the speed that the agents are traveling. Measured in km/h
	float min_walking_speed <- 2 #km / #h;
	float max_walking_speed <- 6 #km / #h;
	float min_driving_speed <- 5 #km / #h;
	float max_driving_speed <- 45 #km / #h;
	
	//variables concerning the speed that the missing person agent will be traveling. Measured in km/h
	float min_speed_missing <- 2.0 #km / #h;
	float max_speed_missing <- 5.4 #km / #h; 
	
	//variables concerning the probability of finding the missing person when near them
	float proba_find_walking <- 0.5;
	float proba_find_driving <- 0.1;
	float proba_find_resting <- 0.01;
	
	//variables for probabilistic location of missing person
	point Point_of_Interest1 <- nil;
	point Point_of_Interest2 <- nil;
	string Point_of_Interest1_name <- nil;
	string Point_of_Interest2_name <- nil;
	point MP_Starting_Pos <- nil;
	string MP_Starting_Pos_name <- nil;
	
	int times_found<- 0;
	int times_found_walking <- 0;
	int times_found_driving <- 0;
	int times_found_resting <- 0;
	int close_call <-0;
	
	//bool variable for mp resting
	//When missing person is resting it is unlikely that they will be found
	bool m_p_resting<-true;
	int arrived_hour_mp <- 0;
	int arrived_min_mp <- 0;
	int how_many_PoIs <-0;
	
	graph the_graph; //initialize the graph that the agents will be moving on
	
	list missing_agents -> missing_person.population;
	agent the_missing_agent -> missing_agents at 0;
	
	float destroy <- 0.02; // burden on road if people agent moves through it
	
	float demographic_driving <- 58.0;
	float demographic_walking <- 0.0;
	bool demographic_bool;
	
	bool a_boolean_to_enable_parameters1 <- false;
	bool a_boolean_to_enable_parameters2 <- false;
	bool a_boolean_to_enable_parameters3 <- false;	
	bool a_boolean_to_enable_parameters4 <- false;
	
	bool is_batch <- false;

	float min_walking_speed_meters_per_s;
	float max_walking_speed_meters_per_s;
	
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
			
			//dist_helper <- gamma_rnd(2519.91,1.15) -2189; // min:6.0 max:10.0; 
			//start_work_hour <- int(dist_helper/60);
			//start_work_min <- int(dist_helper - start_work_hour*60);
			//dist_helper <- gamma_rnd(5.56, 30.81) + 954.96;
			//end_work_hour <- int(dist_helper/60);
			//end_work_min <- int(dist_helper - end_work_hour*60);
			
			
			
			start_work_hour <- min_work_start + rnd (max_work_start - min_work_start) ;
			start_work_min <- rnd(0,59);
			//end_work_hour <- min_work_end + rnd (max_work_end - min_work_end) ;
			//end_work_min <- rnd(0,59);
			
			//dist_helper <- gauss_rnd(9,1);
			//start_work_hour <- int(dist_helper);
			//start_work_min <- rnd(0,59);
			dist_helper <- gauss_rnd(19,1.5);
			end_work_hour <- int(dist_helper);
			end_work_min <- rnd(0,59);
			
			break_start_hour <- start_work_hour + ((end_work_hour - start_work_hour) div 2);
			break_start_min <- 0;
			
			break_end_hour <- break_start_hour;
			break_end_min <- rnd(15,50);
			
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
			
			people_nearby <- agents_at_distance(0.007#km);
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
/* 	
	reflex update_graph{
        map<road,float> weights_map <- road as_map (each:: (each.destruction_coeff * each.shape.perimeter));
        the_graph <- the_graph with_weights weights_map;
     }*/
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


//define the missing_person species
species missing_person skills:[moving] {
	//aria: this parameters are set when the missing_person is being called for the first time to be created in init function
	//aria: afterwards in every cycle it examines the reflexes
	rgb color <- #maroon;

	building living_place <- nil ;
	//PoI.type <-  Point_of_Interest1_name;
	string objective <- "running" ; 
	point the_target <- nil ;
	bool input_flag <- false;

	
	
		
	list people_nearby; //  equals all the agents (excluding the caller) which distance to the caller is lower than 1
	
	int nb_of_agents_nearby -> {length(people_nearby)};
	
	
	//this reflex sets the target of the missing person to either a random building or a number of Points of Interest
	reflex run when: objective = "running" and the_target = nil {
		
		if(Point_of_Interest1 != nil and Point_of_Interest2 = nil){
			if(flip(0.4)){
				the_target <- Point_of_Interest1;
			}
			else {
				the_target <- point(one_of(building));  // casted one_of(building) to point type!!! one_of(the_graph.vertices);
			}
		}
		else if (Point_of_Interest1 != nil and Point_of_Interest2 != nil){
			int i <- rnd (0,1);
			if (i < 0.2) {
				the_target <- Point_of_Interest1;
			}
			else if (i < 0.4) {
				the_target <- Point_of_Interest2;
			}
			else {
				the_target <- point(one_of(building)); 
			}
		}
		else if (Point_of_Interest1 = nil and Point_of_Interest2 != nil){
			if(flip(0.4)){
				the_target <- Point_of_Interest2;
			}
			else {
				the_target <- point(one_of(building));  // casted one_of(building) to point type!!! one_of(the_graph.vertices);
			}
		}
		else {
			the_target <- point(one_of(building));
		}			
			
		
		arrived_hour_mp <- current_hour;  //aria: not understood why this is needed
		arrived_min_mp <- current_min;
	}		
	
	reflex rest_time when: objective = "resting" {
		time_to_move_min <- (arrived_min_mp + time_to_rest_min);
		if(time_to_move_min > 59){
			time_to_move_hours <- (arrived_hour_mp + time_to_rest_hours +1) mod 24;
			time_to_move_min <- time_to_move_min mod 60;			
		}
		else {
			time_to_move_hours <- (arrived_hour_mp + time_to_rest_hours) mod 24;
		}
		
	}

	reflex done_resting when: objective = "resting" and current_hour = time_to_move_hours and current_min = time_to_move_min { //+ time_to_rest_min#minutes )) {
		//write "HEY";
		objective <- "running";
		m_p_resting <- false;
		
		
	}
	
	//this reflex defines how the missing person moves 
	reflex move when: the_target != nil {
		do goto target: the_target on: the_graph ; 
		if the_target = location {
			the_target <- nil ;
			objective <- "resting";
			arrived_hour_mp <- current_hour;
			arrived_min_mp <- current_min;
			m_p_resting <- true;
		}
	}
	
	//the visualisation of the missing person on the graph
	aspect base {
		draw circle(10) color: color border: #black;
	}
	
}



//define the people species
species people skills:[moving] {
	
	rgb color <- #teal;
	
	building living_place <- nil ;
	building working_place <- nil ;
	int start_work_hour;
	int start_work_min;
	int break_start_hour;
	int break_start_min;
	int break_end_hour;
	int break_end_min;
	int end_work_hour;
	int end_work_min;
	
	bool small_distance;
	float distance;
	bool driving_bool <- nil;
	bool walking_bool <- nil;
	
	string objective ; 
	point the_target <- nil ;   //local variable different from the missing person's one
	point work_spot <- nil;
	point home_spot <- nil;
	
	bool local_demo_driving;
	
	bool agenda_0;
	bool agenda_1;
	bool agenda_2;
	bool free_agenda_0;
	bool free_agenda_1;
	bool free_agenda_2;
	bool going_to_l1of2;
	bool going_to_l1of1;
	bool going_to_l2of2;
	
	bool done_2of2;
	bool l1_home_l2;
	bool dont_go_home_from_leisure;
	
	bool weekend_worker;
	
	int arrived_hour;
	int arrived_min;
	
	int activity_start_hour;
	int activity_start_min;
	int departure_hour;
	int departure_min;
	
	bool return_flag <- false;
	
	
	//Reset Bool Decider One Hour Before Minimum Working Time
	reflex bool_decider_init when: current_hour = min_work_start - 1 and current_min = 0 {
		agenda_0 <- false;
		agenda_1 <- false;
		agenda_2 <- false;
		free_agenda_0 <- false;
		free_agenda_1 <- false;
		free_agenda_2 <- false;
		going_to_l1of2 <- false;
		going_to_l1of1 <- false;
		going_to_l2of2 <- false;
		activity_start_hour <- min_work_start -4;
		departure_hour <- min_work_start -3;
		
		
		done_2of2 <- false;
		//initialise l1_home_l2 for later
		l1_home_l2 <- false;

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
			if (i < 0.2) {
				free_agenda_0 <- true;
			}
			else if (i< 0.7) {
				free_agenda_1 <- true;
				//time_for_activity1 to start
				/////////////////////////////////////Check spcific times with Aria
				//we assume a 5 hour window since the agent's work ended for them to start an activity, and a max value of 12pm
				activity_start_hour <- rnd(8, 18);
				activity_start_min <- rnd(0,59);
			
			}
			else {
				free_agenda_2 <- true;
				activity_start_hour <- rnd(8, 15);
				activity_start_min <- rnd(0,59);
			}
		}	
	} 
		
	//this reflex sets the target when it's time to work and changes the objective of the agent to working
	//Wherever the agent is, whatever his current objective, it changes to going to work
	reflex time_to_work when: current_hour = start_work_hour and current_min = start_work_min and (!weekend_bool or weekend_worker){
		objective <- "going_to_work" ;
		the_target <- work_spot;
		distance <- 1.5 * (location distance_to the_target);
		small_distance <- distance < 1 #km;		
		if(demographic_bool){
			if(local_demo_driving){driving_bool <- true;}
			else {walking_bool <- true;}
		}
		else{
			if(small_distance) {walking_bool <- true;}
			else {driving_bool<-true;}
		}		
	}
	
	
	reflex time_for_break when: current_hour = break_start_hour and current_min = break_start_min and (objective = "working"){
		objective <- "going_to_break" ;
		the_target <- any_location_in(one_of(building));
		using topology(the_graph)
		{
			distance <- (location distance_to the_target);
		}	
		loop while: distance > 1 #km	{    //find me a target (leisure place) that is close to me, less than 1km distance
			the_target <- any_location_in(one_of(building));
			using topology(the_graph)
			{
				distance <- (location distance_to the_target);
			}
		}		
		//distance <- 1.5 * (location distance_to the_target);
		small_distance <- distance < 0.5 #km;		
		if(demographic_bool){
			if(local_demo_driving){driving_bool <- true;}
			else {walking_bool <- true;}
		}
		else{
			if(small_distance) {walking_bool <- true;}
			else {driving_bool<-true;}
		}		
	}
	
	reflex return_from_break when: current_hour = break_end_hour and current_min = break_end_min and (objective = "on_break"){
		objective <- "going_to_work" ;
		the_target <- work_spot;
		//distance <- 1.5 * (location distance_to the_target);
		using topology(the_graph)
		{
			distance <- (location distance_to the_target);
		}
		small_distance <- distance < 0.5 #km;		
		if(demographic_bool){
			if(local_demo_driving){driving_bool <- true;}
			else {walking_bool <- true;}
		}
		else{
			if(small_distance) {walking_bool <- true;}
			else {driving_bool<-true;}
		}		
	}
	
	
	
			
	reflex leisure_program_after_work when: current_hour = end_work_hour and current_min = end_work_min and objective = "working"{
		if( agenda_1 ){
			if(flip(0.5)){
				//go to leisure1
				the_target <- any_location_in(one_of(building));
				objective <- "going_for_leisure";
				using topology(the_graph)
				{
					distance <- (location distance_to the_target);
				}	
				loop while: distance > 1 #km	{    //find me a target (leisure place) that is close to me, less than 1km distance
					the_target <- any_location_in(one_of(building));
					using topology(the_graph)
					{
						distance <- (location distance_to the_target);
					}
				}		
				//distance <- 1.5 * (location distance_to the_target);
				small_distance <- distance < 0.5 #km;
				if(demographic_bool){
					if(local_demo_driving){driving_bool <- true;}
					else {walking_bool <- true;}
				}
				else{
					if(small_distance) {walking_bool <- true;}
					else {driving_bool<-true;}
				}
				going_to_l1of1 <- true;
			}
			else {
				//go home and then afterwards go to leisure 1
				objective <- "going_home";
				the_target <- home_spot; 
				using topology(the_graph)
				{
					distance <- (location distance_to the_target);
				}	
				//distance <- 1.5 * (location distance_to the_target);
				small_distance <- distance < 0.5 #km;
				if(demographic_bool){
					if(local_demo_driving){driving_bool <- true;}
					else {walking_bool <- true;}
				}
				else{
					if(small_distance) {walking_bool <- true;}
					else {driving_bool<-true;}
				}
				//time_for_activity1 to start
				//we assume a 5 hour window since the agent's work ended for them to start an activity, and a max value of 12pm
				activity_start_hour <- rnd(end_work_hour, min(end_work_hour + 5, 24));
				if(activity_start_hour = current_hour) 
				{
					activity_start_min <- rnd(current_min,59);
				}
				else{
					activity_start_min <- rnd(0,59);
				}
			}
		}
		else if (agenda_2){
			if(flip(0.5)){
				
				//go to leisure1 from 2
				the_target <- any_location_in(one_of(building));
				objective <- "going_for_leisure";
				//distance <- 1.5 * (location distance_to the_target);
				using topology(the_graph)
				{
					distance <- (location distance_to the_target);
				}	
				loop while: distance > 1 #km	{    //find me a target (leisure place) that is close to me, less than 1km distance
					the_target <- any_location_in(one_of(building));
					using topology(the_graph)
					{
						distance <- (location distance_to the_target);
					}
				}						
				small_distance <- distance < 0.5 #km;
				if(demographic_bool){
					if(local_demo_driving){driving_bool <- true;}
					else {walking_bool <- true;}
				}
				else{
					if(small_distance) {walking_bool <- true;}
					else {driving_bool<-true;}
				}
				going_to_l1of2 <- true;
			}
			else{
				//go home and then to leisure 1 from 2
				objective <- "going_home";
				the_target <- home_spot; 
				//distance <- 1.5 * (location distance_to the_target);
				using topology(the_graph)
				{
					distance <- (location distance_to the_target);
				}		
				small_distance <- distance < 0.5 #km;
				if(demographic_bool){
					if(local_demo_driving){driving_bool <- true;}
					else {walking_bool <- true;}
				}
				else{
					if(small_distance) {walking_bool <- true;}
					else {driving_bool<-true;}
				}
				//time_for_activity1_of_2 to start
				//we assume a 3 hour window since the agent's work ended for them to start an activity
				//and a max value of 10pm, for them to have enough time for their second activity
				
				activity_start_hour <- rnd(end_work_hour, min(end_work_hour + 2, 20));
				if(activity_start_hour = current_hour) 
				{
					activity_start_min <- rnd(current_min,59);
				}
				else{
					activity_start_min <- rnd(0,59);
				}
				
			}
		}
		else {
			//go home and stay there, agenda_0
			objective <- "going_home";
			the_target <- home_spot; 
			//distance <- 1.5 * (location distance_to the_target);
			using topology(the_graph)
			{
				distance <- (location distance_to the_target);
			}	
			small_distance <- distance < 0.5 #km;
			if(demographic_bool){
				if(local_demo_driving){driving_bool <- true;}
				else {walking_bool <- true;}
			}
			else{
				if(small_distance) {walking_bool <- true;}
				else {driving_bool<-true;}
			}
		}
		
		
	}
	
	reflex home_to_leisure_1 when: (agenda_1 = true or free_agenda_1 = true) and !going_to_l1of1 and current_hour = activity_start_hour 
							and current_min = activity_start_min 
		{
		//go from home to single leisure
		the_target <- any_location_in(one_of(building));
		objective <- "going_for_leisure";
		//distance <- 1.5 * (location distance_to the_target);
		using topology(the_graph)
		{
			distance <- (location distance_to the_target);
		}	
		loop while: distance > 1 #km	{    //find me a target (leisure place) that is close to me, less than 1km distance
			the_target <- any_location_in(one_of(building));
			using topology(the_graph)
			{
				distance <- (location distance_to the_target);
			}
		}		
		small_distance <- distance < 0.5 #km;
		if(demographic_bool){
			if(local_demo_driving){driving_bool <- true;}
			else {walking_bool <- true;}
		}
		else{
			if(small_distance) {walking_bool <- true;}
			else {driving_bool<-true;}
		}
		going_to_l1of1 <- true;
	}
	
	reflex home_to_leisure_1of2 when: (agenda_2 = true or free_agenda_2 = true) and !going_to_l1of2 and current_hour = activity_start_hour  
								and current_min = activity_start_min 								
	{
		//go from home to leisure 1 of 2
		the_target <- any_location_in(one_of(building));
		objective <- "going_for_leisure";
		//distance <- 1.5 * (location distance_to the_target);
		using topology(the_graph)
		{
			distance <- (location distance_to the_target);
		}	
		loop while: distance > 1 #km	{    //find me a target (leisure place) that is close to me, less than 1km distance
			the_target <- any_location_in(one_of(building));
			using topology(the_graph)
			{
				distance <- (location distance_to the_target);
			}
		}		
		small_distance <- distance < 0.5 #km;
		if(demographic_bool){
			if(local_demo_driving){driving_bool <- true;}
			else {walking_bool <- true;}
		}
		else{
			if(small_distance) {walking_bool <- true;}
			else {driving_bool<-true;}
		}
		going_to_l1of2 <- true;
		/// Program what start time the 2nd activity will have!
		
	}
	
	reflex leisure_1to2_decider when: objective = "leisure" and going_to_l1of2 and !going_to_l2of2 and current_hour = departure_hour and current_min = departure_min {
		
		//l1 -> home -> and afterwards to l2, only if the day has not changed
		if(flip(0.5) and current_hour > 6) {
			l1_home_l2 <- true;
			if(agenda_2){
				activity_start_hour <- rnd(current_hour, min(current_hour + 3, 24));
				if(activity_start_hour = current_hour) 
				{
					activity_start_min <- rnd(current_min,59);
				}
				else{
					activity_start_min <- rnd(0,59);
				}
			}
			else if(free_agenda_2){
				activity_start_hour <- rnd(current_hour, min(current_hour + 4, 24));
				if(activity_start_hour = current_hour) 
				{
					activity_start_min <- rnd(current_min,59);
				}
				else{
					activity_start_min <- rnd(0,59);
				}
			}
				
		}
		//l1 -> l2 -> home
		else {
			//go to leisure2 from 2, l1->l2->home
			the_target <- any_location_in(one_of(building));
			objective <- "going_for_leisure";
			//distance <- 1.5 * (location distance_to the_target);
			using topology(the_graph)
			{
				distance <- (location distance_to the_target);
			}	
			loop while: distance > 1 #km	{    //find me a target (leisure place) that is close to me, less than 1km distance
				the_target <- any_location_in(one_of(building));
				using topology(the_graph)
				{
					distance <- (location distance_to the_target);
				}
			}		
			small_distance <- distance < 0.5 #km;
			if(demographic_bool){
				if(local_demo_driving){driving_bool <- true;}
				else {walking_bool <- true;}
			}
			else{
				if(small_distance) {walking_bool <- true;}
				else {driving_bool<-true;}
			}
			going_to_l2of2 <- true;
		}
		
	}
	
	reflex home_to_leisure2_of_2 when: (agenda_2 = true or free_agenda_2 = true) and l1_home_l2 = true and current_hour = activity_start_hour and current_min = activity_start_min {
		//go from home to leisure 2 of 2
		the_target <- any_location_in(one_of(building));
		objective <- "going_for_leisure";
		using topology(the_graph)
		{
			distance <- (location distance_to the_target);
		}	
		loop while: distance > 1 #km	{    //find me a target (leisure place) that is close to me, less than 1km distance
			the_target <- any_location_in(one_of(building));
			using topology(the_graph)
			{
				distance <- (location distance_to the_target);
			}
		}		
		//distance <- 1.5 * (location distance_to the_target);
		small_distance <- distance < 0.5 #km;
		if(demographic_bool){
			if(local_demo_driving){driving_bool <- true;}
			else {walking_bool <- true;}
		}
		else{
			if(small_distance) {walking_bool <- true;}
			else {driving_bool<-true;}
		}
		going_to_l2of2 <- true;
	}
	
	//The decision for how much time to spend on a particular leisure activity 
	//can be decided only when the agent arrives at the leisure place
	reflex return_from_leisure when: objective = "leisure" and  return_flag {
		
		int activity_duration;
		int activity_hours;
		int activity_min;
		
		//must check if durations are out of bounds!!!
		if ((agenda_1 or agenda_2) and (arrived_hour > min_work_start)) {
			if (agenda_1 and going_to_l1of1) {
				//min(3, k-z) where z = 1, activity duration in minutes
				activity_duration <- rnd(30, min(3, (24 - arrived_hour + 1))*60);
			}
			else if (agenda_2 and going_to_l2of2) {
				activity_duration <- rnd(30, 60);
			}
			else if (agenda_2 and going_to_l1of2 and !going_to_l2of2){
				activity_duration <- rnd(30, min(3, (22 - arrived_hour + 1))*60);
			}	
			else {
				write "error in return from leisure";
				error_flag <- true;
				write self.name;
			}			
		}
		else if ((agenda_1 or agenda_2) and (arrived_hour < min_work_start)) {
			if ((agenda_1 and going_to_l1of1) or (agenda_2 and going_to_l2of2) or (agenda_2 and going_to_l1of2 and !going_to_l2of2)) {
				//min(3, k-z) where z = 1, activity duration in minutes
				activity_duration <- rnd(30, 60);
			}
			else {
				write "error in return from leisure";
				error_flag <- true;
				write self.name;
				}
		}
		else if (free_agenda_1 and going_to_l1of1)  {
			//min(3, k-z) where z = 1, activity duration in minutes
			activity_duration <- rnd(60, min(5, (24 - arrived_hour + 1))*60);
		}
		else if (free_agenda_2 and going_to_l2of2) {
			activity_duration <- rnd(60, min(2, (24 - arrived_hour + 1))*60);
		}
		else if (free_agenda_2 and going_to_l1of2 and !going_to_l2of2){
			activity_duration <- rnd(60, min(5, (22 - arrived_hour + 1))*60);
		}
		else {
			write "error in return from leisure";
			error_flag <- true;
			write self.name;
		}
		
		activity_hours <- activity_duration div 60;
		activity_min <- activity_duration mod 60;
	
		departure_min <- arrived_min + activity_min;
		if(departure_min) > 59{
			departure_hour <- (arrived_hour + activity_hours + 1) mod 24;
			departure_min <- departure_min mod 60;
		}
		else {
			departure_hour <- (arrived_hour + activity_hours) mod 24;
		}	
		return_flag <- false;
	}
	
	
	
	
	reflex leisure_to_home when: objective = "leisure" and current_hour = departure_hour and current_min = departure_min {
		objective <- "going_home" ;
		the_target <- home_spot; 
		//distance <- 1.5 * (location distance_to the_target);
		using topology(the_graph)
		{
			distance <- (location distance_to the_target);
		}	
		small_distance <- distance < 0.5 #km;
		if(demographic_bool){
			if(local_demo_driving){driving_bool <- true;}
			else {walking_bool <- true;}
		}
		else{
			if(small_distance) {walking_bool <- true;}
			else {driving_bool<-true;}
		}
	}

	
	//this reflex defines the probabilistic model by which the agent is found
	//in any of three states: 
	//when the People Agent is a.walking, b.driving, c.resting
	reflex missing_person_nearby when: agents_at_distance(0.007#km) contains_any missing_person {
		
		if(walking_bool){
			close_call<-close_call+1;
			write "Walking and near " + self;
			if(flip(proba_find_walking)){
				times_found <- times_found + 1;
				times_found_walking <- times_found_walking + 1;
				write "Took a walk and stars aligned, FOUND by " + self +" Times Found " + times_found;
			}
		}
		else if(driving_bool){
			close_call<-close_call+1;
			write ("Driving and near" + self);
			if(flip(proba_find_driving)){
				times_found <- times_found + 1;
				times_found_driving <- times_found_driving + 1;
				write "Prayers to driving gods helped, FOUND by " + self +" Times Found " +times_found;
			}
		}
		else {
			close_call<-close_call+1;
			//write "Resting inside building Phase and Near";
			//if(flip(proba_find_resting) and m_p_resting = false){
			if(flip(proba_find_resting)){
				times_found <- times_found + 1;
				times_found_resting <- times_found_resting + 1;
				write "Quarantine is King, FOUND by " +self +" Times Found " +times_found;
			}
		}
		
	}
	
	reflex walk when: (the_target !=nil and walking_bool){
		//boolean indicator initialization
		driving_bool <- false;
		speed <- rnd (min_walking_speed, max_walking_speed) ;
		path path_followed <- goto(target: the_target, on:the_graph, return_path: true);
    	list<geometry> segments <- path_followed.segments;
    	loop line over: segments {
        	float dist <- line.perimeter;
    	}
		if the_target = location {
			the_target <- nil; 
			//boolen indicator returning to default
			//write "Walking boolen indicator returning to default";
			walking_bool <- false;
			if(objective = "going_to_work") {
				objective <- "working";
			}
			else if (objective = "going_home"){
				objective <- "resting";
	
			}
			else if (objective = "going_for_leisure"){
				arrived_hour <- current_hour;
				arrived_min <- current_min;
				objective <- "leisure";
				return_flag <- true;
			}
			else if (objective = "going_to_break"){
				objective <- "on_break";
			}
		}
	}
	
	reflex drive when: (the_target !=nil and driving_bool){
		//boolean indicator initialization
		speed <- min_driving_speed + rnd (max_driving_speed - min_driving_speed) ;
		path path_followed <- goto(target: the_target, on:the_graph, return_path: true);
    	list<geometry> segments <- path_followed.segments;
    	loop line over: segments {
        	float dist <- line.perimeter;
    	}
		if the_target = location {
			the_target <- nil ;
			//write "Driving boolen indicator returning to default";
			//boolen indicator returning to default
			driving_bool <- false;
			if(objective = "going_to_work") {
				objective <- "working";
			}
			else if (objective = "going_home"){
				objective <- "resting";
			}
			else if (objective = "going_for_leisure"){
				arrived_hour <- current_hour;
				arrived_min <- current_min;
				objective <- "leisure";
				return_flag <- true;
			}
			else if (objective = "going_to_break"){
				objective <- "on_break";
			}
			
		}
		
	}
	
	//the visualisation of people agents on the graph
	aspect base {
		//draw image_file("../includes/car-png-top-white-top-car-png-image-34867-587.png") size:{10#m,2.5#m} rotate: heading+180;
		draw circle(10) color: color border: #black;
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
    //parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    //parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
   	parameter "minimum walking speed (m/s)" var: min_walking_speed category: "People" min: 0.1 #km/#h  max: 5.0 #km/#h step: 0.1 #km/#h ;
	parameter "maximum walking speed (m/s)" var: max_walking_speed category: "People" min: 5.0  #km/#h max: 50 #km/#h step: 1 #km/#h;
	parameter "minimum driving speed (m/s)" var: min_driving_speed category: "People" min: 0.1 #km/#h ;
	parameter "maximum driving speed (m/s)" var: max_driving_speed category: "People" max: 70 #km/#h;
	
	//Missing Person Activatable Parameters
	parameter "minimum speed for missing person (m/s)" var: min_speed_missing category: "Missing_Person Ext" min: 0.1 #km/#h ;
	parameter "maximum speed for missing person (m/s)" var: max_speed_missing category: "Missing_Person Ext" max: 50 #km/#h;
	
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
        //monitor "Hour Arrived" value: arrived_hour_mp;
        //monitor "Min Arrived" value: arrived_min_mp;
        //monitor "M/s" value: min_walking_speed_meters_per_s;
	}
}

//20000 minutes is 13.88 days
experiment Batch_Optimization_No_Times_Found type: batch repeat: 2 keep_seed: true until: ( (time / #day) > 4) {
	parameter "Number of People in Area" var: nb_people min:100 max:1000 step: 20;
	//parameter "Probability of finding ms if walking" var: proba_find_walking category: "Probabilities" min: 0.01 max: 1.0 step: 0.1;
	//parameter "Probability of finding ms if driving" var: proba_find_driving category: "Probabilities" min: 0.01 max: 1.0 step: 0.1;
	//parameter "Probability of finding ms while resting" var: proba_find_resting category: "Probabilities" min: 0.01 max: 1.0 step: 0.1;
  	//parameter "Batch mode:" var: is_batch <- true;
   //,proba_find_walking,proba_find_driving,proba_find_resting  //2880
   
    method exhaustive maximize: times_found;
    //method tabu maximize: times_found iter_max: 10 tabu_list_size: 3;
    
    
    reflex save_results_explo {
        ask simulations {
            save [int(self),nb_people, self.times_found, self.times_found_walking, self.times_found_driving, self.times_found_resting] 
                   to: "../results_no_times.csv" type: "csv" rewrite: (int(self) = 0) ? true : false header: true;
        }        
    }
}

experiment Batch_Optimization_First_Time type:batch repeat: 10 keep_seed: true until: ( times_found = 1 or days_that_is_missing > 30) {
	parameter "Number of People in Area" var: nb_people min:50 max:200 step: 50;
  
    method exhaustive minimize: time;
    //method tabu maximize: times_found iter_max: 10 tabu_list_size: 3;
    
        
    reflex save_results_explo {
        ask simulations {
            save [int(self),nb_people, (self.time / #day), (self.time / #minute) ] 
                   to: "../results_first_time_mp_Athens_centre_50to200_step50.csv" type: "csv" rewrite: (int(self) = 0) ? true : false header: true;
        }        
    }
}