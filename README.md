docker-neutron-server
===========

0.0.1 - 2014.1.2-1 - Icehouse

Overview
--------

Run OpenStack Neutron Server in a Docker container.


Caveats
-------

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed. Reference the [Getting images from outside Docker registries](https://access.redhat.com/articles/881893#images) section of the the guide to pull your base rhel7 image from Red Hat's private registry. This is required to build the rhel7-systemd base image used by the neutron-server container.

Make sure your Docker host has been configured with the required [OSP 5 channels and repositories](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/5/html/Installation_and_Configuration_Guide/chap-Prerequisites.html#sect-Software_Repository_Configuration)

After following the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893) guide, verify your Docker Registry is running:
```
# systemctl status docker-registry
docker-registry.service - Registry server for Docker
   Loaded: loaded (/usr/lib/systemd/system/docker-registry.service; enabled)
   Active: active (running) since Mon 2014-05-05 13:42:56 EDT; 601ms ago
 Main PID: 21031 (gunicorn)
   CGroup: /system.slice/docker-registry.service
           ├─21031 /usr/bin/python /usr/bin/gunicorn --access-logfile - --debug ...
            ...
```
Now that you have the rhel7 base image, follow the instructions in the [docker-rhel7-systemd project](https://github.com/danehans/docker-rhel7-systemd/blob/master/README.md) to build your rhel7-systemd image.

Although the container does initialize the database used by neutron-server, it does not create the database, permissions, etc.. These are responsibilities of the database service.

Although the python-neutron client is installed, it currently does not work due to the following error. For the time being, use Neutron CLI commands from another host/container with python-neutronclient installed.
```
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

From your Docker Registry, set the environment variables used to automate the image building process

Required. Name of the Github repo. Change danehans to your Github repo name if you forked this project. Otherwise set REPO_NAME to danehans.
```
export REPO_NAME=danehans
```
Required. The branch from the REPO_NAME repo. Unless you are using a different branch, set the REPO_BRANCH to master.
```
export REPO_BRANCH=master
```
Optional. Name of the Docker base image in your Docker Registry. This should be the image that includes systemd. Defaults to rhel7-systemd.
```
export BASE_IMAGE=ouruser/rhel7-systemd
```
Optional. Name to use for the Keystone Docker image. Defaults to keystone.
```
export IMAGE_NAME=ouruser/keystone
```
Optional. Hostname to use when running the Keystone container. Defaults to $HOSTNAME
```
export KEYSTONE_HOSTNAME=keystone.example.com
```
Required. IP address/hostname of the Database server.
```
export DB_HOST=10.10.10.200
```
Optional. Password used to connect to the Keystone database on the DB_HOST server. Defaults to changeme.
```
export DB_PASSWORD=changeme
```
Required. IP address/hostname of the RabbitMQ server.
```
export RABBIT_HOST=10.10.10.200
```
Optional. Username/Password used to connect to the RabbitMQ server.
```
export RABBIT_USER=guest
export RABBIT_PASSWORD=guest
```
Required. IP address/hostname of Keystone. This address should resolve to the IP used by the Host and not the container.
```
export KEYSTONE_HOST=10.10.10.100
```
Optional. TCP Port used to connect to the Keystone server Admin API. Defaults to 35357.
```
export KEYSTONE_ADMIN_HOST_PORT=35357
```
Optional. TCP Port used to connect to the Keystone server Public API. Defaults to 5000.
```
export KEYSTONE_PUBLIC_HOST_PORT=5000
```
Optional. The name and password of the service tenant within the Keystone service catalog. Defaults to service/changeme
```
export SERVICE_TENANT=services
export SERVICE_PASSWORD=changeme
```
Optional. Credentials used in the Keystone RC files. Defaults to changeme.
```
export ADMIN_USER_PASSWORD=changeme
export DEMO_USER_PASSWORD=changeme
```
Required.The IP address/hostname of the Nova API server.
```
export NOVA_API_HOST=10.10.10.100
```
Optional. The List of network type driver entrypoints to be loaded from the neutron.ml2.type_drivers namespace. Example: type_drivers = flat,vlan,gre,vxlan. Defaults to local. The default value 'local' is useful for single-box testing but provides no connectivity between hosts.
```
export TYPE_DRIVERS=vxlan
```
Optional. Ordered list of network_types to allocate as tenant networks. Defaults to local. The default value 'local' is useful for single-box testing but provides no connectivity between hosts.
```
export TENANT_NETWORK_TYPES=vxlan
```
Additional environment variables can be set as needed. You can reference the [build script](https://github.com/danehans/docker-neutron-server/blob/master/data/scripts/build#L14-L76) to review all the available environment variables options and their default settings.

Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/neutron-controller-node.html) for more details on the .conf configuration parameters.

Run the build script.
```
bash <(curl \-fsS https://raw.githubusercontent.com/$REPO_NAME/docker-neutron-server/$REPO_BRANCH/data/scripts/build)
```
The image should now appear in your image list:
```
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
neutron-server      latest              d75185a8e696        3 minutes ago       555 MB
```
Now you can run a Keystone container from the newly created image. You can use the run script or run the container manually.

First, set your environment variables:
```
export IMAGE_NAME=ouruser/neutron-server
export NEUTRON_SERVER_HOSTNAME=neutron-server.example.com
export DNS_SEARCH=example.com
```
Additional environment variables can be set as needed. You can reference the [run script](https://github.com/danehans/docker-neutron-server/blob/master/data/scripts/run#L14-L24) to review all the available environment variables options and their default settings.

**Option 1-** Use the run script:
```
# . $HOME/docker-neutron-server/data/scripts/run
```
**Option 2-** Manually:
Run the neutron-server container. The example below uses the -h flag to configure the hostame as neutron-server within the container, exposes TCP port 9696 on the Docker host, names the container neutron-server, uses -d to run the container as a daemon.
```
# docker run --privileged -d -h neutron-server -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-p 9696:9696 --name="neutron-server" ouruser/neutron-server
```
**Note:** SystemD requires CAP_SYS_ADMIN capability and access to the cgroup file system within a container. Therefore, --privileged and -v /sys/fs/cgroup:/sys/fs/cgroup:ro are required flags.

Verification
------------

Verify your neutron-server container is running:
```
# docker ps
CONTAINER ID  IMAGE         COMMAND          CREATED             STATUS              PORTS                                          NAMES
96173898fa16  neutron-server:latest   /usr/sbin/init   About an hour ago   Up 51 minutes       0.0.0.0:9696->9696/tcp neutron-server
```
If you did not use the run script, manually access the shell of your container:
```
# docker inspect --format='{{.State.Pid}}' neutron-server
```
The command above will provide a process ID of the neutron-server container that is used in the following command:
```
# nsenter -m -u -n -i -p -t <PROCESS_ID> /bin/bash
bash-4.2#
```
You can now perform limited functions such as viewing installed RPMs, the neutron.conf file, etc.. Source your Neutron Server credential file. **Note:** The python-neutronclient currently does not work. The following is for reference puposes only.
```
# source /root/admin-openrc.sh
```
Verify the neutron-server service is running.
```
# systemctl status neutron-server -l
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
# neutron net-list
+--------------------------------------+--------+-------------------------------------------------------+
| id                                   | name   | subnets                                               |
+--------------------------------------+--------+-------------------------------------------------------+
+--------------------------------------+--------+-------------------------------------------------------+
```
Verify the extentions loaded by the server:
```
# neutron ext-list
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
# yum install -y curl
# curl -s -d  "{\"auth\":{\"passwordCredentials\": {\"username\": \"neutron\", \"password\": \"%SERVICE_PASSWORD%\"}, \"tenantName\": \"%SERVICE_TENANT%\"}}" -H "Content-type: application/json" http://%KEYSTONE_HOST%:35357/v2.0/tokens

```
IPtables may be blocking you. Check IPtables rules on the host(s) running the other OpenStack services:
```
# iptables -L
```
To change iptables rules:
```
$ vi /etc/sysconfig/iptables
$ systemctl restart iptables.service
```
