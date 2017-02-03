node{
        stage 'build'
        openshiftTag alias: 'false', apiURL: '<repl_env>', authToken: '', destStream: 'myis', destTag: 'tip', destinationAuthToken: '', destinationNamespace: '', namespace: '<repl_ns>', srcStream: 'origin-nodejs-sample', srcTag: 'latest', verbose: 'false'
}
