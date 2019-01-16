-- Used for the SHOW ERRORS command
COLUMN LINE/COL FORMAT A8
COLUMN ERROR    FORMAT A65  WORD_WRAPPED

-- Used for the SHOW SGA command
COLUMN name_col_plus_show_sga FORMAT a24

-- Defaults for SHOW PARAMETERS
COLUMN name_col_plus_show_param FORMAT a36 HEADING NAME
COLUMN value_col_plus_show_param FORMAT a30 HEADING VALUE

-- Defaults for SET AUTOTRACE EXPLAIN report
COLUMN id_plus_exp FORMAT 990 HEADING i
COLUMN parent_id_plus_exp FORMAT 990 HEADING p
COLUMN plan_plus_exp FORMAT a120
COLUMN object_node_plus_exp FORMAT a8
COLUMN other_tag_plus_exp FORMAT a29
COLUMN other_plus_exp FORMAT a44
SET TERMOUT OFF

ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINESIZE 200

SET ECHO OFF 

-- Set up the Session ID, Serial#, Username and host name at the command prompt
-- Only works for tables with select permissions on V$SESSION and V$INSTANCE
-- Generates prompt like: JM@(hodev:MIS):553:10381>

COL sid NEW_VALUE sid
COL serial# NEW_VALUE serialno
COL host_name NEW_VALUE host_name
COL username NEW_VALUE username
COL instance_name NEW_VALUE instance_name

DEF username="UNKNOWN"
DEF HOST_NAME = "UNKNOWN"
DEF SID="SID?"
DEF SERIALNO = "SER?"
COL PLAN_TABLE_OUTPUT FORMAT A150

SELECT sys_context('USERENV', 'SESSION_USER') username, LTRIM(sid) sid, LTRIM(serial#) serial#, i.host_name, i.instance_name
FROM v$session, v$instance i
WHERE sid in (
SELECT sid
FROM v$mystat
WHERE rownum < 2
)
/

SET SQLPROMPT '&USERNAME.@(&HOST_NAME.:&INSTANCE_NAME):&SID.,&SERIALno> '

SET TERMOUT ON 
SET FEEDBACK ON 
set serveroutput on size 1000000

SET TIMING ON 

DEFINE _EDITOR=vi

SCRIPT prompt.js
