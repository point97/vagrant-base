#!/bin/bash

BOX="p97-base-v0.4"

# to build box:
vagrant destroy
vagrant up
vagrant halt
rm ${BOX}.box
vagrant package --output ${BOX}.box

# to install locally:
# vagrant box add ${BOX} ${BOX}.box
