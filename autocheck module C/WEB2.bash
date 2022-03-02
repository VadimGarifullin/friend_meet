#!/bin/bash
{
export docker_install=$( docker -v )
if [[ "$docker_install" == *"build"* ]] ; then docker_install=True ; else docker_install=False ; fi ;

export docker_app=$( docker ps | grep 5000 )
if [[ "$docker_app" == *"Up"* ]] ; then docker_app=True ; else docker_app=False ; fi ;

export docker_link=$( docker inspect $(docker ps -q) | grep ya )
if [[ "$docker_link" == *"yandex"* ]] ; then docker_link=True ; else docker_link=False ; fi ;

export ntp_status=$( chronyc sources )
if [[ "$ntp_status" == *"^* 200"* ]] ; then ntp_status=True ; else ntp_status=False ; fi ;

} &> /dev/null
echo '{"docker_install": "'$docker_install'","docker_app": "'$docker_app'","docker_link": "'$docker_link'","ntp_status": "'$ntp_status'"}' | jq .

