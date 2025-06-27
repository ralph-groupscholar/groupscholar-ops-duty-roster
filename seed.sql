SET search_path TO gs_ops_duty_roster;

INSERT INTO staff (full_name, role_title, timezone, active, start_date, weekly_capacity)
VALUES
  ('Avery Johnson', 'Program Operations Lead', 'America/New_York', true, '2023-04-10', 4),
  ('Maya Chen', 'Scholar Support Manager', 'America/Chicago', true, '2022-09-12', 3),
  ('Rafael Ortiz', 'Operations Associate', 'America/Denver', true, '2024-01-08', 3),
  ('Nia Patel', 'Community Success Lead', 'America/Los_Angeles', true, '2021-06-21', 4),
  ('Quinn Brooks', 'Operations Analyst', 'America/New_York', true, '2025-05-03', 2)
ON CONFLICT (full_name) DO NOTHING;

INSERT INTO staff_unavailability (staff_id, start_date, end_date, reason)
SELECT staff_id, '2026-02-12', '2026-02-13', 'PTO - conference travel'
FROM staff
WHERE full_name = 'Nia Patel'
ON CONFLICT DO NOTHING;

INSERT INTO staff_unavailability (staff_id, start_date, end_date, reason)
SELECT staff_id, '2026-02-10', '2026-02-10', 'Medical appointment'
FROM staff
WHERE full_name = 'Maya Chen'
ON CONFLICT DO NOTHING;

INSERT INTO staff_unavailability (staff_id, start_date, end_date, reason)
SELECT staff_id, '2026-02-11', '2026-02-11', 'Training day'
FROM staff
WHERE full_name = 'Quinn Brooks'
ON CONFLICT DO NOTHING;

INSERT INTO duty_shift (shift_date, start_time, end_time, region, shift_type, required_staff, notes)
VALUES
  ('2026-02-09', '08:00', '12:00', 'US-East', 'primary', 1, 'Weekly kickoff coverage'),
  ('2026-02-09', '12:00', '16:00', 'US-West', 'primary', 1, 'West region midday coverage'),
  ('2026-02-10', '09:00', '13:00', 'US-Central', 'primary', 1, 'Scholar check-in support'),
  ('2026-02-10', '13:00', '17:00', 'US-East', 'secondary', 1, 'Partner outreach window'),
  ('2026-02-11', '08:00', '12:00', 'US-West', 'primary', 1, 'Onboarding follow-ups'),
  ('2026-02-11', '12:00', '16:00', 'US-East', 'primary', 1, 'Review escalation coverage'),
  ('2026-02-12', '09:00', '13:00', 'US-Central', 'primary', 1, 'Application deadline support'),
  ('2026-02-12', '13:00', '17:00', 'US-West', 'secondary', 1, 'Evening prep coverage'),
  ('2026-02-13', '08:00', '12:00', 'US-East', 'primary', 1, 'Final deadline day'),
  ('2026-02-13', '12:00', '16:00', 'US-Central', 'primary', 1, 'Decision communications')
ON CONFLICT (shift_date, start_time, end_time, region, shift_type) DO NOTHING;

INSERT INTO shift_assignment (shift_id, staff_id, status, confirmed_at)
SELECT ds.shift_id, st.staff_id, 'confirmed', now()
FROM duty_shift ds
JOIN staff st ON st.full_name = 'Avery Johnson'
WHERE ds.shift_date = '2026-02-09'
  AND ds.start_time = '08:00'
  AND ds.region = 'US-East'
  AND ds.shift_type = 'primary'
ON CONFLICT DO NOTHING;

INSERT INTO shift_assignment (shift_id, staff_id, status, confirmed_at)
SELECT ds.shift_id, st.staff_id, 'confirmed', now()
FROM duty_shift ds
JOIN staff st ON st.full_name = 'Nia Patel'
WHERE ds.shift_date = '2026-02-09'
  AND ds.start_time = '12:00'
  AND ds.region = 'US-West'
  AND ds.shift_type = 'primary'
ON CONFLICT DO NOTHING;

