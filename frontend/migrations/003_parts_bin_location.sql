-- Migration: Create Parts_Bin_location table
-- Purpose: Store assignment of Transaction_parts records to Bin_location
-- Each row = one Transaction_parts item assigned to a specific Bin_location

CREATE TABLE IF NOT EXISTS "Parts_Bin_location" (
  "id"                BIGSERIAL PRIMARY KEY,
  "status"            VARCHAR(50)  NOT NULL DEFAULT 'active',
  "date_created"      TIMESTAMPTZ  DEFAULT NOW(),
  "date_updated"      TIMESTAMPTZ  DEFAULT NOW(),
  "user_created"      UUID         REFERENCES "directus_users"("id") ON DELETE SET NULL,
  "user_updated"      UUID         REFERENCES "directus_users"("id") ON DELETE SET NULL,
  "transaction_parts" BIGINT       NOT NULL REFERENCES "Transaction_parts"("id") ON DELETE CASCADE,
  "bin_location"      BIGINT       NOT NULL REFERENCES "Bin_location"("id") ON DELETE CASCADE,
  "part"              BIGINT       REFERENCES "Parts"("id") ON DELETE SET NULL,
  "qty"               NUMERIC(18,4) NOT NULL DEFAULT 0,
  CONSTRAINT uq_parts_bin UNIQUE ("transaction_parts", "bin_location")
);

-- Index for lookups by transaction_parts
CREATE INDEX IF NOT EXISTS idx_parts_bin_location_tp
  ON "Parts_Bin_location" ("transaction_parts");

-- Index for lookups by bin_location
CREATE INDEX IF NOT EXISTS idx_parts_bin_location_bl
  ON "Parts_Bin_location" ("bin_location");
