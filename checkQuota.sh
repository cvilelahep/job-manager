#!/bin/bash

FRAC_LIMIT=0.95

if [ $# -eq 1 ]
  then
    FRAC_LIMIT=$1
fi

QUOTA_MAX=`quota 2> /dev/null | sed -n 4p | awk '{print $2}'`
QUOTA_USED=`quota 2> /dev/null | sed -n 4p | awk '{print $1}'`

#echo max $QUOTA_MAX used $QUOTA_USED limit $FRAC_LIMIT

FRAC_USED=`echo "${QUOTA_USED} / ${QUOTA_MAX}" | bc -l`

#echo $FRAC_USED

IS_OVER_LIMIT=`echo "${FRAC_USED} > ${FRAC_LIMIT}" | bc -l`

exit $IS_OVER_LIMIT
