/**
* Name: modelalea
* Author: eisti
* Description: 
* Tags: Tag1, Tag2, TagN
*/




//Donction de diffusion
//List<Points>
//Max_sequence_length
//Centre de gravité

model modelalea

global {

	file building_shapefile <- shape_file("../includes/building.shp");
	file scenar1 <- file("../includes/hazard/RedRiver_scnr1.shp");
	file scenar2 <- file("../includes/hazard/RedRiver_scnr2.shp");
	file scenar3 <- file("../includes/hazard/RedRiver_scnr3.shp");
	file scenar4 <- file("../includes/hazard/RedRiver_scnr4.shp");

	geometry shape <- envelope(scenar4);
	
	float threshold_dist <- 10#nm;
	
	// Display purpose attribute
	geometry current_scenario;
	list<point> points_to_go;

	init{
		
		step <- 1#mn;
		starting_date <- #now;
		create alea from:scenar1 with:[color::#brown]{
			create scenario returns:the_scenar {
				the_steps <+ starting_date+1#h::scenar2[0];
				the_steps <+ starting_date+2#h::scenar3[0];
				the_steps <+ starting_date+3#h::scenar4[0];
			}
			the_scenario <- the_scenar[0];
		}
		ask alea{
			loop i over:remove_duplicates(shape.points){
				create X_point with:[location::i]{
					myself.the_points <+ self;
				}
			}
		}
	}
	
}

species X_point skills:[moving] {
	
	float the_speed;
	point p_destination;
	
	bool moveX <- false;
	
	reflex move_to_next_location when: moveX {
		do goto target:p_destination speed:the_speed;
		if(location = p_destination){
			moveX <- false;
		}
	}
	
	aspect default {
		draw geometry:circle(10#m) color:moveX ? #black : #green;
	}
	
}


species alea skills: [moving] {
	
	scenario the_scenario;
	bool update_cycle <- false;
	
	rgb color;
	
	list<X_point> the_points;
	
	reflex update_scenario when: empty(X_point where each.moveX){
		current_scenario <- the_scenario.get_next_step();
		
		if(current_scenario = nil){
			ask world {
				do pause;
			}
		} else {
			update_cycle <- true;
		}
	}
	
	/*
	 * Update destination and X point
	 */
	reflex update_points when: update_cycle {
		
		list<point> points_to_move <- remove_duplicates(shape.points);
		map<point,point> moving_to;
		
		points_to_move >>- current_scenario.points;
		points_to_go <- remove_duplicates(current_scenario.points);
		points_to_go >>- shape.points;
		
		// Define origin and destination
		if (length(points_to_move) >= length(points_to_go)){
			loop i over:points_to_go {
				moving_to[closest_to(points_to_move,i)]<-i;
			}
			
		} else {
			
			loop i over:points_to_move {
				moving_to[i]<-closest_to(points_to_go,i);
			}
			
			list<point> point_to_go_without_from; 
			point_to_go_without_from <<+ points_to_go;
			point_to_go_without_from >>- moving_to.values;
			
			loop i over: point_to_go_without_from {
				point new_point_to_move <- closest_points_with(i,shape)[1];
				moving_to[new_point_to_move] <- i;
				points_to_move <+ new_point_to_move;
			}
		}
		
		// Create and/or update X_point according to origin and destination
		loop p over:points_to_move{
			// list<X_point> xps <- X_point where (each.location = p); SEE THAT WITH BENOIT AND PATRICK
			list<X_point> xps <- X_point where (each.location distance_to p < threshold_dist);
			point dest <- moving_to[p];
			float dist <- distance_to(p, dest);
			float appointment <- the_scenario.get_next_date() - current_date;
			if(empty(xps)){
				create X_point {
					moveX <- true;
					location <- p;
					p_destination <- dest;
					the_speed <- dist#m/appointment#s;
					myself.the_points <+ self;
				}
			} else {
				X_point upX;
				if(length(xps)>1){
					write "There is several x point at one location";
					loop i from:1 to:length(xps) {
						ask xps[i] {
							myself.the_points >- self;
							do die;
						}
					}
				}
				upX <- first(xps);
				upX.moveX <- true;
				upX.p_destination <- dest;
				upX.the_speed <- dist#m/appointment#s;
			}
		}
		
		update_cycle <- false;
	}

	/*
	 * Move the shape
	 */
	reflex move_to {
		shape <- geometry(the_points collect each.location);
	}
	
	aspect default {
		draw shape color:color;
	}
	
}

species scenario {
	
	map<date, geometry> the_steps;
	
	geometry get_next_step {
		return the_steps[get_next_date()];
	}
	
	date get_next_date {
		return first(the_steps.keys where (each > current_date));
	}
	
}

experiment main type:gui {
	float minimum_cycle_duration <- 0.1; 
	output{
		display map type:opengl {
			species alea aspect:default refresh:true transparency:0.6;
			species X_point aspect:default refresh:true;
			graphics "scenario"{
				/*
				loop p over:current_scenario.points{
					draw circle(5#m,p) color:#red;
				}
				* 
				*/
				loop p over:points_to_go{
					draw circle(20#m,p) color:#purple;
				}
			}
		}
	}	
}

