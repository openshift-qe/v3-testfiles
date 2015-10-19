This folder is for groups related feature.
* sync-groups
* ...

##sync-groups##
1. setup ldap server for sync-groups
Go to openldap folder, and run `docker build .` to generate the openldap image 
2. run the ldap server on node
```
docker run -d --name openldap_server -p 389:389 -p 636:636 <ldap image name>:latest
```
3. Do the following steps in the cases.
