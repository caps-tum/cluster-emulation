#include "mpi.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

int main(int argc, char *argv[]) {
	int rank, size;
	// these are handles
	MPI_Session session = MPI_SESSION_NULL;
	MPI_Comm communicator = MPI_COMM_NULL;

	int rc, flag;
	int ret = 0;
	const char pset_name[] = "mpi://WORLD";
	const char mt_key[] = "thread_level";
	const char mt_value[] = "MPI_THREAD_MULTIPLE";
	char out_value[100];        /* large enough */

	MPI_Group wgroup = MPI_GROUP_NULL;
	MPI_Info sinfo = MPI_INFO_NULL;
	MPI_Info tinfo = MPI_INFO_NULL;
	MPI_Info_create(&sinfo);
	MPI_Info_set(sinfo, mt_key, mt_value);
	rc = MPI_Session_init(sinfo, MPI_ERRORS_RETURN, &session);
	if (rc != MPI_SUCCESS) {
		goto fn_exit;
	}

	// check we got thread support level foo library needs 
	rc = MPI_Session_get_info(session, &tinfo);
	if (rc != MPI_SUCCESS) {
		goto fn_exit;
	}

	MPI_Info_get(tinfo, mt_key, sizeof(out_value), out_value, &flag);
	if (!flag) {
		printf("Could not find key %s\n", mt_key);
		goto fn_exit;
	}
	if (strcmp(out_value, mt_value)) {
		printf("Did not get thread multiple support, got %s\n", out_value);
		goto fn_exit;
	}

	// check how many psets are available 
	int pset_total;
	rc = MPI_Session_get_num_psets(session, MPI_INFO_NULL, &pset_total);
	if (rc != MPI_SUCCESS) {
		printf("Error trying to get num_psets\n");
		goto fn_exit;
	}
	printf("total psets available: %d\n", pset_total);

	// print each pset and its size
	int  pset_len = MPI_MAX_PSET_NAME_LEN;
	char pset_nth_name[MPI_MAX_PSET_NAME_LEN] = "";
	MPI_Info info;
	char pset_nth_size[MPI_MAX_PSET_NAME_LEN] = "";
	int info_flag;
	int total_infos;
	int pset_index;
	for(pset_index = 0; pset_index < pset_total; pset_index++){
		rc = MPI_Session_get_nth_pset(session, MPI_INFO_NULL, pset_index, &pset_len, pset_nth_name);
		if (rc != MPI_SUCCESS) { printf("Error trying to get pset name and len\n"); goto fn_exit; }
		printf("pset name: %s; len: %d\n", pset_nth_name, pset_len);

		rc = MPI_Session_get_pset_info(session, pset_nth_name, &info);
		if (rc != MPI_SUCCESS) { printf("Error trying to get pset info from %s\n", pset_nth_name); goto fn_exit; }

		rc = MPI_Info_get_nkeys(info, &total_infos);
		if (rc != MPI_SUCCESS) { printf("Error trying to get pset info nkeys from %s\n", pset_nth_name); goto fn_exit; }
		printf("total_infos: %d\n", total_infos);

		rc = MPI_Info_get(info, "mpi_size", 16, pset_nth_size, &info_flag);
		if (rc != MPI_SUCCESS) { printf("Error trying to get \'mpi_size\' from %s\n", pset_nth_name); goto fn_exit; }
		printf("pset name: %s; mpi_size: %s; defined: %s\n", pset_nth_name, pset_nth_size, info_flag?"true":"false");
	}

	// create a group from the WORLD process set 
	rc = MPI_Group_from_session_pset(session, pset_name, &wgroup);
	if (rc != MPI_SUCCESS) {
		goto fn_exit;
	}

	// get a communicator 
	rc = MPI_Comm_create_from_group(wgroup, "world",
			MPI_INFO_NULL, MPI_ERRORS_RETURN, &communicator);
	if (rc != MPI_SUCCESS) {
		goto fn_exit;
	}

	// free group, library doesn’t need it. 
fn_exit:
	MPI_Group_free(&wgroup);
	if (sinfo != MPI_INFO_NULL) {
		MPI_Info_free(&sinfo);
	}
	if (tinfo != MPI_INFO_NULL) {
		MPI_Info_free(&tinfo);
	}
	if (ret != MPI_SUCCESS) {
		MPI_Session_finalize(&session);
	}

	MPI_Comm_size(communicator, &size);
	MPI_Comm_rank(communicator, &rank);

	printf("rank: %d; size: %d\n", rank, size);

	int sum;
	MPI_Reduce(&rank, &sum, 1, MPI_INT, MPI_SUM, 0, communicator);
	if (rank == 0) {
		if (sum != (size - 1) * size / 2) {
			printf("MPI_Reduce: expect %d, got %d\n", (size - 1) * size / 2, sum);
		} else {
			printf("Passed initialization check\n");
		}
	}

	rc = MPI_Comm_free(&communicator);
	if (rc != MPI_SUCCESS) {
		printf("MPI_Comm_free returned %d\n", rc);
		return -1;
	}

	rc = MPI_Session_finalize(&session);
	if (rc != MPI_SUCCESS) {
		printf("MPI_Session_finalize returned %d\n", rc);
		return -1;
	}

	return 0;
}
