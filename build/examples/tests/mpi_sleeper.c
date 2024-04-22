/*
 * MPI_Init / MPI_Finalize application template - Sleeper
 *
 * -- 
 */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include "mpi.h"

int main(int argc, char* argv[]) {
    int sleep_time = 0;
    int mcw_rank, mcw_size, len;
    char hname[MPI_MAX_PROCESSOR_NAME];

    if( 1 < argc ) {
        sleep_time = atoi(argv[1]);
    }
    
    printf("starting the process; about to call MPI init...\n"); fflush(0);
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &mcw_rank);
    MPI_Comm_size(MPI_COMM_WORLD,&mcw_size);
    MPI_Get_processor_name(hname, &len);

    MPI_Barrier(MPI_COMM_WORLD);

    printf("%2d/%2d) Sleeping for %d sec on %s\n", mcw_rank, mcw_size, sleep_time, hname);
    sleep(sleep_time);

    MPI_Finalize();


    return 0;
}
