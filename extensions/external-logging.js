'use strict';
angular.module("mylinkextensions", ['openshiftConsole'])
       .run(function(extensionRegistry) {
          extensionRegistry.add('log-links', _.spread(function(resource, options) {
            return {
              type: 'dom',
              node: '<span><a href="https://extension-point.example.com">' + 'See ' + resource.metadata.name + ' Extension Logging' + '</a><span class="action-divider">|</span></span>'
            };
          }));
       });
hawtioPluginLoader.addModule("mylinkextensions");
