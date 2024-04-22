These are Standard Workload Format (SWF) obtained from the https://www.cs.huji.ac.il/labs/parallel/workload/logs.html in their original form.

# wget http://www.cs.huji.ac.il/labs/parallel/workload/l_kit_fh2/KIT-FH2-2016-1.swf.gz
# wget http://www.cs.huji.ac.il/labs/parallel/workload/l_ciemat_euler/CIEMAT-Euler-2008-1.swf.gz

Each line of the history represents a single job.  There are several columns (refer to https://www.cs.huji.ac.il/labs/parallel/workload/swf.html ).

For simulations, only arrival times and allocation parameters are necessary.  How these are handled, depends on the algorithm and machine model.  The output of the simulation are the quality metrics (e.g. node utilization).

These fields can be extracted and stored in binary format to be used as simulation input:
1. Submit Time (Column 2): 
2. Requested Number of Processors (Column 8):
3. Requested Time (Column 9):
4. Requested Memory (Column 10):

Future extensions could consider additional inputs:
a. Executable Number (Column 14):
b. Queue Number (Column 15):
c. Partition Number (Column 16):

Other columns (fields) are actually outputs based on how the system and algorithm processed the jobs.  This makes the parameters unnecessary as input.  These can be tracked per job, or as aggregated system quality metrics, which are the actual outputs of the simulator.

Inputs are better generated in our case, since there is no malleable system history available up to this day. We need to implement a generator, that produces one line inputs with 1.-4. (see above) for jobs, based on configurable models that are based on the real SWF data observerd.
