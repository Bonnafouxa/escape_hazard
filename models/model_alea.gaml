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

	file building_shapefile <- file("../includes/building.shp");

	geometry shape <- envelope(building_shapefile);
	
	list<building> obstacles <- (building at_distance 0.001#m); //liste des obstacles du buildings
	
	float gravity_force <- 0.001;
	float zone_influence <- 20#m;

	//couleur de l'aléa
	rgb color <- °red ;

	// Taille de base de l'aléa
	float taille_base <- 2.5;

	init{
		create building from:building_shapefile ;
		create alea with:[location::any_location_in(shape)];
		ask alea { create G_point with:[location::location]; }
	}
}


species building {
	
	//Height of the buildings
	float height <- 3.0 + rnd(5);
	aspect default {
		draw shape color: #gray depth: height;
	}
	
}

species G_point {
	float self_gravity_force <- gravity_force; //force of the gravity center
	bool natural <- true;
	float maximal_speed <- 10#m; //Maximal speed of the Alea
	float self_zone_influence <- zone_influence; //Zone d'influence d'un gravity center
	list<point> influenced_points;
	list<point> building_points;
	
	init {
		loop i over:alea{
			influenced_points <<+ i.shape.points where (each distance_to self < self_zone_influence);
	
		}
		//write "Gravity center "+self+" has been created with "+length(influenced_points)+" point to influence";			
	}
	
	/*
	 * Die when no more influenced points
	 * 
	 */
	reflex death when:empty(influenced_points){
		do die;
	}
	
	
	/*
	 * Action that apply action force
	 */
	reflex action_force {
		
		ask building {
				myself.building_points <- myself.influenced_points where (each distance_to self < 1#m); // ne s'actualise pas ? quand ils touchent le building
			}
			
		influenced_points <- influenced_points collect (point(each + (each - self.location) * self_gravity_force));
			
	}
	
	reflex building_event when: not empty(building_points){
		//Quand ils touchent le building séparer en deux points ayant un mouvement opposé le long du building
		/*
		 * find the closest building
		 * define the closest point
		 * create a new point next to this one and make them move along the building #hard 
	 	*/
	 	loop while: not empty(building_points){
	 		building closest_building <- building closest_to self;
	// 		point closest_point <- building.shape.points with_min_of(each distance_to self);
	 	}		
	}
	
	aspect default {
		draw circle(1) color: #black;
	}
	

	
	
}


species alea {
	
	// Calculer le nombre de centre qui régissent le point
    // 1) Son centre naturel + Centre d'aléa
	
	//fonction d'évolution de l'aléa
	
	//forme de l'aléa
	geometry shape <- circle(taille_base#m) ;
	
	float coef_distance_new_Gpoint <- 0.01;
	
	list<point> uninfluenced_points;
	
	//Calcul des centres de gravités pour chaque points
	//avance selon un vecteur.  
	//Création des centres de gravité auxiliaire pour les obstacles
	reflex alea_grow {
		/* 
		list<point> point_alea <- shape.points;
		point calcul_distance;
		* 
		*/
		
		list<point> new_points;
		list<point> u_points;
		
		ask G_point {
			
			// Collect the new points to draw the shape with gravity augmentation
			add all: influenced_points to:new_points;
			
			// Collect every point that are out of reach of the gravity center and near to a building
			u_points <- influenced_points where (each distance_to self > self_zone_influence);
			// Remove them 
			remove all: u_points from:influenced_points;
			remove all: building_points from:influenced_points;
			// And add them to the list of point for which we need a new gravity center
			myself.uninfluenced_points <- u_points;
			
			
		}
		

		
		shape <- geometry(new_points);

	}
	
	reflex add_gravity_point when:not empty(uninfluenced_points){
		//write "Create "+length(uninfluenced_points)+" new gravity point";
		geometry gravity_buffer <- self.shape - buffer(location, zone_influence / 1);
		loop while:not empty(uninfluenced_points){
			create G_point with:[location::any_location_in(gravity_buffer)] returns:g_point;
			remove all:g_point[0].influenced_points from:uninfluenced_points; //Il faut aussi les enlever aux autres G_points
		}
	}
	

	
	
	aspect default {
		draw shape color:color;
	}
}



experiment main type:gui {
	parameter gravity_force var:gravity_force;
	output{
		display map type:opengl {
			species building refresh:false aspect:default;
			species alea aspect:default refresh:true ;
			species G_point aspect:default 		;}
	}	
}

