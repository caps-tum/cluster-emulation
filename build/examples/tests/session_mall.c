#include "mpi.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int rank, size, new_size;
    MPI_Session session = MPI_SESSION_NULL;
    MPI_Session new_session = MPI_SESSION_NULL;
    MPI_Comm communicator = MPI_COMM_NULL;

    int rc, flag, test_sum;
    int current_step = 0;
    int algorithm_steps = 600; // approx. 10 minutes
    /* MPI standard */
    const char pset_name[] = "mpi://WORLD";
    const char mt_support_key[] = "thread_level";
    const char mt_support_val[] = "MPI_THREAD_MULTIPLE";
    /* experimental malleability keys and values */
    const char mpix_dp_mode_key[]           = "mpix_dp_mode";
    const char mpix_dp_mode_passive[]       = "MPI_DP_PASSIVE";        // follow mall. commands
    const char mpix_dp_mode_active[]        = "MPI_DP_ACTIVE";         // request mall. commands
    const char mpix_dp_local_init_key[]     = "dynamic_processes_status";
    const char mpix_dp_local_init_new[]     = "MPI_DP_STATUS_NEW";     // just launched
    const char mpix_dp_local_init_joining[] = "MPI_DP_STATUS_JOINING"; // added to the set
    const char mpix_dp_local_init_staying[] = "MPI_DP_STATUS_STAYING"; // continue in the set
    const char mpix_dp_local_init_leaving[] = "MPI_DP_STATUS_LEAVING"; // removed from the set
    char mt_value[100];
    char mpix_dp_local_value[100];

    MPI_Group wgroup = MPI_GROUP_NULL;
    MPI_Info init_info = MPI_INFO_NULL;
    MPI_Info session_info = MPI_INFO_NULL;
    MPI_Info_create(&init_info);
    MPI_Info_set(init_info, mt_support_key, mt_support_val);
    MPI_Info_set(init_info, mpix_dp_mode_key, mpix_dp_mode_passive);
    rc = MPI_Session_init(init_info, MPI_ERRORS_RETURN, &session);
    if (rc != MPI_SUCCESS) { return -1; }

    rc = MPI_Session_get_info(session, &session_info);
    if (rc != MPI_SUCCESS) { return -1; }

    // check how many psets are available
    int pset_total;
    rc = MPI_Session_get_num_psets(session, MPI_INFO_NULL, &pset_total);
    if (rc != MPI_SUCCESS) { printf("Error trying to get num_psets\n"); return -1; }
    printf("total psets available: %d\n", pset_total);

    // print each pset and its size
    int  pset_len = MPI_MAX_PSET_NAME_LEN;
    char pset_nth_name[MPI_MAX_PSET_NAME_LEN] = "";
    MPI_Info pset_info;
    char pset_nth_size[MPI_MAX_PSET_NAME_LEN] = "";
    int info_flag;
    int total_infos;
    int pset_index;
    for(pset_index = 0; pset_index < pset_total; pset_index++){
        rc = MPI_Session_get_nth_pset(session, MPI_INFO_NULL, pset_index, &pset_len, pset_nth_name);
        if (rc != MPI_SUCCESS) { printf("Error trying to get pset name and len\n"); return -1; }
        printf("pset name: %s; len: %d\n", pset_nth_name, pset_len);

        rc = MPI_Session_get_pset_info(session, pset_nth_name, &pset_info);
        if (rc != MPI_SUCCESS) { printf("Error trying to get pset info from %s\n", pset_nth_name); return -1; }

        rc = MPI_Info_get_nkeys(pset_info, &total_infos);
        if (rc != MPI_SUCCESS) { printf("Error trying to get pset info nkeys from %s\n", pset_nth_name); return -1; }
        printf("total keys: %d\n", total_infos);

        rc = MPI_Info_get(pset_info, "mpi_size", 16, pset_nth_size, &info_flag);
        if (rc != MPI_SUCCESS) { printf("Error trying to get \'mpi_size\' from %s\n", pset_nth_name); return -1; }
        printf("pset name: %s; mpi_size: %s; info_flag: %s\n", pset_nth_name, pset_nth_size, info_flag?"true":"false");
    }

    // create a group from the WORLD process set
    // NOTE: joining processes will first block here
    rc = MPI_Group_from_session_pset(session, pset_name, &wgroup);
    if (rc != MPI_SUCCESS) { return -1; }

    // get a communicator
    rc = MPI_Comm_create_from_group(wgroup, "world",
            MPI_INFO_NULL, MPI_ERRORS_RETURN, &communicator);
    if (rc != MPI_SUCCESS) { return -1; }

    MPI_Comm_size(communicator, &size);
    MPI_Comm_rank(communicator, &rank);
    printf("rank: %d; size: %d\n", rank, size);

    // check we got thread support level requested
    MPI_Info_get(session_info, mt_support_key, sizeof(mt_value), mt_value, &flag);
    if (!flag) { printf("Could not find key %s\n", mt_support_key); return -1; }
    if (strcmp(mt_value, mt_support_val)) {
        printf("Did not get thread multiple support, got %s\n", mt_value); return -1; }

    // check the local status of this process within the session
    MPI_Info_get(session_info, mpix_dp_local_init_key, sizeof(mpix_dp_local_value), mpix_dp_local_value, &flag);
    if (!flag) { printf("Could not find key %s\n", mpix_dp_local_init_key); return -1; }
    if (!strcmp(mpix_dp_local_value, mpix_dp_local_init_new)) {
        // the process has been created with the launcher (e.g. batch script body)
        printf("process created by launcher; mpix_dp_local_value: %s\n", mpix_dp_local_value); return -1;
        printf("proceeding to perform progress normally...\n");
    } else if (!strcmp(mpix_dp_local_value, mpix_dp_local_init_joining)){
        // the process was created by the system to join an existing set
        // need to get the current step value (from root in this case) to join the computation
        MPI_Bcast(&current_step, 1, MPI_INT, 0, communicator);
    } else {
        // this should never occur
        printf("error: a newly created process needs to hold status new or joining\n");
        printf("error: new process created with status: %s\n", mpix_dp_local_value);
    }

    while (current_step != algorithm_steps ){
        // check for dynamic processes changes on each step
        rc = MPI_Session_init(init_info, MPI_ERRORS_RETURN, &new_session);
        if (rc != MPI_SUCCESS) { return -1; }

        rc = MPI_Session_get_pset_info(new_session, "mpi://world", &pset_info);
        if (rc != MPI_SUCCESS) { printf("Error trying to get pset info from world pset\n"); return -1; }

        rc = MPI_Info_get(pset_info, "mpi_size", 16, pset_nth_size, &info_flag);
        if (rc != MPI_SUCCESS) { printf("Error trying to get \'mpi_size\' from new world pset\n"); return -1; }
        printf("new mpi_size: %s; info_flag: %s\n", pset_nth_size, info_flag?"true":"false");
        sscanf(pset_nth_size, "%d", &new_size);
        if(size == new_size){
            // there were no changes; nothing to do
            printf("no resource changes at step %d out of %d\n", current_step, algorithm_steps);
            new_session = MPI_SESSION_NULL;
        } else {
            rc = MPI_Session_get_info(new_session, &session_info);
            if (rc != MPI_SUCCESS) { return -1; }

            // check the local status of this process within the session
            MPI_Info_get(session_info, mpix_dp_local_init_key, sizeof(mpix_dp_local_value), mpix_dp_local_value, &flag);
            if (!flag) { printf("Could not find key %s\n", mpix_dp_local_init_key); return -1; }
            if (!strcmp(mpix_dp_local_value, mpix_dp_local_init_staying)) {
                // the process exists in the new session, and should remain in the computation
                printf("process created by launcher; mpix_dp_local_value: %s\n", mpix_dp_local_value); return -1;
                printf("proceeding to perform progress normally...\n");

                // clean up any data structures generated from the current session
                MPI_Group_free(&wgroup);
                rc = MPI_Comm_free(&communicator);
                if (rc != MPI_SUCCESS) { printf("MPI_Comm_free returned %d\n", rc); return -1; }
                rc = MPI_Session_finalize(&session);
                if (rc != MPI_SUCCESS) { printf("MPI_Session_finalize returned %d\n", rc); return -1; }
                session = new_session;

                // generate new communicator from the new session
                // NOTE: joining processes will be waiting for staying processes here, in case of expansion
                rc = MPI_Group_from_session_pset(session, pset_name, &wgroup);
                if (rc != MPI_SUCCESS) { return -1; }
                rc = MPI_Comm_create_from_group(wgroup, "world", MPI_INFO_NULL, MPI_ERRORS_RETURN, &communicator);
                if (rc != MPI_SUCCESS) { return -1; }

                MPI_Comm_size(communicator, &size);
                MPI_Comm_rank(communicator, &rank);
                printf("rank: %d; size: %d\n", rank, size);

                MPI_Bcast(&current_step, 1, MPI_INT, 0, communicator);
            } else if (!strcmp(mpix_dp_local_value, mpix_dp_local_init_leaving)){
                // the process does not exist in the new session, and should exit
                // this process can exit inmediately, since all staying processes (including root)
                // hord the correct current_step to broadcast towards any joining processes
                // TODO add a check for a singleton session here
                goto fn_exit;
            } else {
                // this should never occur
                printf("error: an existing process needs to hold status staying or leaving\n");
                printf("error: existing process received status: %s\n", mpix_dp_local_value);
            }
        }

        // TODO add more MPI checks here
        MPI_Reduce(&rank, &test_sum, 1, MPI_INT, MPI_SUM, 0, communicator);
        if (rank == 0) {
            if (test_sum != (size - 1) * size / 2) {
                printf("MPI_Reduce: expect %d, got %d\n", (size - 1) * size / 2, test_sum);
            } else {
                printf("succesful algorithm step %d out of %d\n", current_step, algorithm_steps);
            }
        }
        sleep(1);
        current_step++;
    }

fn_exit:
    MPI_Group_free(&wgroup);
    if (init_info != MPI_INFO_NULL) { MPI_Info_free(&init_info); }
    if (session_info != MPI_INFO_NULL) { MPI_Info_free(&session_info); }

    rc = MPI_Comm_free(&communicator);
    if (rc != MPI_SUCCESS) { printf("MPI_Comm_free returned %d\n", rc); return -1; }

    rc = MPI_Session_finalize(&session);
    if (rc != MPI_SUCCESS) { printf("MPI_Session_finalize returned %d\n", rc); return -1; }

    return 0;
}
