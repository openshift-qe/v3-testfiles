'''
Created on May 9, 2019
@author: anli@redhat.com
'''
import argparse
import re
import sys
import os
import yaml

images=[]
parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file')
args=parser.parse_args()

"""
pip install pyyaml
http://ansible-tran.readthedocs.io/en/latest/docs/YAMLSyntax.html
"""
f = open(args.file)
res=yaml.load(f, Loader=yaml.FullLoader)
f.close()
#print(res)
res2=yaml.load(res['data']['clusterServiceVersions'],Loader=yaml.FullLoader)
#print res2
for vitem in res2:
    for ditem in  vitem['spec']['install']['spec']['deployments']:
        for citem in ditem["spec"]["template"]['spec']["containers"]:
            images.append(citem['image'])
            print str(citem['image'])
            for  eitem in citem['env']:
                if(re.search("_IMAGE", eitem['name'])):
                    images.append(eitem['value'])
                    print eitem['value']
