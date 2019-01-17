#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <signal.h>


#define N 136
double c[4] = {0.05, 0.009, 20, 0.7};
double T = 100;
double init_T = 100;
double threshold = 1;
//structs
typedef struct point {
	double x;
	double y;
	int connections_amount;
	int *connections;
}Point;

typedef struct edge {
	Point *a;
	Point *b;
}Edge;



//declarations
void read_net_from_file ();
void cluster_points_simulating_annealing ();
int prob_calc(double old, double new);
void new_energy_of_points(int index, double *cur_e_info);
void update_new_position (int i);
void recalculate_energy();
double distance_from_circle(int id);
void intial_points_locations();
int on_segment(Point p, Point q, Point r);
int orientation(Point p, Point q, Point r);
int edges_intersect(Point p1, Point q1, Point p2, Point q2);
void write_net_to_file(char* path);
void show_graphics();

//global vars
double e = 2.718281828459045;
double pi = 3.141592653589793;
int debug_intersection = 0, debug_intersection_start = 0, debug_intersection_cond = 0, debug_control_energy_calc = 0;
int debug = 0, debug_delay = 500000;//500 miliseconds
volatile int new_childpid, old_childpid = - 1;
char* dir_location = "/home/cky800/git/simulating_annealing/test_params/nets/";
char* net_file_name = "/home/cky800/git/simulating_annealing/HW2Net.net";
char* output_net_file_name = "/home/cky800/git/simulating_annealing/HW2Net_output.net";
char* log_file = "log_HW2Net.log";
char title[200], before[100], after[100], ch;
int log_is_on = 1;
static int screen_size = 1000;
static int limit = 400;
static double padd = 0.05;
int edges_sum = 0;
char temp_file_name[70], cmd[250];
double results[5];

Point points[N];
int con_mat[N][N] = {0};
int con_mat_map_to_edges[N][N] = {0};
Edge* edges;
int edges_index_interval[N] = {0};
int edges_index_interval_size = 0;
int table_size = 118;


void cluster_points_simulating_annealing () {
	FILE *read_from , *write_to;
	int i,j,childpid,round=0,rand_i;
	double saved_x,saved_y;
	double e_info[5], new_e_info[5];
	// c_1 is responsible for energy reultion from eachother to make sure everyone are not ending up right next to eachother
	// c_2 is responsible to create a circular barior so nodes dont go far away from the midle of the screen
	// c_3 is mesuring the length of all edges and tries to shorten them
	// c_4 is counting the number of edges intersecting with each other
	printf("### Calculating initial energy ###\n");
	recalculate_energy(); 
	for (i=0;i<5;i++) e_info[i]=results[i];
	printf("### initial energy is %lf ###\n\nProgress: ",e_info[0]);
	while ( T > threshold ) {
		round++;
		if(debug) printf("#################################### T = %lf #####################################\n",T);
		for (i=0;i<N;i++) {
			if(debug) printf("|%*s###############NODE: %d #################%*s|\n", table_size/2-20,"",i+1,table_size/2-20,"");
			rand_i = rand()%N;
			saved_x = points[rand_i].x;
			saved_y = points[rand_i].y;
			update_new_position(rand_i);
			recalculate_energy(); 
			//new_energy_of_points(i, e_info);
			for (j=0;j<5;j++) new_e_info[j]=results[j];
			//show_graphics();
			//if (i%5==0)scanf("%c",&ch);
			//~ for (j=0;j<5;j++) printf("new_e_info[%d]=%lf - ",j,new_e_info[j]);
			//~ printf("/n");
			//~ for (j=0;j<5;j++) printf("results[%d]=%lf - ",j,results[j]);
			//~ printf("/n");
			if ( e_info[0] < new_e_info[0]) {
				if (prob_calc(e_info[0] , new_e_info[0])==1) {
					points[rand_i].x = saved_x;
					points[rand_i].y = saved_y;
					if(debug) printf("restoring point movement!\n");
				} else {
					if(debug) printf("SAVING NEW ENERGY! %lf\n",new_e_info[0]);
					for (j=0;j<5;j++) e_info[j]=new_e_info[j];
				}
			} else {
				if(debug) printf("SAVING NEW ENERGY! %lf\n",new_e_info[0]);
				for (j=0;j<5;j++) e_info[j]=new_e_info[j];
			}
			if(debug) {printf("current Energy is: %lf\n",e_info[0]);}
		}
		T = T*0.95;
		//printf("%.2lf - ",T);
		if (debug) show_graphics();
	}
	//printf("\n");
}

