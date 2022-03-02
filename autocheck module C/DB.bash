#!/bin/bash
{
export database_p=$( docker ps --filter expose=5432 )
export database_m=$( docker ps --filter expose=3006 )
if [[ "$database_m" == *"Up"* ]] | [[ "$database_p" == *"Up"* ]] ; then database=True ; else database=False ; fi ;
export ntp_status=$( chronyc sources )
if [[ "$ntp_status" == *"^* 200"* ]] ; then ntp_status=True ; else ntp_status=False ; fi ;
} &> /dev/null
echo '{"database": "'$database'","ntp_status": "'$ntp_status'"}' | jq .

