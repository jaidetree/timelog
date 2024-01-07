DROP FUNCTION IF EXISTS start_task;
DROP FUNCTION IF EXISTS stop_task;

DROP TRIGGER IF EXISTS sessions_updated_at_trigger ON sessions;
DROP TABLE IF EXISTS sessions;

DROP TRIGGER IF EXISTS tasks_updated_at_trigger ON tasks;
DROP TABLE IF EXISTS tasks;

DROP TRIGGER IF EXISTS statuses_updated_at_trigger ON statuses;
DROP TABLE IF EXISTS statuses;

DROP FUNCTION IF EXISTS update_updated_at();
