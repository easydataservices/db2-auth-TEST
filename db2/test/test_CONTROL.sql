-- Query used after each test
SELECT
  session_internal_id,
  partition_id,
  attribute_partition_num,
  created_ts,
  attribute_generation_id,
  last_accessed_ts,
  last_authenticated_ts,
  expiry_ts,
  deleted_ts,
  SUBSTR(session_id, 1, 20) AS session_id,
  max_idle_minutes,
  SUBSTR(auth_name, 1, 20) AS auth_name,
  SUBSTR(properties_json, 1, 90) AS properties_json
FROM
  sessio
WITH UR;



-- Setup
DELETE FROM sessio;

UPDATE sesctl
SET
  num_attribute_partitions = 3,
  max_authentication_minutes = 60;
 
SELECT active_partition_id, num_attribute_partitions, is_switching, max_idle_minutes, max_authentication_minutes FROM sesctl;

    ACTIVE_PARTITION_ID NUM_ATTRIBUTE_PARTITIONS IS_SWITCHING MAX_IDLE_MINUTES MAX_AUTHENTICATION_MINUTES
    ------------------- ------------------------ ------------ ---------------- --------------------------
    A                                          3            0               10                         60
    
      1 record(s) selected.



-- PROCEDURE add_session(p_session_id VARCHAR(60), p_session_config session_config)

-- Test 1a: Add unauthenticated session.
-- Expected result:
--   * Session created in partition A with CREATED_TS and LAST_ACCESSED_TS set to current time.
--   * ATTRIBUTE_PARTITION_NUM between 0 and 2.
--   * AUTH_NAME and LAST_AUTHENTICATED_TS set NULL.
--   * EXPIRY_TS set to current time plus SESCTL.MAX_IDLE_MINUTES.
--   * PROPERTIES_JSON set to empty document.

