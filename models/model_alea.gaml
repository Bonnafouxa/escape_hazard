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
	
	geometry moving_shape;
	list<point> starting_points;


	init{
			
			
			
			create alea from:scenar1 with:[scenario_number::1, color::#brown];
			create alea from:scenar2 with:[color::#red, scenario_number::2];
			create alea from:scenar3 with:[color::#blue, scenario_number::3];
			create alea from:scenar4 with:[color::#white, scenario_number::4];
			loop i from:0 to:2 {
				do init_moving_points(alea[i], alea[i+1]);
				do init_moving_alea(alea[i]);
				do create_destination(alea[i]);
			}	

			starting_points <- alea[3].shape.points;
			
			

	}
	
	action init_moving_points(alea move_from, alea move_to) {
		
		move_from.points_to_move >>- move_to.shape.points;
		move_from.points_to_go <- move_to.shape.points;
		move_from.points_to_go >>- move_from.shape.points ;
		
		if (length(move_from.points_to_move)>= length(move_from.points_to_go)){
		
			loop i over:move_from.points_to_go {
				move_from.moving_to[closest_to(move_from.points_to_move,i)]<-i;
			}
			
		} else {
			
			loop i over:move_from.points_to_move {
				move_from.moving_to[i]<-closest_to(move_from.points_to_go,i);
			}
			
			list<point> point_to_go_without_from <- move_from.points_to_go;
			point_to_go_without_from >>- move_from.moving_to.keys;
			loop i over: point_to_go_without_from {
				point new_point_to_move <- closest_points_with(i,move_from.shape)[1];
				move_from.moving_to[new_point_to_move] <- i;
				move_from.points_to_move <+ new_point_to_move;
			}
			
		}
	}
	
	action create_destination(alea alea_from){
		loop i over:alea_from.moving_to {
			create destination_finale with:[location::i];
		}
	}
	
	action init_moving_alea(alea alea_from){
		loop i over:alea_from.shape.points {
			if(alea_from.points_to_move contains i){
				create X_point with:[location::i,p_destination::alea_from.moving_to[i],moveX::true]{
					alea_from.the_points <+ self;
				}
			} else {
				create X_point with:[location::i]{
					alea_from.the_points <+ self;
				}
			}
		}
	}
}

species X_point skills:[moving] {
	
	float the_speed <- 10#km/#h;
	point p_destination;
	bool moveX <- false;
	bool alea_moving <- false;
	
	aspect default {
		draw geometry:circle(10#m) color:moveX ? #black : #green;
	}
	
	
	reflex move_to_next_location when: moveX and alea_moving {
		do goto target:p_destination speed:the_speed;
	}
	
}


species alea skills: [moving] {
	list<point> points_to_move;
	list<point> points_to_go;
	map<point,point> moving_to;
	point point_to_move;
	point point_to_go;
	rgb color;
	int scenario_number;
	bool moved <- false;
	
	list<X_point> the_points;
	list<X_point> the_list;
	
	init{
		points_to_move <- shape.points;
	}

	reflex move_to {
		shape <- geometry(the_points collect each.location);
	}
	
	reflex first_good_timing when:scenario_number=1{
		bool acc <-true;
		the_list<- the_points where (each.moveX);
		if(scenario_number = 1){
			loop i over:the_list {			
				if(distance_to(i.location,i.p_destination) > 10#m){
					acc <- false;	
				}
				i.alea_moving <-true;
			}
			moved <- acc;
		}
	}
	
	reflex good_timing when:scenario_number != 1 and alea[(scenario_number-2)].moved {
		bool acc <-true;
		the_list<- the_points where (each.moveX);
		loop i over:the_list {
			if(distance_to(i.location,i.p_destination) > 10#m){
				acc <- false;
			}
			i.alea_moving <-true;
		}
		moved <- acc;
	}
	
	
	reflex bad_timing when:scenario_number != 1 and !(alea[(scenario_number-2)].moved){
		loop i over:the_points {
				i.alea_moving <- false;
		}
	}

	aspect default {
		draw shape color:color;
	}
	
}
	
species destination_finale skills:[moving] {
	
	aspect default {
		draw geometry:circle(10#m) color:#red;
	}
}








experiment main type:gui {
	float minimum_cycle_duration <- 0.1; 
	output{
		display map type:opengl {
			species alea aspect:default refresh:true transparency:0.6;
			species X_point aspect:default refresh:true;
			//species destination_finale aspect:default refresh:true;
			}
	}	
}

