# _About the AUTH Service test repository_

# Synopsis
This is the test repository for the Db2 [AUTH Service](https://github.com/easydataservices/db2-auth).

# Project status
In active development, not yet completed.

# Quick start

## Prerequisites
Follow the instructions to install the Db2 [AUTH Service](https://github.com/easydataservices/db2-auth) in a DB2 for LUW database (version 11.5 or later).

## Instructions

> Note: ``/home/db2inst1/sqllib`` in the instuctions below must be changed to the sqllib path for your Db2 instance.

1. Change to the ``java`` subdirectory.
1. Optional: Replace the supplied ``lib/db2-auth.jar`` with a freshly built JAR for the Db2 AUTH Service.
1. Build the Java code using the supplied Ant XML: ``ant -f build-db2-auth-TEST.xml``
1. Amend the sample ``db_config.properties`` file to provide actual database, schema and user details.
1. Execute a test by calling TestAuthBootstrap and supplying a properties file for the test payload. For example:
    > ``java -cp dist/db2-auth-TEST.jar:/home/db2inst1/sqllib/java/db2jcc4.jar com.easydataservices.open.test.TestAuthBootstrap payload_create_sessions.properties``
