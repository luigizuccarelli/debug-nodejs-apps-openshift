### Debug node apps in openshift

**Assumptions**
 
 * Working in the vagrant ose32 env
 * Openshift up and running


**Configuration**


A. fh-supercore (I will use this as the reference throughout) 

B. All commands will be executed in the vagrant vm

 1. Navigate to the directory and execute ```bash npm install --production```
 2. Execute ```bash npm ls```
 3. Finally execute ```bash npm install node-inspector```
 4. Make a copy of the current Dockerfile and call it Dockerfile-dev
 5. Update the Dockefile-dev 
    5.a Ensure USER root is set and that you have rw for all directories where the source code is mounted
    5.b Add the following to the end of the Dockerfile-dev
    
    ```
    ADD root /
    ENTRYPOINT ["container-entrypoint"]
    CMD ["run.sh"] 
    ```

 6. Create the directories 

    ```
    mkdir -p root/usr/bin
    cd /root/usr/bin
    
    ```

 7. Create a file container-entrypoint and insert the following
    ```
    #!/bin/bash
    exec "$@" 
    
    ```

 8. Create a file called run.sh and insert the following (I tried including the node-inspector server startup but couldn't get it work)

    ```
    #!/bin/bash

    if [ $# -gt 0 ] && [ "$1" == "debug" ]
    then
      # ensure port 9000 is set in the dc template 
      node --debug node --debg fh-supercore.js config/conf.json --master-only
    else
      node fh-supercore.js config/conf.json --master-only    
    fi
     
    ```
 9. Change permissions on both files (chmod 755)

 10. Execute grunt fh:dist

 11. Copy the dist/fh-supercore-*.tar.gz file to docker/

 12. Navigat to the docker folder ``` cd docker/ ``` and execute ``` docker build -f Dockerfile-dev -t fh-supercore:lmz-dev . ```

 13. Update the fh-supercore template
     
     a. Add the port 9000 and protocol TCP to supercore service

     b. Add the port and protocol TCP to the supercore depolymentconfig

     c. Add the following to spec.container

     d. Update the current image to point to the newly created image (e.g. fh-supercore:lmz-dev)

     
   ```json
     
    "command" : [
      "run.sh",
      "debug"
    ]

   ```
 14. Deploy the template (you can make use of the scripts backend.sh or front-end.sh etc)

 15. Once deployed 'oc rsh fh-supercore-xxx bash'

 16. Execute 

   ```
   node node_modules/node-inspector/bin/inspector.js -p 9000 --save-live-edit &

   ```

 17. Create a route for the debugger and save it (I used debug-route.json) 
 
   ```
   apiVersion: v1
   kind: Route
   metadata:
    creationTimestamp: 2016-09-20T11:32:07Z
    labels:
     name: fh-supercore
    name: fh-supercore
    namespace: core
    resourceVersion: "74437"
    selfLink: /oapi/v1/namespaces/core/routes/fh-supercore
    uid: dc895f20-7f25-11e6-87a2-08002798a04f
  spec:
    host: local.feedhenry.io
    port:
      targetPort: debugport
    to:
      kind: Service
      name: fh-supercore
  status:
    ingress:
    - conditions:
      - lastTransitionTime: 2016-09-20T11:32:07Z
        status: "True"
        type: Admitted
      host: local.feedhenry.io
      routerName: router

   ```



18 Create the route oc create -f debug.json

20 Navigate to the using the route or http://local.feedhenry.io (this will take a while - it loads all the scripts !!!)

21 You can set breakpoints and debug using the chrome interface. You can also edit and save changes - primitive but it works 

22 The exercise to create a PVC and PV and mount the source dir to your existing git repo work dir is left for you to do

Screen shots 


![chrome debugger] (./images/chrome-debugger.png)


![oc logs of supecore] (./images/console-log.png)

