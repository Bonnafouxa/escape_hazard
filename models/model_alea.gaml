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
	geometry current_scenario;
	
	list<point> points_to_go;
	
	geometry moving_shape;
	list<point> starting_points;

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
	
	rgb color;
	
	list<X_point> the_points;
	
	/*
	 * Update destination and X point
	 */
	reflex update_scenario when: empty(X_point where each.moveX) {
		
		current_scenario <- the_scenario.get_next_step();
		
		if(current_scenario = nil){
			ask world {do pause;}
		}
		
		list<point> points_to_move <- remove_duplicates(shape.points);
		map<point,point> moving_to;
		
		points_to_move >>- current_scenario.points;
		points_to_go <- remove_duplicates(current_scenario.points);
		points_to_go >>- shape.points;
		
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
		
		list<point> the_p <- X_point collect (each.location);
		list<point> the_x_points <- remove_duplicates(the_p);
		map<point, list<point>> the_duplicates;
		loop p over:the_p{
			if(the_duplicates.keys contains p){
				the_duplicates[p] <+ p;
			} else {
				the_duplicates[p] <- [p];
			}
		}
		
		
		write "Nb of non duplicates equals to "+length(the_duplicates)+" | full = "+length(the_p)+" & no-duplicate = "+length(the_x_points);
		write the_duplicates;
		
		write "the nb of points to move: "+length(points_to_move);
		
		ask X_point where (points_to_move contains each.location) {
			moveX <- true;
			p_destination <- moving_to[location];
			the_speed <- distance_to(location,p_destination)#m/(myself.the_scenario.get_next_date() - current_date)#s;
			points_to_move >- location;
		}
		
		write "the nb of points to create: "+length(points_to_move);
		write "Basic X_points "+length(X_point);
		
		loop i over:points_to_move{
			create X_point {
				moveX <- true;
				location <- i;
				p_destination <- moving_to[i];
				the_speed <- distance_to(location,p_destination)#m/(myself.the_scenario.get_next_date() - current_date)#s;
				myself.the_points <+ self;
			}
		}
		
		write "New X_points "+length(X_point);
		
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

