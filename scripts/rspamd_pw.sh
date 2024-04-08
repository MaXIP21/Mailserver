#!/bin/bash

echo -n Enter Web Interface Password:
read -r -s password
echo
# Run Command
hash="$(docker container run registry.gitlab.com/container-email/rspamd:latest rspamadm pw -e -p "$password")"

echo "Add to persistant file override.d/worker-controller.inc :-

password: \"$hash\";
enable_password: \"$hash\";"
