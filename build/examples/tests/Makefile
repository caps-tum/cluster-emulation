CC=mpicc
CFLAGS=-Wall -g -O0

PROGS=init_finalize sinit_finalize mpi_sleeper session_mall pmi_test check_monitoring

all: $(PROGS)

init_finalize: init_finalize.c
	$(CC) init_finalize.c $(CFLAGS) -o init_finalize

sinit_finalize: sinit_finalize.c
	$(CC) sinit_finalize.c $(CFLAGS) -o sinit_finalize

mpi_sleeper: mpi_sleeper.c
	$(CC) mpi_sleeper.c $(CFLAGS) -o mpi_sleeper

session_mall: session_mall.c
	$(CC) session_mall.c $(CFLAGS) -o session_mall

check_monitoring: check_monitoring.c
	$(CC) check_monitoring.c $(CFLAGS) -o check_monitoring

pmi_test: pmi_test.c
	$(CC) pmi_test.c $(CFLAGS) -o pmi_test \
		-I${LIBDYNPM_ROOT}/include -L${LIBDYNPM_ROOT}/lib -ldynpmcommon -ldynpmshm \
		-I${PMIX_ROOT}/include -L${PMIX_ROOT}/lib -lpmix 

install: all
	mv -f $(PROGS) ../bin/

clean:
	$(RM) $(PROGS) *.o output-* hostfile-*