INSERT INTO shift_assignment (shift_id, staff_id, status, confirmed_at)
SELECT ds.shift_id, st.staff_id, 'assigned', NULL
FROM duty_shift ds
JOIN staff st ON st.full_name = 'Maya Chen'
WHERE ds.shift_date = '2026-02-10'
  AND ds.start_time = '09:00'
  AND ds.region = 'US-Central'
  AND ds.shift_type = 'primary'
ON CONFLICT DO NOTHING;

INSERT INTO shift_assignment (shift_id, staff_id, status, confirmed_at)
SELECT ds.shift_id, st.staff_id, 'assigned', NULL
FROM duty_shift ds
JOIN staff st ON st.full_name = 'Quinn Brooks'
WHERE ds.shift_date = '2026-02-10'
  AND ds.start_time = '13:00'
  AND ds.region = 'US-East'
  AND ds.shift_type = 'secondary'
ON CONFLICT DO NOTHING;

INSERT INTO shift_assignment (shift_id, staff_id, status, confirmed_at)
SELECT ds.shift_id, st.staff_id, 'confirmed', now()
FROM duty_shift ds
JOIN staff st ON st.full_name = 'Rafael Ortiz'
WHERE ds.shift_date = '2026-02-11'
  AND ds.start_time = '08:00'
  AND ds.region = 'US-West'
  AND ds.shift_type = 'primary'
ON CONFLICT DO NOTHING;

INSERT INTO shift_swap_request (shift_id, requester_staff_id, proposed_staff_id, status, reason, notes)
SELECT ds.shift_id, requester.staff_id, proposed.staff_id, 'pending', 'Overlapping cohort visit', 'Prefer swap by end of week'
FROM duty_shift ds
JOIN staff requester ON requester.full_name = 'Maya Chen'
JOIN staff proposed ON proposed.full_name = 'Rafael Ortiz'
WHERE ds.shift_date = '2026-02-10'
  AND ds.start_time = '09:00'
  AND ds.region = 'US-Central'
  AND ds.shift_type = 'primary'
ON CONFLICT DO NOTHING;

INSERT INTO coverage_issue (shift_id, issue_type, severity, description, resolved)
SELECT ds.shift_id, 'unfilled', 4, 'Coverage gap detected 48 hours before shift', false
FROM duty_shift ds
WHERE ds.shift_date = '2026-02-12'
  AND ds.start_time = '13:00'
  AND ds.region = 'US-West'
  AND ds.shift_type = 'secondary'
ON CONFLICT DO NOTHING;

INSERT INTO coverage_issue (shift_id, issue_type, severity, description, resolved)
SELECT ds.shift_id, 'capacity_risk', 3, 'Two overlapping deadlines require extra prep', false
FROM duty_shift ds
WHERE ds.shift_date = '2026-02-13'
  AND ds.start_time = '08:00'
  AND ds.region = 'US-East'
  AND ds.shift_type = 'primary'
ON CONFLICT DO NOTHING;

INSERT INTO handoff_note (shift_id, author_staff_id, note_body)
SELECT ds.shift_id, st.staff_id, 'Escalations likely from Midwest cohort; prioritize FAFSA follow-ups.'
FROM duty_shift ds
JOIN staff st ON st.full_name = 'Avery Johnson'
WHERE ds.shift_date = '2026-02-11'
  AND ds.start_time = '12:00'
  AND ds.region = 'US-East'
  AND ds.shift_type = 'primary'
  AND NOT EXISTS (
    SELECT 1 FROM handoff_note hn
    WHERE hn.shift_id = ds.shift_id
      AND hn.note_body LIKE 'Escalations likely%'
  );

INSERT INTO shift_assignment (shift_id, staff_id, status, confirmed_at)
SELECT ds.shift_id, st.staff_id, 'confirmed', now()
FROM duty_shift ds
JOIN staff st ON st.full_name = 'Nia Patel'
WHERE ds.shift_date = '2026-02-12'
  AND ds.start_time = '13:00'
  AND ds.region = 'US-West'
  AND ds.shift_type = 'secondary'
ON CONFLICT DO NOTHING;
