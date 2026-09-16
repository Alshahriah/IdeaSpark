CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE team_status_enum AS ENUM ('pending','approved','rejected');
CREATE TYPE submission_status_enum AS ENUM ('pending_submission','in_review','rejected','accepted');
CREATE TYPE payment_status_enum AS ENUM ('unpaid','paid');
CREATE TYPE payment_txn_status_enum AS ENUM ('created','paid','failed');
CREATE TYPE admin_role_enum AS ENUM ('super_admin','evaluator','volunteer');

CREATE TABLE tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE departments (
  code VARCHAR(16) PRIMARY KEY,
  label VARCHAR(128) UNIQUE NOT NULL
);
CREATE TABLE admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  role admin_role_enum NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_name TEXT UNIQUE NOT NULL,
  track_id UUID REFERENCES tracks(id) ON DELETE SET NULL,
  lead_user_id TEXT UNIQUE NOT NULL,
  status team_status_enum NOT NULL DEFAULT 'pending',
  payment_status payment_status_enum,
  reviewed_by UUID REFERENCES admins(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT teams_name_not_blank CHECK (length(trim(team_name)) > 0)
);
CREATE INDEX teams_track_id_idx ON teams(track_id);
CREATE INDEX teams_status_idx ON teams(status);
CREATE INDEX teams_payment_status_idx ON teams(payment_status);

CREATE TABLE members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  ra_number TEXT UNIQUE NOT NULL,
  net_id TEXT UNIQUE NOT NULL,
  phone_number TEXT NOT NULL,
  department_code VARCHAR(16) NOT NULL REFERENCES departments(code),
  faculty_name TEXT NOT NULL,
  faculty_phone TEXT NOT NULL,
  faculty_email TEXT NOT NULL,
  is_leader BOOLEAN NOT NULL DEFAULT FALSE,
  attendance_code VARCHAR(128) UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX one_leader_per_team ON members(team_id) WHERE is_leader = TRUE;
CREATE INDEX members_team_id_idx ON members(team_id);
CREATE INDEX members_department_idx ON members(department_code);

CREATE TABLE evaluation_rounds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  sequence_no INTEGER UNIQUE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  results_published BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX evaluation_rounds_one_active_unique
  ON evaluation_rounds(is_active) WHERE is_active = TRUE;

CREATE TABLE submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  round_id UUID NOT NULL REFERENCES evaluation_rounds(id) ON DELETE CASCADE,
  title TEXT,
  description TEXT,
  drive_link TEXT,
  status submission_status_enum NOT NULL DEFAULT 'pending_submission',
  submitted_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES admins(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  remarks TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT submissions_team_round_unique UNIQUE (team_id, round_id)
);
CREATE INDEX submissions_team_id_idx ON submissions(team_id);
CREATE INDEX submissions_round_id_idx ON submissions(round_id);
CREATE INDEX submissions_status_idx ON submissions(status);
CREATE INDEX submissions_reviewed_by_idx ON submissions(reviewed_by);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID UNIQUE NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  razorpay_order_id TEXT UNIQUE NOT NULL,
  razorpay_payment_id TEXT UNIQUE,
  razorpay_signature TEXT,
  amount NUMERIC(10,2) NOT NULL,
  status payment_txn_status_enum NOT NULL DEFAULT 'created',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at TIMESTAMPTZ,
  CONSTRAINT payments_amount_nonnegative CHECK (amount >= 0),
  CONSTRAINT payments_paid_requires_provider_id CHECK (status <> 'paid' OR razorpay_payment_id IS NOT NULL)
);
CREATE INDEX payments_status_idx ON payments(status);
CREATE INDEX payments_razorpay_payment_id_idx ON payments(razorpay_payment_id);

CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  event_date DATE NOT NULL,
  scanned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  scanned_by UUID REFERENCES admins(id) ON DELETE SET NULL,
  CONSTRAINT attendance_member_date_unique UNIQUE (member_id, event_date)
);
CREATE INDEX attendance_event_date_idx ON attendance(event_date);
CREATE INDEX attendance_scanned_by_idx ON attendance(scanned_by);

CREATE TABLE scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  round_id UUID NOT NULL REFERENCES evaluation_rounds(id) ON DELETE CASCADE,
  evaluator_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  score NUMERIC(5,2) NOT NULL,
  remarks TEXT,
  innovation NUMERIC(5,2),
  feasibility NUMERIC(5,2),
  impact NUMERIC(5,2),
  presentation NUMERIC(5,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT scores_score_range CHECK (score >= 0 AND score <= 100),
  CONSTRAINT scores_team_round_evaluator_unique UNIQUE (team_id, round_id, evaluator_id)
);
CREATE INDEX scores_team_id_idx ON scores(team_id);
CREATE INDEX scores_round_id_idx ON scores(round_id);
CREATE INDEX scores_evaluator_id_idx ON scores(evaluator_id);

CREATE TABLE event_config (
  id INTEGER PRIMARY KEY DEFAULT 1,
  registration_deadline TIMESTAMPTZ NOT NULL,
  submission_deadline TIMESTAMPTZ NOT NULL,
  registration_fee NUMERIC(10,2) NOT NULL,
  results_published BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT event_config_singleton CHECK (id = 1),
  CONSTRAINT event_config_deadline_order CHECK (registration_deadline <= submission_deadline),
  CONSTRAINT event_config_fee_nonnegative CHECK (registration_fee >= 0)
);

CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX announcements_created_at_idx ON announcements(created_at);

CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id TEXT,
  action VARCHAR(64) NOT NULL,
  target_type VARCHAR(32) NOT NULL,
  target_id TEXT NOT NULL,
  meta TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX audit_log_target_idx ON audit_log(target_type, target_id);
CREATE INDEX audit_log_actor_idx ON audit_log(actor_user_id);
CREATE INDEX audit_log_created_at_idx ON audit_log(created_at);

CREATE OR REPLACE FUNCTION enforce_team_member_limit()
RETURNS TRIGGER AS $$
DECLARE
  current_count INTEGER;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(NEW.team_id::text));
  SELECT count(*) INTO current_count FROM members WHERE team_id = NEW.team_id;
  IF current_count >= 4 THEN
    RAISE EXCEPTION 'Team is full (maximum 4 members)';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER team_member_limit_trigger
BEFORE INSERT ON members
FOR EACH ROW
EXECUTE FUNCTION enforce_team_member_limit();

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

CREATE TRIGGER prevent_paid_team_roster_changes_trigger
BEFORE INSERT OR DELETE OR UPDATE OF team_id ON members
FOR EACH ROW
EXECUTE FUNCTION prevent_paid_team_roster_changes();
