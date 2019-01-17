#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>
#include <errno.h>

#define N 10

int childpids[N] = {0};

int get_next_available_index() {
	int i, kill_ret;
	for (i=0;i<N;i++) {
		kill_ret = kill(childpids[i],0);
		printf("proccess id: %d kill signal returned: %d ? %d\n",childpids[i],kill_ret,ESRCH);
		if (kill_ret<0)
			if(errno==ESRCH)
				return i; /* proc does not exist */
			else {
			   printf("ERROR");
			   return -1;
			}
		else continue; /* proc exists */
	}
	return -1;
}

void main() {
	clock_t start, end;
    double cpu_time_used;
    char file_name[50];
    double vals[4] = {0.01, 0.001, 15, 0.5};
    double intervals[4] = {0.02, 0.002, 2, 0.2 };
    double max_vals[4] = {0.1 , 0.015 , 25 , 1.5 };
    double i , j , k , l , p=0;
    int x,available_pid;
    read_net_from_file();
    for (i=vals[0];i<max_vals[0];i+=intervals[0]) {
		for(j=vals[1];j<max_vals[1];j+=intervals[1]) {
			for(k=vals[2];k<max_vals[2];k+=intervals[2]) {
				for(l=vals[3];l<max_vals[3];l+=intervals[3]) {
					while((available_pid=get_next_available_index())==-1) ;
					if ((childpids[available_pid] = vfork()) < 0) {
						perror("fork ERROR\n"); 
						exit(-1);
					} else if (childpids[i] > 0) {  /* Parent. */
						
					} else {  /* Child. */
						c[0] = i ;
						c[1] = j ;
						c[2] = k ;
						c[3] = l ;
						if (execlp("/home/cky800/git/simulating_annealing/params","params",i,j,k,l,NULL) < 0)
							perror("execlpXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n");
						/* Never returns */
					}
				}
			}
		}
	}
	return;
}
