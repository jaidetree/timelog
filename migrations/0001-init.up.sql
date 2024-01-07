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
    end_time TIMESTAMPTZ DEFAULT NULL
);

CREATE TRIGGER sessions_updated_at_trigger
BEFORE UPDATE ON sessions
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Create a start_task function

CREATE OR REPLACE FUNCTION start_task(p_task_id INTEGER)
RETURNS VOID AS $$
BEGIN
    INSERT INTO sessions (task_id, start_time)
    VALUES (p_task_id, CURRENT_TIMESTAMP);
END;
$$ LANGUAGE plpgsql;

-- Create a stop_task function

CREATE OR REPLACE FUNCTION stop_task(p_task_id INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE sessions
    SET end_time = CURRENT_TIMESTAMP
    WHERE task_id = p_task_id
    AND id = (
        SELECT id
        FROM sessions
        WHERE task_id = p_task_id
        AND end_time IS NULL
        ORDER BY start_time DESC
        LIMIT 1
    );
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
