-- =====================================================
-- TASK COMPLETION REPORT QUERIES
-- =====================================================
-- Run TASK_REPORT_SETUP.sql FIRST before using these queries

-- =====================================================
-- BASIC REPORT QUERY - Main report with all details
-- =====================================================
SELECT 
  task_title,
  completion_time_formatted AS time,
  days_since_completion AS days,
  floor,
  staff_name AS "who got the bin",
  trashcan_name,
  completion_date
FROM task_completion_report
ORDER BY completion_time DESC;

-- =====================================================
-- SIMPLIFIED REPORT - Just the essentials
-- =====================================================
SELECT 
  completion_time_formatted AS "Time",
  days_since_completion AS "Days",
  floor AS "Floor",
  staff_name AS "Staff Member",
  trashcan_name AS "Trashcan"
FROM task_completion_report
ORDER BY completion_time DESC;

-- =====================================================
-- RECENT COMPLETIONS (Last 30 days)
-- =====================================================
SELECT 
  task_title,
  completion_time_formatted,
  days_since_completion,
  floor,
  staff_name,
  trashcan_name
FROM task_completion_report
WHERE completion_time >= NOW() - INTERVAL '30 days'
ORDER BY completion_time DESC;

-- =====================================================
-- COMPLETIONS BY STAFF MEMBER
-- =====================================================
SELECT 
  staff_name,
  COUNT(*) AS total_completions,
  AVG(days_since_completion) AS avg_days_since_completion,
  MAX(completion_time) AS last_completion
FROM task_completion_report
GROUP BY staff_name
ORDER BY total_completions DESC;

-- =====================================================
-- COMPLETIONS BY FLOOR
-- =====================================================
SELECT 
  floor,
  COUNT(*) AS total_completions,
  COUNT(DISTINCT staff_id) AS unique_staff_count
FROM task_completion_report
GROUP BY floor
ORDER BY floor;

-- =====================================================
-- DAILY REPORT SUMMARY
-- =====================================================
SELECT 
  completion_date,
  COUNT(*) AS tasks_completed,
  COUNT(DISTINCT staff_id) AS staff_count,
  COUNT(DISTINCT floor) AS floors_covered
FROM task_completion_report
GROUP BY completion_date
ORDER BY completion_date DESC;

-- =====================================================
-- TODAY'S COMPLETIONS
-- =====================================================
SELECT 
  completion_time_only AS "Time",
  floor AS "Floor",
  staff_name AS "Staff",
  trashcan_name AS "Trashcan"
FROM task_completion_report
WHERE completion_date = CURRENT_DATE
ORDER BY completion_time;


