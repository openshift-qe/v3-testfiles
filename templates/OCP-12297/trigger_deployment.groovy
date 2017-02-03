node{
        stage 'build'
        openshiftDeploy apiURL: '<repl_env>', authToken: '', depCfg: 'frontend', namespace: '<repl_ns>', verbose: 'false', waitTime: '', waitUnit: 'sec'
}
