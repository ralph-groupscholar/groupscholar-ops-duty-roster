SET search_path TO gs_ops_duty_roster;

-- Upcoming coverage gaps
SELECT shift_date, start_time, end_time, region, shift_type, open_slots
FROM coverage_gap_summary
ORDER BY shift_date, start_time;

-- Staff workload for the next two weeks
SELECT full_name, role_title, timezone, upcoming_assignments, weekly_capacity
FROM staff_load_summary
ORDER BY upcoming_assignments DESC, full_name;

-- Duty calendar with assignments
SELECT shift_date, start_time, end_time, region, shift_type, full_name, status
FROM duty_calendar
ORDER BY shift_date, start_time, full_name;

-- Unresolved coverage issues
SELECT ds.shift_date, ds.region, ci.issue_type, ci.severity, ci.description
FROM coverage_issue ci
JOIN duty_shift ds ON ds.shift_id = ci.shift_id
WHERE ci.resolved = false
ORDER BY ds.shift_date, ci.severity DESC;
