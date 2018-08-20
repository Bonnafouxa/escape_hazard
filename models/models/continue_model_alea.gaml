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
	
	init {
		create building from:building_shapefile;
		create alea with:[location::base];
		
		do init_moving_alea(alea[0]);
	}
	
	action init_moving_alea(alea alea_from){
		write(alea_from.shape);
		loop i over:alea_from.shape.points {
			write i;
				create X_point with:[location::i,p_destination::(i - alea_from.location)+i,moveX::true]{
			}
		}
	}
	
}

species building {
	//Height of the buildings
 	float height <- 3.0 + rnd(5);
 	aspect default {
 		draw shape color: #black depth:height;
}
}

species X_point skills:[moving] {
	
	float the_speed <- 10#km/#h;
	float the_duration <- 1#h;
	point p_destination;
	bool moveX <- false;
	
	aspect default {
		draw geometry:circle(5#dm) color:moveX ? #black : #green;
	}
	
	
	reflex move_to_next_location when: moveX{
		the_speed <- distance_to(self,self.p_destination)#km/the_duration;
		do goto target:p_destination speed:the_speed;
	}
}


species alea {
	
	list<X_point> point_to_extend;
	
	geometry shape <- circle(10#m);
	aspect default {
		draw shape color:#blue;
	}
}


experiment main type:gui {
	float minimum_cycle_duration <- 0.1; 
	output{
		display map type:opengl {
			species alea aspect:default refresh:true;
			species building aspect:default refresh:false;
			species X_point aspect:default ;
		}
	}	
}

/* Insert your model definition here */

