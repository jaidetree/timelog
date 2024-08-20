BEGIN;

ALTER DEFAULT PRIVILEGES FOR ROLE timelog
  GRANT SELECT, INSERT, UPDATE ON TABLES TO timelog;

ALTER DEFAULT PRIVILEGES FOR ROLE timelog
  GRANT USAGE ON SEQUENCES TO timelog;

-- Create a reusable update_updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create statuses table and trigger

CREATE TABLE statuses (
    id SERIAL PRIMARY KEY,
    status VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


CREATE TRIGGER statuses_updated_at_trigger
BEFORE UPDATE ON statuses
FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- Create tasks table and trigger

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    task_name VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    status_id INTEGER REFERENCES statuses(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER tasks_updated_at_trigger
BEFORE UPDATE ON tasks
FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- Create sessions table and trigger

CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    is_active BOOLEAN DEFAULT TRUE,
    task_id INTEGER REFERENCES tasks(id),
    start_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMPTZ DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER sessions_updated_at_trigger
BEFORE UPDATE ON sessions
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Look up task id given a task name

CREATE OR REPLACE FUNCTION get_task_id_by_name(p_task_name VARCHAR)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT id
    FROM tasks
    WHERE task_name = p_task_name
  );
END;
$$ LANGUAGE plpgsql;

-- Create a start_task function

CREATE OR REPLACE FUNCTION start_task(p_task_name VARCHAR)
RETURNS sessions AS $$
DECLARE
  task_row RECORD;
  session_record sessions;
BEGIN
  -- Look for any ongoing sessions for an active task
  SELECT *
  INTO task_row
  FROM tasks t
  INNER JOIN sessions s ON t.id = s.task_id
  WHERE s.end_time IS NULL
    AND s.is_active = TRUE
    AND t.is_active = TRUE
  LIMIT 1;

  -- If an ongoing session was found, throw an error with hint
  IF task_row.id IS NOT NULL THEN
    RAISE EXCEPTION 'Task % \"%\" is still in progress. Action refused.',
      task_row.id, task_row.task_name;
  ELSE
    -- Start the session
    INSERT INTO sessions (task_id)
    VALUES (get_task_id_by_name(p_task_name))
    RETURNING * INTO session_record;
  END IF;

  RETURN session_record;
END;
$$ LANGUAGE plpgsql;

-- Create a stop_task function

CREATE OR REPLACE FUNCTION stop_task(p_task_name VARCHAR)
RETURNS tasks AS $$
DECLARE
  target_task_id INTEGER;
  updated_task tasks;
BEGIN
  SELECT get_task_id_by_name(p_task_name) INTO target_task_id;
  -- Update task using task_id
  UPDATE sessions
  SET end_time = CURRENT_TIMESTAMP
  WHERE task_id = target_task_id
  AND id = (
      SELECT id
      FROM sessions
      WHERE task_id = target_task_id
      AND end_time IS NULL
      ORDER BY start_time DESC
      LIMIT 1
  );

  SELECT * FROM tasks
  INTO updated_task
  WHERE id = target_task_id;

  RETURN updated_task;
END;
$$ LANGUAGE plpgsql;

-- Complete a task and end a session

CREATE OR REPLACE FUNCTION complete_task(p_task_name VARCHAR)
RETURNS tasks AS $$
DECLARE
  target_task_id INTEGER;
  updated_task tasks;
  task_row RECORD;
BEGIN
  SELECT get_task_id_by_name(p_task_name) INTO target_task_id;

  -- Look for any ongoing sessions for an active task
  SELECT
    t.*,
    s.id AS session_id,
    s.task_id,
    s.start_time,
    s.end_time
  INTO task_row
  FROM tasks t
  INNER JOIN sessions s ON t.id = s.task_id
  WHERE
    s.task_id = target_task_id
    AND s.is_active = true
    AND t.is_active = true
  ORDER BY s.end_time DESC
  LIMIT 1;

  IF task_row.end_time IS NOT NULL THEN
    RAISE EXCEPTION 'Task % \"%\" already completed. Action refused.',
      task_row.id, task_row.task_name;
  END IF;

  IF task_row.id IS NULL THEN
    RAISE EXCEPTION 'Task % \"%\" not found. Action refused.',
      task_row.id, task_row.task_name;
  END IF;

  PERFORM stop_task(p_task_name);
  UPDATE tasks
  SET status_id = (
    SELECT id
    FROM statuses
    WHERE status = 'Complete'
  )
  WHERE id = get_task_id_by_name(p_task_name)
  RETURNING * INTO updated_task;

  RETURN updated_task;
END;
$$ LANGUAGE plpgsql;

-- Permissions

GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO timelog;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO timelog;

COMMIT;

BEGIN;

INSERT INTO statuses (status, is_default)
VALUES
  ('To Do', true),
  ('Deferred', false),
  ('In Progress', false),
  ('Complete', false),
  ('Archived', false);


COMMIT;
