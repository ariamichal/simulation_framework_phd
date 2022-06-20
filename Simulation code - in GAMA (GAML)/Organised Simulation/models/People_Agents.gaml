/**
* Name: PeopleAgents
* The People Agents 
* Author: mpizi
* Tags: 
*/


model PeopleAgents

import "./../models/Map.gaml"
import "./../models/Parameters.gaml"

//define the people species
species people skills:[moving] {
	
	rgb color <- #teal;
	
	building living_place <- nil ;
	building working_place <- nil ;
	int start_work_hour;
	int start_work_min;
	int end_work_hour;
	int end_work_min;
	
	bool small_distance;
	float distance;
	bool driving_bool <- nil;
	bool walking_bool <- nil;
	
	string objective ; 
	point the_target <- nil ;
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
	
	
	//Reset Bool Decider One Hour Before Mininmum Working Time
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
		activity_start_hour <- min_work_start -2;
		departure_hour <- min_work_start -2;
		
		
		done_2of2 <- false;
		//initialise l1_home_l2 for later
		l1_home_l2 <- false;

		float i <- rnd(0.0,1.0);
		
		//First Condition for Work Days and Weekends with Work, Second for Free Weekends
		if (!weekend_bool or weekend_worker) {
			if(i < 0.05){
				agenda_0 <- true;
			}
			else if (i< 0.1) {
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
			
	reflex leisure_program_after_work when: current_hour = end_work_hour and current_min = end_work_min and objective = "working"{
		if( agenda_1 ){
			if(flip(0.5)){
				//go to leisure1
				the_target <- any_location_in(one_of(building));
				objective <- "going_for_leisure";
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
				going_to_l1of1 <- true;
			}
			else {
				//go home and then afterwards go to leisure 1
				objective <- "going_home";
				the_target <- home_spot; 
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
				going_to_l1of2 <- true;
			}
			else{
				//go home and then to leisure 1 from 2
				objective <- "going_home";
				the_target <- home_spot; 
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
				//time_for_activity1_of_2 to start
				//we assume a 3 hour window since the agent's work ended for them to start an activity
				//and a max value of 10pm, for them to have enough time for their second activity
				
				activity_start_hour <- rnd(end_work_hour, min(end_work_hour + 3, 22));
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
		
		
	}
	
	reflex home_to_leisure_1 when: (agenda_1 = true or free_agenda_1 = true) and !going_to_l1of1 and current_hour = activity_start_hour 
							and current_min = activity_start_min 
		{
		//go from home to single leisure
		the_target <- any_location_in(one_of(building));
		objective <- "going_for_leisure";
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
		going_to_l1of1 <- true;
	}
	
	reflex home_to_leisure_1of2 when: (agenda_2 = true or free_agenda_2 = true) and !going_to_l1of2 and current_hour = activity_start_hour  
								and current_min = activity_start_min 								
	{
		//go from home to leisure 1 of 2
		the_target <- any_location_in(one_of(building));
		objective <- "going_for_leisure";
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
		going_to_l1of2 <- true;
		/// Program what start time the 2nd activity will have!
		
	}
	
	reflex leisure_1to2_decider when: objective = "leisure" and going_to_l1of2 and !going_to_l2of2 and current_hour = departure_hour and current_min = departure_min {
		
		//l1 -> home -> and afterwards to l2
		if(flip(0.5)) {
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
			going_to_l2of2 <- true;
		}
		
	}
	
	reflex home_to_leisure2_of_2 when: (agenda_2 = true or free_agenda_2 = true) and l1_home_l2 = true and current_hour = activity_start_hour and current_min = activity_start_min {
		//go from home to leisure 2 of 2
		the_target <- any_location_in(one_of(building));
		objective <- "going_for_leisure";
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
		going_to_l2of2 <- true;
	}
	
	//The decision for how much time to spend on a particular leisure activity 
	//can be decided only when the agent arrives at the leisure place
	reflex return_from_leisure when: objective = "leisure" and  return_flag {
		
		int activity_duration;
		int activity_hours;
		int activity_min;
		
		//must check if durations are out of bounds!!!
		if (agenda_1 or (agenda_2 and going_to_l2of2)){
			//min(3, k-z) where z = 1, activity duration in minutes
			activity_duration <- rnd(30, min(3, (24 - arrived_hour + 1))*60);
		}
		else if (agenda_2 and going_to_l1of2 and !going_to_l2of2){
			activity_duration <- rnd(30, min(3, (22 - arrived_hour + 1))*60);
		}	
		else if (free_agenda_1 or (free_agenda_2 and going_to_l2of2)) {
			//min(3, k-z) where z = 1, activity duration in minutes
			activity_duration <- rnd(30, min(3, (24 - arrived_hour + 1))*60);
		}
		else if (free_agenda_2 and going_to_l1of2 and !going_to_l2of2){
			activity_duration <- rnd(30, min(3, (22 - arrived_hour + 1))*60);
		}
		else {
			//activity_duration <- 0;
			write "error in return from leisure";
			write self.name;
			error_flag <- true;

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

	
	//this reflex defines the probabilistic model by which the agent is found
	//in any of three states: 
	//when the People Agent is a.walking, b.driving, c.resting
	reflex missing_person_nearby when: agents_at_distance(4) contains_any missing_person {
		
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
		}
		
	}
	
	//the visualisation of people agents on the graph
	aspect base {
		//draw image_file("../includes/car-png-top-white-top-car-png-image-34867-587.png") size:{10#m,2.5#m} rotate: heading+180;
		draw circle(10) color: color border: #black;
	}
}

