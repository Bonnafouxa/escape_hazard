/**
* Name: continuemodelalea
* Author: eisti
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model continuemodelalea

global {

	file building_shapefile <- shape_file("../../includes/building.shp");
	geometry shape <- envelope(building_shapefile);
	point base <- any_location_in(shape);
	float epsilon <- 1#cm;
	float delta;
	
	init {
		create building from:building_shapefile;
		create alea with:[location::base];
		ask alea{
			do init_moving_alea;
			write length(shape.points);
			float average;
			loop i from:1 to:length(shape.points)-1{
				write i;
				average <- average + distance_to(shape.points[i],shape.points[i-1]);
			}
			delta <- average/length(shape.points);
		}
		
	}
	

	
}

species obstacle {
	//height of obstacle
	float height;
	
}

species building parent:obstacle{
	
	/* 
	action create_B_point(list<point> points_in){
		loop i over:points_in{
			create B_point with:[location::i];
		}
		
	}
	* 
	*/
	
		
 	aspect default {
 		draw shape color: #black depth:height;
	}
}

species X_point skills:[moving] {
	
	alea hazard; //with english prononciation
	float the_speed <- 10#km/#h;
	float the_duration <- 1#h;
	point p_destination;
	bool moveX <- false;
	
	aspect default {
		draw geometry:circle(5#dm) color:moveX ? #black : #green;
	}
	

	
	reflex move_to_next_location when: moveX{
		p_destination <- (location - hazard.location) +location;
		do goto target:p_destination speed:the_speed;
	}
	
	reflex stop_moving when: 
		location.x < 0 or location.y < 0 or
		location.x > world.shape.width or location.y > world.shape.height {
		moveX <- false;
	}
}

species B_point {
	building attached;
	bool flooded <-false;
	
	aspect default {
		draw geometry:circle(5#dm) color:flooded ? #red : #green;
	}
}

species alea {
	list<X_point> points_to_extend;
	
	map<building,list<B_point>> map_obstacle;
	
	init {
		 shape <- circle(10#m);
	}
	
	action init_moving_alea{
		loop i over:shape.points {
			create X_point with:[location::i,moveX::true,hazard::self]{
			myself.points_to_extend <+ self;
			}
		}
	}
	
	reflex move_to {
		shape <- geometry(points_to_extend collect each.location);
	}
	
	reflex detection_obstacle {
		list<building> close_building <- building where !(map_obstacle.keys contains each) at_distance epsilon;
		
		ask close_building {
			list<B_point> B_points <- [];
			list<point> shape_points <- remove_duplicates(shape.points);  //shape.points duplicate first point ??????????????
			loop i over: shape_points {
				create B_point with:[location::i,attached::self]{
					B_points <+ self;
				}
			}
			myself.map_obstacle[self] <- B_points;
		}
	}
	
	/*
	 * 
	 */
	reflex flooded_activation {
		ask B_point where !(each.flooded) {
			if(self overlaps myself){
				flooded <- true;
			}
		}
	}
	
	reflex create_X_point {
		loop i from:1 to:length(points_to_extend)-1{
			point light <- points_to_extend[i].location;
			point light2 <- points_to_extend[i-1].location;
			if (distance_to(light,light2)>delta){
				create X_point with:[location::(light+light2)/2, moveX::true,hazard::self]{
					myself.points_to_extend[i] +<- self;
				}
			}
		}
	} 
	
	/*
	 * 	reflex touch_my_big_building {
		list<point> points_in;
		ask building {
			points_in <- shape.points where(myself overlaps (each));
			loop i over:points_in{
				if(myself.map_obstacle[self]=nil){
					create B_point with:[location::i];
					myself.map_obstacle <+ self::[last(B_point)];
				} else {
					//write "look there";
					//write myself.map_obstacle[self] where (each.location=i);
					if((myself.map_obstacle[self] where (each.location=i))=nil){
						create B_point with:[location::i];
						myself.map_obstacle[self] <+ last(B_point);
					} else {
						
					}
				}
				
				
			}
		}
		write map_obstacle;
	}
	 */
	

	
	aspect default {
		draw shape color:#blue;
	}
	
}


experiment main type:gui {
	float minimum_cycle_duration <- 0.5; 
	output{
		display map type:opengl {
			species alea aspect:default refresh:true;
			species building aspect:default refresh:false transparency:0.5;
			species X_point aspect:default ;
			species B_point aspect:default;
		}
	}	
}

