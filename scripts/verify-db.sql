SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'tracks','departments','admins','teams','members','submissions',
    'payments','attendance','evaluation_rounds','scores','event_config',
    'announcements','audit_log'
  )
ORDER BY table_name;

SELECT indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'one_leader_per_team',
    'attendance_member_date_unique',
    'evaluation_rounds_one_active_unique',
    'scores_team_round_evaluator_unique'
  )
ORDER BY indexname;
