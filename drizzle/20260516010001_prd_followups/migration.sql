-- IdeaSpark incremental migration:
-- 1) remove obsolete member Google fields / department enum
-- 2) make submissions round-specific
-- 3) remove manual-payment compatibility fields
-- 4) enforce paid-roster lock at the DB boundary

DROP INDEX IF EXISTS one_leader_per_team;
CREATE UNIQUE INDEX IF NOT EXISTS one_leader_per_team
  ON members(team_id) WHERE is_leader = TRUE;

ALTER TABLE members
  DROP COLUMN IF EXISTS email,
  DROP COLUMN IF EXISTS google_id;

-- The application now uses the departments table exclusively.
ALTER TABLE members
  DROP CONSTRAINT IF EXISTS members_department_code_fkey;
ALTER TABLE members
  ADD CONSTRAINT members_department_code_fkey
  FOREIGN KEY (department_code) REFERENCES departments(code);

ALTER TABLE submissions
  ADD COLUMN IF NOT EXISTS round_id UUID;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM submissions WHERE round_id IS NULL)
     AND NOT EXISTS (SELECT 1 FROM evaluation_rounds)
  THEN
    RAISE EXCEPTION
      'Cannot migrate existing submissions to round-specific records: evaluation_rounds is empty';
  END IF;
END $$;

UPDATE submissions
SET round_id = (
  SELECT id
  FROM evaluation_rounds
  ORDER BY sequence_no
  LIMIT 1
)
WHERE round_id IS NULL;

ALTER TABLE submissions
  ALTER COLUMN round_id SET NOT NULL;

ALTER TABLE submissions
  DROP CONSTRAINT IF EXISTS submissions_team_id_key;

ALTER TABLE submissions
  DROP CONSTRAINT IF EXISTS submissions_round_id_fkey;

ALTER TABLE submissions
  ADD CONSTRAINT submissions_round_id_fkey
  FOREIGN KEY (round_id) REFERENCES evaluation_rounds(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS submissions_team_round_unique
  ON submissions(team_id, round_id);

DROP INDEX IF EXISTS submissions_status_idx;
CREATE INDEX IF NOT EXISTS submissions_status_idx ON submissions(status);
CREATE INDEX IF NOT EXISTS submissions_team_id_idx ON submissions(team_id);
CREATE INDEX IF NOT EXISTS submissions_round_id_idx ON submissions(round_id);
CREATE INDEX IF NOT EXISTS submissions_reviewed_by_idx ON submissions(reviewed_by);

ALTER TABLE payments
  DROP COLUMN IF EXISTS txn_ref,
  DROP COLUMN IF EXISTS screenshot_url,
  DROP COLUMN IF EXISTS reviewed_by,
  DROP COLUMN IF EXISTS reviewed_at;

CREATE OR REPLACE FUNCTION prevent_paid_team_roster_changes()
RETURNS TRIGGER AS $$
DECLARE
  locked BOOLEAN;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT payment_status = 'paid' INTO locked
    FROM teams WHERE id = NEW.team_id FOR SHARE;
  ELSE
    SELECT payment_status = 'paid' INTO locked
    FROM teams WHERE id = OLD.team_id FOR SHARE;
  END IF;

  IF COALESCE(locked, FALSE) THEN
    RAISE EXCEPTION 'Roster is locked after payment';
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.team_id IS DISTINCT FROM OLD.team_id THEN
    SELECT payment_status = 'paid' INTO locked
    FROM teams WHERE id = NEW.team_id FOR SHARE;

    IF COALESCE(locked, FALSE) THEN
      RAISE EXCEPTION 'Destination roster is locked after payment';
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_paid_team_roster_changes_trigger ON members;

CREATE TRIGGER prevent_paid_team_roster_changes_trigger
BEFORE INSERT OR DELETE OR UPDATE OF team_id ON members
FOR EACH ROW
EXECUTE FUNCTION prevent_paid_team_roster_changes();

DROP TYPE IF EXISTS department_enum;
