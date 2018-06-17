#!/bin/bash
set -e

vagrant destroy -f || :
vagrant plugin install vagrant-vbguest
trap 'vagrant destroy -f' SIGINT ERR
vagrant up
vagrant ssh -c "bash /vagrant/build.sh"
vagrant destroy -f
echo "build done!"
