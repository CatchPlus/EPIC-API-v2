#!/bin/bash
###
### This script is developed by GWDG. Licensed under the Apache License, Version 2.0 (see http://www.apache.org/licenses/LICENSE-2.0)
###
### Tibor [dot] Kalman [at] gwdg [dot] de
###

### A very simple script for testing the EPIC API v2
### $Id$


TIMESTAMP=$(date +"%Y%m%d%H%M%S") 
PIDSERVICE_URL="http://dariah-vm07.gwdg.de:8444/handles/11022"
PIDSERVICE_USER="tkalman1"
PIDSERVICE_PASSWD="PaSsWoRd"


### creating a PID for the URL "http://www.gwdg.de/TEST/test123"
echo "Creating a test PID:"
curl -q -s -S --dump-header log_PUT_${TIMESTAMP} --output response_PUT_${TIMESTAMP} --digest -u "${PIDSERVICE_USER}:${PIDSERVICE_PASSWD}" -H "Accept:application/json" -H "Content-Type:application/json" -X PUT --data '[{"type":"URL","parsed_data":"http://www.gwdg.de/TEST/test123"}]' ${PIDSERVICE_URL}/test_${TIMESTAMP}

echo "-----"
echo -n "CREATE rc: "
grep 'HTTP/1.1 201 Created' log_PUT_${TIMESTAMP}
grep "Location: ${PIDSERVICE_URL}/test_${TIMESTAMP}" log_PUT_${TIMESTAMP}


### checking whether the new PID contains the URL "http://www.gwdg.de/TEST/test123"
echo "-----"
echo "Checking whether the PID really exists:"
curl -q -s -S --dump-header log_GET_${TIMESTAMP} --output response_GET_${TIMESTAMP} --digest -u "${PIDSERVICE_USER}:${PIDSERVICE_PASSWD}" -H "Accept:application/json" ${PIDSERVICE_URL}/test_${TIMESTAMP}

echo -n "GET rc: "
grep 'HTTP/1.1 200 OK' log_GET_${TIMESTAMP}
### a not so stylish JSON parser:
cat response_GET_${TIMESTAMP} | grep parsed_data | grep "http://www.gwdg.de/TEST/test123"

echo "-----"
echo "Debug info:  cat response_PUT_${TIMESTAMP} log_PUT_${TIMESTAMP} response_GET_${TIMESTAMP} log_GET_${TIMESTAMP}"
echo "Cleanup logs with:  rm response_PUT_${TIMESTAMP} log_PUT_${TIMESTAMP} response_GET_${TIMESTAMP} log_GET_${TIMESTAMP}"
echo "-----"

###DB cleanup:
###DELETE FROM `handle11022`.`handles` WHERE `handles`.`handle` LIKE '%11022/TEST_2012%'
