# GroupScholar Ops Duty Roster

GroupScholar Ops Duty Roster is a PostgreSQL-first schema and query set for managing on-call and operational duty coverage. It centralizes staff capacity, duty shifts, coverage issues, and handoff notes so program operations can see weekly coverage gaps and workload balance in seconds.

## Features
- Structured tables for staff, shifts, assignments, coverage issues, and handoff notes
- Coverage gap and staff load views for fast weekly audits
- Staff unavailability tracking and conflict detection for coverage planning
- Weekly capacity utilization view for over-capacity alerts
- Shift swap request queue and pending-swap coverage impact view
- Seed data for realistic February 2026 duty planning scenarios
- Simple SQL-based tests to validate integrity assumptions

## Tech
- SQL (PostgreSQL)

## Setup
1. Ensure the PostgreSQL client is available:
   - `brew install libpq`
   - Use `$(brew --prefix libpq)/bin/psql` if `psql` is not on PATH.
2. Export production connection variables (do not commit credentials):
   - `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`
3. Apply schema and seed data:
   - `make schema`
   - `make seed`
4. Run tests:
   - `make test`

## Notes
- The schema uses the `gs_ops_duty_roster` schema to avoid collisions.
- Seed data is safe to re-run thanks to conflict guards on unique keys.
- Do not use the production database for local dev workloads; only run targeted schema and seed updates.
