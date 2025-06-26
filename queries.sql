SET search_path TO gs_ops_duty_roster;

-- Upcoming coverage gaps
SELECT shift_date, start_time, end_time, region, shift_type, open_slots
FROM coverage_gap_summary
ORDER BY shift_date, start_time;

-- Staff workload for the next two weeks
SELECT full_name, role_title, timezone, upcoming_assignments, weekly_capacity
FROM staff_load_summary
ORDER BY upcoming_assignments DESC, full_name;

-- Weekly capacity utilization overview (next two weeks)
SELECT full_name, week_start, assignments, weekly_capacity, capacity_overage, utilization_ratio, over_capacity
FROM weekly_capacity_utilization
ORDER BY week_start, utilization_ratio DESC, full_name;

-- Assignments that conflict with staff unavailability
SELECT full_name, shift_date, start_time, end_time, region, shift_type, unavailability_start, unavailability_end, reason, status
FROM assignment_unavailability_conflicts
ORDER BY shift_date, start_time, full_name;

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
