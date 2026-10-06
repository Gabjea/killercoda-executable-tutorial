#!/bin/bash
clear
echo "Preparing your environment (about 1-2 minutes)..."
while [ ! -f /tmp/.setup-done ] && [ ! -f /tmp/.setup-failed ]; do sleep 2; echo -n "."; done
echo
if [ -f /tmp/.setup-failed ]; then
  echo "Setup failed. Details: /var/log/workshop-setup.log"
else
  cd /root/workshop
  clear
  echo "Environment ready. Your workspace is /root/workshop"
fi