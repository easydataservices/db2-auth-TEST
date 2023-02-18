-- Queries used after each test
SELECT
  session_internal_id,
  SUBSTR(session_id, 1, 20) AS session_id,
  attribute_partition_num,
  attribute_generation_id
FROM
  sessio
ORDER BY 1
WITH UR;

SELECT
  session_internal_id,
  partition_id,
  SUBSTR(attribute_name, 1, 15) AS attribute_name,
  attribute_partition_num,
  generation_id,
  SUBSTR(object, 1, 40) AS object
FROM
  sesatt
ORDER BY 1
WITH UR;

-- Setup
DELETE FROM sessio;
DELETE FROM sesatt;
CREATE OR REPLACE VARIABLE test.session_config control.session_config;
CALL control.add_session('session_11', test.session_config);
CALL control.add_session('session_12', test.session_config);
CALL control.add_session('session_13', test.session_config);
CALL control.add_session('session_14', test.session_config);
CALL control.add_session('session_15', test.session_config);

SELECT session_id, session_internal_id FROM sessio ORDER BY session_id;

    SESSION_ID                                                   SESSION_INTERNAL_ID 
    ------------------------------------------------------------ --------------------
    session_11                                                                  13863
    session_12                                                                  13864
    session_13                                                                  13865
    session_14                                                                  13866
    session_15                                                                  13867
    
      5 record(s) selected.

SELECT attribute_active_partition_id, num_attribute_partitions, attribute_is_switching FROM sesctl;

    ATTRIBUTE_ACTIVE_PARTITION_ID NUM_ATTRIBUTE_PARTITIONS ATTRIBUTE_IS_SWITCHING
    ----------------------------- ------------------------ ----------------------
    A                                                    3                      0
    
      1 record(s) selected.



-- PROCEDURE save_attributes(p_session_id VARCHAR(60), p_session_attributes session_attribute_array)

