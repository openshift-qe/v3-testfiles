#!/usr/bin/env bash
#test description: to add adldap idp

set -o errexit
set -o nounset
set -o pipefail

echo -e "\033[44;37mPlease execute this script on the machine which contains kubeconfig file!\033[0m"
echo -n "please enter the kubeconfig absolute path ->"
read KC

datename=$(date +%Y%m%d-%H%M%S)

step(){
echo -e "\033[47;30m$1\033[0m"
}

checkreturn(){
if [ $? -ne 0 ]; then
echo -e "`date +%H:%M:%S` \033[31mThe step failed and you need to get the cluster status back manually e.g switch back to previous user!!! \033[0m"
exit 1
fi
}

if [ ! -f ${KC} ];then
echo -e "`date +%H:%M:%S` \033[31mThe kubeconfig file doesn't exit \033[0m"
exit 1
fi

step "Step 1: check whether oc client exits"
which "oc" > /dev/null
if [ $? -eq 0 ]
then
echo -e "`date +%H:%M:%S` \033[32m oc command is exist \033[0m"
else
echo -e "`date +%H:%M:%S` \033[31m oc command not exist,you should install the oc client on master \033[0m"
exit 1
fi

step "Step 2: switch to cluster-admin user"
CC=`oc config current-context --config="${KC}"`
oc login -u system:admin --config="${KC}" > /dev/null
checkreturn

step "Step 3: will add ad-ldap idp"
OUT=./oauth_adldap.yaml

oc get oauth cluster -o yaml > $OUT
cat <<EOF >> $OUT
  - ldap:
      attributes:
        id:
        - dn
        name:
        - cn
        preferredUsername:
        - uid
      bindDN: ""
      bindPassword:
        name: ""
      ca:
        name: ad-ldap
      insecure: false
      url: ldaps://10.66.147.179/cn=users,dc=ad-example,dc=com?uid
    mappingMethod: claim
    name: AD_ldaps_provider
    type: LDAP
EOF
echo $OUT
sleep 1
oc apply -f $OUT
sleep 1
##ca.crt comes from openssl s_client -showcerts -connect 10.66.147.179:636
oc apply -f - <<EOF
  apiVersion: v1
  data:
  ca.crt: |
      -----BEGIN CERTIFICATE-----
      MIIFgzCCBGugAwIBAgIKOxVtSQAAAAAABjANBgkqhkiG9w0BAQ0FADBZMRMwEQYK
      CZImiZPyLGQBGRYDY29tMRowGAYKCZImiZPyLGQBGRYKYWQtZXhhbXBsZTEmMCQG
      A1UEAxMdYWQtZXhhbXBsZS1XSU4tQlYyUUQ2OEI0Q0otQ0EwHhcNMTgxMDI1MDkz
      NTU3WhcNMjAxMDI0MDkzNTU3WjApMScwJQYDVQQDEx53aW4tYnYycWQ2OGI0Y2ou
      YWQtZXhhbXBsZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCw
      tEY2PrJJklBYgrN0b1lNv44HCQWjn+8QedyhDaV4vHJK09V04YMeiSsgHw9k/mfA
      17Lh3cCoN0ANbFdVGCArWRE3zQ3EGHhP4W/wwoipBofSXhJYI0NGhh97hCsvLmvc
      w8mhtZntzAak6cq1XQr+s4fOKthiztUtcEq3aEgX4idBFdcuHUIJzz5dANOU8zfy
      ius8GlHuZz0/1HOvGV+KIxbEmkROVZ9GNed919ulXouFaM2TQxOY79uFM8Jftu1V
      GtiW3foeR9SEKVCQlKao7TxUymiIrSZpKr9VIlotHn91lDljlGYvww7nErKVp03I
      jhZ13j74sxOhdnfOY0AfAgMBAAGjggJ7MIICdzAhBgkrBgEEAYI3FAIEFB4SAFcA
      ZQBiAFMAZQByAHYAZQByMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA4GA1UdDwEB/wQE
      AwIFoDAvBgNVHREEKDAmgh53aW4tYnYycWQ2OGI0Y2ouYWQtZXhhbXBsZS5jb22H
      BApCk7MwHQYDVR0OBBYEFCPBnBchKZUwTG4v3TSnOgy8CogbMB8GA1UdIwQYMBaA
      FNSlEcKQoWH+H6zXgV78SzRvyp7cMIHmBgNVHR8Egd4wgdswgdiggdWggdKGgc9s
      ZGFwOi8vL0NOPWFkLWV4YW1wbGUtV0lOLUJWMlFENjhCNENKLUNBLENOPVdJTi1C
      VjJRRDY4QjRDSixDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049
      U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1hZC1leGFtcGxlLERDPWNvbT9j
      ZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JMRGlz
      dHJpYnV0aW9uUG9pbnQwgdIGCCsGAQUFBwEBBIHFMIHCMIG/BggrBgEFBQcwAoaB
      smxkYXA6Ly8vQ049YWQtZXhhbXBsZS1XSU4tQlYyUUQ2OEI0Q0otQ0EsQ049QUlB
      LENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZp
      Z3VyYXRpb24sREM9YWQtZXhhbXBsZSxEQz1jb20/Y0FDZXJ0aWZpY2F0ZT9iYXNl
      P29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwDQYJKoZIhvcNAQEN
      BQADggEBAFzzcS36sRKuqPPPtkel2BqaAPvGvXcjfnhYiX3odhJuGChsRlVLEXro
      5u8xbtzYVi3sU8X5gHun5JUT3tlFYSMKff16t/fK+Gcupfnwom+DIA7OzRYJzA1J
      1mkv1476l67kJtue29GWD+djCgQdQsUsbTtepWRDZ0EJh/ljx7K2AJkTKv7TYU24
      RxN8WEIF6uqJ0hzIJg4qOBqckL0D4ofTXW8k6k4/Jxid7DgbntSHtMcBHsB20gb2
      M94YcL+Okz3ay3uRU7zl1ArBDmxqAinl6RCaZLFPxdrwZADaZOIGNsUlb5EHrfPR
      xKmp6APeT9gFySnrVzdjeE6rs2zp8Co=
      -----END CERTIFICATE-----
  kind: ConfigMap
  metadata:
    name: ca.crt
    namespace: openshift-config
EOF

sleep 30

step "Step 4: switch back to previous user"
oc config use-context ${CC} --config="${KC}"
checkreturn

echo -e "\033[32mAll Success\033[0m"
