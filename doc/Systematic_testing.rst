Systemtic testing of the OIO REST interface
===========================================

(this document is work in progress...)

The OIO REST interface (or parts of it) will be systematically tested (kind of)
using *Equivalence Class Partitioning* and *Myers Heuristics* (a good reference
describing these techniques can be found here_). Please note, that the
equivalence classes (ECs) used here are a little fuzzy and the union of them do
NOT form the full input set to the interface.

.. _here: http://www.baerbak.com/

OrganisationOpret
-----------------

Equivalence class partitioning:

=================  =================================================  =================================================
Condition          Invalid ECs                                        Valid ECs
=================  =================================================  =================================================
Note               Note not a string [1]                              Zero notes [2], One note [3]
Attr, BVN          BVN missing [4], BVN not a string [5]              Exactly one BVN [6]
Attr, BVN          BVN consists of special characters [7]
Attr, OrgName      OrgName not string [8]                             No OrgName [9], OrgName string [10]
Attr, Virkning     Virkning missing [11], Virkning malformed [12]     Virkning correct [13]
Attr, No of attrs  OrgEgenskaber missing [14]                         Two OrgEgenskaber present (no overlaps) [15]
Attr, Virkning     Different OrgNames for overlapping virknings [16]
Empty org          Empty org [17]
Attr               Attr missing [18]
Tilstand, number   Tilstand missing [19]
Tilstand, orgGyld  OrgGyldighed missing [20]                          One valid OrgGyld [21], Two valid OrgGyld [22]
Tilstand, gyldigh  Gyld not aktiv or inaktiv [23], gyld missing [26]  gyldighed aktiv [24], gyldighed inaktiv [25]
Tilstd, virkning   Virkning missing [27], Virkning malformed [28]     Virkning valid [29]
Tilstd, virkning   Different gyldighed for overlapping virkning [30]
=================  =================================================  =================================================

More cases to come...

Myers Heuristics
----------------

The test cases will be constructed using Myers Heuristics following
(in general) these rules (taken from the above reference):

1. Until all valid ECs have been covered, define a test case that covers as
   many uncovered valid ECs as possible.
2. Until all invalid ECs have been covered, define a test case whose element
   only lies in a single invalid EC.

Boundary conditions
-------------------
Check virkning...

TODO
----
Test registrations...
Test virkning...