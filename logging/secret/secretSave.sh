prefix=$1
oc get secret logging-curator -o jsonpath={.data.key} |base64 -d |tee logging-$prefix-curator.key
oc get secret logging-curator -o jsonpath={.data.ca} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-curator.ca
oc get secret logging-curator -o jsonpath={.data.cert} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-curator.cert

oc get secret logging-fluentd -o jsonpath={.data.key} |base64 -d |tee logging-$prefix-fluentd.key
oc get secret logging-fluentd -o jsonpath={.data.ca} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-fluentd.ca
oc get secret logging-fluentd -o jsonpath={.data.cert} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-fluentd.cert
oc get secret logging-fluentd -o jsonpath={.data.ops-key} |base64 -d |tee logging-$prefix-fluentd.ops-key
oc get secret logging-fluentd -o jsonpath={.data.ops-ca} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-fluentd.ops-ca
oc get secret logging-fluentd -o jsonpath={.data.ops-cert} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-fluentd.ops-cert

oc get secret logging-elasticsearch -o jsonpath={.data.key} |tee  logging-$prefix-elasticsearch.key
oc get secret logging-elasticsearch -o jsonpath={.data.admin-key} |tee  logging-$prefix-elasticsearch.admin-key
oc get secret logging-elasticsearch -o jsonpath={.data.admin-ca} |base64 -d | openssl x509 -noout -text  |tee  logging-$prefix-elasticsearch.admin-ca
oc get secret logging-elasticsearch -o jsonpath={.data.admin-cert} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-elasticsearch.admin-cert
oc get secret logging-elasticsearch -o jsonpath={.data.'admin\.jks'} |tee logging-$prefix-elasticsearch.admin.jks
oc get secret logging-elasticsearch -o jsonpath={.data.'passwd\.yml'} |base64 -d |tee  logging-$prefix-elasticsearch.passwd.yml
oc get secret logging-elasticsearch -o jsonpath={.data.'searchguard\.key'} |tee  logging-$prefix-elasticsearch.searchguard.key
oc get secret logging-elasticsearch -o jsonpath={.data.'searchguard\.truststore'} |tee  logging-$prefix-elasticsearch.searchguard.truststore
oc get secret logging-elasticsearch -o jsonpath={.data.'truststore'} |tee  logging-$prefix-elasticsearch.truststore

oc get secret logging-kibana -o jsonpath={.data.key} |base64 -d |tee logging-$prefix-kibana.key
oc get secret logging-kibana -o jsonpath={.data.ca} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-kibana.ca
oc get secret logging-kibana -o jsonpath={.data.cert} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-kibana.cert
oc get secret logging-kibana-proxy -o jsonpath={.data.server-key} |base64 -d |tee  logging-$prefix-kibana-proxy.server-key
oc get secret logging-kibana-proxy -o jsonpath={.data.server-cert} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-kibana-proxy.server-cert
oc get secret logging-kibana-proxy -o jsonpath={.data.'server-tls\.json'} |base64 -d |tee logging-$prefix-kibana-proxy.server-tls.json
oc get secret logging-kibana-proxy -o jsonpath={.data.oauth-secret} |base64 -d |tee logging-$prefix-kibana-proxy.oauth-secret
oc get secret logging-kibana-proxy -o jsonpath={.data.session-secret} |base64 -d |tee logging-$prefix-kibana-proxy.session-secret

oc get secret prometheus-tls -o jsonpath={.data.'tls\.key'} |base64 -d |tee logging-${prefix}-prometheus-tls.key
oc get secret prometheus-tls -o jsonpath={.data.'tls\.crt'} |base64 -d | openssl x509 -noout -text  |tee logging-$prefix-prometheus-tls.crt

oc get pods  |tee logging-$prefix-pods.logs