-- Test 1a: Save session attributes for sessions with with 0, 1 and 2 attributes.
-- Expected result:
--   * Session session_11 with no attribuutes is unchanged.
--   * Session session_12 has 1 attribute saved.
--   * Session session_13 has 2 attributes saved.

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
CALL attributes.save_attributes('session_11', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = CAST('red' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_12', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = CAST('green' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
SET test.session_attribute.attribute_name = 'product';
SET test.session_attribute.object = CAST('hair dye' AS VARBINARY);
SET test.session_attribute_array[2] = test.session_attribute;
CALL attributes.save_attributes('session_13', test.session_attribute_array);

-- Run test queries (see top)
    
    SESSION_INTERNAL_ID  SESSION_ID           ATTRIBUTE_PARTITION_NUM ATTRIBUTE_GENERATION_ID
    -------------------- -------------------- ----------------------- -----------------------
                   13863 session_11                                 0                       0
                   13864 session_12                                 1                       1
                   13865 session_13                                 2                       1
                   13866 session_14                                 0                       0
                   13867 session_15                                 1                       0
    
      5 record(s) selected.
    
    SESSION_INTERNAL_ID  ATTRIBUTE_NAME                 ATTRIBUTE_PARTITION_NUM GENERATION_ID OBJECT                                                                             
    -------------------- ------------------------------ ----------------------- ------------- -----------------------------------------------------------------------------------
                   13864 colour                                               1             1 x'72656400000000000000000000000000000000000000000000000000000000000000000000000000'
                   13865 colour                                               2             1 x'677265656E0000000000000000000000000000000000000000000000000000000000000000000000'
                   13865 product                                              2             1 x'68616972206479650000000000000000000000000000000000000000000000000000000000000000'
    
      3 record(s) selected.

-- Test 1b: Save same attributes and values.
-- Expected result:
--   * Successful completion.
--   * Session and attribute data unchanged.

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
CALL attributes.save_attributes('session_11', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = CAST('red' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_12', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = CAST('green' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
SET test.session_attribute.attribute_name = 'product';
SET test.session_attribute.object = CAST('hair dye' AS VARBINARY);
SET test.session_attribute_array[2] = test.session_attribute;
CALL attributes.save_attributes('session_13', test.session_attribute_array);

-- Run test queries (see top)

    SESSION_INTERNAL_ID  SESSION_ID           ATTRIBUTE_PARTITION_NUM ATTRIBUTE_GENERATION_ID
    -------------------- -------------------- ----------------------- -----------------------
                   13863 session_11                                 0                       0
                   13864 session_12                                 1                       1
                   13865 session_13                                 2                       1
                   13866 session_14                                 0                       0
                   13867 session_15                                 1                       0
    
      5 record(s) selected.
    
    SESSION_INTERNAL_ID  ATTRIBUTE_NAME                 ATTRIBUTE_PARTITION_NUM GENERATION_ID OBJECT                                                                             
    -------------------- ------------------------------ ----------------------- ------------- -----------------------------------------------------------------------------------
                   13864 colour                                               1             1 x'72656400000000000000000000000000000000000000000000000000000000000000000000000000'
                   13865 colour                                               2             1 x'677265656E0000000000000000000000000000000000000000000000000000000000000000000000'
                   13865 product                                              2             1 x'68616972206479650000000000000000000000000000000000000000000000000000000000000000'
    
      3 record(s) selected.



-- Test 2: Save attribute changes: session_12 changed attribute object; session_13 one attribute deleted; session_14 one new attribute 
-- Expected result:
--   * All attribute changes succeed (respectively updated, deleted and inserted).
--   * All three sessions have exactly one attribute.
--   * All three sessions have GENERATION_ID incremented by 1.

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = CAST('blue' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_12', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = NULL;
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_13', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = CAST('yellow' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_14', test.session_attribute_array);

-- Run test queries (see top)

    SESSION_INTERNAL_ID  SESSION_ID           ATTRIBUTE_PARTITION_NUM ATTRIBUTE_GENERATION_ID
    -------------------- -------------------- ----------------------- -----------------------
                   13863 session_11                                 0                       0
                   13864 session_12                                 1                       2
                   13865 session_13                                 2                       2
                   13866 session_14                                 0                       1
                   13867 session_15                                 1                       0
    
      5 record(s) selected.
    
    SESSION_INTERNAL_ID  ATTRIBUTE_NAME                 ATTRIBUTE_PARTITION_NUM GENERATION_ID OBJECT                                                                             
    -------------------- ------------------------------ ----------------------- ------------- -----------------------------------------------------------------------------------
                   13864 colour                                               1             2 x'626C7565000000000000000000000000000000000000000000000000000000000000000000000000'
                   13865 product                                              2             1 x'68616972206479650000000000000000000000000000000000000000000000000000000000000000'
                   13866 colour                                               0             1 x'79656C6C6F7700000000000000000000000000000000000000000000000000000000000000000000'
    
      3 record(s) selected.



-- Partition independence testing

-- Prerequisite: Lock the B attribute partition in a second session: db2 +c "lock table SESATB in exclusive mode"
--               The lock must be held - do not COMMIT or ROLLBACK!

-- Test 3: Test that all routines operate solely on active attribute partition (partition A).
-- Expected result:
--   * All routine calls complete successfully.

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'product';
SET test.session_attribute.object = CAST('yoghurt' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_13', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'colour';
SET test.session_attribute.object = NULL;
SET test.session_attribute_array[1] = test.session_attribute;
SET test.session_attribute.attribute_name = 'product';
SET test.session_attribute.object = CAST('jelly' AS VARBINARY);
SET test.session_attribute_array[2] = test.session_attribute;
CALL attributes.save_attributes('session_14', test.session_attribute_array);

-- Run test queries (see top)

      Return Status = 0

      Return Status = 0

      Return Status = 0

    SESSION_INTERNAL_ID  SESSION_ID           ATTRIBUTE_PARTITION_NUM ATTRIBUTE_GENERATION_ID
    -------------------- -------------------- ----------------------- -----------------------
                   13863 session_11                                 0                       0
                   13864 session_12                                 1                       2
                   13865 session_13                                 2                       2
                   13866 session_14                                 0                       2
                   13867 session_15                                 1                       0
    
      5 record(s) selected.
    
    SESSION_INTERNAL_ID  ATTRIBUTE_NAME                 ATTRIBUTE_PARTITION_NUM GENERATION_ID OBJECT                                                                             
    -------------------- ------------------------------ ----------------------- ------------- -----------------------------------------------------------------------------------
                   13864 colour                                               1             2 x'626C7565000000000000000000000000000000000000000000000000000000000000000000000000'
                   13865 product                                              2             1 x'68616972206479650000000000000000000000000000000000000000000000000000000000000000'
                   13866 colour                                               0             2 x'6F72616E676500000000000000000000000000000000000000000000000000000000000000000000'
                   13866 product                                              0             2 x'6A656C6C790000000000000000000000000000000000000000000000000000000000000000000000'
    
      4 record(s) selected.

-- Note: COMMIT in second session to release lock.



-- Partition movement testing

-- Test 4a; Start attribute switch
-- Expected result:
--   * SESCTL.ATTRIBUTE_IS_SWITCHING is set TRUE.
--   * SESCTL.ATTRIBUTE_SWITCH_START_TS is set to UTC time that switching started.

SELECT attribute_active_partition_id, attribute_is_switching, attribute_switch_start_ts FROM sesctl;

CALL admin.start_attribute_switch();
SELECT attribute_active_partition_id, attribute_is_switching, attribute_switch_start_ts FROM sesctl;

    ATTRIBUTE_ACTIVE_PARTITION_ID ATTRIBUTE_IS_SWITCHING ATTRIBUTE_SWITCH_START_TS
    ----------------------------- ---------------------- -------------------------
    A                                                  0 -                        
    
      1 record(s) selected.

      Return Status = 0

    ATTRIBUTE_ACTIVE_PARTITION_ID ATTRIBUTE_IS_SWITCHING ATTRIBUTE_SWITCH_START_TS
    ----------------------------- ---------------------- -------------------------
    A                                                  1 2023-02-12-19.08.41      
    
      1 record(s) selected.

-- Test 4b: Save attribute changes: session_13 changed attribute object; session_14 one attribute deleted; session_15 one new attribute 
-- Expected result:
--   * All attribute changes succeed (respectively updated, deleted and inserted).
--   * All three sessions have exactly one attribute.
--   * All three sessions have GENERATION_ID incremented by 1.

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'product';
SET test.session_attribute.object = CAST('muesli' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_13', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'product';
SET test.session_attribute.object = NULL;
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_14', test.session_attribute_array);

CREATE OR REPLACE VARIABLE test.session_attribute attributes.session_attribute;
CREATE OR REPLACE VARIABLE test.session_attribute_array attributes.session_attribute_array;
SET test.session_attribute.attribute_name = 'product';
SET test.session_attribute.object = CAST('muesli' AS VARBINARY);
SET test.session_attribute_array[1] = test.session_attribute;
CALL attributes.save_attributes('session_15', test.session_attribute_array);

    -- Run test queries (see top)
    
    SESSION_INTERNAL_ID  SESSION_ID           ATTRIBUTE_PARTITION_NUM ATTRIBUTE_GENERATION_ID
    -------------------- -------------------- ----------------------- -----------------------
                   13863 session_11                                 0                       0
                   13864 session_12                                 1                       2
                   13865 session_13                                 2                       4
                   13866 session_14                                 0                       4
                   13867 session_15                                 1                       1
    
      5 record(s) selected.
    
    SESSION_INTERNAL_ID  PARTITION_ID ATTRIBUTE_NAME  ATTRIBUTE_PARTITION_NUM GENERATION_ID OBJECT                                                                             
    -------------------- ------------ --------------- ----------------------- ------------- -----------------------------------------------------------------------------------
                   13864 A            colour                                1             2 x'626C7565000000000000000000000000000000000000000000000000000000000000000000000000'
                   13865 B            product                               2             4 x'6D7565736C6900000000000000000000000000000000000000000000000000000000000000000000'
                   13867 B            product                               1             1 x'6D7565736C6900000000000000000000000000000000000000000000000000000000000000000000'
    
      3 record(s) selected.

-- Test 4c; End attribute session switch
-- Expected result:
--   * SESCTL.ATTRIBUTE_IS_SWITCHING is set FALSE.
--   * SESCTL.ATTRIBUTE_SWITCH_START_TS is set NULL.

SELECT attribute_active_partition_id, attribute_is_switching, attribute_switch_start_ts FROM sesctl;

CALL admin.end_attribute_switch();
SELECT attribute_active_partition_id, attribute_is_switching, attribute_switch_start_ts FROM sesctl;

    ATTRIBUTE_ACTIVE_PARTITION_ID ATTRIBUTE_IS_SWITCHING ATTRIBUTE_SWITCH_START_TS
    ----------------------------- ---------------------- -------------------------
    A                                                  1 2023-02-12-19.08.41      
    
      1 record(s) selected.

      Return Status = 0

    ATTRIBUTE_ACTIVE_PARTITION_ID ATTRIBUTE_IS_SWITCHING ATTRIBUTE_SWITCH_START_TS
    ----------------------------- ---------------------- -------------------------
    B                                                  0 -                        
    
      1 record(s) selected.
