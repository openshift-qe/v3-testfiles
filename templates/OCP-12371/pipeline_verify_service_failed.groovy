node{
       stage 'build'
       openshiftVerifyService( apiURL: '<repl_env>', authToken: '', namespace:'<repl_ns>', svcName: 'frontend-prod', verbose: 'false', retryCount: '5')
}
