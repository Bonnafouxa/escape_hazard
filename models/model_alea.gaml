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
	
	// WHY DO WE NEED THIS GAMA TEAM ?
	float threshold_dist <- 10#nm;
	
	// Display purpose attribute
	geometry current_scenario;
	list<point> origins;
	list<point> destinations;

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
	
	reflex print_shape_num when:false {
		write alea[0].the_points collect int(each);
	}
	
}

species X_point skills:[moving] {
	
	float the_speed;
	point p_destination;
	
	bool moveX <- false;
	
	reflex move_to_next_location when: moveX {
		do goto target:p_destination speed:the_speed#m/#s;
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
	
	/*
	 * Update scenario
	 */
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
	 * Update destination of X point
	 */
	reflex update_x_points when: update_cycle {
		origins <- shape.points - current_scenario.points;
		destinations <- remove_duplicates(current_scenario.points - shape.points);
		
		list<X_point> x_origins <- the_points where (origins contains each.location); // TODO make sure it's working
		map<X_point, point> origins_destinations;
		
		// More origins than destinations
		if(length(destinations) < length(x_origins)) {
			origins_destinations <- destinations as_map (x_origins closest_to each::each);
		// Less origins than destinations, have to create new X_point
		} else {
			map<point, X_point> od_map <- x_origins as_map (destinations closest_to each::each);
			loop dest over:destinations {
				X_point oxp;
				if(od_map.keys contains dest){
					oxp <- od_map[dest];
				} else {
					create X_point with:[location::closest_points_with(dest,shape)[1]] returns: new_xps;
					oxp <- new_xps[0];
				}
				origins_destinations[oxp] <- dest;
			}
		}
		
		int updated_index <- min(x_origins collect (the_points index_of(each)));
		
		loop px over:origins_destinations.pairs{
			X_point update_xp <- px.key;
			point update_destination <- px.value;  
			update_xp.the_speed <- (update_xp.location distance_to update_destination)#m / (the_scenario.get_next_date() - current_date)#s;
			update_xp.p_destination <- update_destination;
			update_xp.moveX <- true;
			
			if(not (the_points contains update_xp)){
				the_points[updated_index] +<- update_xp;
			}
			updated_index <- the_points index_of update_xp + 1;
		}
		
		write "Destinations: "+length(destinations)+" | origins: "+length(x_origins)
			+" | actual x_points: "+length(X_point)+" with "+length(X_point where each.moveX)+" moving and "+(length(origins_destinations)-length(x_origins))+" created";
		
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
		return the_steps.keys where (each > current_date) with_min_of each;
	}
	
}

experiment main type:gui {
	float minimum_cycle_duration <- 0.1; 
	output{
		display map type:opengl {
			graphics "scenario" { draw current_scenario color:#yellow; }
			species alea aspect:default refresh:true transparency:0.6;
			species X_point aspect:default refresh:true;
			graphics "destinations"{
				loop p over:destinations{
					draw circle(5#m,p) color:#purple;
				}
			}
		}
	}	
}

