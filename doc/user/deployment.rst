Deployment
==========


System requirements
-------------------

LoRA currently supports Ubuntu 16.04 (Xenial).
We recommend running it on a VM with the following allocation:

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * -
     - CPU
     - Memory
     - Storage
     - Disk type
   * - Minimal
     - 1 core
     - 2 GB
     - 15 GB
     - any *(SSD or HD)*
   * - Test & development
     - 2 cores
     - 4 GB
     - 30 GB
     - SSD *(recommended)*
   * - Production
     - 4 cores
     - 8 GB
     - 60 GB
     - SSD

You should initially provision all the storage space you expect to use,
as adjusting it is somewhat cumbersome. By comparison, increasing or
decreasing CPU and memory is trivial.

Getting started
---------------

.. warning:: FIXME
   Fillout this section.

In a production environment, it is recommended to bind the oio_rest service to a
unix socket, then expose the socket using a HTTP proxy of your own choosing.

(Recommended: Nginx or Apache)

More on how to configure in the advanced configuration document. Link:
``Document is currently being written``
