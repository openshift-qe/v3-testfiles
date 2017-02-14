node{
      stage 'build'
      def verify = openshiftVerifyDeployment apiURL: '<repl_env>', authToken: '', depCfg: 'frontend', namespace: '<repl_ns>', replicaCount: '', verbose: 'false', verifyReplicaCount: 'false', waitTime: '', waitUnit: 'sec'
}
