Setting up a development environment
====================================

Let us setup a Linux container to run LoRa within before we begin.


Setting up a Linux container
----------------------------
An easy way to get a LoRa instance up and running is to install it in a Linux
Container using LXC. This is done in the following way on an Ubuntu machine::

  $ sudo apt install lxc
  $ sudo lxc-create -n mox -t download -- -d ubuntu -r xenial -a amd64

where ``mox`` is the name of the container. It uses the lxc ``download``
template, ``ubuntu`` as the distribution, ``xenial`` as the release and
``amd64`` as the architecture. LXC will now setup an Ubuntu container.

To start the container do the following::

  $ sudo lxc-start -n mox

Attach to the container by doing::

  $ sudo lxc-attach -n mox

You will now get root access to the container.
Add a unix user account and install some utilities: ::

  $ adduser operator
  $ addgroup operator sudo
  $ apt update
  $ apt install ssh git curl

Lookup the IP address of the container::

  $ ifconfig
  eth0          Link encap:Ethernet  HWaddr 00:16:3e:d5:57:a9
                inet addr:10.0.3.248  Bcast:10.0.3.255  Mask:255.255.255.0
                inet6 addr: fe80::216:3eff:fed5:57a9/64 Scope:Link
                UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                RX packets:2170 errors:0 dropped:0 overruns:0 frame:0
                TX packets:1526 errors:0 dropped:0 overruns:0 carrier:0
                collisions:0 txqueuelen:1000
                RX bytes:21592926 (21.5 MB)  TX bytes:132278 (132.2 KB)

  lo            Link encap:Local Loopback
                inet addr:127.0.0.1  Mask:255.0.0.0
                inet6 addr: ::1/128 Scope:Host
                UP LOOPBACK RUNNING  MTU:65536  Metric:1
                RX packets:2121 errors:0 dropped:0 overruns:0 frame:0
                TX packets:2121 errors:0 dropped:0 overruns:0 carrier:0
                collisions:0 txqueuelen:1

We see that the IP-address in this case is 10.0.3.248. Log out of the container
and SSH back in::

  $ ssh -l operator 10.0.3.248

Installing and configuring LoRa
-------------------------------

.. note::
   Using the built-in installer should be considered
   a "developer installation". Please note that it *will not* work
   on a machine with less than 1GB of RAM.

   In the current state of the installer,
   we recommend using it only on a newly installed system,
   preferrably in a dedicated container or VM.
   It is our intention to provide more flexible
   installation options in the near future.

Following the instructions on the
`LoRa GitHub site <https://github.com/magenta-aps/mox>`_ we can install LoRa
(use the development branch) in our Linux container in the following way::

  $ git clone -b development https://github.com/magenta-aps/mox
  $ cd mox
  $ ./install.sh

This can take a while...

The default location of the log directory is::

   /var/log/mox

The following log files are created:

 - OIO REST HTTP access log: /var/log/mox/oio_access.log
 - OIO REST HTTP error log: /var/log/mox/oio_error.log

Additionally, a directory for file uploads is created::

   # settings.py
   FILE_UPLOAD_FOLDER = getenv('FILE_UPLOAD_FOLDER', '/var/mox')

The oio rest api is installed as a service,
for more information, see the oio_rest.service.

Once the installation process is complete,
you may confirm that the OIO rest api is running::

  $ curl -L http://localhost:8080

which should give a JSON response like::

  {
    "site-map": [
      "/",
      "/aktivitet/aktivitet",
      "/aktivitet/aktivitet/<regex(\"[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}\"):uuid>",
      "/aktivitet/aktivitet/fields",
      "/aktivitet/classes",
      "/dokument/classes",
      ...
    ]
  }
