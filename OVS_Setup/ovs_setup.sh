#!/bin/bash

sudo apt-get -yq update;
sudo apt-get -yq install openvswitch-switch python-tinyrpc;
sudo systemctl enable openvswitch-switch;
sudo systemctl start openvswitch-switch;