CREATE OR REPLACE VARIABLE test.session_config control.session_config;

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.add_session('session_1', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-01-30-03.19.30.365749
    
      1 record(s) selected.
    
      Return Status = 0

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 -                   session_1                           - -                    {}                                                                                        
    
      1 record(s) selected.

-- Test 1b: Add same session.
-- Expected result:
--   * Rejection with error (you cannot add same session twice).
--   * Session data unchanged.

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.add_session('session_1', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-01-30-03.20.41.787955
    
      1 record(s) selected.
    
    SQL0438N  Application raised error or warning with diagnostic text: "Session 
    already exists".  SQLSTATE=72001

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 -                   session_1                           - -                    {}                                                                                        
    
      1 record(s) selected.

-- Test 1c: Add authenticated session with JSON properties.
-- Expected result:
--   * Session created in partition A with CREATED_TS, LAST_ACCESSED_TS and LAST_AUTHENTICATED_TS set to current time.
--   * ATTRIBUTE_PARTITION_NUM incrementing by one between 0 and 2; then resetting to 0;
--   * AUTH_NAME contains authenticated user name.
--   * EXPIRY_TS set to current time plus SESCTL.MAX_IDLE_MINUTES.
--   * PROPERTIES_JSON set to empty document.

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.auth_name = 'davidj';
SET test.session_config.properties_json = '{"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}';

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.add_session('session_2', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-01-30-03.21.15.328387
    
      1 record(s) selected.

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 -                   session_1                           - -                    {}                                                                                        
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
    
      2 record(s) selected.

-- Test 1d: Add unauthenticated session with backdated change time and override MAX_IDLE_MINUTES.
-- Expected result:
--   * Session created in partition A with CREATED_TS and LAST_ACCESSED_TS set to backdated time.
--   * ATTRIBUTE_PARTITION_NUM incrementing by one between 0 and 2; then resetting to 0;
--   * AUTH_NAME and LAST_AUTHENTICATED_TS set NULL.
--   * EXPIRY_TS calculated based on backdated time.

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.change_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE - 20 MINUTES;
SET test.session_config.max_idle_minutes = 120;

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.add_session('session_4', test.session_config);
-- Run test query (see top)
    
    1                         
    --------------------------
    2023-01-30-03.22.24.668987
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 -                   session_1                           - -                    {}                                                                                        
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
    
      3 record(s) selected.

-- Test 1e: Add authenticated session with backdated change time and override MAX_IDLE_MINUTES.
-- Expected result:
--   * Session created in partition A with CREATED_TS, LAST_ACCESSED_TS and LAST_AUTHENTICATED_TS set to backdated time.
--   * ATTRIBUTE_PARTITION_NUM incrementing by one between 0 and 2; then resetting to 0;
--   * AUTH_NAME contains authenticated user name.
--   * EXPIRY_TS calculated based on backdated time (override MAX_IDLE_MINUTES > MAX_AUTHENTICATION_MINUTES is permitted).

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.change_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE - 20 MINUTES;
SET test.session_config.auth_name = 'fredas';
SET test.session_config.max_idle_minutes = 120;

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.add_session('session_3', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-01-30-03.24.04.395034
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 -                   session_1                           - -                    {}                                                                                        
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
    
      4 record(s) selected.



-- PROCEDURE remove_session(p_session_id VARCHAR(60))

-- Test 2a: Remove current session.
-- Expected result:
--   * Session DELETED_TS is set to current time.
VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.remove_session('session_1');

    1                         
    --------------------------
    2023-01-30-04.38.12.108784
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.38.12 session_1                           - -                    {}                                                                                        
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 2b: Remove previously removed session.
-- Expected result:
--   * No change.
VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.remove_session('session_1');
    
    1                         
    --------------------------
    2023-01-30-04.39.30.352266
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.38.12 session_1                           - -                    {}                                                                                        
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 2c: Remove non-existent session.
-- Expected result:
--   * No error and no change.
VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.remove_session('session_6');

    1                         
    --------------------------
    2023-01-30-04.41.10.545772
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.38.12 session_1                           - -                    {}                                                                                        
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
    
      4 record(s) selected.



-- PROCEDURE change_session_id(p_session_id VARCHAR(60), p_new_session_id VARCHAR(60))

-- Test 3a: Change current session identifier.
-- Expected result:
--   * Session identifier is changed.
--   * No other data change (does not affect timestamps).

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_id('session_1', 'session_5');
-- Run test query (see top)
    
    1                         
    --------------------------
    2023-01-30-04.22.17.829614
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 -                   session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 3b: Change deleted session.
-- Expected result:
--   * Rejection with error.
--   * Session data unchanged.

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
UPDATE sessio SET deleted_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE WHERE session_id = 'session_5';
CALL control.change_session_id('session_5', 'session_6');
-- Run test query (see top)

    1                         
    --------------------------
    2023-01-30-04.28.55.024551
    
      1 record(s) selected.
    
    DB20000I  The SQL command completed successfully.
    
    SQL0438N  Application raised error or warning with diagnostic text: "Session 
    does not exist".  SQLSTATE=72002

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 3c: Change non-existent session.
-- Expected result:
--   * Rejection with error.
--   * Session data unchanged.

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_id('session_9', 'session_6');
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-05-21.28.02.716613
    
      1 record(s) selected.
    
    SQL0438N  Application raised error or warning with diagnostic text: "Session 
    does not exist".  SQLSTATE=72002

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 3d: Change session identifier to an existing session identifier. 
-- Expected result:
--   * Rejection with error.
--   * Session data unchanged.

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_id('session_2', 'session_3');
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-05-21.30.11.424228
    
      1 record(s) selected.

    SQL0438N  Application raised error or warning with diagnostic text: "Session 
    already exists".  SQLSTATE=72001

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-01-30-03.02.24 -                     2023-01-30-05.02.24 -                   session_4                         120 -                    {}                                                                                        
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.


-- PROCEDURE change_session_config(p_session_id VARCHAR(60), p_session_config session_config)

-- Test 4a: Update unauthenticated session to authenticated, supplying JSON properties.
-- Expected result:
--   * Session LAST_ACCESSED_TS and LAST_AUTHENTICATED_TS set to current time.
--   * AUTH_NAME set to authenticated user name.
--   * EXPIRY_TS set to current time plus SESCTL.MAX_IDLE_MINUTES.
--   * PROPERTIES_JSON set to supplied JSON.

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.auth_name = 'sallyj';
SET test.session_config.properties_json = '{"server":"ubuntu99", "sessionType":"web", "authenticatedBy":["password"]}';

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_config('session_4', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-05-21.51.22.742429
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-02-05-21.51.22 2023-02-05-21.51.22   2023-02-05-22.01.22 -                   session_4                           - sallyj               {"server":"ubuntu99", "sessionType":"web", "authenticatedBy":["password"]}                
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 4b: Update previous authenticated session to different user name.
-- Expected result:
--   * Rejection with error (because you cannot change authenticated user name).

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.auth_name = 'fredf';
SET test.session_config.properties_json = '{"server":"ubuntu99", "sessionType":"web", "authenticatedBy":["password"]}';

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_config('session_4', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-06-04.43.40.134514
    
      1 record(s) selected.
    
    SQL0438N  Application raised error or warning with diagnostic text: "AUTH_NAME 
    cannot be changed".  SQLSTATE=72011

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-02-05-21.51.22 2023-02-05-21.51.22   2023-02-05-22.01.22 -                   session_4                           - sallyj               {"server":"ubuntu99", "sessionType":"web", "authenticatedBy":["password"]}                
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 4c: Re-authenticate session using backdated change time that is more recent than previous update.
-- Expected result:
--   * Session updated with LAST_ACCESSED_TS and LAST_AUTHENTICATED_TS set to backdated time.
--   * EXPIRY_TS calculated based on backdated time.

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.change_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE - 20 MINUTES;
SET test.session_config.auth_name = 'sallyj';

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_config('session_4', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-06-04.48.34.872693
    
      1 record(s) selected.
    
      Return Status = 0
    
SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
-------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
               13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
               13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
               13306 A                                  1 2023-01-30-03.02.24                       0 2023-02-06-04.28.34 2023-02-06-04.28.34   2023-02-06-04.38.34 -                   session_4                           - sallyj               {"server":"ubuntu99", "sessionType":"web", "authenticatedBy":["password"]}                
               13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        

  4 record(s) selected.

-- Test 4d: Re-authenticate session using backdated change time that is older than previous update. Change some JSON properties.
-- Expected result:
--   * LAST_ACCESSED_TS, LAST_AUTHENTICATED_TS and EXPIRY_TS unchanged (you may not set times older than previous).
--   * PROPERTIES_JSON updated.

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.change_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE - 1 HOUR;
SET test.session_config.auth_name = 'sallyj';
SET test.session_config.properties_json = '{"server":"ubuntu102", "sessionType":"app", "authenticatedBy":["fingerprint"]}';

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_config('session_4', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-06-04.59.30.378022
    
      1 record(s) selected.
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-02-06-04.28.34 2023-02-06-04.28.34   2023-02-06-04.38.34 -                   session_4                           - sallyj               {"server":"ubuntu102", "sessionType":"app", "authenticatedBy":["fingerprint"]}            
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 4e: Change deleted session.
-- Expected result:
--   * Rejection with error.
--   * Session data unchanged.

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_config('session_5', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-08-10.24.25.440233
    
      1 record(s) selected.
    
    SQL0438N  Application raised error or warning with diagnostic text: "Session 
    does not exist".  SQLSTATE=72002
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-02-06-04.28.34 2023-02-06-04.28.34   2023-02-06-04.38.34 -                   session_4                           - sallyj               {"server":"ubuntu102", "sessionType":"app", "authenticatedBy":["fingerprint"]}            
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.

-- Test 4f: Change non-existent session.
-- Expected result:
--   * Rejection with error.
--   * Session data unchanged.

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.change_session_config('session_101', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-08-10.26.22.110690
    
      1 record(s) selected.
    
    SQL0438N  Application raised error or warning with diagnostic text: "Session 
    does not exist".  SQLSTATE=72002
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-02-06-04.28.34 2023-02-06-04.28.34   2023-02-06-04.38.34 -                   session_4                           - sallyj               {"server":"ubuntu102", "sessionType":"app", "authenticatedBy":["fingerprint"]}            
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
    
      4 record(s) selected.



-- Partition independence testing

-- Prerequisite: Lock the B partition in a second session: db2 +c "lock table SESSIB in exclusive mode"
--               The lock must be held - do not COMMIT or ROLLBACK!

-- Test 5: Test that all routines operate solely on active partition (partition A).
-- Expected result:
--   * All routine calls complete successfully.
--   * New session row added.

CALL control.add_session('session_50', test.session_config);
CALL control.change_session_id('session_50', 'session_51');
CALL control.change_session_config('session_51', test.session_config);
CALL control.remove_session('session_51');
-- Run test query (see top)

      Return Status = 0

      Return Status = 0

      Return Status = 0

      Return Status = 0

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13305 A                                  0 2023-01-30-03.21.15                       0 2023-01-30-03.21.15 2023-01-30-03.21.15   2023-01-30-03.31.15 -                   session_2                           - davidj               {"server":"ubuntu101", "sessionType":"web", "authenticatedBy":["password", "sms"]}        
                   13307 A                                  2 2023-01-30-03.04.04                       0 2023-01-30-03.04.04 2023-01-30-03.04.04   2023-01-30-04.04.04 -                   session_3                         120 fredas               {}                                                                                        
                   13306 A                                  1 2023-01-30-03.02.24                       0 2023-02-06-04.28.34 2023-02-06-04.28.34   2023-02-06-04.38.34 -                   session_4                           - sallyj               {"server":"ubuntu102", "sessionType":"app", "authenticatedBy":["fingerprint"]}            
                   13304 A                                  2 2023-01-30-03.19.30                       0 2023-01-30-03.19.30 -                     2023-01-30-03.29.30 2023-01-30-04.28.55 session_5                           - -                    {}                                                                                        
                   13841 A                                  2 2023-02-08-10.38.48                       0 2023-02-08-10.38.57 -                     2023-02-08-10.48.57 2023-02-08-10.39.00 session_51                          - -                    {}                                                                                        

      5 record(s) selected.

-- Note: COMMIT in second session to release lock.



-- Partition movement testing

DELETE FROM sessio;

-- Test 6a; Start session switch
-- Expected result:
--   * SESCTL.IS_SWITCHING is set TRUE.
--   * SESCTL.SWITCH_START_TS is set to UTC time that switching started.

SELECT active_partition_id, is_switching, switch_start_ts FROM sesctl;

CALL admin.start_session_switch();
SELECT active_partition_id, is_switching, switch_start_ts FROM sesctl;

    ACTIVE_PARTITION_ID IS_SWITCHING SWITCH_START_TS    
    ------------------- ------------ -------------------
    A                              0 -                  
    
      1 record(s) selected.
    
      Return Status = 0
    
    ACTIVE_PARTITION_ID IS_SWITCHING SWITCH_START_TS    
    ------------------- ------------ -------------------
    A                              1 2023-02-08-10.53.25
    
      1 record(s) selected.

-- Test 6b: New sessions inserted
-- Expected result:
--   * All new sessions are created in partition B.
--   * Behaviour otherwise similar to earlier tests om partition A.

CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.auth_name = 'flintstone';
DELETE FROM sessio;

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CALL control.add_session('session_61', test.session_config);
CALL control.add_session('session_62', test.session_config);
CALL control.add_session('session_63', test.session_config);
CALL control.add_session('session_64', test.session_config);
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-08-10.59.46.265578
    
      1 record(s) selected.
    
      Return Status = 0
    
      Return Status = 0
    
      Return Status = 0
    
      Return Status = 0
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13846 B                                  1 2023-02-08-10.59.46                       0 2023-02-08-10.59.46 2023-02-08-10.59.46   2023-02-08-11.09.46 -                   session_61                          - flintstone           {}                                                                                        
                   13847 B                                  2 2023-02-08-10.59.46                       0 2023-02-08-10.59.46 2023-02-08-10.59.46   2023-02-08-11.09.46 -                   session_62                          - flintstone           {}                                                                                        
                   13848 B                                  0 2023-02-08-10.59.46                       0 2023-02-08-10.59.46 2023-02-08-10.59.46   2023-02-08-11.09.46 -                   session_63                          - flintstone           {}                                                                                        
                   13849 B                                  1 2023-02-08-10.59.46                       0 2023-02-08-10.59.46 2023-02-08-10.59.46   2023-02-08-11.09.46 -                   session_64                          - flintstone           {}                                                                                        
    
      4 record(s) selected.

-- Test 6c: Sessions changed
-- Expected result:
--   * Session session_66 (previously session_61) is moved to partition B.
--   * Session session_62 is moved to partition B.
--   * Other sessions are not moved (Note: By design REMOVE_SESSION does not move data).

  UPDATE sessio SET partition_id = 'A';

VALUES CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
CREATE OR REPLACE VARIABLE test.session_config control.session_config;
SET test.session_config.properties_json = '{"server":"ubuntu60", "sessionType":"web"}';
CALL control.change_session_id('session_61', 'session_66');
CALL control.change_session_config('session_62', test.session_config);
CALL control.remove_session('session_63');
-- Run test query (see top)

    1                         
    --------------------------
    2023-02-08-11.06.34.965410
    
      1 record(s) selected.

      Return Status = 0
    
      Return Status = 0
    
      Return Status = 0

    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_PARTITION_NUM CREATED_TS          ATTRIBUTE_GENERATION_ID LAST_ACCESSED_TS    LAST_AUTHENTICATED_TS EXPIRY_TS           DELETED_TS          SESSION_ID           MAX_IDLE_MINUTES AUTH_NAME            PROPERTIES_JSON                                                                           
    -------------------- ------------ ----------------------- ------------------- ----------------------- ------------------- --------------------- ------------------- ------------------- -------------------- ---------------- -------------------- ------------------------------------------------------------------------------------------
                   13846 B                                  1 2023-02-08-10.59.46                       0 2023-02-08-10.59.46 2023-02-08-10.59.46   2023-02-08-11.09.46 -                   session_66                          - flintstone           {}                                                                                        
                   13847 B                                  2 2023-02-08-10.59.46                       0 2023-02-08-11.06.39 2023-02-08-11.06.39   2023-02-08-11.16.39 -                   session_62                          - flintstone           {"server":"ubuntu60", "sessionType":"web"}                                                
                   13848 A                                  0 2023-02-08-10.59.46                       0 2023-02-08-10.59.46 2023-02-08-10.59.46   2023-02-08-11.09.46 2023-02-08-11.06.39 session_63                          - flintstone           {}                                                                                        
                   13849 A                                  1 2023-02-08-10.59.46                       0 2023-02-08-10.59.46 2023-02-08-10.59.46   2023-02-08-11.09.46 -                   session_64                          - flintstone           {}                                                                                        
    
      4 record(s) selected.

-- Test 6d; End session switch
-- Expected result:
--   * SESCTL.IS_SWITCHING is set FALSE.
--   * SESCTL.SWITCH_START_TS is set NULL.

UPDATE sessio SET partition_id = 'B';
SELECT active_partition_id, is_switching, switch_start_ts FROM sesctl;

    DB20000I  The SQL command completed successfully.
    
    ACTIVE_PARTITION_ID IS_SWITCHING SWITCH_START_TS    
    ------------------- ------------ -------------------
    A                              1 2023-02-08-10.53.25

  1 record(s) selected.

CALL admin.end_session_switch();
SELECT active_partition_id, is_switching, switch_start_ts FROM sesctl;

      Return Status = 0
    
    ACTIVE_PARTITION_ID IS_SWITCHING SWITCH_START_TS    
    ------------------- ------------ -------------------
    B                              0 -                  
    
      1 record(s) selected.
