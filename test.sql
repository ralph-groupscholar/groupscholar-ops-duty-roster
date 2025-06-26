SET search_path TO gs_ops_duty_roster;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM staff) < 5 THEN
    RAISE EXCEPTION 'Expected at least 5 staff rows';
  END IF;
END $$;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM duty_shift) < 10 THEN
    RAISE EXCEPTION 'Expected at least 10 duty shifts';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM duty_shift
    WHERE end_time <= start_time
  ) THEN
    RAISE EXCEPTION 'Invalid shift times detected';
  END IF;
END $$;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM coverage_gap_summary) < 1 THEN
    RAISE EXCEPTION 'Expected at least one coverage gap';
  END IF;
END $$;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM coverage_issue) < 2 THEN
    RAISE EXCEPTION 'Expected coverage issues in seed data';
  END IF;
END $$;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM staff_unavailability) < 3 THEN
    RAISE EXCEPTION 'Expected staff unavailability rows';
  END IF;
END $$;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM assignment_unavailability_conflicts) < 1 THEN
    RAISE EXCEPTION 'Expected assignment conflicts with unavailability';
  END IF;
END $$;
