#!/bin/bash

QUEUES=(atmpd all)
MAX_JOBS=200
QUOTA_MAX=0.95
JOB_MANAGER_DIR=/home/cvilela/jobManager/
SENDMAIL_PATH=/usr/sbin/sendmail
MY_EMAIL_ADDRESS="cristovao.vilela@stonybrook.edu" # Quotation marks necessary!
THIS_HOST=`hostname`

# First, make sure quota space is not at risk, otherwise this script will go haywire
${JOB_MANAGER_DIR}checkQuota.sh ${QUOTA_MAX}
QUOTA_IS_OVER_LIMIT=$?

# If quota is over limit and job submission is not paused, pause it and send email to me.
if [ ${QUOTA_IS_OVER_LIMIT} ]
then
    if [ ! -f ${JOB_MANAGER_DIR}pause ]
    then
	touch ${JOB_MANAGER_DIR}pause
	printf "Subject: [JobManager] Quota is over limit\n\nJob submission on ${THIS_HOST} is now paused as disk usage exceeded the ${QUOTA_MAX} fractinal limit.\nDelete file ${JOB_MANAGER_DIR}pause to resume.\n" | ${SENDMAIL_PATH} ${MY_EMAIL_ADDRESS}
    fi
fi

# If job submission is paused exit here
if [ -f ${JOB_MANAGER_DIR}pause ]
then
    exit
fi

# Get snapshot of queue
/usr/local/bin/qstat -a > ${JOB_MANAGER_DIR}queueSnapshot

for QUEUE in ${QUEUES[*]}
do
    FILE=${JOB_MANAGER_DIR}${QUEUE}.list
    if [ -f $FILE ]
    then
	# FIGURE OUT HOW MANY JOBS WANT TO SUBMIT
	NTEMPSTART=`cat ${JOB_MANAGER_DIR}queueSnapshot  | grep -n ${QUEUE} | awk -F':' '{print $1}'`
	tail -n +${NTEMPSTART} ${JOB_MANAGER_DIR}queueSnapshot  > ${JOB_MANAGER_DIR}${QUEUE}Snapshot
	NTEMP=`cat ${JOB_MANAGER_DIR}${QUEUE}Snapshot  | grep -n @   | tail -n +2 | head -n 1 | awk -F':' '{print $1}'`
	N_RUNNING=`head ${JOB_MANAGER_DIR}${QUEUE}Snapshot -n $NTEMP | grep cvilela | wc -l`
	rm ${JOB_MANAGER_DIR}${QUEUE}Snapshot
	
	N_SUBMIT=$(($MAX_JOBS-$N_RUNNING))

	echo $QUEUE $N_RUNNING $N_SUBMIT
	
	for ((i=0; i<N_SUBMIT; i++))
	do
	    # Read line from file
	    LINE=$(head -n 1 $FILE)
	    
	    # SUBMIT JOBS
	    /usr/local/bin/qsub -q $QUEUE $LINE

	    # Remove line from file
	    sed -i -e "1d" $FILE
	done
    fi
done
rm ${JOB_MANAGER_DIR}queueSnapshot
