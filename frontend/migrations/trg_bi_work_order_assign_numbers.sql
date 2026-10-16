trg_bi_work_order_assign_numbers

-- Re-sequence existing request numbers from 1..N.
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

-- Re-sequence existing work-order numbers from 1..N.
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

CREATE OR REPLACE FUNCTION public.trg_bi_work_order_assign_numbers()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  next_req_no BIGINT;
  next_wo_no  BIGINT;
BEGIN
  IF NEW.created_type = 'request' THEN
    IF NEW.req_number IS NULL THEN
      PERFORM pg_advisory_xact_lock(8811001);
      SELECT COALESCE(MAX(req_number), 0) + 1
        INTO next_req_no
        FROM "Work_order"
        WHERE created_type = 'request';
      NEW.req_number := next_req_no;
    END IF;
  ELSE
    IF NEW.wo_number IS NULL THEN
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
  END IF;
  RETURN NEW;
END;
$function$




trg_bu_work_order_assign_numbers

CREATE OR REPLACE FUNCTION public.trg_bu_work_order_assign_numbers()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  next_wo_no BIGINT;
BEGIN
  -- Assign wo_number when request shifts into open workflow and number is still empty.
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
$function$
