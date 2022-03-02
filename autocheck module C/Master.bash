#!/bin/bash
{
export http_access=$( curl -L --insecure http://site.unakbars.ru )
if [[ "$http_access" == *"username"* ]] ; then http_access=True ; else http_access=False ; fi ;

export http_redirection=$( curl -I -L --insecure http://site.unakbars.ru )
if [[ "$http_redirection" == *"Moved"* ]] ; then http_redirection=True ; else http_redirection=False ; fi ;

export https_access=$( curl -L --insecure https://site.unakbars.ru )
if [[ "$https_access" == *"username"* ]] ; then https_access=True ; else https_access=False ; fi ;
export loadbalance_1=$( curl -L --insecure http://site.unakbars.ru/db/add?message=hello | gawk '{print $8}' )
export loadbalance_2=$( curl -L --insecure http://site.unakbars.ru/db/add?message=hello | gawk '{print $8}' )
export loadbalance_3=$( curl -L --insecure http://site.unakbars.ru/db/add?message=hello | gawk '{print $8}' )
if [[ "$loadbalance_1" != "$loadbalance_2" ]]; then loadbalance=True ; else loadbalance=False ; fi ;


export lrtr_dns=$( sshpass -p cisco ssh -o 'StrictHostKeyChecking no' cisco@L-RTR.unakbars.ru 'sh run | s ip name' )
if [[ "$lrtr_dns" == *"200.100.100.254"* ]] ; then lrtr_dns=True ; else lrtr_dns=False ; fi ;

export rrtr_dns=$( sshpass -p cisco ssh -o 'StrictHostKeyChecking no' cisco@R-RTR.unakbars.ru 'sh run | s ip name' )
if [[ "$rrtr_dns" == *"200.100.100.254"* ]] ; then rrtr_dns=True ; else rrtr_dns=False ; fi ;

export rtun=$( sshpass -p cisco ssh -o 'StrictHostKeyChecking no' cisco@R-RTR.unakbars.ru 'sh run int tun1' )
if [[ "$rtun" == *"100.100.100.2"* ]] ; then r_gre=True ; else r_gre=False ; fi ;

export gre_ping=$( sshpass -p cisco ssh -o 'StrictHostKeyChecking no' cisco@L-RTR.unakbars.ru 'ping 100.100.100.2 timeout 5' )
if [[ "$gre_ping" == *"!"* ]] ; then gre_ping=True ; else gre_ping=False ; fi ;

export ipsec=$( sshpass -p cisco ssh -o 'StrictHostKeyChecking no' cisco@L-RTR.unakbars.ru 'sh crypto ipsec sa detail | s Status' )
if [[ "$ipsec" == *"ACTIVE(ACTIVE)"* ]] ; then ipsec=True ; else ipsec=False ; fi ;

export l_stnat=$( sshpass -p toor ssh -o 'StrictHostKeyChecking no' root@L-RTR.unakbars.ru -p 2222 echo 'Hello' )
if [[ "$l_stnat" == *"Hello"* ]] ; then l_stnat=True ; else l_stnat=False ; fi ;

export r_stnat=$( sshpass -p toor ssh -o 'StrictHostKeyChecking no' root@R-RTR.unakbars.ru -p 2222 echo 'Hello' )
if [[ "$r_stnat" == *"Hello"* ]] ; then r_stnat=True ; else r_stnat=False ; fi ;

export l_ntp=$( sshpass -p cisco ssh -o 'StrictHostKeyChecking no' cisco@L-RTR.unakbars.ru 'sh ntp status' )
if [[ "$l_ntp" == *"Clock is synchronized"* ]] ; then l_ntp=True ; else l_ntp=False ; fi ;

export r_ntp=$( sshpass -p cisco ssh -o 'StrictHostKeyChecking no' cisco@R-RTR.unakbars.ru 'sh ntp status' )
if [[ "$r_ntp" == *"Clock is synchronized"* ]] ; then r_ntp=True ; else r_ntp=False ; fi ;

} &> /dev/null
echo '{"http_access": "'$http_access'","http_redirection": "'$http_redirection'","https_access": "'$https_access'","loadbalance": "'$loadbalance'","lrtr_dns": "'$lrtr_dns'","rrtr_dns": "'$rrtr_dns'","r_gre": "'$r_gre'","gre_ping": "'$gre_ping'","ipsec": "'$ipsec'","l_stnat": "'$l_stnat'","r_stnat": "'$r_stnat'","l_ntp": "'$l_ntp'","r_ntp": "'$r_ntp'"}' | jq .

