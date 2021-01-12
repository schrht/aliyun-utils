#!/bin/bash

# Description:
#   This script summarize the test results for avocodo-cloud.
#

function collect_results() {
	fdir=$1
	fres=$fdir/results.json
	flog=$fdir/job.log

	res_p=$(cat $fres | jq -r '.pass')
	res_c=$(cat $fres | jq -r '.cancel')
	res_e=$(cat $fres | jq -r '.error')
	res_f=$(cat $fres | jq -r '.failures')
	res_s=$(cat $fres | jq -r '.skip')
	logid=$(cat $fres | jq -r '.debuglog' | sed 's#.*\(job-20.*\)/job.log#\1#')

        table="${table}$(printf '%s,%s,%s,%s,%s,%s' $logid $res_p $res_f $res_e $res_c $res_s)\n"
}

# Parse parameters
if [ -z $1 ]; then
	echo "Usage: $(basename $0) <dirs>" >&2
	echo "Notes:" >&2
 	echo "- dirs: avocado-cloud log dirs starts with 'job-'." >&2
	exit 1
fi

dlist="$@"

# Collect results for each avocado-cloud run
for d in $dlist; do
	collect_results $d
done

# Show the summary as a table
echo -e $table | column -t -s ',' -R 2,3,4,5,6 -N LogID,PASS,FAIL,ERROR,CANCEL,SKIP

exit 0

