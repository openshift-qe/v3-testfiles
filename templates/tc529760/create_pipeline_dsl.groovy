node{
  stage 'build'
	openshiftCreateResource apiURL: 'https://ec2-54-89-88-34.compute-1.amazonaws.com:8443', authToken: '', jsonyaml: '''{
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {
			"name": "hello-openshift",
			"creationTimestamp": null,
			"labels": {
				"name": "hello-openshift"
			}
		},
		"spec": {
			"containers": [
				{
					"name": "hello-openshift",
					"image": "openshift/hello-openshift",
					"ports": [
						{
							"containerPort": 8080,
							"protocol": "TCP"
						}
					],
					"resources": {},
					"volumeMounts": [
						{
							"name":"tmp",
							"mountPath":"/tmp"
						}
					],
					"terminationMessagePath": "/dev/termination-log",
					"imagePullPolicy": "IfNotPresent",
					"capabilities": {},
					"securityContext": {
						"capabilities": {},
						"privileged": false
					}
				}
			],
			"volumes": [
				{
					"name":"tmp",
					"emptyDir": {}
				}
			],
			"restartPolicy": "Always",
			"dnsPolicy": "ClusterFirst",
			"serviceAccount": ""
		},
		"status": {}
	}
	''', namespace: 'test1', verbose: 'false'
	}
