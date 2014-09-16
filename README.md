docker-neutron-server
===========

0.0.1 - 2014.1.2-1 - Icehouse

Overview
--------

Run OpenStack Neutron Server in a Docker container.


Caveats
-------

The systemd_rhel7 base image used by the Neutron Server container is a private image.
Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893)
to create your base rhel7 image. Then enable systemd within the rhel7 base image.
Use [Running SystemD within a Docker Container](http://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/) to enable SystemD.

Although the container does initialize the database used by Neutron Server, it does not create the database, permissions, etc.. These are responsibilities of the database service.

Although the python-neutron client is installed, it currently does not work due to the following error. For the time being, use Neutron CLI commands from another host/container with python-neutronclient installed.```
Traceback (most recent call last):
  File "/usr/bin/neutron", line 6, in <module>
    from neutronclient.shell import main
  File "/usr/lib/python2.7/site-packages/neutronclient/shell.py", line 26, in <module>
    from cliff import app
  File "/usr/lib/python2.7/site-packages/cliff/app.py", line 13, in <module>
    from .interactive import InteractiveApp
  File "/usr/lib/python2.7/site-packages/cliff/interactive.py", line 9, in <module>
    import cmd2
  File "/usr/lib/python2.7/site-packages/cmd2.py", line 361, in <module>
    class Cmd(cmd.Cmd):
  File "/usr/lib/python2.7/site-packages/cmd2.py", line 426, in Cmd
    stderr=subprocess.STDOUT)
  File "/usr/lib64/python2.7/subprocess.py", line 711, in __init__
    errread, errwrite)
  File "/usr/lib64/python2.7/subprocess.py", line 1308, in _execute_child
    raise child_exception
OSError: [Errno 2] No such file or directory
```

Installation
------------

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed.

### From Github

Clone the Github repo and change to the project directory:
```
yum install -y git
git clone https://github.com/danehans/docker-neutron-server.git
cd docker-neutron-server
```
Edit the neutron.conf, ml2_conf.ini and all .sh files according to your deployment needs. Replace all configuration parameters in the %NAME% format. Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/neutron-ml2-controller-node.html) for details. The project includes .example files for reference purposes.

Build your Docker neutron-server image.
```
docker build -t neutron-server .
```
The image should now appear in your image list:
```
$ docker images
REPOSITORY                TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
neutron-server                      latest              d75185a8e696        3 minutes ago       555 MB
```
Run the Neutron Server container. The example below uses the -h flag to configure the hostame as neutron-server within the container, exposes TCP port 9696 on the Docker host, names the container neutron-server, uses -d to run the container as a daemon.
```
docker run --privileged -d -h neutron-server -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-p 9696:9696 --name="neutron-server" neutron-server
```
**Note:** SystemD requires CAP_SYS_ADMIN capability and access to the cgroup file system within a container. Therefore, --privileged and -v /sys/fs/cgroup:/sys/fs/cgroup:ro are required flags.

Verification
------------

Verify your Neutron Server container is running:
```
$ docker ps
CONTAINER ID  IMAGE         COMMAND          CREATED             STATUS              PORTS                                          NAMES
96173898fa16  neutron-server:latest   /usr/sbin/init   About an hour ago   Up 51 minutes       0.0.0.0:9696->9696/tcp neutron-server
```
Access the shell from your container:
```
$ docker inspect --format='{{.State.Pid}}' neutron-server
```
The command above will provide a process ID of the Neutron Server container that is used in the following command:
```
$ nsenter -m -u -n -i -p -t <PROCESS_ID> /bin/bash
bash-4.2#
```
From here you can perform limited functions such as viewing installed RPMs, the neutron.conf file, etc..

```
Source your Neutron Server credential file. **Note:** The python-neutronclient currently does not work. The following is for reference puposes only.```
$ unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
$ source /root/admin-openrc.sh
```
Verify the neutron-server service is running.
```
$ systemctl status neutron-server -l
neutron-server.service - OpenStack Neutron Server
   Loaded: loaded (/usr/lib/systemd/system/neutron-server.service; enabled)
   Active: active (running) since Mon 2014-09-15 22:33:46 EDT; 24min ago
 Main PID: 181 (neutron-server)
   CGroup: /system.slice/docker-22791591891d45d3dab8155bd875dbbb4e17db51eb7f1b93c1d8497572376dd1.scope/system.slice/neutron-server.service
           └─181 /usr/bin/python /usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --log-file /var/log/neutron/server.log

Sep 15 22:33:45 neutron-server systemd[1]: Starting OpenStack Neutron Server...
Sep 15 22:33:46 neutron-server systemd[1]: Started OpenStack Neutron Server.
```
You should be able to perform a neutron net-list and receive a blank response. **Note:** The python-neutronclient currently does not work, so Neutron CLI commands MUST be performed from another container/host with the python-neutronclient installed.
```
$ neutron net-list
+--------------------------------------+--------+-------------------------------------------------------+
| id                                   | name   | subnets                                               |
+--------------------------------------+--------+-------------------------------------------------------+
+--------------------------------------+--------+-------------------------------------------------------+
```
Verify the extentions loaded by the server:
```
neutron ext-list
+-----------------------+-----------------------------------------------+
| alias                 | name                                          |
+-----------------------+-----------------------------------------------+
| service-type          | Neutron Service Type Management               |
| ext-gw-mode           | Neutron L3 Configurable external gateway mode |
| security-group        | security-group                                |
| l3_agent_scheduler    | L3 Agent Scheduler                            |
| lbaas_agent_scheduler | Loadbalancer Agent Scheduler                  |
| fwaas                 | Firewall service                              |
| binding               | Port Binding                                  |
| metering              | Neutron Metering                              |
| agent                 | agent                                         |
| quotas                | Quota management support                      |
| dhcp_agent_scheduler  | DHCP Agent Scheduler                          |
| multi-provider        | Multi Provider Network                        |
| external-net          | Neutron external network                      |
| router                | Neutron L3 Router                             |
| allowed-address-pairs | Allowed Address Pairs                         |
| vpnaas                | VPN service                                   |
| extra_dhcp_opt        | Neutron Extra DHCP opts                       |
| provider              | Provider Network                              |
| lbaas                 | LoadBalancing service                         |
| extraroute            | Neutron Extra Route                           |
+-----------------------+-----------------------------------------------+
```
If you have an existing Neutron agent/network node deployment, you should be able to create networks, subnets, routers, etc.. Use the steps from the official OpenStack [Admin Guide](http://docs.openstack.org/admin-guide-cloud/content/l3_workflow.html) for more details.

Troubleshooting
---------------

Can you connect to the OpenStack API endpints from your Docker host and container? Verify connectivity with tools such as ping and curl.
```
$ yum install -y curl
$ curl -s -d  "{\"auth\":{\"passwordCredentials\": {\"username\": \"neutron\", \"password\": \"%SERVICE_PASSWORD%\"}, \"tenantName\": \"%SERVICE_TENANT%\"}}" -H "Content-type: application/json" http://%KEYSTONE_HOST%:35357/v2.0/tokens

```
IPtables may be blocking you. Check IPtables rules on the host(s) running the other OpenStack services:
```
$ iptables -L
```
To change iptables rules:
```
$ vi /etc/sysconfig/iptables
$ systemctl restart iptables.service
```
