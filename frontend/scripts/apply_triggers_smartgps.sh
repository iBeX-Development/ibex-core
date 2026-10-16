#!/bin/bash
# Apply Work_order triggers to smartgps_db

: "${PGPASSWORD:?Set PGPASSWORD before running this script}"
export PGPASSWORD
psql \
  -h 124.158.124.19 \
  -p 5432 \
  -U smartgps \
  -d smartgps_db \
  -f "$(dirname "$0")/../migrations/002_work_order_numbering_sequences.sql"
