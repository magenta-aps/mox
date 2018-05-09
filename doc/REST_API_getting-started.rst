Introduction to the REST API
============================

Let us setup a Linux container to run LoRa within before we begin.


Setting up a Linux container
----------------------------
An easy way to get a LoRa instance up and running is to install it in a Linux
Container using LXC. This is done in the following way on an Ubuntu machine::

  $ sudo apt install lxc
  $ sudo lxc-create -t download -n mox

where “mox” is just the name of the container. When prompted for distribution,
release and architecture choose e.g. ubuntu, xenial and amd64, respectively.
LXC will now setup an Ubuntu container. To start the container do the
following::

  $ sudo lxc-start -n mox

Attach to the container by doing::

  $ sudo lxc-attach -n mox

You will now get root access to the container.
Add a unix user account: ::

  $ adduser operator
  $ addgroup operator sudo
  $ apt install ssh

Lookup the IP-address of the container::

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
Following the instructions on the
`LoRa GitHub site <https://github.com/magenta-aps/mox>`_ we can install LoRa
(use the development branch) in our Linux container in the following way::

  $ sudo apt install git
  $ git clone -b development https://github.com/magenta-aps/mox
  $ cd mox
  $ ./install.sh

This can take a while...

Once the installation process is complete,
you may confirm that the OIO rest api is running::

  $ apt install curl
  $ curl http://localhost:8080

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

Getting to know LoRas REST API
------------------------------
The following small exercises can be used as an inspiration to getting to know
LoRas REST API. Read the
`HOWTO <https://github.com/magenta-aps/mox/blob/master/doc/LoRa_HOWTO.rst>`_
from the LoRa GitHub page before moving on. Also, have a look at the LoRa
documentation found in Magenta’s Alfresco system.

1. Create an organisation called e.g. “Magenta” valid from 2017-01-01
   (included) to 2019-12-31 (excluded).
2. Make a query searching for all organisations in LoRa - confirm that Magenta
   exists in the system.
3. Create an organisationenhed called “Copenhagen” (which should be a subunit
   to Magenta) active from 2017-01-01 (included) to 2018-03-14 (excluded).
   Consider which attributes and relations to set.
4. Create an organisationenhed called “Aarhus” (which should be a subunit of
   Magenta) active from 2018-01-01 (included) to 2019-09-01 (excluded).
   Consider which attributes and relations to set.
5. Make a query searching for all organisationenheder in LoRa - confirm that
   Copenhagen and Aarhus exist in the system.
6. Add an address to the org unit in Aarhus (valid within the period where the
   org unit is active).
7. Fetch the org unit Aarhus and verify that the newly added address is
   present in the response.
8. Add another address to the org unit in Aarhus (valid in a period exceeding
   the period where the org unit is active). What happens in this case?
9. Remove all addresses from the Aarhus org unit and confirm that they are
   gone afterwards.
10. Make a small script capable of adding n new org units
    (e.g. where 10 < n < 20) named orgEnhed1, orgEnhed2, orgEnhed3,... These
    org units should all be subunits of the Copenhagen org unit and they
    should be active in random intervals ranging from 2017-01-01 (included) to
    2019-12-31 (excluded).
11. Find all active org (if any) in the period from 2017-12-01 to 2019-06-01.
12. What are the names of the org units from above?