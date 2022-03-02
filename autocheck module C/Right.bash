#!/bin/bash
{
export ping_test=$( ping -c 2 192.168.200.254 )
if [[ "$ping_test" == *"ttl="* ]] ; then ping_test=True ; else ping_test=False ; fi ;

export pat_test=$( ping -c 2 8.8.8.8 )
if [[ "$pat_test" == *"ttl="* ]] ; then pat_test=True ; else pat_test=False ; fi ;

export connect_test=$( ping -c 2 192.168.100.10 )
if [[ "$connect_test" == *"ttl="* ]] ; then connect_test=True ; else connect_test=False ; fi ;


} &> /dev/null
echo '{"ping_test": "'$ping_test'","pat_test": "'$pat_test'","connect_test": "'$connect_test'"}' | jq .

