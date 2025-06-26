CREATE SCHEMA IF NOT EXISTS gs_ops_duty_roster;
SET search_path TO gs_ops_duty_roster;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS staff (
  staff_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL UNIQUE,
  role_title text NOT NULL,
  timezone text NOT NULL,
  active boolean NOT NULL DEFAULT true,
  start_date date NOT NULL,
  weekly_capacity integer NOT NULL CHECK (weekly_capacity >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS staff_unavailability (
  unavailability_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES staff(staff_id) ON DELETE CASCADE,
  start_date date NOT NULL,
  end_date date NOT NULL,
  reason text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS staff_unavailability_unique
  ON staff_unavailability(staff_id, start_date, end_date, reason);

CREATE TABLE IF NOT EXISTS duty_shift (
  shift_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  region text NOT NULL,
  shift_type text NOT NULL,
  required_staff integer NOT NULL CHECK (required_staff > 0),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (shift_date, start_time, end_time, region, shift_type)
);

CREATE TABLE IF NOT EXISTS shift_assignment (
  assignment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_id uuid NOT NULL REFERENCES duty_shift(shift_id) ON DELETE CASCADE,
  staff_id uuid NOT NULL REFERENCES staff(staff_id),
  status text NOT NULL CHECK (status IN ('assigned', 'confirmed', 'completed', 'missed', 'swapped')),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS shift_assignment_unique
  ON shift_assignment(shift_id, staff_id);

CREATE TABLE IF NOT EXISTS coverage_issue (
  issue_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_id uuid NOT NULL REFERENCES duty_shift(shift_id) ON DELETE CASCADE,
  issue_type text NOT NULL CHECK (issue_type IN ('unfilled', 'late_swap', 'no_show', 'capacity_risk')),
  severity integer NOT NULL CHECK (severity BETWEEN 1 AND 5),
  description text NOT NULL,
  resolved boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  UNIQUE (shift_id, issue_type)
);

CREATE TABLE IF NOT EXISTS handoff_note (
  note_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_id uuid NOT NULL REFERENCES duty_shift(shift_id) ON DELETE CASCADE,
  author_staff_id uuid REFERENCES staff(staff_id),
  note_body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE VIEW shift_coverage_status AS
SELECT
  s.shift_id,
  s.shift_date,
  s.start_time,
  s.end_time,
  s.region,
  s.shift_type,
  s.required_staff,
  COUNT(a.assignment_id) FILTER (
    WHERE a.status IN ('assigned', 'confirmed', 'completed')
  ) AS active_assignments,
  s.required_staff - COUNT(a.assignment_id) FILTER (
    WHERE a.status IN ('assigned', 'confirmed', 'completed')
  ) AS open_slots
FROM duty_shift s
LEFT JOIN shift_assignment a ON a.shift_id = s.shift_id
GROUP BY
  s.shift_id,
  s.shift_date,
  s.start_time,
  s.end_time,
  s.region,
  s.shift_type,
  s.required_staff;

CREATE OR REPLACE VIEW coverage_gap_summary AS
SELECT *
FROM shift_coverage_status
WHERE open_slots > 0
ORDER BY shift_date, start_time;

CREATE OR REPLACE VIEW staff_load_summary AS
SELECT
  st.staff_id,
  st.full_name,
  st.role_title,
  st.timezone,
  COUNT(sa.assignment_id) FILTER (
    WHERE ds.shift_date >= CURRENT_DATE
      AND ds.shift_date < CURRENT_DATE + 14
      AND sa.status IN ('assigned', 'confirmed')
  ) AS upcoming_assignments,
  st.weekly_capacity
FROM staff st
LEFT JOIN shift_assignment sa ON sa.staff_id = st.staff_id
LEFT JOIN duty_shift ds ON ds.shift_id = sa.shift_id
GROUP BY st.staff_id, st.full_name, st.role_title, st.timezone, st.weekly_capacity;

CREATE OR REPLACE VIEW weekly_capacity_utilization AS
SELECT
  st.staff_id,
  st.full_name,
  DATE_TRUNC('week', ds.shift_date)::date AS week_start,
  COUNT(sa.assignment_id) FILTER (
    WHERE sa.status IN ('assigned', 'confirmed', 'completed')
  ) AS assignments,
  st.weekly_capacity,
  COUNT(sa.assignment_id) FILTER (
    WHERE sa.status IN ('assigned', 'confirmed', 'completed')
  ) - st.weekly_capacity AS capacity_overage,
  ROUND(
    COUNT(sa.assignment_id) FILTER (
      WHERE sa.status IN ('assigned', 'confirmed', 'completed')
    )::numeric / NULLIF(st.weekly_capacity, 0),
    2
  ) AS utilization_ratio,
  COUNT(sa.assignment_id) FILTER (
    WHERE sa.status IN ('assigned', 'confirmed', 'completed')
  ) > st.weekly_capacity AS over_capacity
FROM staff st
LEFT JOIN shift_assignment sa ON sa.staff_id = st.staff_id
LEFT JOIN duty_shift ds ON ds.shift_id = sa.shift_id
WHERE st.active = true
  AND ds.shift_date >= CURRENT_DATE
  AND ds.shift_date < CURRENT_DATE + 14
GROUP BY st.staff_id, st.full_name, st.weekly_capacity, DATE_TRUNC('week', ds.shift_date);

CREATE OR REPLACE VIEW assignment_unavailability_conflicts AS
SELECT
  st.full_name,
  ds.shift_date,
  ds.start_time,
  ds.end_time,
  ds.region,
  ds.shift_type,
  su.start_date AS unavailability_start,
  su.end_date AS unavailability_end,
  su.reason,
  sa.status
FROM shift_assignment sa
JOIN duty_shift ds ON ds.shift_id = sa.shift_id
JOIN staff st ON st.staff_id = sa.staff_id
JOIN staff_unavailability su ON su.staff_id = st.staff_id
WHERE ds.shift_date BETWEEN su.start_date AND su.end_date
  AND sa.status IN ('assigned', 'confirmed');

CREATE OR REPLACE VIEW duty_calendar AS
SELECT
  ds.shift_date,
  ds.start_time,
  ds.end_time,
  ds.region,
  ds.shift_type,
  st.full_name,
  sa.status
FROM duty_shift ds
LEFT JOIN shift_assignment sa ON sa.shift_id = ds.shift_id
LEFT JOIN staff st ON st.staff_id = sa.staff_id
ORDER BY ds.shift_date, ds.start_time, st.full_name;
