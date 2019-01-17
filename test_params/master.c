#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>
#include <errno.h>

#define N 10

int childpids[N];

int get_next_available_index() {
	int i, kill_ret;
	for (i=0;i<N;i++) {
		if (childpids[i]==-1) return i;
		kill_ret = kill(childpids[i],0);
		//printf("proccess id: %d kill signal returned: %d ? %d\n",childpids[i],kill_ret,ESRCH);
		if (kill_ret<0) {
			if(errno==ESRCH)
				return i; /* proc does not exist */
			else {
			   continue;
			}
		}
		else {
			//printf("proc with id %d exists\n",childpids[i]);
			continue; /* proc exists */		
		}
	}
	usleep(1000*500);
	return -1;
}

void main() {
	clock_t start, end;
    double cpu_time_used;
    char file_name[50],c1[10],c2[10],c3[10],c4[10];
    double vals[4] = {0.01, 0.001, 15, 0.5};
    double intervals[4] = {0.02, 0.002, 2, 0.2 };
    double max_vals[4] = {0.1 , 0.015 , 25 , 1.5 };
    double i , j , k , l , p=0;
    int x,pid;
    for(x=0;x<N;x++) childpids[x]=-1;
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
						if (execlp("/home/cky800/git/simulating_annealing/test_params/params","params",c1,c2,c3,c4,NULL) < 0)
							perror("execlpXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n");
						/* Never returns */
						return;
					}
					x++;
				}
			}
		}
	}
	return;
}
