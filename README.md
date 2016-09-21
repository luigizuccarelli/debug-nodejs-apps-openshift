### Debug node apps in openshift

**Assumptions**
 
 * Working in the vagrant ose32 env
 * Openshift up and running


**Configuration**


fh-supercore (I will use this as the reference throughout) 

All commands executed in the vagrant vm

1. Navigate to the directory and execute 
 
   ```bash 
   npm install --production
   
   ```

2. Execute 
  
  ```bash 
  npm ls
  
  ```
3. Finally execute 
 
  ```bash 
  npm install node-inspector
  
  ```
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
      node --debug fh-supercore.js config/conf.json --master-only
    else
      node fh-supercore.js config/conf.json --master-only    
    fi
     
    ```
9. Change permissions on both files (chmod 755)

10. Execute grunt fh:dist

11. Copy the dist/fh-supercore-*.tar.gz file to docker/

12. Navigate to the docker folder 
 
   ``` 
    cd docker/ 
    docker build -f Dockerfile-dev -t fh-supercore:lmz-dev . 
    
   ```

13. Update the fh-supercore template
     
     Add the following to the service template spec: (heading) 

     
  ```json

     "ports": [
       {
         "name": "server",
         "protocol": "TCP",
         "port": 8080,
         "targetPort": 8080
       },
       {
         "name": "debugger",
         "protocol": "TCP",
         "port": 9000,
         "targetPort": 9000
       }
     ]

  ```

     b. Add the port and protocol TCP to the supercore depolymentconfig

     c. Add the following to spec.container (heading)

  ```json
     
      "command" : [
        "run.sh",
        "debug"
      ]

  ```

     d. Update the current image to point to the newly created image (e.g. fh-supercore:lmz-dev)

 
     
14. Deploy the updated template

15. Once deployed 

  ```
  oc rsh fh-supercore-xxx bash

  ```

16. Execute 

   ```
   node node_modules/node-inspector/bin/inspector.js -p 9000 --save-live-edit &

   ```

17. Create a file for the debugger route and copy the contents below and save it (I used debug-route.json) 
     
     a. Make sure the name corresponds to the name you used in the service.
     
     b. Make sure the namespace (project) is correct.

     c. Ensure the spec:to:name corresponds to the correct service
     
 
   ```
   {
      "kind": "Route",
      "apiVersion": "v1",
      "metadata": {
          "name": "fh-supercore",
          "creationTimestamp": null,
          "labels": {
              "name": "fh-supercore"
          }
      },
      "spec": {
          "host": "local.feedhenry.io",
          "to": {
              "kind": "Service",
              "name": "fh-supercore"
          },
          "port": {
              "targetPort": "debugger"
          }
      }
  }
  
  ```

   d. Create the route in openshift
  
  ```
  oc create -f debug-route.json

  ```



18 Navigate to the route or http://debug.local.feedhenry.io (this will take a while - it loads all the scripts !!!)

19 You can set breakpoints and debug using the chrome interface. You can also edit and save changes - primitive but it works 

20 The exercise to create a PVC and PV and mount the source dir to your existing git repo work dir is left for you to do

Screen shots 


![chrome debugger] (./images/chrome-debugger.png)



Notice the 'DEBUG LMZ ..' log info in the console log (code changed and saved in the debugger)


![oc logs of supecore] (./images/console-log.png)

