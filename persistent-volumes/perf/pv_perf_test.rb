#!/usr/bin/env ruby
#
# Preparation:
# gem install parallel
# gem install ruby-progressbar
#

require 'parallel'
require 'securerandom'
require 'ruby-progressbar'

$templates_path = '/tmp/pvtest'

Dir.mkdir($templates_path) unless Dir.exist?($templates_path)

def gen_uuid
  SecureRandom.uuid.slice(0, 8)
end

# Create PV templates
# Use fake volume id here because we do not use volume
def gen_pv
  pv_name = "pv-#{gen_uuid}"
  file = "#{$templates_path}/#{pv_name}.yaml"
  File.open(file, 'w') do |f|
    f.puts <<-PV
kind: PersistentVolume
apiVersion: v1
metadata:
  name: #{pv_name}
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  awsElasticBlockStore:
    volumeID: "aws://us-east-1d/#{gen_uuid}"
    fsType: "ext4"
  persistentVolumeReclaimPolicy: "Retain"
PV
  end

  `oc create -f #{file}`
end

# Create PVC templates
def gen_pvc
  pvc_name = "pvc-#{gen_uuid}"
  file = "#{$templates_path}/#{pvc_name}.json"

  File.open(file, 'w') do |f|
    f.puts <<-PVC
{
    "apiVersion": "v1",
    "kind": "PersistentVolumeClaim",
    "metadata": {
        "name": "#{pvc_name}"
    },
    "spec": {
        "accessModes": [ "ReadWriteOnce" ],
        "resources": {
            "requests": {
                "storage": "512Mi"
            }
        }
    }
}
PVC
  end

  `oc create -f #{file}`
end

# Delete all PVs and PVCs
def clean_up
  puts "Run the following commands to clean up your test data:"
  puts "oc delete pv --all"
  puts "oc delete pvc --all"
  puts "Deleting temporary test files"
  `rm -rf #{$templates_path}/*`
end

# Verify Bound status
def verify
  pv_status = `oc get pv | grep Available`
  pvc_status = `oc get pvc | grep -e Failed -e Pending`

  result = pv_status && pvc_status

  if result.length == 0
    puts 'Test passed!'
  else
    puts 'Test failed!'
    puts 'Please check your PVs and PVCs.'
    puts
  end
end

####################
# Test starts here #
####################
num = 1000
in_processes = 10 # number of processes to run the test

# First create PVs
Parallel.map(1..num, progress: 'Creating Persistent Volumes', in_processes: in_processes) do
  gen_pv
end

# Then create PVCs
Parallel.map(1..num, progress: 'Creating Persistent Volumes', in_processes: in_processes) do
  gen_pvc
end

# Verification
sleep(30)
verify
clean_up