void show_graphics() {
	sprintf(temp_file_name,"T-%.0lf_graph_data.net",T);
	write_net_to_file(temp_file_name);
	if(old_childpid!=-1) kill(old_childpid,1);
	if ((new_childpid = vfork()) < 0) {
		perror("fork"); 
		exit(-1);
	} else if (new_childpid > 0) {  /* Parent. */
		//scanf("%c",&ch); 
		usleep(debug_delay);
		old_childpid = new_childpid;
		//if (ch=='s') exit(1);
	} else {  /* Child. */
		if (execlp("/home/cky800/git/simulating_annealing/simulating_annealing.tcl","simulating_annealing.tcl",temp_file_name,NULL) < 0)
			perror("execlpXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		/* Never returns */
	}
}

int prob_calc(double old, double new) {
	double p = 1.0 - pow(e,(old-new)/T);
	double r = (double)rand() * 1/(double)RAND_MAX;
	char big_small, move_happend[10];
	if (r<p) {
		big_small = '>'; 
		sprintf(move_happend,"(X)");
	} else {
		big_small = '<' ; 
		sprintf(move_happend,"(O)");
	}
	sprintf(title,"Probability Table");
	if(debug) printf("|%*s%s%*s|" ,table_size/2-10,"", title ,table_size/2-7,"");
	if(debug) printf("|%.4lf %c %.4lf = random number%s %s", p ,big_small, r , move_happend,"|");
	if (r<p) return 1;
	return 0;
}

void new_energy_of_points(int index, double *cur_e_info) {
	// getting new energy by reducing the node's energy contribution and later on adding its new positioned contribution
	double red_n[4] = {0}, new_n[4] = {0}, n[4] = {0}, updated_n[4] = {0};
	double dx, dy,diff_reduction, energy_without_id_node,old_x , old_y,diff_addition,total_diff;
	int are_intersecting, i, k , j;
	char indicator[20];
	//#reduction of n1
	for (i=0;i<N;i++) {
		if (i == index) {continue;}
		dx = points[i].x-points[index].x;
		dy = points[i].y-points[index].y;
		if (dx == 0 && dy == 0) {dx = 0.0001;}
		red_n[0]+= 1.0/(pow(dx,2)+pow(dy,2));
	}
	//reduction of n2
	red_n[1] = distance_from_circle(index);
	
	//reduction of n4
	for (i=0;i<points[index].connections_amount;i++) {
		//here index and j are 2 node that represent an edge
		//going over all existing edges and counting those that intersect with index-j
		j=points[index].connections[i];
		for (k=0 ; k<edges_sum; k++) {
			if (&points[index]==edges[k].a || &points[index]==edges[k].b || &points[j]==edges[k].a || &points[j]==edges[k].b) {continue;}
			are_intersecting = edges_intersect(*(edges[k].a), *(edges[k].b), points[j], points[index]);
			if (are_intersecting) {
				red_n[3]++;
			}
		}
		//reduction of n3
		red_n[2]+= pow(points[j].x-points[index].x,2) + pow(points[j].y-points[index].y,2);
	}

	diff_reduction = c[1]*red_n[1] + c[2]*red_n[2] + c[3]*red_n[3] + c[0]* red_n[0];
	energy_without_id_node =cur_e_info[0] - diff_reduction;
	//here energy_without_id_node holds the energy without the energy of the node_id
	//now we will add its new locations energy
	if(debug) printf("|%*s|\n", table_size, "");
	if(debug) printf("|%*s###############NODE: %d #################%*s|\n", table_size/2-20,"",index+1,table_size/2-20,"");
	old_x = points[index].x;
	old_y = points[index].y;
	//this function changed points[index] x-y coordinates
	update_new_position(index);
	
	
	//addition of new n1
	for (i=0;i<N;i++) {
		if (i == index) {continue;}
		dx = points[i].x-points[index].x;
		dy = points[i].y-points[index].y;
		if (dx == 0 && dy == 0) {dx = 0.0001;}
		new_n[0]+= 1.0/(pow(dx,2)+pow(dy,2));
	}
	//addition of new n2
	new_n[1] = distance_from_circle(index);
	
	//addition of new n4
	for (i=0;i<points[index].connections_amount;i++) {
		//here index and j are 2 node that represent an edge
		//going over all existing edges and counting those that intersect with index-j
		j=points[index].connections[i];
		for (k=0 ; k<edges_sum; k++) {
			if (&points[index]==edges[k].a || &points[index]==edges[k].b || &points[j]==edges[k].a || &points[j]==edges[k].b) {continue;}
			are_intersecting = edges_intersect(*(edges[k].a), *(edges[k].b), points[j], points[index]);
			if (are_intersecting) {
				new_n[3]++;
			}
		}
		//reduction of n3
		new_n[2]+= pow(points[j].x-points[index].x,2) + pow(points[j].y-points[index].y,2);
	}
	for(k=0;k<4;k++) {results[k+1] = updated_n[k] = n[k]-red_n[k]+new_n[k];}
	diff_addition = c[1]*new_n[1] + c[2]*new_n[2] + c[3]*new_n[3] + c[0]*new_n[0];
	results[0] = cur_e_info[0] - diff_reduction + diff_addition;
	total_diff = results[0]-cur_e_info[0];
	if (total_diff>0) {
		sprintf(indicator,"(X)");
	} else { 
		sprintf(indicator,"(O)");
	}
	//~ if (total_diff==0) {
		//~ printf("total diff is ZERO??? before:%lf diff:%lf after:%lf %lf %lf %lf\n",
		//~ cur_e_info[0] , results[0]-cur_e_info[0] , cur_e_info[0] - diff_reduction + diff_addition ,diff_reduction , diff_addition,results[0]);
		//~ scanf("%c",&ch);
	//~ }
	sprintf(title, "Energy Table");
	if(debug) printf("|%*s%s%*s|\n", table_size/2-7,"", title, table_size/2-7,"");
	if(debug) printf("|%-3s %-15s %-15s %-15s %-15s %-15s %-15s %-15s|\n", "Var", "Before", "New", "reduced(n)", "reduced(n*c)", "added(n)", "added(n*c)", "diff(n*c)");
	for (i=0;i<4;i++) {
		if(debug) printf("|%c%d  %-15.2lf %-15.2lf %-15.2lf %-15.2lf %-15.2lf %-15.2lf %-15.2lf|\n", 'n', i+1, cur_e_info[i+1], updated_n[i], red_n[i], c[i]*red_n[i], new_n[i] ,c[i]*new_n[i], c[i]*(new_n[i]-red_n[i]));
	}
	if(debug) printf("|%-8s %-15s %-15s %-15s %-15s %-30s|\n",       
    "Energy", "before",     "diff_reduction","diff_addition", "after"    ,"total_diff");
	if(debug) printf("|%-8s %-15.2lf %-15.2lf %-15.2lf %-15.2lf %-30.2lf%s|\n", 
	"Energy", cur_e_info[0], diff_reduction ,diff_addition,    results[0], total_diff, indicator);
	if(debug) printf("|%-*d|\n", table_size,0);
}

void update_new_position (int i) {
	int dir_x , dir_y ,j;
	double new_x , new_y ,dx, dy,sum_x=0,sum_y=0;
	char direction[3];
	direction[2] = '\0';
	sprintf(title,"Movement Table");
	double r_x = (((double)rand() * 1/(double)RAND_MAX)-0.5)*2;
	double r_y = (((double)rand() * 1/(double)RAND_MAX)-0.5)*2;
	if(debug) printf(" -- r_x %lf , r_y %lf -- dir_x %d dir_y %d rand_num %lf--\n",r_x,r_y,dir_x,dir_y,(double)rand() * 1/(double)RAND_MAX);
	dx = (r_x/init_T)*T;
	dy = (r_y/init_T)*T;
	new_x = points[i].x+dx;
	new_y = points[i].y+dy;
	if (new_x>1) {new_x =1; dx = 1-points[i].x;}
	if (new_x<0) {new_x = 0;  dx = 0-points[i].x;}
	if (new_y>1) {new_y =1; dy = 1-points[i].y;}
	if (new_y<0) {new_y = 0;  dy = 0-points[i].y;}

	if(debug) printf("|%*s%*s|\n",table_size/2-8, title,table_size/2-8,"");
	if(debug) printf("|%*s|\n", table_size, "-");
	sprintf(before, "( %.5lf , %.5lf )", points[i].x, points[i].y);
	sprintf(after, "( %.5lf , %.5lf )", new_x, new_y);
	if (dir_y>0) {
		direction[0]= 'S';
	} else {
		direction[0]= 'N';
	} 
	if (dir_x<0) {
		direction[1]= 'W';
	} else {
		direction[1]= 'E';
	}
	if(debug) printf("|%-8s %-30s %-30s %-25s|\n" ,"Node#" ,"before" ,"after" ,"direction");
	if(debug) printf("|%-8d %-30s %-30s %-25s|\n" ,i+1, before ,after , direction);
	if(debug) printf("|%*s|\n" , table_size, "-");
	
	points[i].x = new_x;
	points[i].y = new_y;
}

void recalculate_energy() {
	double n[4] = {0};
	int i, j, k, are_intersecting, edge_index;
	for(i=1 ; i<N-1; i++) {
		//getting n2
		n[1]+= distance_from_circle(i-1);
		for (j=i ; j<N ; j++) {
			//getting n1
			n[0]+= 1.0/(pow(points[i-1].x-points[j].x,2)+pow(points[i-1].y-points[j].y,2));
			if (!con_mat[i-1][j]) {continue;}
			//getting n4
			edge_index = con_mat_map_to_edges[i-1][j];
			for (k=edges_index_interval[i-1] ; k<edges_index_interval[i]; k++) {
				if (&points[i-1]==edges[k].a || &points[i-1]==edges[k].b || &points[j]==edges[k].a || &points[j]==edges[k].b) {continue;}
				are_intersecting = edges_intersect(*(edges[k].a), *(edges[k].b), *(edges[edge_index].a), *(edges[edge_index].b));
				if (are_intersecting) {
					n[3]++;
				}
			}
		}
	}
	//getting n3
	for (k=0 ; k<edges_sum; k++) {
		n[2]+= pow(edges[k].a->x-edges[k].b->x,2) + pow(edges[k].a->y-edges[k].b->y,2);
	}
	results[0] = c[0]*n[0]+c[2]*n[2]+c[1]*n[1]+c[3]*n[3];
	for(k=1;k<=4;k++) {results[k] = n[k-1];}
	sprintf(title, "Energy Table");
	if(debug) printf("|%*s%s%*s|\n", table_size/2-7,"", title, table_size/2-7,"");
	if(debug) printf("|%-3s %-15s %-15s|\n", "Var", "Val", "Val*c");
	for (i=0;i<4;i++) {
		if(debug) printf("|%c%d  %-15.2lf %-15.2lf|\n", 'n', i+1, n[i], n[i]*c[i]);
	}
	if(debug) printf("|%-8s %-15s|\n",       
    "Energy", "Total");
	if(debug) printf("|%-8s %-15.2lf|\n", 
	"Energy", results[0]);
	if(debug) printf("|%-*d|\n", table_size,0);
}

double distance_from_circle(int id) {
	double circle_center = 0.5;
	double distance_from_center_of_screen_ratio;
	distance_from_center_of_screen_ratio = sqrt(pow(points[id].x-circle_center,2)+pow(points[id].y-circle_center,2))/circle_center;
	return distance_from_center_of_screen_ratio;
}

// Given three colinear points p, q, r, the function checks if 
// point q lies on line segment 'pr' 
int on_segment(Point p, Point q, Point r) { 
    if (q.x <= (p.x > r.x ? p.x : r.x) && q.x >= (p.x < r.x ? p.x : r.x) && 
        q.y <= (p.y > r.y ? p.y : r.y) && q.y >= (p.y < r.y ? p.y : r.y)) 
       return 1; 
  
    return 0; 
} 

// To find orientation of ordered triplet (p, q, r). 
// The function returns following values 
// 0 --> p, q and r are colinear 
// 1 --> Clockwise 
// 2 --> Counterclockwise 
int orientation(Point p, Point q, Point r) { 
    int val = (q.y - p.y) * (r.x - q.x) - 
              (q.x - p.x) * (r.y - q.y); 
  
    if (val == 0) return 0;  // colinear 
  
    return (val > 0)? 1: 2; // clock or counterclock wise 
} 

int edges_intersect(Point p1, Point q1, Point p2, Point q2) { 
    // Find the four orientations needed for general and 
    // special cases 
    int o1 = orientation(p1, q1, p2); 
    int o2 = orientation(p1, q1, q2); 
    int o3 = orientation(p2, q2, p1); 
    int o4 = orientation(p2, q2, q1); 
  
    // General case 
    if (o1 != o2 && o3 != o4) 
        return 1; 
  
    // Special Cases 
    // p1, q1 and p2 are colinear and p2 lies on segment p1q1 
    if (o1 == 0 && on_segment(p1, p2, q1)) return 1; 
  
    // p1, q1 and q2 are colinear and q2 lies on segment p1q1 
    if (o2 == 0 && on_segment(p1, q2, q1)) return 1; 
  
    // p2, q2 and p1 are colinear and p1 lies on segment p2q2 
    if (o3 == 0 && on_segment(p2, p1, q2)) return 1; 
  
     // p2, q2 and q1 are colinear and q1 lies on segment p2q2 
    if (o4 == 0 && on_segment(p2, q1, q2)) return 1; 
  
    return 0; // Doesn't fall in any of the above cases 
} 

void read_net_from_file () {
	FILE *data;
	int ii, i , j, connections, indexes[N]= {0};
	char str[50];
	for (i=0;i<N;i++){
		points[i].connections_amount=0;
		points[i].connections = NULL;
		points[i].x = 0;
		points[i].y = 0;
	}
	data = fopen(net_file_name,"r");
	if (data == NULL){
       printf("Error! opening file\n");
       // Program exits if the file pointer returns NULL.
       exit(1);
    }
    fscanf(data,"%s %d",str,&i);
    fscanf(data,"%s",str);
    while (fscanf(data,"%d %d",&i,&j)!=EOF) {
		i--;
		j--;
		points[i].connections_amount++;
		points[j].connections_amount++;
		con_mat[i][j] = con_mat[j][i] = 1;
	}
	
	for (i = 0 ; i<N ; i++) {
		connections = points[i].connections_amount;
		points[i].connections = (int *) calloc(connections,sizeof(int));
	}
	
	intial_points_locations();
	
	for (i=0;i<N-1;i++) {
		for (j=i+1;j<N;j++) {
			if (con_mat[i][j]) {
				edges_sum++; //counting the amount of connections in general
				points[i].connections[indexes[i]++] = j;
				points[j].connections[indexes[j]++] = i;
			}
		}
	}
	edges = (Edge*) malloc(sizeof(Edge)*edges_sum);
	ii = 0;
	for (i=0;i<N-1;i++) {
		for (j=i+1;j<N;j++) {
			if (con_mat[i][j]) {
				edges[ii].a = &points[i];
				edges[ii].b = &points[j];
				con_mat_map_to_edges[i][j] = con_mat_map_to_edges[j][i] = ii;
				ii++;
			}
		}
		edges_index_interval[i] = ii;
	}
	edges_index_interval_size=i;
	fclose(data);
}

void intial_points_locations() {
	int i, r = 1;
	double alfa_change, alfa;
	double conv_rad = pi/180;
	alfa_change = 360.0/N;
	for (i = 0 ; i<N ; i++) {
		alfa = i*alfa_change;
		points[i].x = (r*cos(alfa*conv_rad)+r)/2;
		points[i].y = (r*sin(alfa*conv_rad)+r)/2;
	}
}

void write_net_to_file(char* path) {
	FILE *data;
	int i , j;
	char n_name[50];
	data = fopen(path,"w");
	if (data == NULL){
       printf("Error! opening file\n");
       // Program exits if the file pointer returns NULL.
       exit(1);
    }
    fprintf(data,"*Vertices %d\n",N);
    for(i=0;i<N;i++) {
		sprintf(n_name, "\"v%d\"",i+1);
		fprintf(data,"%4d %7s%-45s%-10.4lf%-9.4lf 0.5000\n",i+1,n_name," ",points[i].x,points[i].y);
	}
	
	fprintf(data,"*Edges\n");
	
	for (i=0;i<N-1;i++) {
		for (j=i+1;j<N;j++) {
			if (con_mat[i][j]) {
				fprintf(data,"%4d %-4d\n",j+1,i+1);
			}
		}
	}
	fclose(data);
	return;
}

void main( int argc, char **argv ) {
	clock_t start, end;
    double cpu_time_used;
    char file_name[100];
	double d;

	sscanf(argv[1], "%lf", &c[0]);
	sscanf(argv[2], "%lf", &c[1]);
	sscanf(argv[3], "%lf", &c[2]);
	sscanf(argv[4], "%lf", &c[3]);
	
	printf("Starting with c1 = %lf c2 = %lf c3 = %lf c4 = %lf\n",c[0],c[1],c[2],c[3]);
	srand(time(NULL));   // Initialization, should only be called once.
	start = clock();
	read_net_from_file();
	cluster_points_simulating_annealing();
	sprintf(file_name,"%sc1-%.3lf-c2-%.3lf-c3-%.3lf-c4-%.3lf",dir_location, c[0],c[1],c[2],c[3]);
	write_net_to_file(file_name);
	end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
	printf("DONE, time took: %d minutes and %d seconds\n",(int)cpu_time_used/60, (int)(cpu_time_used)%60);
	return;
}
