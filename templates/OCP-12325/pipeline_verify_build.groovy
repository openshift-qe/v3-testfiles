node{
      stage 'build' 
      def verify = openshiftVerifyBuild apiURL: '<repl_env>', authToken: '', bldCfg: 'frontend', checkForTriggeredDeployments: 'false', namespace: '<repl_ns>', verbose: 'false', waitTime: ''
}
