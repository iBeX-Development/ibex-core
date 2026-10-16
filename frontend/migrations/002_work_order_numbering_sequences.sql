-- Migration: Separate request/work-order numbering sequences (PostgreSQL)
-- Purpose:
-- 1) Keep request numbering in req_number  (created_type = 'request' rows)
-- 2) Keep work-order numbering in wo_number (open/pm/pdm/inspection + accepted requests)
-- 3) Re-sequence ALL existing rows from 1..N (not just empty ones)
-- 4) Auto-assign numbers on insert and on request -> open-style transitions

ALTER TABLE "Work_order"
  ADD COLUMN IF NOT EXISTS req_number VARCHAR(50);

-- ── Convert wo_number and req_number to BIGINT for correct numeric sorting ─────
ALTER TABLE "Work_order" DROP CONSTRAINT IF EXISTS work_order_wo_number_unique;
ALTER TABLE "Work_order" ALTER COLUMN req_number DROP DEFAULT;
ALTER TABLE "Work_order"
  ALTER COLUMN req_number TYPE BIGINT
  USING CASE WHEN req_number ~ '^[0-9]+$' THEN req_number::BIGINT ELSE NULL END;
ALTER TABLE "Work_order" ALTER COLUMN wo_number DROP DEFAULT;
ALTER TABLE "Work_order"
  ALTER COLUMN wo_number TYPE BIGINT
  USING CASE WHEN wo_number::text ~ '^[0-9]+$' THEN wo_number::BIGINT ELSE NULL END;

-- ── Re-sequence: assign req_number 1,2,3,… to every request row ───────────────
WITH req_ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY id) AS new_req_no
  FROM "Work_order"
  WHERE created_type = 'request'
)
UPDATE "Work_order" w
SET req_number = r.new_req_no
FROM req_ranked r
WHERE w.id = r.id;

-- ── Re-sequence: assign wo_number 1,2,3,… to every work-order row ─────────────
WITH wo_ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY id) AS new_wo_no
  FROM "Work_order"
  WHERE created_type <> 'request'
     OR type = 2
     OR COALESCE(is_accepted, FALSE) = TRUE
     OR action_status IN (2, 5)
)
UPDATE "Work_order" w
SET wo_number = r.new_wo_no
FROM wo_ranked r
WHERE w.id = r.id;

-- ── Triggers ──────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS bi_work_order_assign_numbers ON "Work_order";
DROP TRIGGER IF EXISTS bu_work_order_assign_numbers ON "Work_order";
DROP FUNCTION IF EXISTS trg_bi_work_order_assign_numbers();
DROP FUNCTION IF EXISTS trg_bu_work_order_assign_numbers();

CREATE FUNCTION trg_bi_work_order_assign_numbers()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  next_req_no BIGINT;
  next_wo_no  BIGINT;
BEGIN
  IF NEW.created_type = 'request' THEN
    IF COALESCE(NEW.req_number::text, '') = '' THEN
      PERFORM pg_advisory_xact_lock(8811001);

      SELECT COALESCE(
        MAX(
          CASE
            WHEN req_number::text ~ '^[0-9]+$' THEN req_number::bigint
            ELSE NULL
          END
        ),
        0
      ) + 1
      INTO next_req_no
      FROM "Work_order"
      WHERE created_type = 'request';

      NEW.req_number := next_req_no;
    END IF;
  ELSE
    IF COALESCE(NEW.wo_number::text, '') = '' THEN
      PERFORM pg_advisory_xact_lock(8811002);

      SELECT COALESCE(
        MAX(
          CASE
            WHEN wo_number::text ~ '^[0-9]+$' THEN wo_number::bigint
            ELSE NULL
          END
        ),
        0
      ) + 1
      INTO next_wo_no
      FROM "Work_order"
      WHERE created_type <> 'request'
         OR type = 2
         OR COALESCE(is_accepted, FALSE) = TRUE
         OR action_status IN (2, 5);

      NEW.wo_number := next_wo_no;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE FUNCTION trg_bu_work_order_assign_numbers()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  next_wo_no BIGINT;
BEGIN
  -- Assign wo_number when a request shifts into open workflow and number is still empty.
  IF NEW.wo_number IS NULL
     AND (
       NEW.created_type <> 'request'
       OR NEW.type = 2
       OR COALESCE(NEW.is_accepted, FALSE) = TRUE
       OR NEW.action_status IN (2, 5)
     ) THEN
    PERFORM pg_advisory_xact_lock(8811002);
    SELECT COALESCE(MAX(wo_number), 0) + 1
      INTO next_wo_no
      FROM "Work_order"
      WHERE created_type <> 'request'
         OR type = 2
         OR COALESCE(is_accepted, FALSE) = TRUE
         OR action_status IN (2, 5);
    NEW.wo_number := next_wo_no;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER bi_work_order_assign_numbers
BEFORE INSERT ON "Work_order"
FOR EACH ROW
EXECUTE FUNCTION trg_bi_work_order_assign_numbers();

CREATE TRIGGER bu_work_order_assign_numbers
BEFORE UPDATE ON "Work_order"
FOR EACH ROW
EXECUTE FUNCTION trg_bu_work_order_assign_numbers();
