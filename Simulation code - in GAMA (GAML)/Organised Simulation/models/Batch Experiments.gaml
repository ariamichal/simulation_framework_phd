/**
* Name: BatchExperiments
*  
* Author: mpizi
* Tags: 
*/




model BatchExperiments

import "./../models/Missing_Child_Sim_main.gaml"

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

experiment Batch_Optimization_First_Time type:batch repeat: 10 keep_seed: true until: ( times_found = 1 ) {
	parameter "Number of People in Area" var: nb_people min:100 max:1000 step: 20;
  
    method exhaustive minimize: time;
    //method tabu maximize: times_found iter_max: 10 tabu_list_size: 3;
    
        
    reflex save_results_explo {
        ask simulations {
            save [int(self),nb_people, (self.time / #day), (self.time / #minute) ] 
                   to: "../results_first_time_mp_Athens_centre.csv" type: "csv" rewrite: (int(self) = 0) ? true : false header: true;
        }        
    }
}

