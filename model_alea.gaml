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


	//couleur de l'aléa
	rgb color <- °red ;
	
	
	

// Taille de base de l'aléa
float taille_base <- 2.5;

species building {
	
	//Height of the buildings
	float height <- 3.0 + rnd(5);
	aspect default {
		draw shape color: #gray depth: height;
	}
	
}

species G_point {
	float gravity_force; //force of the gravity center
	bool natural;
	float maximal_speed; //Maximal speed of the Alea
	float zone_influence; //Zone d'influence d'un gravity center
	list<point> influenced_point ;
	
	init {
		gravity_force <-0.001;
		maximal_speed <- 10#m;
		natural <- true;
		zone_influence <- 50#m;
		influenced_point <- alea.shape.points where (each distance_to G_point < zone_influence);
	}
	
	
	//Pour chaque centre de gravités : faire grandir les points sous influence.
	//Trigger: tout les points 
	
	
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
	
	//Calcul des centres de gravités pour chaque points
	//avance selon un vecteur.  
	//Création des centres de gravité auxiliaire pour les obstacles
	reflex alea_grow {
		list<point> point_alea <- shape.points;
		point calcul_distance;
		list<G_point> gravity_center;
		//For each point, extend.
		loop i over:point_alea {
			
			gravity_center <- G_point where (each distance_to i < each.zone_influence);
					
			
			if(gravity_center !=  []){
				put growing(gravity_center,i) in:point_alea at:point_alea index_of i;
			} else {
				//TODO calculer la distance minimale pour un centre de gravité (sinon problèmes avec la vitesse).
				//calcul_distance <- {gravity_force,gravity_force};
				create G_point number:1 with:[location::{i.location.x-1,i.location.y-1}] ;
			}
			
			//gestion des obstacles TODO: nouveau réflexe
			obstacles <- building where (each distance_to i <0.001#m);
			building closest <-building closest_to (i);
			if(distance_to(closest,i)<0.01){
				write(distance_to(closest,i));
				//remove item:(point_alea index_of i) from:point_alea;	
			}
			
		}
		shape <- geometry(point_alea);
		
		//augmentation de l'aléa
	}
	
	//Chaque centre de gravité influence l'avancée du point en question
	point growing (list<G_point> gravity_center, point point_to_move){
		point destination <- point_to_move;
		loop i over: gravity_center{
			//Calcul vectoriel du point d'arrivée en fonction de chaque centre de gravité
			
			
			//destination <- (point_to_move-i.location)*i.gravity_force + destination;  //growing move f(x):ax +b
			
			//LINEAR MOVE
			point test <-(point_to_move-i.location)*i.gravity_force - point_to_move;
			
			//TODO extend but with the maximal speed 

			destination <- test+point_to_move+destination; 
		}
		
		return (destination);
	}
	
	
	
	
	aspect default {
		draw shape color:color;
	}
}


init{
	create building from:building_shapefile ;
	create alea number:1 with:[location::base];
	create G_point number:1 with:[location::base];
	
}
}




experiment main type:gui {
	output{
		display map type:opengl {
			species building refresh:false aspect:default;
			species alea aspect:default refresh:true ;
			species G_point aspect:default 		;}
	}
	
	
}

