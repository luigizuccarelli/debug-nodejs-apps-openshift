#!/bin/bash

if [ $# -gt 0 ] && [ "$1" == "debug" ]
then
  node --debug fh-supercore.js config/conf.json --master-only
  # ensure port 9000 is set in the dc template 
  # also that you have set rw permissions in your src dir
  # DEBUG=node-inspector:protocol:* node-inspector
  node node_modules/node-inspector/bin/inspector.js -p 9000 --save-live-edit=true &
else
  node --debug fh-supercore.js config/conf.json --master-only
fi
