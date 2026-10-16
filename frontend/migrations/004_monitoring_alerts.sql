-- ============================================================
-- Migration 004: Monitoring Alerts / Commands  (PostgreSQL)
-- Тоног төхөөрөмжийн хяналтын дохиолол
-- ============================================================

CREATE TABLE IF NOT EXISTS "Monitoring_alerts" (
    id               SERIAL        PRIMARY KEY,

    -- Холбоос
    asset            INT           NOT NULL,   -- Asset.id
    field            INT           NULL,        -- Device_tracking_fields.id
    field_key        VARCHAR(100)  NOT NULL,    -- жишээ: 'fuel_level', 'speed'
    field_name       VARCHAR(255)  NULL,        -- Харуулах нэр

    -- Нөхцөл
    condition        VARCHAR(10)   NOT NULL DEFAULT '>',
                                               -- '>', '<', '>=', '<=', '=', '!='

    -- Босго утга
    threshold_type   VARCHAR(20)   NOT NULL DEFAULT 'custom',
                                               -- 'value1'|'value2'|'value3'|'value4'|'value5'|'custom'
    custom_value     NUMERIC(18,4) NULL,        -- threshold_type='custom' үед ашиглана

    -- Дохиолол илгээх сонголтууд
    notify_popup     SMALLINT      NOT NULL DEFAULT 1,  -- Popup / toaster
    notify_sound     SMALLINT      NOT NULL DEFAULT 0,  -- Дуун дохиолол
    notify_browser   SMALLINT      NOT NULL DEFAULT 0,  -- Browser push notification
    notify_email     SMALLINT      NOT NULL DEFAULT 0,  -- Имэйл
    email_address    VARCHAR(255)  NULL,        -- notify_email=1 үед ашиглана

    -- Дохиолол текст
    alert_message    VARCHAR(500)  NULL,        -- Харуулах мессеж (хоосон бол авт)

    -- Cooldown (дахин дохиох хугацаа)
    cooldown_minutes INT           NOT NULL DEFAULT 30,  -- минутаар

    -- Идэвхтэй эсэх
    is_active        SMALLINT      NOT NULL DEFAULT 1,

    -- Сүүлд дохиосон цаг
    last_triggered   TIMESTAMP     NULL,

    -- Систем
    date_created     TIMESTAMP     NOT NULL DEFAULT NOW(),
    date_updated     TIMESTAMP     NOT NULL DEFAULT NOW(),
    user_created     VARCHAR(36)   NULL,
    user_updated     VARCHAR(36)   NULL
);

-- Индекс
CREATE INDEX IF NOT EXISTS idx_monitoring_alerts_asset  ON "Monitoring_alerts"(asset);
CREATE INDEX IF NOT EXISTS idx_monitoring_alerts_active ON "Monitoring_alerts"(asset, is_active);
