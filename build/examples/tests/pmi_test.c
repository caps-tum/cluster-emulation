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

#include <dynpm_shm.h>
#include <pmix.h>

#include "mpi.h"

static pmix_proc_t local_process;

int main(int argc, char* argv[]) {
    int sleep_time = 0;
    int mcw_rank, mcw_size, len;
    char hname[MPI_MAX_PROCESSOR_NAME];
	char *job_id;
	char *step_id;
	int job_index, application_index;

	job_id = getenv("SLURM_JOB_ID");
	step_id = getenv("SLURM_STEP_ID");

	if(job_id) {
		printf("SLURM_JOB_ID  : %s\n", job_id);
		job_index = atoi(job_id);
	} else printf("job_id not found\n");

	if(step_id) {
		printf("SLURM_STEP_ID : %s\n", step_id);
		application_index = atoi(step_id);
	} else printf("step_id not found\n");

	dynpm_init_logger("pmi.out", "pmi.err");

	void *read_buffer = malloc(sizeof(char)*4096); // single page size
	int read_bytes;
	int shm_code = dynpm_shm_process_attach(job_index, application_index, 1, 1);
	if(shm_code){
		fprintf(stderr, "could not open shm: %d\n", shm_code);
		printf("error: %s\n", strerror(errno));
		return -1;
	}

	printf("trying to read from shm\n");
	shm_code = dynpm_shm_process_read(&read_buffer, &read_bytes);
	if(shm_code){
		printf("could not read from shm!\n");
	} else if(read_bytes > 0) {
		printf("read: %s (%d bytes)\n", (char*)read_buffer, read_bytes);
	} else {
		printf("no bytes available\n");
	}

	printf("repeated read from shm\n");
	shm_code = dynpm_shm_process_read(&read_buffer, &read_bytes);
	if(shm_code){
		printf("could not read from shm!\n");
	} else if(read_bytes > 0) {
		printf("read: %s (%d bytes)\n", (char*)read_buffer, read_bytes);
	} else {
		printf("no bytes available\n");
	}

	uint32_t mode = DYNPM_ACTIVE_FLAG|DYNPM_OFFERLISTENER_FLAG|DYNPM_SLURMFORMAT_FLAG;
	if(dynpm_shm_process_set_malleability_mode(mode)){
		printf("error while trying to set mall. mode\n");
	} else {
		printf("set mall. mode to: %x\n", mode);
	}

	int pmix_code;
	if (PMIX_SUCCESS != (pmix_code = PMIx_Init(&local_process, NULL, 0))) {
		fprintf(stderr, "Client ns %s rank %d: PMIx_Init failed: %s\n", local_process.nspace, local_process.rank,
				PMIx_Error_string(pmix_code));
	}
	fprintf(stderr, "pmix ns %s rank %d\n", local_process.nspace, local_process.rank);

    if( 1 < argc ) {
        sleep_time = atoi(argv[1]);
    }

    printf("start\n");
    int count = 0;
    while( count < 20) {
        printf("still sleeping (%d)...\n", count);
        sleep(1);
        count++;
    }
    printf("end\n");

	shm_code = dynpm_shm_process_detach();
	if(shm_code){
		fprintf(stderr, "could not detach shm: %d\n", shm_code);
		printf("error: %s\n", strerror(errno));
		return -1;
	}
	printf("detached\n");
    return 0;

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
