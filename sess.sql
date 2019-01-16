sess.sql
Earlier this month
2 Jan

You uploaded an item
SQL
sess.sql
/*
   Name:    sess.sql
   Date:    March 2004
   Author:  John Thomas
   Purpose: Displays sessions, prompts for a Session ID and displays the current SQL.  

   Prerequisites: User must have access to certain V$ tables. Listed below:

grant select on v_$database to jan;
grant select on v_$session to jan;
grant select on v_$process to jan;
grant select on v_$sql to jan;
*/

col first_change# format 999,999,999,999,999

SET TIMING OFF
SET LINESIZE 148
REM SET ECHO OFF
SET LONG 1000
COL name NEW_VALUE dbname NOPRINT
COL datetime NEW_VALUE datetime NOPRINT

SELECT name, TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') datetime
FROM sys.v_$database
/

PROMPT Users connected to &&dbname at &&datetime
PROMPT
PROMPT Alternate sort orders include: p.spid;
PROMPT 
ACCEPT sort_order PROMPT "Enter sort terms (Default: s.status DESC, st.value, s.osuser, s.username, module, s.sid, cpu): " DEFAULT "s.status DESC, st.value, s.osuser, s.username, module, s.sid, cpu"

/*
s.status DESC, 
st.value, -- desc, 
s.osuser, s.username, module, s.sid
--TO_NUMBER(p.spid)
*/
--USERNAME OSUSER    MACHINE         Module/Program                pid     ACTION          STATUS   LOGON_TIME         CPU secs

SET LINES 200
UNDEF sid
COL sid FORMAT 99999
COL username FORMAT A9
COL osuser FORMAT A10
COL machine FORMAT A20 
COL program FORMAT A26 NOPRINT 
COL spid HEADING "pid" FORMAT A7 NEW_VALUE pid
COL client_info FORMAT A10
COL client_identifier FORMAT A10
COL module FORMAT A40 PRINT HEADING "Module/Program"
COL action FORMAT A24 PRINT
COL serial# HEADING "Srlno" FORMAT 99999
COL command_name FORMAT A7 HEADING "Command"
COL cpu FORMAT 999,999 HEADING "CPU secs"

SELECT s.sid, s.serial#, s.username, REPLACE(s.osuser, 'BAILLIEGIFFORD\') osuser, REPLACE(s.machine, 'BAILLIEGIFFORD\') machine,s.program, 
       NVL(REPLACE
       (
       REPLACE
       (
       REPLACE
       ( 
          s.module, 
          'Client Deployment Services', 
          'Cli Depl Serv'
       ), 
       'Warehouse Builder', 
       'OWB'
       ), 
       'Runtime Service', 
       'RT Serv'
       ), 'Prog: ' || s.program) module, 
       p.spid spid, 
       s.action, 
       s.status, s.logon_time,  st.value/100 cpu, 
       REPLACE
       (
          aa.name, 
          'EXECUTE', 
          'EXEC'
       ) command_name
FROM  sys.v_$process p, sys.v_$session s, v$sesstat st, v$statname n, audit_actions aa
WHERE 
/* s.username IS NOT NULL
AND   */
p.addr=s.paddr
AND s.status IN ('ACTIVE', 'INACTIVE')
AND s.sid = st.sid 
AND n.statistic#  = st.statistic#
AND n.name = 'CPU used by this session'
AND s.command = aa.action
ORDER BY &&sort_order
/


ACCEPT sid PROMPT "Enter SID: "

COL sql_text FORMAT A110
COL elapsed_time FORMAT 999,999.99 HEADING "Elapsed Secs"

SET DOC OFF
/*
   Enhanced to detect version of database and not report columns not available in that version
*/

SET DOC ON 

COL rem_for_9i NEW_VALUE rem_for_9i
COL rem_for_8i NEW_VALUE rem_for_8i


SET TERMOUT OFF

SELECT 
   (
       CASE 
          WHEN banner LIKE '%8.1.7%' THEN '--'
          WHEN banner LIKE '%9.2%' THEN ''
          WHEN banner LIKE '%10.2%' THEN ''
       END 
   ) rem_for_8i, 
   (
       CASE 
          WHEN banner LIKE '%8.1.7%' THEN '--'
          WHEN banner LIKE '%9.2%' THEN '--'
          WHEN banner LIKE '%10.2%' THEN ''
       END 
   ) rem_for_9i 
FROM v$version
WHERE banner like 'CORE%'
/

/*
SELECT s.serial#, 
       s.username, p.spid , s.machine, 
       &&rem_for_9i s.sql_id, 
       s.sql_hash_value, 
       &&rem_for_9i s.sql_child_number, 
       q.buffer_gets, q.disk_reads, 
       q.executions, 
       q.rows_processed, 
       &&rem_for_8i q.elapsed_time/1e6 elapsed_time, 
       s.action, 
       CURSOR(SELECT t.sql_text FROM v$sqltext t WHERE q.hash_value  = t.hash_value ORDER BY t.piece) sql_text
FROM  sys.v_$process p, sys.v_$session s, sys.v$sql q
WHERE s.username IS NOT NULL
AND   p.addr = s.paddr 
AND   q.hash_value = s.sql_hash_value
AND   s.sid = &&SID
ORDER BY s.sid

Alternate 9i version

SELECT s.sid, s.serial#,
       s.username, p.spid , s.machine,
       &&rem_for_9i s.sql_id,
       s.sql_hash_value,
       &&rem_for_9i s.sql_child_number,
       q.buffer_gets, q.disk_reads,
       q.executions,
       q.rows_processed,
       &&rem_for_8i ROUND(q.elapsed_time/1e6, 2) elapsed_time,
       &&rem_for_9i ROUND(q.cpu_time/1e6, 2) cpu_time,
       s.action,
       CURSOR(SELECT t.sql_text FROM v$sqltext t WHERE q.hash_value  = t.hash_value ORDER BY t.piece) sql_text
FROM  sys.v_$process p, sys.v_$session s, sys.v$sql q
WHERE
/*
s.username IS NOT NULL
AND   */
p.addr = s.paddr
--AND   q.sql_id = s.sql_id
AND   s.sid = &&SID
--AND s.sql_child_number = q.child_number
and s.sql_hash_value = q.hash_value
ORDER BY s.sid
*/
SET TERMOUT ON

SET VERIFY OFF



SELECT s.sid, s.serial#,
       s.username, p.spid , s.machine,
       &&rem_for_9i s.sql_id,
       s.sql_hash_value,
       &&rem_for_9i s.sql_child_number,
       q.buffer_gets, q.disk_reads,
       q.executions,
       q.rows_processed,
       &&rem_for_8i ROUND(q.elapsed_time/1e6, 2) elapsed_time,
       &&rem_for_9i ROUND(q.cpu_time/1e6, 2) cpu_time,
       s.action,
       CURSOR(SELECT t.sql_text FROM v$sqltext t WHERE q.hash_value  = t.hash_value ORDER BY t.piece) sql_text
FROM  sys.v_$process p, sys.v_$session s, sys.v$sql q
WHERE
/*
s.username IS NOT NULL
AND   */
p.addr = s.paddr
AND   q.sql_id = s.sql_id
AND   s.sid = &&SID
AND s.sql_child_number = q.child_number
ORDER BY s.sid
/



--SET VERIFY ON 



