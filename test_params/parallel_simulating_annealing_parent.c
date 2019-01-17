#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>
#include <errno.h>

#define N 10

int main( int argc, char **argv ) {
	clock_t start, end;
    double cpu_time_used;
    char c1[10],c2[10],c3[10],c4[10],path_to_child_cmd[256];
    double vals[4] = {0.01, 0.001, 15, 0.5};
    double intervals[4] = {0.02, 0.002, 2, 0.2 };
    double max_vals[4] = {0.1 , 0.015 , 25 , 1.5 };
    double i , j , k , l , p=0;
    int x,pid;
    
    if(argc!=2) {
		printf("run %s <realpath_of_child_exec>\n",argv[0]);
		return -1;
	} else {
		sprintf(path_to_child_cmd,"%s",argv[1]);
	}
    x=1;
    for (i=vals[0];i<max_vals[0];i+=intervals[0]) {
		for(j=vals[1];j<max_vals[1];j+=intervals[1]) {
			for(k=vals[2];k<max_vals[2];k+=intervals[2]) {
				for(l=vals[3];l<max_vals[3];l+=intervals[3]) {
					if (x%10==0)usleep(1000*90000);
					if ((pid = vfork()) < 0) {
						perror("fork ERROR\n"); 
						exit(-1);
					} else if (pid > 0) {  /* Parent. */
						
					} else {  /* Child. */
						printf("child executing params %lf %lf %lf %lf\n",i,j,k,l);
						sprintf(c1,"%.5lf",i);
						sprintf(c2,"%.5lf",j);
						sprintf(c3,"%.5lf",k);
						sprintf(c4,"%.5lf",l);
						if (execlp(path_to_child_cmd,path_to_child_cmd,c1,c2,c3,c4,NULL) < 0)
							perror("execlpXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n");
						/* Never returns */
						return 1;
					}
					x++;
				}
			}
		}
	}
	return 1;
}
