#!/bin/sh

sleep 10 # give time for docker to start

DNS_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}')

iptables-legacy --insert DOCKER-USER --destination 10.0.0.0/8 --jump REJECT
iptables-legacy --insert DOCKER-USER --destination "$DNS_IP" --jump ACCEPT
