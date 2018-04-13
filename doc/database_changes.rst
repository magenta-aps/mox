Working with database templates and patches for Magenta's Mox/LoRa-Actual State Server
======================================================================================

The tables, indexes, datatypes and functions in the database of
Magenta's Mox/LoRa-actual state server are generated when the
recreatedb.sh script is executed. NOTICE: You do not want to run
recreatedb.sh on a database, that is already in production (i.e. that
has production data in it ) - as it will be dropped . The script is
intended to initialize a new database.

The recreatedb.sh script runs a process, where configuration defined in
settings.py for each OIO-type, combined with the listing of OIO-types a
few places in recreatedb.sh, will trigger the generation of tables,
indexes, datatypes and functions in the database, to support the
handling of the OIO-types.

This process uses the jinja-templates (.jinja.sql) located in the folder
'templates' to generate the bulk of the code/structures in the database
to support a given OIO-type. In a few cases (e.g. for OIO-type
'Dokument'), the settings.py file contains some extra configuration,
that is utilized in very specific parts of a template, to accommodate
for variations for that particular type. However, in a lot of cases, the
handling of variations is done by applying patch-files to the output of
the template process, generating a modified SQL-script, which is then
executed on the DB-server. This has the advantage of not increasing the
complexity of the jinja-templates to accommodate every other variation,
which may only apply to one or few OIO-types. The downside is, that you
have to generate and maintain the patch-files. When introducing support
for new variations, you have to balance the cost of increased complexity
in the jinja-templates against the 'hassle' of working with patch-files,
when choosing where to implement the support for the new variations.

When working with new/existing patch-files, following the steps listed
below are recommended. Also, it is highly recommended that you have a
good (graphical) tool for visualizing differences, when you inspect the
differences of the generated SQL-scripts, comparing the output from the
jinja-template process before and after the patch is applied. Also, make
sure that .rej and .orig are NOT ignored by Git, as you would want to be
alerted to their sudden occurrence, as they will help you discover, when
a patch failed to apply fully (or entirely).

1. Create a dedicated branch to hold your work (as usual).

2. Make sure that you can run recreatedb.sh and run_tests.sh in your
   developer-environment successfully, that is, no errors creating the
   DB and no failing tests - ensuring that the basis your are working of
   is sound. In particular make sure to inspect the output of
   recreatedb.sh, that pertains to applying the patches. Look for
   patches that failed to apply (partly of entirely). Fix any issues
   before continuing (perhaps by choosing a better branch as your
   starting point.)

3. If you are going to introduce changes to a function/table/datatype
   that is already the target of an existing patch, before you proceed,
   you should make sure that the relevant .org file in the 'patches'
   folder, contains any changes, that may have been introduced in the
   jinja-template, since the .org-file was updated last. Since you have
   completed step 2 above, you can do this by simply copying the
   corresponding .sql-file from the folder 'generated'-files, as we have
   now made sure, that it contains the successful application of the
   content of the existing patch to the current output of the template
   process. Also, if the function that you wish to change is not
   currently the target of any patching, you should carry out this step
   anyway, providing you with a new .org-file, in which you can
   introduce your changes. If, as an example, you are planning to make
   changes to the function 'as_create_or_import_tilstand' you should
   execute the command below, to complete this step:

   `cp ./generated-files/as_create_or_import_tilstand.sql ./patches/as_create_or_import_tilstand.org.sql`

4. Now, you are ready to introduce the changes you want in the the
   .org-file, corresponding to the function/table-def/datatype-def that
   you want to change. TIP: Test the new version of the db-function by
   manually applying it to the development-database, using psql or
   pgadmin or similar and make sure that the existing tests still pass,
   as well as any new tests, that you have introduced to test the new
   functionality. This will speed up the development process, as you
   will postpone the generation of the patch-file, until the function
   definition is ready.

5. If you are altering an existing patch, disable the application of
   this particular patch temporarily in the recreatedb.sh script. Now,
   re-run recreatedb.sh, leaving you with the 'raw' output of the
   template process for the particular function in the 'generated-files'
   folder.

6. Create the actual .diff file by running the command below,
   substituting function names as needed.

    `diff --context=5  ./patches/as_create_or_import_tilstand.org.sql ./generated-files/as_create_or_import_tilstand.sql > patches/as_create_or_import_tilstand.sql.diff`

7. Make sure that the patch is applied in the relevant section of
   recreatedb.sh script. That is, undo what you did in step 5 or - if
   you are targeting a previously unpatched function/file - introduce a
   line similar to the one below (again, substituting names as needed)

    `patch --fuzz=3 -i ../patches/as_create_or_import_tilstand.sql.diff`

8. Run recreatedb.sh and verify that the patch was applied successfully
   by inspecting the output.

9. Execute run_tests.sh and make sure that all tests are still passing -
   now including any new tests, that you hopefully have provided to test
   the newly introduced functionality.

10. Important: Use Git and visual diff tool to verify that the changes
    your operations here have introduced, have only introduced the
    wanted changes to the relevant file in the 'generated-files' folder.
    (And the ability to carry out this step, is the reason why you
    really really want to keep the files in the 'generated-files' folder
    in Git. )

11. Commit the files to git: The .sql file in the 'generated-files'
    folder, the .org file in the 'patches' folder and the '.diff' file
    also in the patches folder, the modified recreatedb.sh script and
    files containing any new or modified tests.

How changes in settings.py or jinja-tempaltes may affect patching
-----------------------------------------------------------------

When you are introducing changes in settings.py or in jinja-tempaltes,
you need to pay special attention, when your changes involves OIO-types,
the function definitions of which are the target of patching.

As a basis, you should always run recreatedb.sh and verify that all
patches applied successfully, by inspecting the output of the script -
and that all tests are still passing, by running run_tests.sh.

However, if you are unsure, if the changes introduced may affect code in
patches, you should do a search in the .diff files to check for relevant
sections, that may need manual updating. As an example, say you need to
add a new relation type to the OIO-type 'Tilstand', where the new
relation is of unlimited cardinality. After you have added the new
relation to the relevant section in settings.py and you have completed
the step described above - you should search the patch (.diff) files
related to 'Tilstand' for the name of an existing relation type of
unlimited cardinality. If you find occurrences in the diff files (and at
the time of this writing, you should) of the 'sister'-relation type, you
need to inspect the code in the full context and determine if not your
new relation type, should be named in that particular section as well.
Most likely, is should.

As always, it is sound practise, to run the changes you wish to make by
the developer available with the most in-depth knowledge of the code, to
help identify aspects to be aware of.
