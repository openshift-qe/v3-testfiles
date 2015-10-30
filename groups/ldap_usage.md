1. Add data to ldap server;
```
ldapadd -x -h <LDAP SERVER IP> -p 389 -D cn=Manager,dc=example,dc=com -w admin -f <ldif file> 
```
2. Search all data to check if the data is added;
```
ldapsearch -D "cn=directory manager" -w admin -p 389 -h <LDAP SERVER IP> -b "dc=example,dc=com" -s sub "(objectclass=*)"
```
