#!/usr/bin/env bash

#
# DANCE
#

while true; do
    figlet -f slant "media" | lolcat
    kubecolor get po -n media; sleep 5; clear;
    figlet -f slant "home" | lolcat
    kubecolor get po -n home; sleep 5; clear;
    figlet -f slant "nodes" | lolcat
    kubecolor get nodes; sleep 5; clear;
done
