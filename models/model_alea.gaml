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
			create need_for_shape from:scenar1 ;
			create need_for_shape from:scenar2 ;
			create need_for_shape from:scenar3 ;
			create need_for_shape from:scenar4 ;
			ask alea{
			do init_moving_points(need_for_shape[1]);
			do init_moving_alea;
			}
	}
}

species need_for_shape {
	aspect default {
		draw shape color:color;
	}
}


species X_point skills:[moving] {
	
	float the_speed <- 10#km/#h;
	float the_duration <- 1#h;
	point p_destination <- {0,0};
	bool moveX <- false;
	
	aspect default {
		draw geometry:circle(10#m) color:moveX ? #black : #green;
	}
	
	
	reflex move_to_next_location when: moveX {
		the_speed <- distance_to(self,self.p_destination)#km/the_duration;
		do goto target:p_destination speed:the_speed;
	}
	
}


species alea skills: [moving] {
	
	map<date,geometry> scenario;
	
	list<point> points_to_move;
	list<point> points_to_go;
	map<point,point> moving_to;
	point point_to_move;
	point point_to_go;
	rgb color;
	int scenario_number <- 0;
	
	list<X_point> the_points;
	list<X_point> the_list;
	
	init{
		points_to_move <- shape.points;
		scenario <+ date([2018,8,15,10,0,0])::envelope(scenar1);
		scenario <+ date([2018,8,15,11,0,0])::envelope(scenar2);
		scenario <+ date([2018,8,15,12,0,0])::envelope(scenar3);
	}
	
	action init_moving_alea{
		loop i over:shape.points {
			if(points_to_move contains i){
				create X_point with:[location::i,p_destination::moving_to[i],moveX::true]{
					myself.the_points <+ self;
				}
			} else {
				create X_point with:[location::i]{
					myself.the_points <+ self;
				}
			}
		}
	}
	
	action init_moving_points(need_for_shape move_to) {
		
		points_to_move >>- move_to.shape.points;
		points_to_go <- move_to.shape.points;
		points_to_go >>- shape.points;
		
		if (length(points_to_move)>= length(points_to_go)){
			loop i over:points_to_go {
				moving_to[closest_to(points_to_move,i)]<-i;
			}
			
		} else {
			loop i over:points_to_move {
				moving_to[i]<-closest_to(points_to_go,i);
			}
			
			list<point> point_to_go_without_from <- points_to_go;
			point_to_go_without_from >>- moving_to.keys;
			write length(point_to_go_without_from);
			
			loop i over: point_to_go_without_from {
				point new_point_to_move <- closest_points_with(i,shape)[1];
				moving_to[new_point_to_move] <- i;
				points_to_move <+ new_point_to_move;
			}
			write length(points_to_move);
		}

		write length(moving_to);
	}
	
	
	reflex update_X_point when: length(X_point where (distance_to(each.p_destination,each.location)<5#m))=length(points_to_move){
		write "slt";
		scenario_number <- scenario_number +1;
		ask X_point {
			do die;
		}
			do init_moving_points(need_for_shape[scenario_number+1]);
			do init_moving_alea;
	}

	reflex move_to {
		shape <- geometry(the_points collect each.location);
		write length(X_point where (distance_to(each.p_destination,each.location)<5#m));
	}
	
	aspect default {
		draw shape color:color;
	}
	
}
	
	






experiment main type:gui {
	float minimum_cycle_duration <- 0.1; 
	output{
		display map type:opengl {
			species alea aspect:default refresh:true transparency:0.6;
			species X_point aspect:default refresh:true;
			species need_for_shape aspect:default refresh:true transparency:0.5;
			}
	}	
}

