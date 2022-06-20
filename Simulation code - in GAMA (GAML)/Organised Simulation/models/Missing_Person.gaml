/**
* Name: MissingPerson
* Missing Person
 
* Author: mpizi
* Tags: 
*/


model MissingPerson

import "./../models/Map.gaml"
import "./../models/Parameters.gaml"

/* Insert your model definition here */

//define the missing_person species
species missing_person skills:[moving] {
	rgb color <- #maroon;

	building living_place <- nil ;
	//PoI.type <-  Point_of_Interest1_name;
	string objective <- "running" ; 
	point the_target <- nil ;
	bool input_flag <- false;

	
	
		
	list people_nearby; // people_nearby equals all the agents (excluding the caller) which distance to the caller is lower than 1
	
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
			
		
		arrived_hour_mp <- current_hour;
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


