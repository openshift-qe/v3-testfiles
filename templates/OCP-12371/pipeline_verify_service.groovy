node{
       stage 'build'
       def service = openshiftVerifyService apiURL: '<repl_env>', authToken: '', namespace:'<repl_ns>', svcName: 'frontend', verbose: 'false'
}
