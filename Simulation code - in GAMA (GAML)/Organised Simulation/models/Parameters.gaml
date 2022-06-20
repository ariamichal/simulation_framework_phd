/**
* Name: Parameters
* Description: parameters and variables for the simulations and common agents
* Author: mpizi
* Tags: 
*/

model Parameters

import "./../models/Missing_Person.gaml"

/* List of parameters and global variables used in the simulations and common agents */

global{
	
	
	float step <- 1 #mn; //every step is defined as 1 minute
	
	bool weekend_bool <- false;
	bool error_flag <- false;
	
	int nb_people <- 200; //number of people in the simulation
	int nb_missing <- 1; //number of missing people (It will always be 1 in this simulation)
	int missing -> {length(missing_person)};
	int days_that_is_missing update: int(time / #day);
	int hours_that_is_missing update: int(time / #hour) mod 24;
	int minutes_that_is_missing update: int(time / #minute) mod 60;
	int current_hour <- starting_date.hour update: current_date.hour; //the current hour of the simulation
	int current_min <- starting_date.minute update: current_date.minute; //the current minute
	
	
	//variables concerning the times that people agents go and leave work respectively
	int min_work_start <- 6;
	int max_work_start <- 12;
	int min_work_end <- 13; 
	int max_work_end <- 21;
	
	//variables concerning the duration of leisure time of people agents
	
	
	//variables concerning the missing person
	int time_to_rest_hours <- 1;
	int time_to_rest_min <- 0;
	
	int time_to_move_hours <- 0;
	int time_to_move_min <- 0;
	
	//variables concerning the speed that the agents are traveling. Measured in km/h
	float min_walking_speed <- 3 #km / #h;
	float max_walking_speed <- 6 #km / #h;
	float min_driving_speed <- 5 #km / #h;
	float max_driving_speed <- 20 #km / #h;
	
	//variables concerning the speed that the missing person agent will be traveling. Measured in km/h
	float min_speed_missing <- 3.0 #km / #h;
	float max_speed_missing <- 5.0 #km / #h; 
	
	//variables concerning the probability of finding the missing person when near them
	float proba_find_walking <- 0.9;
	float proba_find_driving <- 0.4;
	float proba_find_resting <- 0.1;
	
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
	
	float demographic_driving <- 0.0;
	float demographic_walking <- 0.0;
	bool demographic_bool;
	
	bool a_boolean_to_enable_parameters1 <- false;
	bool a_boolean_to_enable_parameters2 <- false;
	bool a_boolean_to_enable_parameters3 <- false;	
	bool a_boolean_to_enable_parameters4 <- false;
	
	bool is_batch <- false;

	float min_walking_speed_meters_per_s;
	float max_walking_speed_meters_per_s;
	
}

