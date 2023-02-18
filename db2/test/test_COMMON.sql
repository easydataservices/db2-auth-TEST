-- FUNCTION new_partition_id(p_is_switching BOOLEAN, p_partition_id CHAR(1)) RETURNS CHAR(1)

-- Test 1a: When P_IS_SWITCHING is false, function must return P_PARTITION_ID unchanged.

VALUES common.new_partition_id(FALSE, 'A');

VALUES common.new_partition_id(FALSE, 'B');

    1
    -
    A
    
      1 record(s) selected.
    
    1
    -
    B
    
      1 record(s) selected.

-- Test 1b: When P_IS_SWITCHING is true, function must return the other partition.

VALUES common.new_partition_id(TRUE, 'A');

VALUES common.new_partition_id(TRUE, 'B');

    1
    -
    B
    
      1 record(s) selected.
    
    1
    -
    A
    
      1 record(s) selected.

VALUES common.new_partition_id(NULL, 'B');



-- FUNCTION expiry_ts(p_max_idle_minutes SMALLINT, p_last_accessed_ts TIMESTAMP(0), p_last_authenticated_ts TIMESTAMP(0)) RETURNS TIMESTAMP(0)

UPDATE sesctl SET max_authentication_minutes = 60;

SELECT max_idle_minutes, max_authentication_minutes FROM sesctl;

    MAX_IDLE_MINUTES MAX_AUTHENTICATION_MINUTES
    ---------------- --------------------------
                  10                         60
    
      1 record(s) selected.

-- Test 2a: No P_MAX_IDLE_MINUTES override. Validate that default calculations of expiry based on:
--   (1) P_LAST_ACCESSED_TS only - result must be time plus 10 minutes.
--   (2) P_LAST_AUTHENTICATED_TS only - result must be time plus 60 minutes.
--   (3) P_LAST_ACCESSED_TS and P_LAST_AUTHENTICATED_TS - result must be earlier of (1) and (2).

VALUES
  (1, CURRENT_TIMESTAMP(0), common.expiry_ts(NULL, CURRENT_TIMESTAMP, NULL)),
  (2, CURRENT_TIMESTAMP(0), common.expiry_ts(NULL, NULL, CURRENT_TIMESTAMP)),
  (3, CURRENT_TIMESTAMP(0), common.expiry_ts(NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP));

    1           2                   3                  
    ----------- ------------------- -------------------
              1 2023-01-30-09.26.39 2023-01-30-09.36.39
              2 2023-01-30-09.26.39 2023-01-30-10.26.39
              3 2023-01-30-09.26.39 2023-01-30-09.36.39
    
      3 record(s) selected.

-- Test 2b: P_MAX_IDLE_MINUTES override 120 minutes. Validate that default calculations of expiry based on:
--   (1) P_LAST_ACCESSED_TS only - result must be time plus 120 minutes.
--   (2) P_LAST_AUTHENTICATED_TS only - result must be time plus 60 minutes.
--   (3) P_LAST_ACCESSED_TS and P_LAST_AUTHENTICATED_TS - result must be earlier of (1) and (2).

VALUES
  (1, CURRENT_TIMESTAMP(0), common.expiry_ts(120, CURRENT_TIMESTAMP, NULL)),
  (2, CURRENT_TIMESTAMP(0), common.expiry_ts(120, NULL, CURRENT_TIMESTAMP)),
  (3, CURRENT_TIMESTAMP(0), common.expiry_ts(120, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP));

    1           2                   3                  
    ----------- ------------------- -------------------
              1 2023-01-30-09.26.47 2023-01-30-11.26.47
              2 2023-01-30-09.26.47 2023-01-30-10.26.47
              3 2023-01-30-09.26.47 2023-01-30-10.26.47
    
      3 record(s) selected.



-- PROCEDURE check_json(p_json VARCHAR(32000))
-- Note: This procedure uses Db2 JSON_OBJECT function. These tests are therefore just validation of expected behaviour of
-- a supplied component.

-- Test 3a: Procedure accepts correct JSON documents.
--   (1) A sequence of name/value pairs
--   (2) An array
--   (3) Nested JSON
--   (4) Empty object
--   (5) Empty array

CALL common.check_json('{"name":"John", "age":30, "car":null, "married":true}');

CALL common.check_json('["apples", null, false, 20]');

CALL common.check_json('{"department":{"name":"Accounts", "location":"Auckland"}, "people":[{"name":"John", "age":30}, {"name":"Jo", "age":52}]}');

CALL common.check_json('{}');

CALL common.check_json('[]');

      Return Status = 0
    
      Return Status = 0
    
      Return Status = 0
    
      Return Status = 0
    
      Return Status = 0

-- Test 3b: Procedure rejects incorrect JSON documents.
--   (1) A sequence of name/value pairs containing a duplicate key
--   (2) An unquoted string value
--   (3) An unquoted name

CALL common.check_json('{"name":"John", "age":30, "age":null, "married":true}');

CALL common.check_json('{"name":John, "age":30, "married":true}');

CALL common.check_json('{"name":"John", age:30, "married":true}');

    SQL16407N  JSON object has non-unique keys.  SQLSTATE=22037

    SQL16402N  JSON data is not valid.  SQLSTATE=22032
    
    SQL16402N  JSON data is not valid.  SQLSTATE=22032
