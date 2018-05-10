Systematic testing of the OIO REST interface
============================================

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
Attr, BVN          (BVN consists of special characters [7])
Attr, OrgName      OrgName not string [8]                             No OrgName [9], OrgName string [10]
Attr, Virkning     Virkning missing [11], Virkning malformed [12]     Virkning correct [13]
Attr, No of attrs  OrgEgenskaber missing [14]                         Two OrgEgenskaber present (no overlaps) [15]
Attr, Virkning     Different OrgNames for overlapping virknings [16]
Empty org          Empty org [17]
Attr               Attr missing [18], Two attr objects [40]
Tilstand, number   Tilstand missing [19], Two tilstande objects [41]
Tilstand, orgGyld  OrgGyldighed missing [20]                          One valid OrgGyld [21], Two valid OrgGyld [22]
Tilstand, gyldigh  Gyld not aktiv or inaktiv [23], gyld missing [26]  gyldighed aktiv [24], gyldighed inaktiv [25]
Tilstd, virkning   Virkning missing [27], Virkning malformed [28]     Virkning valid [29]
Tilstd, virkning   Different gyldighed for overlapping virkning [30]
Rel, object        Two relationobjects present [39]                   Relation object missing [38]
Rel, number                                                           Zero allowed [31], one allowed [32], two [33]
Rel, number                                                           Specific relation list empty [42]
Rel, reference     Reference not an UUID [34]                         Reference is an UUID [35]
Rel, name          Invalid relation name not allowed [36]             All valid relation names allowed [37]
=================  =================================================  =================================================

FacetOpret (JSON validation)
----------------------------

Equivalence class partitioning:

=================  =================================================  =================================================
Condition          Invalid ECs                                        Valid ECs
=================  =================================================  =================================================
Note               Note not a string [43]                             No notes [44], Note a string[45]
Attr, BVN          BVN missing [46], BVN not a string [47]            BVN a string [48]
Attr, Facetbeskriv Not a string [49]                                  Missing [80], beskrivelse is a String [50]
Attr, Facetplan    Not a string [78]                                  Missing [79], beskrivelse is a String [81]
Attr, Facetopbyg   Not a string [82]                                  Missing [83], beskrivelse is a String [84]
Attr, Facetophavs  Not a string [85]                                  Missing [86], beskrivelse is a String [87]
Attr, Facetsuppl   Not a string [88]                                  Missing [89], beskrivelse is a String [90]
Attr, Retsklide    Not a string [91]                                  Missing [92], beskrivelse is a String [93]
Attr, Virkning     Virkning missing [51], Virkning malformed [52]     Virkning correct [53]
Attr, No of attrs  Egenskaber missing [54]                            One egenenskaber [77],two egenskaber present [55]
Attr, unknown      Unknown key [94]
Empty facet        Empty facet [56]
Attr               Attr missing [57]
Tilstand, number   Tilstand missing [58]
Tilstand, FacetPub Missing [60]                                       One valid FacetPubl [61], Two valid FacetPub [62]
Tilstand, FacetPub Pub not valid enum [61], pub missing [62]          Pub = pub [63], pub = IkkePub [64]
Tilstd, virkning   Virkning missing [65], Virkning malformed [66]     Virkning valid [67]
Tilstd, unknown    Unknown key [95]
Rel, object                                                           Relation object missing [68]
Rel, number                                                           Zero allowed [69], one allowed [70], two [71]
Rel, number        Two references in nul til en relation [96]         Specific relation list empty [72]
Rel, reference     Reference not an UUID or URN [73]                  Reference is UUID [74], reference is URN [112]
Rel, name          Invalid relation name not allowed [75]             All valid relation names allowed [76]
Virkning, from     missing [97], not string [98]                      String [101]
Virkning, to       missing [99], not string [100]                     String [102]
Virk, aktoerref    not UUID [103]                                     Is UUID [104], missing [108]
Virk, aktoertype   Not string [105]                                   String [106], missing [109]
Virk, notetekst    Not string [107]                                   String [110], missing [111]
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