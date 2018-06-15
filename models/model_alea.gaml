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

	point base <- any_location_in(shape);

	list<building> obstacles <- (building at_distance 0.001#m); //liste des obstacle du buildings
	
	float gravity_force <- 0.001;

	//couleur de l'aléa
	rgb color <- °red ;

	// Taille de base de l'aléa
	float taille_base <- 2.5;

	init{
		create building from:building_shapefile ;
		create alea number:1 with:[location::base];
		create G_point number:1 with:[location::base];
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
	float self_gravity_force; //force of the gravity center
	bool natural;
	float maximal_speed; //Maximal speed of the Alea
	float zone_influence; //Zone d'influence d'un gravity center
	list<point> influenced_points ;
	
	init {
		self_gravity_force <- gravity_force;
		maximal_speed <- 10#m;
		natural <- true;
		zone_influence <- 50#m;
		
		loop i over:alea{
			influenced_points <<+ i.shape.points where (each distance_to self < zone_influence);
		}
				
	}
	
	
	//Pour chaque centre de gravités : faire grandir les points sous influence.
	//Trigger: tout les points 
	
	/*
	 * Action that apply action force
	 */
	list<point> action_force {
		list<point> uninfluenced_points;
		list<point> new_points;
		point new_p;
		loop p over:influenced_points{
			new_p <- (p - location) * gravity_force + p;
			if(new_p distance_to self > zone_influence){
				uninfluenced_points <+ new_p;
			} else {
				new_points <+ new_p;
			}
		}
		influenced_points <- new_points;
		return uninfluenced_points;
	}
	
	/*
	 * Die when no more influenced points
	 * 
	 */
	reflex death when:empty(influenced_points){
		do die;
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
		
		ask G_point {
			do action_force returns:u_points; 
			new_points <<+ influenced_points;
	
			add all: u_points to: myself.uninfluenced_points;
			//myself.uninfluenced_points <<+ list<point>(self.action_force);
			
			// remove all: new_points from: myself.uninfluenced_points;
			//myself.uninfluenced_points >>- influenced_points;
			
		}
		
		/*
		//For each point, extend.
		loop i over:point_alea {
			
			//gravity_center <- G_point where (each distance_to i < each.zone_influence);
			
			//gestion des obstacles TODO: nouveau réflexe
			obstacles <- building where (each distance_to i <0.001#m);
			building closest <-building closest_to (i);
			if(distance_to(closest,i)<0.01){
				write(distance_to(closest,i));
				//remove item:(point_alea index_of i) from:point_alea;	
			}
			
		}
		* 
		*/
		
		shape <- geometry(new_points);

		
		//augmentation de l'aléa
	}
	
	reflex add_gravity_point when:not empty(uninfluenced_points){
		loop p over:uninfluenced_points{
			create G_point number:1 with:[location::point((closest_to(G_point, p) - p) * coef_distance_new_Gpoint)];
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

