FROM openshift/openshift-ansible
ENV DEFAULT_LOCAL_TMP /tmp
ENV ANSIBLE_LOCAL_TEMP /tmp
USER root
RUN yum -y install ed iproute python-dbus PyYAML yum-utils pyOpenSSL python-cryptography python-lxml openjdk-8-jre java-1.8.0-openjdk java-1.8.0-openjdk-devel httpd-tools
RUN chmod 770 /etc
RUN adduser --system -s /bin/bash -u 1234321 -g 0 ansible
RUN chmod 664 /etc/passwd /etc/group
# set ansible to ignore ssh-key check
ENV ANSIBLE_HOST_KEY_CHECKING=False
# enable anisble color output
ENV ANSIBLE_FORCE_COLOR=True
ENV ANSIBLE_CALLBACK_WHITELIST=profile_tasks
# set plugins search path
ENV ANSIBLE_FILTER_PLUGINS=/tmp/tmp/ansible_plugins
ENV ANSIBLE_CALLBACK_PLUGINS=/tmp/tmp/ansible_plugins
ENV ANSIBLE_LOOKUP_PLUGINS=/tmp/tmp/ansible_plugins
#USER ansible
CMD sleep infinity
