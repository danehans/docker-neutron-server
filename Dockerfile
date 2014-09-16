# Neutron-Server Node
# VERSION               0.0.1
# Tested on RHEL7 and OSP5 (i.e. Icehouse)

FROM       systemd_rhel7
MAINTAINER Daneyon Hansen "daneyonhansen@gmail.com"

WORKDIR /root

# Uses Cisco Internal Mirror. Follow the OSP 5 Repo documentation if you are using subscription manager.
RUN curl --url http://173.39.232.144/repo/redhat.repo --output /etc/yum.repos.d/redhat.repo
RUN yum -y update; yum clean all

# Required Utilities.
RUN yum -y install openssl ntp

# Neutron-Server
RUN yum install -y openstack-neutron openstack-neutron-ml2 python-neutronclient
RUN mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.save
RUN mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.save
ADD neutron.conf /etc/neutron/neutron.conf
ADD ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
RUN chown root:neutron /etc/neutron/neutron.conf
RUN chown root:neutron /etc/neutron/plugins/ml2/ml2_conf.ini
RUN ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
#RUN mkdir -p /var/log/neutron && touch /var/log/neutron/server.log
#RUN chown neutron:neutron /var/log/neutron/server.log
RUN systemctl enable neutron-server

# Copy Neutron-Server Credential Files
ADD admin-openrc.sh /root/admin-openrc.sh
ADD demo-openrc.sh /root/demo-openrc.sh

# Expose Neutron-Server TCP ports
EXPOSE 9696

CMD ["/usr/sbin/init"]
