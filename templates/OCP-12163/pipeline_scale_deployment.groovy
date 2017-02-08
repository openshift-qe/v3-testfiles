node{
        stage 'build' def scale = openshiftScale apiURL: '<repl_env>', authToken: '', depCfg: 'frontend', namespace: '<repl_ns>', replicaCount: '<repl_count>', verbose: 'false', verifyReplicaCount: 'false', waitTime: ''
}
