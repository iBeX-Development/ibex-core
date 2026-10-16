
const axios = require("axios");

// process-ийн ажиллах туршид cron tick-үүдийн хооронд хадгалагдана
// (24 цагийн дотор дахин дахин login хийхээс сэргийлнэ).
let smartgpsToken = null;
let smartgpsTokenExpiresAt = 0;

const SMARTGPS_TOKEN_TTL_MS = 24 * 60 * 60 * 1000;
const SMARTGPS_TOKEN_SAFETY_BUFFER_MS = 5 * 60 * 1000;

async function getSmartgpsToken(loginUrl) {
  if (
    smartgpsToken &&
    Date.now() < smartgpsTokenExpiresAt - SMARTGPS_TOKEN_SAFETY_BUFFER_MS
  ) {
    return smartgpsToken;
  }

  const username = process.env.CORE_UPSTREAM_USERNAME;
  const password = process.env.CORE_UPSTREAM_PASSWORD;
  if (!username || !password) {
    throw new Error('Core upstream integration disabled: required credentials are not configured');
  }
  const loginResponse = await axios.post(loginUrl, { username, password });

  const token = loginResponse.data.access;

  if (!token) {
    throw new Error(
      `Login хариунд access token олдсонгүй: ${JSON.stringify(loginResponse.data)}`,
    );
  }

  smartgpsToken = token;
  smartgpsTokenExpiresAt = Date.now() + SMARTGPS_TOKEN_TTL_MS;

  console.log(
    `[smartgps-poll] Шинэ token авлаа, хүчинтэй хугацаа: ${new Date(smartgpsTokenExpiresAt).toISOString()}`,
  );

  return token;
}

// ─── Monitoring Alert Checker (15 минут тутам) ──────────────────────────────
// scripts/monitoring-alert-checker.js-ийн логикийг Directus process дотор
// ItemsService-ээр (HTTP/DIRECTUS_TOKEN шаардлагагүйгээр) ажиллуулна.

const MONITORING_ALERT_EMAIL_FLOW_URL =
  process.env.MONITORING_ALERT_FLOW_URL ||
  `http://localhost:${process.env.PORT || 8056}/flows/trigger/d831f177-8490-4329-b257-fee2a7820a6d`;

function checkAlertCondition(value, condition, threshold) {
  switch (condition) {
    case ">":
      return value > threshold;
    case "<":
      return value < threshold;
    case ">=":
      return value >= threshold;
    case "<=":
      return value <= threshold;
    case "=":
      return value === threshold;
    case "!=":
      return value !== threshold;
    default:
      return false;
  }
}

// Frontend-тэй (OwnMonitoring.vue/AssetOwnLiveData.vue) адил дүрмээр
// json_data-аас утгыг тодорхойлно: эхлээд top-level, дараа нь sensors.*,
// эцэст нь хуучин WISE flat багана fallback.
function resolveMonitoringSensorValue(reading, fieldKey) {
  if (!reading) return undefined;
  const data = reading.json_data;
  if (data && typeof data === "object") {
    if (data[fieldKey] !== null && data[fieldKey] !== undefined) {
      return Number(data[fieldKey]);
    }
    if (
      data.sensors &&
      typeof data.sensors === "object" &&
      data.sensors[fieldKey] !== null &&
      data.sensors[fieldKey] !== undefined
    ) {
      return Number(data.sensors[fieldKey]);
    }
  }
  if (
    ["temperature", "vibration_x", "vibration_y", "vibration_z"].includes(
      fieldKey,
    )
  ) {
    return Number(reading[fieldKey]);
  }
  return undefined;
}

// is_mode='rawdata' талбаруудын утгыг Asset_field_data_json-оос (хамгийн
// сүүлийн импортолсон бичлэг) авна.
async function fetchLatestAssetFieldValues(
  assetFieldDataService,
  assetId,
  companyId,
) {
  const rows = await assetFieldDataService.readByQuery({
    filter: {
      asset: { _eq: assetId },
      company_id: { _eq: companyId },
    },
    sort: ["-date_created"],
    limit: 1,
    fields: ["field_values"],
  });

  if (!rows || rows.length === 0) return {};

  const raw = rows[0]?.field_values;
  if (!raw) return {};

  const parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
  const result = {};
  for (const [k, v] of Object.entries(parsed)) {
    result[k] = Number(v);
  }
  return result;
}

// is_mode='livedata' талбарын device_id (Device_tracking_fields.code)-аар нь
// Sensor_reading-ийн хамгийн сүүлийн бичлэгийг татна.
async function fetchLatestSensorReadingByDeviceId(sensorReadingService, deviceId) {
  const rows = await sensorReadingService.readByQuery({
    filter: { device_id: { _eq: String(deviceId) } },
    sort: ["-date_created"],
    limit: 1,
    fields: ["json_data", "temperature", "vibration_x", "vibration_y", "vibration_z"],
  });

  return rows && rows.length > 0 ? rows[0] : null;
}

// ЗӨВХӨН is_show=1 (Settings/OwnDeviceSettings.vue-ээр идэвхжүүлсэн)
// Device_tracking_fields мөрүүдийг is_mode/code-тэй нь татна. Ижил
// field_key давхцвал ЭХНИЙ (сортлогдсон) мөрийг нь авна.
async function fetchActiveMonitoringTrackingFields(
  trackingFieldsService,
  assetId,
  companyId,
) {
  const rows = await trackingFieldsService.readByQuery({
    filter: {
      asset: { _eq: assetId },
      company_id: { _eq: companyId },
      is_show: { _eq: 1 },
    },
    fields: ["field_key", "value1", "value2", "value3", "value4", "is_mode", "code"],
    sort: ["sort_order"],
    limit: 50,
  });

  if (!rows) return [];

  const seen = new Set();
  const result = [];
  for (const item of rows) {
    if (!item.field_key || seen.has(item.field_key)) continue;
    seen.add(item.field_key);
    result.push(item);
  }
  return result;
}

async function sendMonitoringAlertEmail(alert, value, threshold) {
  if (!alert.email_address) return;

  const label = alert.field_name || alert.field_key;
  const subject = `[CMMS Alert] ${label} дохиолол`;
  const message =
    alert.alert_message || `${label}: ${value} ${alert.condition} ${threshold}`;

  try {
    const headers = { "Content-Type": "application/json" };
    if (process.env.DIRECTUS_TOKEN) {
      headers.Authorization = `Bearer ${process.env.DIRECTUS_TOKEN}`;
    }

    await axios.post(
      MONITORING_ALERT_EMAIL_FLOW_URL,
      {
        to: alert.email_address,
        subject,
        message,
        asset: alert.asset,
        field: alert.field_key,
        value,
        threshold,
      },
      { headers },
    );

    console.log(`[monitoring]   Email sent to ${alert.email_address}`);
  } catch (e) {
    console.warn(`[monitoring]   Email flow failed: ${e.message}`);
  }
}

async function triggerMonitoringAlert(ctx, alert, value, threshold) {
  const { monitoringAlertsService, alertLogsService } = ctx;
  const label = alert.field_name || alert.field_key;
  const message =
    alert.alert_message || `${label}: ${value} ${alert.condition} ${threshold}`;

  console.log(
    `[monitoring]   ALERT #${alert.id} | ${label}: ${value} ${alert.condition} ${threshold} | msg: ${message}`,
  );

  try {
    await monitoringAlertsService.updateOne(alert.id, {
      last_triggered: new Date().toISOString(),
    });
  } catch (e) {
    console.warn(`[monitoring]   Failed to update last_triggered: ${e.message}`);
  }

  try {
    await alertLogsService.createOne({
      alert: alert.id,
      asset: alert.asset,
      field_key: alert.field_key,
      field_name: alert.field_name,
      condition: alert.condition,
      threshold_type: alert.threshold_type,
      threshold_value: threshold,
      triggered_value: value,
      message,
      notify_popup: alert.notify_popup ? 1 : 0,
      notify_sound: alert.notify_sound ? 1 : 0,
      notify_browser: alert.notify_browser ? 1 : 0,
      notify_email: alert.notify_email ? 1 : 0,
      source: "auto",
      company_id: alert.company_id,
      triggered_at: new Date().toISOString(),
    });
  } catch (e) {
    console.warn(`[monitoring]   Failed to write alert log: ${e.message}`);
  }

  if (alert.notify_email) {
    console.log('sendMonitoringAlertEmail')
    // await sendMonitoringAlertEmail(alert, value, threshold);
  }
}

async function processMonitoringAsset(assetId, alertsForAsset, ctx) {
  const { assetFieldDataService, sensorReadingService, trackingFieldsService } = ctx;
  const companyId = alertsForAsset[0]?.company_id;

  const trackingFields = await fetchActiveMonitoringTrackingFields(
    trackingFieldsService,
    assetId,
    companyId,
  );

  if (trackingFields.length === 0) {
    console.log(`[monitoring] Asset ${assetId}: no is_show=1 tracking fields, skipping`);
    return;
  }

  const rawdataFields = trackingFields.filter((f) => f.is_mode !== "livedata");

  const rawValues =
    rawdataFields.length > 0
      ? await fetchLatestAssetFieldValues(assetFieldDataService, assetId, companyId)
      : {};

  const readingCache = new Map();
  const values = { ...rawValues };
  const thresholds = {};

  for (const field of trackingFields) {
    thresholds[field.field_key] = {
      value1: Number(field.value1) || 0,
      value2: Number(field.value2) || 0,
      value3: Number(field.value3) || 0,
      value4: Number(field.value4) || 0,
    };

    if (field.is_mode !== "livedata") continue;
    if (!field.code) continue;

    if (!readingCache.has(field.code)) {
      readingCache.set(
        field.code,
        await fetchLatestSensorReadingByDeviceId(sensorReadingService, field.code),
      );
    }
    const reading = readingCache.get(field.code);
    const value = resolveMonitoringSensorValue(reading, field.field_key);
    if (value !== undefined && !isNaN(value)) {
      values[field.field_key] = value;
    }
  }

  if (Object.keys(values).length === 0) {
    console.log(`[monitoring] Asset ${assetId}: no field data, skipping`);
    return;
  }

  for (const alert of alertsForAsset) {
    const currentValue = values[alert.field_key];
    if (currentValue === undefined || isNaN(currentValue)) {
      console.log(
        `[monitoring]   Alert #${alert.id}: field_key "${alert.field_key}" not in latest data`,
      );
      continue;
    }

    let threshold = null;
    if (alert.threshold_type === "custom") {
      threshold = alert.custom_value !== null ? Number(alert.custom_value) : null;
    } else {
      const ft = thresholds[alert.field_key];
      if (ft && alert.threshold_type in ft) {
        threshold = ft[alert.threshold_type];
      }
    }

    if (threshold === null || isNaN(threshold)) {
      console.log(`[monitoring]   Alert #${alert.id}: threshold undefined, skip`);
      continue;
    }

    if (checkAlertCondition(currentValue, alert.condition, threshold)) {
       console.log(`triggerMonitoringAlert-started`);
      await triggerMonitoringAlert(ctx, alert, currentValue, threshold);
    } else {
      console.log(
        `[monitoring]   Alert #${alert.id} (${alert.field_key}): ${currentValue} ${alert.condition} ${threshold} = false, ok`,
      );
    }
  }
}

module.exports = function registerHook(
  { schedule },
  { services, database, getSchema },
) {

  // 15 минут тутамд идэвхтэй Monitoring_alerts-ийг шалгаж, нөхцөл хангагдвал
  // Monitoring_alert_logs бүртгэн, шаардлагатай бол имэйл мэдэгдэл илгээнэ.
  schedule("*/15 * * * *", async () => {
    try {
      console.log(
        `[monitoring] === Monitoring Alert Checker started at ${new Date().toISOString()} ===`,
      );

      const schema = await getSchema();
      const { ItemsService } = services;

      const monitoringAlertsService = new ItemsService("Monitoring_alerts", {
        schema,
        knex: database,
        accountability: null,
      });

      const alertLogsService = new ItemsService("Monitoring_alert_logs", {
        schema,
        knex: database,
        accountability: null,
      });

      const assetFieldDataService = new ItemsService("Asset_field_data_json", {
        schema,
        knex: database,
        accountability: null,
      });

      const sensorReadingService = new ItemsService("Sensor_reading", {
        schema,
        knex: database,
        accountability: null,
      });

      const trackingFieldsService = new ItemsService("Device_tracking_fields", {
        schema,
        knex: database,
        accountability: null,
      });

      const alerts = await monitoringAlertsService.readByQuery({
        filter: { is_active: { _eq: true } },
        limit: -1,
        fields: [
          "id",
          "asset",
          "company_id",
          "field_key",
          "field_name",
          "condition",
          "threshold_type",
          "custom_value",
          "notify_popup",
          "notify_sound",
          "notify_browser",
          "notify_email",
          "email_address",
          "alert_message",
          "last_triggered",
        ],
      });

      if (!alerts || alerts.length === 0) {
        console.log("[monitoring] No active alerts found, exiting.");
        return;
      }

      console.log(`[monitoring] Loaded ${alerts.length} active alert(s)`);

      const byAsset = {};
      for (const alert of alerts) {
        const aid = String(alert.asset);
        if (!byAsset[aid]) byAsset[aid] = [];
        byAsset[aid].push(alert);
      }

      const ctx = {
        monitoringAlertsService,
        alertLogsService,
        assetFieldDataService,
        sensorReadingService,
        trackingFieldsService,
      };

      for (const [assetId, assetAlerts] of Object.entries(byAsset)) {
        console.log(
          `[monitoring] --- Asset ${assetId} (${assetAlerts.length} alert(s)) ---`,
        );
        try {
          await processMonitoringAsset(assetId, assetAlerts, ctx);
        } catch (e) {
          console.error(`[monitoring] Asset ${assetId} error: ${e.message}`);
        }
      }

      console.log(`[monitoring] === Done at ${new Date().toISOString()} ===`);
    } catch (error) {
      console.error("[monitoring] Fatal:", error.message);
    }
  });

  // 2 минут тутамд SmartGPS CRM-ээс realtime device өгөгдөл татаж
  // Sensor_data (raw dump) болон Sensor_reading (device бүрийн бичлэг) рүү
  // create хийнэ.
  schedule("*/10 * * * *", async () => {
    const SMARTGPS_DEVICE_TYPE = "SmartGPS";
    const SMARTGPS_LOGIN_URL =
      "https://crm.smartgps.mn/bridge/api/auth/login/";
    const SMARTGPS_UNITS_STATUS_URL =
      "https://crm.smartgps.mn/bridge/api/units/status/?search=&unit_ids=";

    try {
      console.log("Running SmartGPS realtime poll");

      let token = await getSmartgpsToken(SMARTGPS_LOGIN_URL);

      let statusResponse;

      try {
        statusResponse = await axios.get(SMARTGPS_UNITS_STATUS_URL, {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
      } catch (statusError) {
        // Кэшлэсэн token хүчингүй болсон (401) бол нэг удаа дахин
        // login хийж, шинэ token-оор дахин оролдоно.
        if (statusError.response && statusError.response.status === 401) {
          console.log(
            "[smartgps-poll] Token хүчингүй байна, дахин login хийж байна.",
          );

          smartgpsToken = null;
          token = await getSmartgpsToken(SMARTGPS_LOGIN_URL);

          statusResponse = await axios.get(SMARTGPS_UNITS_STATUS_URL, {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          });
        } else {
          throw statusError;
        }
      }

      const payload = statusResponse.data;
      const results = payload.results || [];

      console.log(`[smartgps-poll] ${results.length} device-ийн өгөгдөл ирлээ`);

      const schema = await getSchema();
      const { ItemsService } = services;

      const sensorDataService = new ItemsService("Sensor_data", {
        schema,
        knex: database,
        accountability: null,
      });

      await sensorDataService.createOne({
        sensor_data: payload,
        date_created: new Date(),
      });

      const sensorReadingService = new ItemsService("Sensor_reading", {
        schema,
        knex: database,
        accountability: null,
      });

      for (const unit of results) {
        try {
          await sensorReadingService.createOne({
            device_type: SMARTGPS_DEVICE_TYPE,
            device_id: unit.imei || String(unit.unit_id),
            temperature: unit.temperature ?? null,
            temperature_unit: unit.temperature !== null ? "C" : null,
            vibration_x: null,
            vibration_y: null,
            vibration_z: null,
            vibration_unit: null,
            timestamp: unit.last_message_ts ?? null,
            timestamp_datetime:
              unit.last_message_ts != null
                ? new Date(unit.last_message_ts * 1000)
                : null,
            json_data: unit,
            date_created: new Date(),
          });
        } catch (unitError) {
          console.error(
            `[smartgps-poll] unit_id=${unit.unit_id} бичихэд алдаа:`,
            unitError.message,
          );
        }
      }

      console.log("[smartgps-poll] Дууслаа.");
    } catch (error) {
      console.error("[smartgps-poll] Алдаа:", error.message);
    }
  });

  // Өдөр бүр 00:01 цагт ажиллах cron Work_pm
  schedule("*/20 * * * *", async () => {
    try {
      console.log("Running Work_pm scheduled");
      const schema = await getSchema();
      const { ItemsService } = services;

      const maintenanceService = new ItemsService("Work_pm", {
        schema,
        knex: database,
        accountability: null,
      });

      const taskService = new ItemsService("Work_pm_item", {
        schema,
        knex: database,
        accountability: null,
      });

      const getWoSchedule = new ItemsService("Work_pm_schedules", {
        schema,
        knex: database,
        accountability: null,
      });

      const getSchedule = new ItemsService("Schedule", {
        schema,
        knex: database,
        accountability: null,
      });

      const tradeService = new ItemsService("Work_pm_Tradecode", {
        schema,
        knex: database,
        accountability: null,
      });

      const partService = new ItemsService("Work_pm_Parts", {
        schema,
        knex: database,
        accountability: null,
      });

      const fileService = new ItemsService("Work_pm_files", {
        schema,
        knex: database,
        accountability: null,
      });

      const assetService = new ItemsService("Work_pm_assets", {
        schema,
        knex: database,
        accountability: null,
      });

      const assetDetailsService = new ItemsService("Assets", {
        schema,
        knex: database,
        accountability: null,
      });

      // Өнөөдрийн огноог өөр өөр форматаар авах
      const today = new Date();

      const todayISO = today.toISOString().split("T")[0]; // "ЖЖЖЖ-СС-ӨӨ" формат
      const todayDayOfMonth = today.getDate(); // Сарын өдөр (1-31)
      const todayOfmonth = today.getMonth() + 1; // 0-ээс эхэлдэг тул +1 нэмнэ
      const todayDayOfWeek = today.getDay() || 7; // Долоо хоногийн өдөр (1-7, 1=Даваа, 7=Ням)

      // Өнөөдрийн эхлэл ба төгсгөлийн цаг
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0);
      const todayEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59);

      // ******** HELPER FUNCTIONS: Хуваарийн огноо шинэчлэх ********
      // Дараачийн хуваарийн огноог тооцоол
      const calculateNextScheduleDate = (scheduleDates, repeatUnit, currentDate = null) => {
        const refDate = currentDate || today;
        
        if (!scheduleDates || scheduleDates.length === 0) {
          return scheduleDates;
        }

        try {
          if (repeatUnit === "daily") {
            // Daily schedules stay the same (every day)
            return scheduleDates.map(item => ({
              ...item,
              month: item.month || 1,
              date: item.date || 1,
              hour: item.hour || 0,
              min: item.min || 0
            }));
          } 
          else if (repeatUnit === "weekly") {
            // Weekly schedules keep same day of week numbers (1-7)
            return scheduleDates.map(item => ({
              ...item,
              month: item.month || 1,
              date: item.date, // Day of week (1-7) stays same
              hour: item.hour || 0,
              min: item.min || 0
            }));
          } 
          else if (repeatUnit === "monthly") {
            // Monthly schedules: move to next month, keep same date of month
            return scheduleDates.map(item => {
              let targetDate = new Date(refDate.getFullYear(), refDate.getMonth() + 1, 1);
              // Ensure the day exists in the month (e.g., Jan 31 -> Feb 28/29)
              const dayOfMonth = Math.min(item.date || 1, new Date(targetDate.getFullYear(), targetDate.getMonth() + 1, 0).getDate());
              return {
                ...item,
                month: item.month || (targetDate.getMonth() + 1),
                date: dayOfMonth,
                hour: item.hour || 0,
                min: item.min || 0
              };
            });
          } 
          else if (repeatUnit === "yearly") {
            // Yearly schedules: move to next year, keep same month and date
            return scheduleDates.map(item => ({
              ...item,
              month: item.month, // Keep same month
              date: item.date, // Keep same day
              hour: item.hour || 0,
              min: item.min || 0
            }));
          }
          else {
            // Default: return as is
            return scheduleDates.map(item => ({
              ...item,
              month: item.month || 1,
              date: item.date || 1,
              hour: item.hour || 0,
              min: item.min || 0
            }));
          }
        } catch (e) {
          console.error("Error calculating next schedule date:", e);
          return scheduleDates.map(item => ({
            ...item,
            month: item.month || 1,
            date: item.date || 1,
            hour: item.hour || 0,
            min: item.min || 0
          }));
        }
      };

      // Work_pm_schedules-ын огноог шинэчил
      const updateWorkOrderScheduleDate = async (woScheduleId, newScheduleDates) => {
        try {
          if (!woScheduleId || !newScheduleDates) return false;
          
          await getWoSchedule.updateOne(woScheduleId, {
            schedules_date: JSON.stringify(newScheduleDates)
          });
          
          console.log(`Updated Work_pm_schedules ${woScheduleId} with new schedules_date`);
          return true;
        } catch (error) {
          console.error(`Error updating Work_pm_schedules ${woScheduleId}:`, error);
          return false;
        }
      };

      // Helper function: Check if current time matches scheduled times
      // Uses a forward-looking window (fires up to 1 min early) plus a catch-up window
      // (fires up to CATCHUP_WINDOW_MINUTES late) so a missed/delayed cron tick (server
      // restart, deploy, slow query, etc.) doesn't silently skip the schedule for the day.
      // Each matched item is marked with _lastFiredDate so a widened window can't double-fire
      // it on a later tick the same day; callers must persist scheduleDates back to the DB
      // after a successful daily-schedule generation for this marker to stick.
      const CATCHUP_WINDOW_MINUTES = 15;
      const shouldGenerateAtTime = (scheduleDates) => {
        if (!scheduleDates || scheduleDates.length === 0) {
          return false;
        }

        const today = new Date();
        const currentHour = today.getHours();
        const currentMin = today.getMinutes();
        const todayStr = today.toISOString().split("T")[0];
        const currentTotal = currentHour * 60 + currentMin;

        for (const scheduleItem of scheduleDates) {
          if (scheduleItem._lastFiredDate === todayStr) {
            // Already generated for this time slot today - skip to avoid duplicates
            continue;
          }

          const schedHour = parseInt(scheduleItem.hour) || 0;
          const schedMin = parseInt(scheduleItem.min) || 0;

          // timeDiff >= 0 means the scheduled time has arrived or passed
          const timeDiff = currentTotal - (schedHour * 60 + schedMin);

          if (timeDiff >= -1 && timeDiff <= CATCHUP_WINDOW_MINUTES) {
            console.log(`Time match found! Current: ${currentHour}:${String(currentMin).padStart(2, '0')}, Scheduled: ${schedHour}:${String(schedMin).padStart(2, '0')}, TimeDiff: ${timeDiff} minutes`);
            scheduleItem._lastFiredDate = todayStr;
            return true;
          }
          console.log(`No time match. Current: ${currentHour}:${String(currentMin).padStart(2, '0')}, Scheduled: ${schedHour}:${String(schedMin).padStart(2, '0')}, TimeDiff: ${timeDiff} minutes`);
        }

        return false;
      };

      // ******** PM ШУУД ХУВААРЬ: Өнөөдөр хийгдэх ажлуудыг хайх ********
      const templateTasks = await maintenanceService.readByQuery({
        filter: {
          pm_type: "pm",
          template_pm: { _null: true },
          schedule: { _eq: 1 },
          active: { _eq: '1' },
          wo_status: 8, // pm ноорог төлөв
          action_status: 2, // батлагдсан
          _or: [
            { last_generated: { _null: true } }, // Эхлээд үүсгээгүй
            { last_generated: { _lt: todayStart.toISOString() } } // Өнөөрүүгээр үүсгээгүй
          ]
        },
        fields: ["*"],
      });

      console.log("templateTasks DIRECT_WO", templateTasks.length);

      if (templateTasks.length > 0) {
        // Шаблон ажил тус бүрийг боловсруулах
        for (const task of templateTasks) {
          try {
            console.log("DIRECT SCHEDULE starting Work_pm  ...");

            const woSchedules = await getWoSchedule.readByQuery({
              filter: {
                work_order: { _eq: task.id },
              },
              fields: ["*"],
            });

            // console.log('woSchedules_result', woSchedules, woSchedules.length)
            if (woSchedules.length <= 0) continue;
            // let wo_schedule =woSchedules[0]

            for (const wo_schedule of woSchedules) {
              if (wo_schedule.repeat_types != "direct") {
                continue;
              }

              if (wo_schedule.type == "public") {
                const scheduleResult = await getSchedule.readByQuery({
                  filter: {
                    id: wo_schedule.schedule_id,
                    active: "1",
                  },
                  fields: ["*"],
                });

                if (scheduleResult.length <= 0) continue;
                const schedule = scheduleResult[0];

                if (schedule.repeat_types != "direct") continue;
                let scheduleDates = [];

                try {
                  // Өгөгдөлийн санд JSON мөр хэлбээрээр хадгалагдсан тохиолдолд задлах
                  scheduleDates = JSON.parse(schedule.schedules_date);
                } catch (e) {
                  // Аль хэдийн массив объект бол шууд авах
                  scheduleDates = schedule.schedules_date || [];
                }

                let shouldGenerateToday = false;

                if (schedule.repeat_unit == "daily") {
                  // For daily direct PM, check specific times in schedules_date
                  shouldGenerateToday = shouldGenerateAtTime(scheduleDates);
                  console.log("daily_pm_time_check", shouldGenerateToday);
                } else if (schedule.repeat_unit == "weekly") {
                  shouldGenerateToday = scheduleDates.some(
                    (item) => parseInt(item.date) === todayDayOfWeek,
                  );
                  console.log("weekly", shouldGenerateToday);
                } else if (schedule.repeat_unit == "monthly") {
                  shouldGenerateToday = scheduleDates.some(
                    (item) => parseInt(item.date) === todayDayOfMonth,
                  );
                  console.log("monthly", shouldGenerateToday);
                } else if (schedule.repeat_unit == "yearly") {
                  shouldGenerateToday = scheduleDates.some(
                    (item) => item.date === todayISO,
                  );
                  console.log("yearly", shouldGenerateToday);
                }

                if (!shouldGenerateToday) continue;
                console.log(
                  `public_Task ${task.id}: Should generate today: ${shouldGenerateToday}`,
                );

                // Fetch assets from Work_pm_assets
                const templateAssets = await assetService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["assets"],
                });

                // Determine assets to process
                let assetsToProcess = [task.asset]; // Default to template task asset
                if (templateAssets.length > 0) {
                  const uniqueAssets = [
                    ...new Set(templateAssets.map((a) => a.assets)),
                  ];
                  assetsToProcess = uniqueAssets;
                }

                // Process each asset - create separate work order for each
                for (const finalAsset of assetsToProcess) {
                  // Skip if asset ID is null/undefined
                  if (!finalAsset) {
                    console.warn(
                      "Skipping null/undefined asset ID in public DIRECT schedule",
                    );
                    continue;
                  }

                  // Fetch asset code
                  let assetCode = "";
                  try {
                    const assetDetail = await assetDetailsService
                      .readOne(finalAsset, {
                        fields: ["asset_code"],
                      })
                      .catch(() => null); // Return null if asset not found
                    assetCode = assetDetail?.asset_code || "";
                    if (!assetCode) {
                      console.warn(
                        `Asset code not found for ID: ${finalAsset}`,
                      );
                    }
                  } catch (err) {
                    console.warn(
                      `Error fetching asset details for ID: ${finalAsset}:`,
                      err.message,
                    );
                  }

                  // Шинэ ажил үүсгэх
                  const newWorkOrder = await maintenanceService.createOne({
                    name: `${task.name}${assetCode ? " - " + assetCode : ""}`,
                    history_description: task.history_description,
                    safety_notes: task.safety_notes,
                    asset: finalAsset,
                    assigned_team: task.assigned_team,
                    department: task.department,
                    location: task.location,
                    work_type: task.work_type,
                    type: task.type,
                    active: task.active,
                    pm_type: "generated",
                    created_type: "pm_generated",
                    wo_status: 8, // pm ноорог төлөв
                    // type: 4, // pm төрөл
                    template_pm: task.id, // Энэ ажил аль загвараас үүссэнийг заах
                    priority: task.priority || 2,
                    status: task.status,
                    company_id: task.company_id,
                    schedule: null,
                    other_amount: task.other_amount,
                    other_actual_amount: task.other_actual_amount,
                    budget: task.budget,
                    budget_actual_amount: task.budget_actual_amount,
                    budget_planned_amount: task.budget_planned_amount,
                  });

                  console.log(
                    `Created_by DIRECT_PUBLIC work_order ${newWorkOrder} based on template ${task.id}`,
                  );

                  // Загвар ажлын дэд таскуудыг авах
                  const templateItems = await taskService.readByQuery({
                    filter: {
                      workorder: { _eq: task.id },
                    },
                    fields: ["*"],
                  });

                  // console.log(`Found ${templateItems.length} template items to copy`);

                  // Нэмэгдэл таск үүсгэх (work_order_item.created_type='pm_generated')
                  for (const item of templateItems) {
                    const newItem = await taskService.createOne({
                      workorder: newWorkOrder, // Шинэ ажлын захиалгатай холбох
                      name: item.name,
                      company_id: item.company_id,
                      value: item.value,
                      status: item.status,
                      code: item.code,
                      priority: item.priority,
                      parent: item.parent,
                      pos: item.pos,
                      active: item.active,
                      children: item.children,
                      template_type: item.template_type,
                      estimated_hours: item.estimated_hours,
                      instructions: item.instructions,
                      created_type: "pm_generated",
                      date_created: new Date(),
                    });

                    // console.log(`Created  work_order_item ${newItem} of work_order ${newWorkOrder}`);
                  }

                  // Ажлын захиалгат кодуудыг хуулах
                  const trades = await tradeService.readByQuery({
                    filter: {
                      work_order: { _eq: task.id },
                    },
                    fields: ["*"],
                  });
                  for (const t_item of trades) {
                    const tItem = await tradeService.createOne({
                      name: t_item.name,
                      work_order: newWorkOrder,
                      company_id: t_item.company_id,
                      duration: t_item.duration,
                      status: t_item.status,
                      rate: t_item.rate,
                      total: t_item.total,
                      trade: t_item.trade,
                      actual_duration: t_item.actual_duration,
                      actual_total: t_item.actual_total,
                      actual_rate: t_item.actual_rate,
                      date_created: new Date(),
                    });
                  }

                  // Ашигласан сэлбэгүүдийг хуулах
                  const parts = await partService.readByQuery({
                    filter: {
                      work_order: { _eq: task.id },
                    },
                    fields: ["*"],
                  });
                  for (const p_item of parts) {
                    const pItem = await partService.createOne({
                      work_order: newWorkOrder,
                      company_id: p_item.company_id,
                      quantity: p_item.quantity,
                      price: p_item.price,
                      status: p_item.status,
                      amount: p_item.amount,
                      parts: p_item.parts,
                      actual_quantity: p_item.actual_quantity,
                      actual_price: p_item.actual_price,
                      actual_amount: p_item.actual_amount,
                      date_created: new Date(),
                    });
                  }

                  // Файлуудыг хуулах
                  const files = await fileService.readByQuery({
                    filter: {
                      work_order: { _eq: task.id },
                    },
                    fields: ["*"],
                  });

                  for (const f_item of files) {
                    const fItem = await fileService.createOne({
                      work_order: newWorkOrder,
                      file: f_item.file,
                      status: f_item.status,
                      date_created: new Date(),
                    });
                  }
                } // End of assetsToProcess loop

                // Шинэчил: Дараачийн хуваарийн огноог тооцоож, Work_pm_schedules-ын schedules_date-г шинэчил
                if (schedule.repeat_unit && schedule.repeat_unit !== "daily") {
                  const nextScheduleDates = calculateNextScheduleDate(scheduleDates, schedule.repeat_unit);
                  await updateWorkOrderScheduleDate(wo_schedule.id, nextScheduleDates);
                } else if (schedule.repeat_unit === "daily") {
                  // Persist the _lastFiredDate marker set by shouldGenerateAtTime so this
                  // time slot doesn't fire again today within the catch-up window
                  await getSchedule.updateOne(schedule.id, {
                    schedules_date: JSON.stringify(scheduleDates),
                  });
                }

                // Only update last_generated for non-time-based schedules (weekly, monthly, yearly)
                // For daily time-based schedules, allow multiple generations throughout the day
                if (schedule.repeat_unit !== "daily") {
                  await maintenanceService.updateOne(task.id, {
                    last_generated: new Date(),
                  });
                }
              } else if (wo_schedule.type == "private") {
                let scheduleDates = [];
                try {
                  // Өгөгдөлийн санд JSON мөр хэлбээрээр хадгалагдсан тохиолдолд задлах
                  scheduleDates = JSON.parse(wo_schedule.schedules_date);
                } catch (e) {
                  // Аль хэдийн массив объект бол шууд авах
                  scheduleDates = wo_schedule.schedules_date || [];
                }

                let shouldGenerateToday = false;

                if (wo_schedule.repeat_unit == "daily") {
                  // For daily direct PM private, check specific times in schedules_date
                  shouldGenerateToday = shouldGenerateAtTime(scheduleDates);
                  console.log("daily_private_pm_time_check", shouldGenerateToday);
                } else if (wo_schedule.repeat_unit == "weekly") {
                  shouldGenerateToday = scheduleDates.some(
                    (item) => parseInt(item.date) === todayDayOfWeek,
                  );
                  console.log("weekly_private", shouldGenerateToday);
                } else if (wo_schedule.repeat_unit == "monthly") {
                  shouldGenerateToday = scheduleDates.some(
                    (item) => parseInt(item.date) === todayDayOfMonth,
                  );
                  console.log("monthly_private", shouldGenerateToday);
                } else if (wo_schedule.repeat_unit == "yearly") {
                  shouldGenerateToday = scheduleDates.some(
                    (item) =>
                      item.month === todayOfmonth &&
                      item.date === todayDayOfMonth,
                  );
                  console.log("yearly_private", shouldGenerateToday);
                }

                if (!shouldGenerateToday) continue;
                console.log(
                  `private_Task ${task.id}: Should generate today: ${shouldGenerateToday}`,
                );

                // Fetch assets from Work_pm_assets
                const templateAssets = await assetService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["assets"],
                });

                // Determine assets to process
                let assetsToProcess = [task.asset]; // Default to template task asset
                if (templateAssets.length > 0) {
                  const uniqueAssets = [
                    ...new Set(templateAssets.map((a) => a.assets)),
                  ];
                  assetsToProcess = uniqueAssets;
                }

                // Process each asset - create separate work order for each
                for (const finalAsset of assetsToProcess) {
                  // Skip if asset ID is null/undefined
                  if (!finalAsset) {
                    console.warn(
                      "Skipping null/undefined asset ID in private DIRECT schedule",
                    );
                    continue;
                  }

                  // Fetch asset code
                  let assetCode = "";
                  try {
                    const assetDetail = await assetDetailsService
                      .readOne(finalAsset, {
                        fields: ["asset_code"],
                      })
                      .catch(() => null); // Return null if asset not found
                    assetCode = assetDetail?.asset_code || "";
                    if (!assetCode) {
                      console.warn(
                        `Asset code not found for ID: ${finalAsset}`,
                      );
                    }
                  } catch (err) {
                    console.warn(
                      `Error fetching asset details for ID: ${finalAsset}:`,
                      err.message,
                    );
                  }

                  // Шинэ ажил үүсгэх
                  const newWorkOrder = await maintenanceService.createOne({
                    name: `${task.name}${assetCode ? " - " + assetCode : ""}`,
                    history_description: task.history_description,
                    safety_notes: task.safety_notes,
                    company_id: task.company_id,
                    asset: finalAsset,
                    assigned_team: task.assigned_team,
                    department: task.department,
                    location: task.location,
                    type: task.type,
                    work_type: task.work_type,
                    active: task.active,
                    pm_type: "generated",
                    created_type: "pm_generated",
                    wo_status: 8, // pm ноорог төлөв
                    // type: 4, // pm төрөл
                    template_pm: task.id, // Энэ ажил аль загвараас үүссэнийг заах
                    priority: task.priority || 2,
                    status: task.status,
                    schedule: null,
                    other_amount: task.other_amount,
                    other_actual_amount: task.other_actual_amount,
                    budget: task.budget,
                    budget_actual_amount: task.budget_actual_amount,
                    budget_planned_amount: task.budget_planned_amount,
                  });

                  console.log(
                    `Created_by DIRECT PRIVATE WO work_order ${newWorkOrder} based on template ${task.id}`,
                  );

                  // Загвар ажлын дэд таскуудыг авах
                  const templateItems = await taskService.readByQuery({
                    filter: {
                      workorder: { _eq: task.id },
                    },
                    fields: ["*"],
                  });

                  // Нэмэгдэл таск үүсгэх (work_order_item.created_type='pm_generated')
                  for (const item of templateItems) {
                    const newItem = await taskService.createOne({
                      workorder: newWorkOrder, // Шинэ ажлын захиалгатай холбох
                      name: item.name,
                      company_id: item.company_id,
                      value: item.value,
                      status: item.status,
                      code: item.code,
                      priority: item.priority,
                      parent: item.parent,
                      pos: item.pos,
                      active: item.active,
                      children: item.children,
                      template_type: item.template_type,
                      estimated_hours: item.estimated_hours,
                      instructions: item.instructions,
                      created_type: "pm_generated",
                      date_created: new Date(),
                    });

                    console.log(
                      `Created  DIRECT_PRIVATE WO_ITEMS  ${newItem} of work_order ${newWorkOrder}`,
                    );
                  }

                  // Ажлын захиалгат кодуудыг хуулах
                  const trades = await tradeService.readByQuery({
                    filter: {
                      work_order: { _eq: task.id },
                    },
                    fields: ["*"],
                  });
                  for (const t_item of trades) {
                    const tItem = await tradeService.createOne({
                      name: t_item.name,
                      work_order: newWorkOrder,
                      company_id: t_item.company_id,
                      duration: t_item.duration,
                      status: t_item.status,
                      rate: t_item.rate,
                      total: t_item.total,
                      trade: t_item.trade,
                      actual_duration: t_item.actual_duration,
                      actual_total: t_item.actual_total,
                      actual_rate: t_item.actual_rate,
                      date_created: new Date(),
                    });
                  }

                  // Ашигласан сэлбэгүүдийг хуулах
                  const parts = await partService.readByQuery({
                    filter: {
                      work_order: { _eq: task.id },
                    },
                    fields: ["*"],
                  });
                  for (const p_item of parts) {
                    const pItem = await partService.createOne({
                      work_order: newWorkOrder,
                      quantity: p_item.quantity,
                      company_id: p_item.company_id,
                      price: p_item.price,
                      status: p_item.status,
                      amount: p_item.amount,
                      parts: p_item.parts,
                      actual_quantity: p_item.actual_quantity,
                      actual_price: p_item.actual_price,
                      actual_amount: p_item.actual_amount,
                      date_created: new Date(),
                    });
                  }

                  // Файлуудыг хуулах
                  const files = await fileService.readByQuery({
                    filter: {
                      work_order: { _eq: task.id },
                    },
                    fields: ["*"],
                  });

                  for (const f_item of files) {
                    const fItem = await fileService.createOne({
                      work_order: newWorkOrder,
                      file: f_item.file,
                      status: f_item.status,
                      date_created: new Date(),
                    });
                  }
                } // End of assetsToProcess loop

                // Шинэчил: Дараачийн хуваарийн огноог тооцоож, Work_pm_schedules-ын schedules_date-г шинэчил
                if (wo_schedule.repeat_unit && wo_schedule.repeat_unit !== "daily") {
                  const nextScheduleDates = calculateNextScheduleDate(scheduleDates, wo_schedule.repeat_unit);
                  await updateWorkOrderScheduleDate(wo_schedule.id, nextScheduleDates);
                } else if (wo_schedule.repeat_unit === "daily") {
                  // Persist the _lastFiredDate marker set by shouldGenerateAtTime so this
                  // time slot doesn't fire again today within the catch-up window
                  await updateWorkOrderScheduleDate(wo_schedule.id, scheduleDates);
                }

                // Only update last_generated for non-time-based schedules (weekly, monthly, yearly)
                // For daily time-based schedules, allow multiple generations throughout the day
                if (wo_schedule.repeat_unit !== "daily") {
                  await maintenanceService.updateOne(task.id, {
                    last_generated: new Date(),
                  });
                }
              }
            }

            // console.log(`Updated template task-id ${task.id} after generating new work order`);
          } catch (error) {
            console.error(`Error direct template task ${task.id}:`, error);
          }
        }
      }

      // ******** PM ДУУССАН ХУВААРЬ: Дууссан ажлаас шинэ ажил үүсгэх ********
      const templateCompletedTasks = await maintenanceService.readByQuery({
        filter: {
          template_pm: { _nnull: true },
          pm_type: "completed",
          action_status: 2, // батлагдсан
          // completed_at:{  _nnull: true },
          // wo_status:8, // pm ноорог
          // ...(!first_work_co ? {} : { schedule: { _eq: 1 } }),
          _or: [
            { last_generated: { _null: true } }, // Эхлээд үүсгээгүй
            { last_generated: { _lt: todayStart.toISOString() } } // Өнөөрүүгээр үүсгээгүй
          ]
        },
        fields: ["*"],
        sort: ["-id"],
        limit: 1,
      });

      if (templateCompletedTasks.length > 0) {
        console.log("completedTasks", templateCompletedTasks.length);
        // Дууссан ажил тус бүрийг боловсруулах
        for (const task of templateCompletedTasks) {
          try {
            console.log("COMPLETED SCHEDULE starting ...");

            if (!task.completed_at) {
              console.log("not_finish ");
              continue;
            }

            // Таскийн хуваарь тохиргоог авах
            const woSchedules = await getWoSchedule.readByQuery({
              filter: {
                work_order: { _eq: task.template_pm },
              },
              fields: ["*"],
            });

            // console.log('woSchedules_result', woSchedules, woSchedules.length)
            if (woSchedules.length <= 0) continue;
            let wo_schedule = woSchedules[0];
            if (wo_schedule.repeat_types != "completed") {
              continue;
            }

            if (wo_schedule.type == "public") {
              const scheduleResult = await getSchedule.readByQuery({
                filter: {
                  id: wo_schedule.schedule_id,
                  active: "1",
                },
                fields: ["*"],
              });

              if (scheduleResult.length <= 0) continue;
              const schedule = scheduleResult[0];
              if (schedule.repeat_types != "completed") continue;

              // `completed_at`-ийг `Date` объект болгон хөрвүүлэх
              const completedDate = new Date(task.completed_at);
              // console.log('completedDate_1', completedDate.getDate())
              // console.log('completedDate_2', completedDate)

              // Динамик өдрүүдийг тооцоолох (1 өдөр, 19 өдөр)
              const calculatedDates = schedule.schedules_date.map((dateObj) => {
                const nextDate = new Date(completedDate); // completedDate-ийн хуулбар үүсгэх
                nextDate.setDate(completedDate.getDate() + dateObj.date); // completedDate-аас хойшхи dateObj.date өдөр нэмэх
                return nextDate; // Бүтэн Date объектыг буцаах нь илүү хэрэгтэй
              });

              // console.log('Calculated dates:', calculatedDates);
              const calculatedDatesISO = calculatedDates.map(
                (date) => date.toISOString().split("T")[0],
              );

              const hasTodaySchedule = calculatedDatesISO.includes(todayISO);

              if (!hasTodaySchedule) {
                continue;
              }

              // Fetch assets from Work_pm_assets
              const templateAssets = await assetService.readByQuery({
                filter: {
                  work_order: { _eq: task.id },
                },
                fields: ["assets"],
              });

              // Determine assets to process
              let assetsToProcess = [task.asset]; // Default to template task asset
              if (templateAssets.length > 0) {
                const uniqueAssets = [
                  ...new Set(templateAssets.map((a) => a.assets)),
                ];
                assetsToProcess = uniqueAssets;
              }

              // Process each asset - create separate work order for each
              for (const finalAsset of assetsToProcess) {
                // Skip if asset ID is null/undefined
                if (!finalAsset) {
                  console.warn(
                    "Skipping null/undefined asset ID in COMPLETED public schedule",
                  );
                  continue;
                }

                // Fetch asset code
                let assetCode = "";
                try {
                  const assetDetail = await assetDetailsService
                    .readOne(finalAsset, {
                      fields: ["asset_code"],
                    })
                    .catch(() => null); // Return null if asset not found
                  assetCode = assetDetail?.asset_code || "";
                  if (!assetCode) {
                    console.warn(`Asset code not found for ID: ${finalAsset}`);
                  }
                } catch (err) {
                  console.warn(
                    `Error fetching asset details for ID: ${finalAsset}:`,
                    err.message,
                  );
                }

                // Шинэ ажил үүсгэх
                const newWorkOrder = await maintenanceService.createOne({
                  name: `${task.name} - CT${assetCode ? " - " + assetCode : ""}`,
                  history_description: task.history_description,
                  safety_notes: task.safety_notes,
                  company_id: task.company_id,
                  asset: finalAsset,
                  assigned_team: task.assigned_team,
                  department: task.department,
                  location: task.location,
                  work_type: task.work_type,
                  type: task.type,
                  active: task.active,
                  pm_type: "completed",
                  created_type: "pm_generated",
                  wo_status: 8, // pm ноорог төлөв
                  // type: 4, // pm төрөл
                  template_pm: task.id,
                  priority: task.priority || 2,
                  status: task.status,
                  schedule: null,
                  other_amount: task.other_amount,
                  other_actual_amount: task.other_actual_amount,
                  budget: task.budget,
                  budget_actual_amount: task.budget_actual_amount,
                  budget_planned_amount: task.budget_planned_amount,
                });

                console.log(
                  `Created_by COMPLETED PUBLIC work_order ${newWorkOrder} based on template ${task.id}`,
                );

                // Загвар ажлын дэд таскуудыг авах
                const templateItems_comp = await taskService.readByQuery({
                  filter: {
                    workorder: { _eq: task.id },
                  },
                  fields: ["*"],
                });

                // Нэмэгдэл таск үүсгэх
                for (const item of templateItems_comp) {
                  await taskService.createOne({
                    workorder: newWorkOrder,
                    name: item.name,
                    company_id: item.company_id,
                    value: item.value,
                    status: item.status,
                    code: item.code,
                    priority: item.priority,
                    parent: item.parent,
                    pos: item.pos,
                    active: item.active,
                    children: item.children,
                    template_type: item.template_type,
                    estimated_hours: item.estimated_hours,
                    instructions: item.instructions,
                    created_type: "pm_generated",
                    date_created: new Date(),
                  });
                }

                // Ажлын захиалгат кодуудыг хуулах
                const trades = await tradeService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["*"],
                });
                for (const t_item of trades) {
                  const tItem = await tradeService.createOne({
                    name: t_item.name,
                    work_order: newWorkOrder,
                    duration: t_item.duration,
                    company_id: t_item.company_id,
                    status: t_item.status,
                    rate: t_item.rate,
                    total: t_item.total,
                    trade: t_item.trade,
                    actual_duration: t_item.actual_duration,
                    actual_total: t_item.actual_total,
                    actual_rate: t_item.actual_rate,
                    date_created: new Date(),
                  });
                }

                // Ашигласан сэлбэгүүдийг хуулах
                const parts = await partService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["*"],
                });
                for (const p_item of parts) {
                  const pItem = await partService.createOne({
                    work_order: newWorkOrder,
                    quantity: p_item.quantity,
                    price: p_item.price,
                    company_id: p_item.company_id,
                    status: p_item.status,
                    amount: p_item.amount,
                    parts: p_item.parts,
                    actual_quantity: p_item.actual_quantity,
                    actual_price: p_item.actual_price,
                    actual_amount: p_item.actual_amount,
                    date_created: new Date(),
                  });
                }

                // Файлуудыг хуулах
                const files = await fileService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["*"],
                });

                for (const f_item of files) {
                  const fItem = await fileService.createOne({
                    work_order: newWorkOrder,
                    file: f_item.file,
                    status: f_item.status,
                    date_created: new Date(),
                  });
                }
              } // End of assetsToProcess loop

              // Шинэчил: COMPLETED SCHEDULE-ын хувьд, дараачийн хуваарийн огноог тооцоо
              // Schedule таблицын schedules_date-с авсан датаг дээр үндэслэн шинэчил
              try {
                if (schedule.repeat_types === "completed" && schedule.schedules_date) {
                  const nextScheduleDates = calculateNextScheduleDate(
                    Array.isArray(schedule.schedules_date) ? schedule.schedules_date : JSON.parse(schedule.schedules_date),
                    schedule.repeat_unit
                  );
                  // Update Schedule table for completed-type schedules
                  const scheduleService = new ItemsService("Schedule", {
                    schema,
                    knex: database,
                    accountability: null,
                  });
                  await scheduleService.updateOne(schedule.id, {
                    schedules_date: JSON.stringify(nextScheduleDates)
                  });
                  console.log(`Updated Schedule ${schedule.id} with new schedules_date for completed type`);
                }
              } catch (err) {
                console.error(`Error updating Schedule dates for completed type:`, err);
              }

              await maintenanceService.updateOne(task.id, {
                last_generated: new Date(),
              });
            } else if (wo_schedule.type == "private") {
              const schedule = wo_schedule;
              if (schedule.repeat_types != "completed") continue;

              // `completed_at`-ийг `Date` объект болгон хөрвүүлэх
              const completedDate = new Date(task.completed_at);
              // console.log('completedDate_1', completedDate.getDate())
              // console.log('completedDate_2', completedDate)

              // Динамик өдрүүдийг тооцоолох (1 өдөр, 19 өдөр)
              const calculatedDates = schedule.schedules_date.map((dateObj) => {
                const nextDate = new Date(completedDate); // completedDate-ийн хуулбар үүсгэх
                nextDate.setDate(completedDate.getDate() + dateObj.date); // completedDate-аас хойшхи dateObj.date өдөр нэмэх
                return nextDate; // Бүтэн Date объектыг буцаах нь илүү хэрэгтэй
              });

              // console.log('Calculated dates:', calculatedDates);
              const calculatedDatesISO = calculatedDates.map(
                (date) => date.toISOString().split("T")[0],
              );

              const hasTodaySchedule = calculatedDatesISO.includes(todayISO);

              if (!hasTodaySchedule) {
                // console.log(`Skipping task ${task.id}: Today (${todayISO}) is not in schedules_date.`);
                continue;
              } else {
                // Өмнөх ажил системээс үүссэн эсэхийг шалгах
                console.log("checkiing ...");
                const completedTypeWo = await maintenanceService.readByQuery({
                  filter: {
                    template_pm: task.id,
                    pm_type: "completed",
                    created_type: "pm_generated",
                    action_status: 1, // үүсгэсэн
                    wo_status: 8, // pm ноорог төлөв
                    // ...(!first_work_co ? {} : { schedule: { _eq: 1 } }),
                  },
                  fields: ["*"],
                  sort: ["-id"],
                  limit: 1,
                });

                // console.log('completedTypeWo ...', completedTypeWo)

                if (completedTypeWo.length > 0) {
                  console.log("skip ...");
                  continue;
                }
              }

              // Fetch assets from Work_pm_assets
              const templateAssets = await assetService.readByQuery({
                filter: {
                  work_order: { _eq: task.id },
                },
                fields: ["assets"],
              });

              // Determine assets to process
              let assetsToProcess = [task.asset]; // Default to template task asset
              if (templateAssets.length > 0) {
                const uniqueAssets = [
                  ...new Set(templateAssets.map((a) => a.assets)),
                ];
                assetsToProcess = uniqueAssets;
              }

              // Process each asset - create separate work order for each
              for (const finalAsset of assetsToProcess) {
                // Skip if asset ID is null/undefined
                if (!finalAsset) {
                  console.warn(
                    "Skipping null/undefined asset ID in COMPLETED private schedule",
                  );
                  continue;
                }

                // Fetch asset code
                let assetCode = "";
                try {
                  const assetDetail = await assetDetailsService
                    .readOne(finalAsset, {
                      fields: ["asset_code"],
                    })
                    .catch(() => null); // Return null if asset not found
                  assetCode = assetDetail?.asset_code || "";
                  if (!assetCode) {
                    console.warn(`Asset code not found for ID: ${finalAsset}`);
                  }
                } catch (err) {
                  console.warn(
                    `Error fetching asset details for ID: ${finalAsset}:`,
                    err.message,
                  );
                }

                // Шинэ ажил үүсгэх
                const newWorkOrder = await maintenanceService.createOne({
                  name: `${task.name} - CT${assetCode ? " - " + assetCode : ""}`,
                  history_description: task.history_description,
                  safety_notes: task.safety_notes,
                  asset: finalAsset,
                  assigned_team: task.assigned_team,
                  company_id: task.company_id,
                  department: task.department,
                  location: task.location,
                  work_type: task.work_type,
                  type: task.type,
                  active: task.active,
                  pm_type: "completed",
                  created_type: "pm_generated",
                  wo_status: 8, // pm ноорог төлөв
                  action_status: 1, // үүсгэсэн
                  // type: 4, // pm төрөл
                  template_pm: task.id,
                  priority: task.priority || 2,
                  status: task.status,
                  schedule: null,
                  other_amount: task.other_amount,
                  other_actual_amount: task.other_actual_amount,
                  budget: task.budget,
                  budget_actual_amount: task.budget_actual_amount,
                  budget_planned_amount: task.budget_planned_amount,
                });

                console.log(
                  `Created_by COMPLETED PRIVATE work_order ${newWorkOrder} based on template ${task.id}`,
                );

                // Загвар ажлын дэд таскуудыг авах
                const templateItems_comp = await taskService.readByQuery({
                  filter: {
                    workorder: { _eq: task.id },
                  },
                  fields: ["*"],
                });

                // Нэмэгдэл таск үүсгэх
                for (const item of templateItems_comp) {
                  await taskService.createOne({
                    workorder: newWorkOrder,
                    name: item.name,
                    value: item.value,
                    company_id: item.company_id,
                    status: item.status,
                    code: item.code,
                    priority: item.priority,
                    parent: item.parent,
                    pos: item.pos,
                    active: item.active,
                    children: item.children,
                    template_type: item.template_type,
                    estimated_hours: item.estimated_hours,
                    instructions: item.instructions,
                    created_type: "pm_generated",
                    date_created: new Date(),
                  });
                }

                // Ажлын захиалгат кодуудыг хуулах
                const trades = await tradeService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["*"],
                });
                for (const t_item of trades) {
                  const tItem = await tradeService.createOne({
                    name: t_item.name,
                    work_order: newWorkOrder,
                    duration: t_item.duration,
                    company_id: t_item.company_id,
                    status: t_item.status,
                    rate: t_item.rate,
                    total: t_item.total,
                    trade: t_item.trade,
                    actual_duration: t_item.actual_duration,
                    actual_total: t_item.actual_total,
                    actual_rate: t_item.actual_rate,
                    date_created: new Date(),
                  });
                }

                // Ашигласан сэлбэгүүдийг хуулах
                const parts = await partService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["*"],
                });
                for (const p_item of parts) {
                  const pItem = await partService.createOne({
                    work_order: newWorkOrder,
                    quantity: p_item.quantity,
                    price: p_item.price,
                    company_id: p_item.company_id,
                    status: p_item.status,
                    amount: p_item.amount,
                    parts: p_item.parts,
                    actual_quantity: p_item.actual_quantity,
                    actual_price: p_item.actual_price,
                    actual_amount: p_item.actual_amount,
                    date_created: new Date(),
                  });
                }

                // Файлуудыг хуулах
                const files = await fileService.readByQuery({
                  filter: {
                    work_order: { _eq: task.id },
                  },
                  fields: ["*"],
                });

                for (const f_item of files) {
                  const fItem = await fileService.createOne({
                    work_order: newWorkOrder,
                    file: f_item.file,
                    status: f_item.status,
                    date_created: new Date(),
                  });
                }
              } // End of assetsToProcess loop

              // Шинэчил: COMPLETED PRIVATE SCHEDULE-ын хувьд, дараачийн хуваарийн огноог тооцоо
              try {
                if (schedule.repeat_types === "completed" && schedule.schedules_date) {
                  const nextScheduleDates = calculateNextScheduleDate(
                    Array.isArray(schedule.schedules_date) ? schedule.schedules_date : JSON.parse(schedule.schedules_date),
                    schedule.repeat_unit
                  );
                  // Update Work_pm_schedules for private completed type
                  await updateWorkOrderScheduleDate(wo_schedule.id, nextScheduleDates);
                }
              } catch (err) {
                console.error(`Error updating Work_pm_schedules for completed private type:`, err);
              }

              await maintenanceService.updateOne(task.id, {
                last_generated: new Date(),
              });
            }
            // Таск үүсгэсний дараа template_pm дээх task.id-ийг last_generated-д шинэчлэх
          } catch (error) {
            console.error(`Error processing template task ${task.id}:`, error);
          }
        }
      }

      // ******** INSPECTION ШАЛГАЛТЫН ШУУД ХУВААРЬ  ********
      try {
        const inspectionService = new ItemsService("Work_inspections", {
          schema,
          knex: database,
          accountability: null,
        });

        const inspectionItemService = new ItemsService("Work_inspection_item", {
          schema,
          knex: database,
          accountability: null,
        });

        const inspectionSchedule = new ItemsService(
          "Work_inspection_schedules",
          {
            schema,
            knex: database,
            accountability: null,
          },
        );

        const publicSchedule = new ItemsService("Schedule", {
          schema,
          knex: database,
          accountability: null,
        });

        const inspectionPartService = new ItemsService("Work_inpection_Parts", {
          schema,
          knex: database,
          accountability: null,
        });

        const inspectionFileService = new ItemsService(
          "Work_inspection_files",
          {
            schema,
            knex: database,
            accountability: null,
          },
        );

        const inspectionUsersService = new ItemsService(
          "Work_inspection_users",
          {
            schema,
            knex: database,
            accountability: null,
          },
        );

        const inspectionAssetDetailsService = new ItemsService("Assets", {
          schema,
          knex: database,
          accountability: null,
        });

        // Өнөөдрийн огноог өөр өөр форматаар авах
        const today = new Date();

        const todayISO = today.toISOString().split("T")[0]; // "ЖЖЖЖ-СС-ӨӨ" формат
        const todayDayOfMonth = today.getDate(); // Сарын өдөр (1-31)
        const todayOfmonth = today.getMonth() + 1; // 0-ээс эхэлдэг тул +1 нэмнэ
        const todayDayOfWeek = today.getDay() || 7; // Долоо хоногийн өдөр (1-7, 1=Даваа, 7=Ням)

        // const currentDate = new Date().toLocaleString("en-US", { timeZone: "Asia/Ulaanbaatar" });

        // Өнөөдрийн эхлэл ба төгсгөлийн цаг
        const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0);
        const todayEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59);

        console.log(
          `Today: ${todayISO}, Month: ${todayOfmonth}, day:${todayDayOfMonth} ,Day of Week: ${todayDayOfWeek}`,
        );

        const templateInspection = await inspectionService.readByQuery({
          filter: {
            pm_type: "inspection",
            template_pm: { _null: true },
            schedule: { _eq: 1 },
            active: { _eq: '1' },
            wo_status: 1, // шалгалт үүсгэсэн төлөв
            action_status: 2, // батлагдсан
            _or: [
              { last_generated: { _null: true } }, // Эхлээд үүсгээгүй
              { last_generated: { _lt: todayStart.toISOString() } }, // Өнөөрөө өмнөх өдөрт үүсгээгүй
              { last_generated: { _gte: todayStart.toISOString() } } // Allow time-based daily schedules to generate multiple times
            ]
          },
          fields: ["*"],
        });

        // console.log('templateInspection', templateInspection)

        if (templateInspection.length > 0) {
          console.log("length", templateInspection.length);
          // Шаблон шалгалт тус бүрийг боловсруулах
          for (const task of templateInspection) {
            try {
              const woSchedules = await inspectionSchedule.readByQuery({
                filter: {
                  work_order: { _eq: task.id },
                },
                fields: ["*"],
              });

              // console.log('Inspection - ', woSchedules, woSchedules.length)
              if (woSchedules.length <= 0) continue;
              // let wo_schedule =woSchedules[0]

              for (const wo_schedule of woSchedules) {
                if (wo_schedule.repeat_types != "direct") {
                  continue;
                }

                let scheduleDates = [];
                if (wo_schedule.type == "public") {
                  const scheduleResult = await publicSchedule.readByQuery({
                    filter: {
                      id: wo_schedule.schedule_id,
                      active: "1",
                    },
                    fields: ["*"],
                  });

                  if (scheduleResult.length <= 0) continue;
                  const schedule = scheduleResult[0];

                  if (schedule.repeat_types != "direct") continue;

                  try {
                    // Өгөгдөлийн санд JSON мөр хэлбээрээр хадгалагдсан тохиолдолд задлах
                    scheduleDates = JSON.parse(schedule.schedules_date);
                  } catch (e) {
                    // Аль хэдийн массив объект бол шууд авах
                    scheduleDates = schedule.schedules_date || [];
                  }

                  let shouldGenerateToday = false;
                  if (schedule.repeat_unit == "daily") {
                    // For daily direct inspection, check specific times in schedules_date
                    shouldGenerateToday = shouldGenerateAtTime(scheduleDates);
                    console.log("daily_inspection_time_check", shouldGenerateToday);
                  } else if (schedule.repeat_unit == "weekly") {
                    shouldGenerateToday = scheduleDates.some(
                      (item) => parseInt(item.date) === todayDayOfWeek,
                    );
                    console.log("weekly", shouldGenerateToday);
                  } else if (schedule.repeat_unit == "monthly") {
                    shouldGenerateToday = scheduleDates.some(
                      (item) => parseInt(item.date) === todayDayOfMonth,
                    );
                    console.log("monthly", shouldGenerateToday);
                  } else if (schedule.repeat_unit == "yearly") {
                    shouldGenerateToday = scheduleDates.some(
                      (item) => item.date === todayISO,
                    );
                    console.log("yearly", shouldGenerateToday);
                  }

                  if (!shouldGenerateToday) continue;
                  console.log(
                    `public_Task ${task.id}: Should generate today: ${shouldGenerateToday}`,
                  );

                  // Хэрэглэх хэрэглэгчидийг авах (public)
                  const users_inspec = await inspectionUsersService.readByQuery(
                    {
                      filter: {
                        work_order: { _eq: task.id },
                        shift_user: { _null: true },
                      },
                      fields: ["*"],
                    },
                  );

                  if (users_inspec.length == 0) continue;

                  // Determine assets to process from Work_inspection_users
                  let assetsToProcess = [];
                  if (users_inspec.length > 0) {
                    const uniqueAssets = [
                      ...new Set(
                        users_inspec.map((u) => u.asset).filter((a) => a),
                      ),
                    ];
                    assetsToProcess = uniqueAssets;
                  }

                  // If no assets from users, fall back to template asset
                  if (assetsToProcess.length === 0 && task.asset) {
                    assetsToProcess = [task.asset];
                  }

                  // Process each asset - create separate work order for each
                  for (const finalAsset of assetsToProcess) {
                    // Skip if asset is null/undefined
                    if (!finalAsset) {
                      console.warn(
                        "Skipping null/undefined asset ID in public inspection",
                      );
                      continue;
                    }

                    // Fetch asset code
                    let assetCode = "";
                    if (finalAsset) {
                      try {
                        const assetDetail =
                          await inspectionAssetDetailsService.readOne(
                            finalAsset,
                            {
                              fields: ["asset_code"],
                            },
                          );
                        assetCode = assetDetail?.asset_code || "";
                      } catch (err) {
                        console.warn(
                          `Asset details not found for ID: ${finalAsset}`,
                        );
                      }
                    }

                    for (const p_item of users_inspec) {
                      // Шинэ шалгалт үүсгэх
                      const newWorkOrder = await inspectionService.createOne({
                        name: `${task.name}${assetCode ? " - " + assetCode : ""}`,
                        history_description: task.history_description,
                        safety_notes: task.safety_notes,
                        asset: finalAsset,
                        assigned_team: task.assigned_team,
                        department: task.department,
                        company_id: task.company_id,
                        location: task.location,
                        picture: task.picture,
                        type: task.type,
                        work_type: task.work_type,
                        active: task.active,
                        pm_type: "generated",
                        created_type: "ins_generated",
                        wo_status: 1, //pm_draft
                        template_pm: task.id, //bi ene ajliin zagwaraas uussen shuu
                        priority: task.priority || 2,
                        status: task.status,
                        schedule: null,
                        other_amount: task.other_amount,
                        other_actual_amount: task.other_actual_amount,
                        budget: task.budget,
                        budget_actual_amount: task.budget_actual_amount,
                        budget_planned_amount: task.budget_planned_amount,
                      });

                      const pItem = await inspectionUsersService.createOne({
                        work_order: newWorkOrder,
                        shift_user: p_item.user,
                        // asset: finalAsset,
                        type:'generated',
                        date_created: new Date(),
                        company_id: task.company_id,
                      });

                      console.log(
                        `Created_by DIRECT_PUBLIC work_order ${newWorkOrder} based on template ${task.id}`,
                      );
                      // console.log(newWorkOrder);

                      // Загвар ажлын дэд таскуудыг авах (public inspection)
                      const templateItems =
                        await inspectionItemService.readByQuery({
                          filter: {
                            workorder: { _eq: task.id },
                          },
                          fields: ["*"],
                        });

                      // Нэмэгдэл таск үүсгэх (work_order_item.created_type='ins_generated')
                      for (const item of templateItems) {
                        const newItem = await inspectionItemService.createOne({
                          workorder: newWorkOrder, // Шинэ ажлын захиалгатай холбох
                          name: item.name,
                          value: item.value,
                          status: item.status,
                          company_id: item.company_id,
                          code: item.code,
                          priority: item.priority,
                          parent: item.parent,
                          active: item.active,
                          pos: item.pos,
                          children: item.children,
                          template_type: item.template_type,
                          estimated_hours: item.estimated_hours,
                          instructions: item.instructions,
                          created_type: "ins_generated",
                          date_created: new Date(),
                        });

                        // console.log(`Created  work_order_item ${newItem} of work_order ${newWorkOrder}`);
                      }

                      // Ашигласан сэлбэгүүдийг хуулах
                      const parts = await inspectionPartService.readByQuery({
                        filter: {
                          work_order: { _eq: task.id },
                        },
                        fields: ["*"],
                      });
                      for (const p_item of parts) {
                        const pItem = await inspectionPartService.createOne({
                          work_order: newWorkOrder,
                          quantity: p_item.quantity,
                          company_id: p_item.company_id,
                          price: p_item.price,
                          status: p_item.status,
                          amount: p_item.amount,
                          parts: p_item.parts,
                          actual_quantity: p_item.actual_quantity,
                          actual_price: p_item.actual_price,
                          actual_amount: p_item.actual_amount,
                          date_created: new Date(),
                        });
                      }

                      // Файлуудыг хуулах
                      const files = await inspectionFileService.readByQuery({
                        filter: {
                          work_order: { _eq: task.id },
                        },
                        fields: ["*"],
                      });

                      for (const f_item of files) {
                        const fItem = await inspectionFileService.createOne({
                          work_order: newWorkOrder,
                          file: f_item.file,
                          status: f_item.status,
                          date_created: new Date(),
                        });
                      }
                    }
                  } // End of assetsToProcess loop

                  // Шинэчил: Дараачийн хуваарийн огноог тооцоож, Work_inspection_schedules-ын schedules_date-г шинэчил
                  if (schedule.repeat_unit && schedule.repeat_unit !== "daily") {
                    const nextScheduleDates = calculateNextScheduleDate(scheduleDates, schedule.repeat_unit);
                    // For inspection, update Work_inspection_schedules
                    try {
                      const inspectionScheduleService = new ItemsService("Work_inspection_schedules", {
                        schema,
                        knex: database,
                        accountability: null,
                      });
                      await inspectionScheduleService.updateOne(wo_schedule.id, {
                        schedules_date: JSON.stringify(nextScheduleDates)
                      });
                      console.log(`Updated Work_inspection_schedules ${wo_schedule.id} with new schedules_date`);
                    } catch (err) {
                      console.error(`Error updating Work_inspection_schedules ${wo_schedule.id}:`, err);
                    }
                  } else if (schedule.repeat_unit === "daily") {
                    // Persist the _lastFiredDate marker set by shouldGenerateAtTime so this
                    // time slot doesn't fire again today within the catch-up window
                    await publicSchedule.updateOne(schedule.id, {
                      schedules_date: JSON.stringify(scheduleDates),
                    });
                  }

                  // Only update last_generated for non-time-based schedules (weekly, monthly, yearly)
                  // For daily time-based schedules, allow multiple generations throughout the day
                  if (schedule.repeat_unit !== "daily") {
                    await inspectionService.updateOne(task.id, {
                      last_generated: new Date(),
                    });
                  }
                } else if (wo_schedule.type == "private") {
                  try {
                    // Өгөгдөлийн санд JSON мөр хэлбээрээр хадгалагдсан тохиолдолд задлах
                    scheduleDates = JSON.parse(wo_schedule.schedules_date);
                  } catch (e) {
                    // Аль хэдийн массив объект бол шууд авах
                    scheduleDates = wo_schedule.schedules_date || [];
                  }

                  let shouldGenerateToday = false;

                  if (wo_schedule.repeat_unit == "daily") {
                    // For daily direct inspection, check specific times in schedules_date
                    shouldGenerateToday = shouldGenerateAtTime(scheduleDates);
                    console.log("daily_private_inspection_time_check", shouldGenerateToday);
                  } else if (wo_schedule.repeat_unit == "weekly") {
                    shouldGenerateToday = scheduleDates.some(
                      (item) => parseInt(item.date) === todayDayOfWeek,
                    );
                    console.log("weekly_private", shouldGenerateToday);
                  } else if (wo_schedule.repeat_unit == "monthly") {
                    shouldGenerateToday = scheduleDates.some(
                      (item) => parseInt(item.date) === todayDayOfMonth,
                    );
                    console.log("monthly_private", shouldGenerateToday);
                  } else if (wo_schedule.repeat_unit == "yearly") {
                    shouldGenerateToday = scheduleDates.some(
                      (item) =>
                        item.month === todayOfmonth &&
                        item.date === todayDayOfMonth,
                    );
                    console.log("yearly_private", shouldGenerateToday);
                  }

                  if (!shouldGenerateToday) continue;
                  // console.log(`private_Task ${task.id}: Should generate today: ${shouldGenerateToday}`);

                  // Хэрэглэх хэрэглэгчидийг авах (private)
                  const users_inspec = await inspectionUsersService.readByQuery(
                    {
                      filter: {
                        work_order: { _eq: task.id },
                        shift_user: { _null: true },
                      },
                      fields: ["*"],
                    },
                  );

                  if (users_inspec.length == 0) continue;

                  // Determine assets to process from Work_inspection_users
                  let assetsToProcess = [];
                  if (users_inspec.length > 0) {
                    const uniqueAssets = [
                      ...new Set(
                        users_inspec.map((u) => u.asset).filter((a) => a),
                      ),
                    ];
                    assetsToProcess = uniqueAssets;
                  }

                  // If no assets from users, fall back to template asset
                  if (assetsToProcess.length === 0 && task.asset) {
                    assetsToProcess = [task.asset];
                  }

                  // Process each asset - create separate work order for each
                  for (const finalAsset of assetsToProcess) {
                    // Skip if asset is null/undefined
                    if (!finalAsset) {
                      console.warn(
                        "Skipping null/undefined asset ID in private inspection",
                      );
                      continue;
                    }

                    // Fetch asset code
                    let assetCode = "";
                    if (finalAsset) {
                      try {
                        const assetDetail =
                          await inspectionAssetDetailsService.readOne(
                            finalAsset,
                            {
                              fields: ["asset_code"],
                            },
                          );
                        assetCode = assetDetail?.asset_code || "";
                      } catch (err) {
                        console.warn(
                          `Asset details not found for ID: ${finalAsset}`,
                        );
                      }
                    }

                    for (const p_item of users_inspec) {
                      // Шинэ шалгалт үүсгэх
                      const newWorkOrder = await inspectionService.createOne({
                        name: `${task.name}${assetCode ? " - " + assetCode : ""}`,
                        history_description: task.history_description,
                        company_id: task.company_id,
                        safety_notes: task.safety_notes,
                        asset: finalAsset,
                        assigned_team: task.assigned_team,
                        department: task.department,
                        location: task.location,
                        picture: task.picture,
                        type: task.type,
                        work_type: task.work_type,
                        active: task.active,
                        pm_type: "generated",
                        created_type: "ins_generated",
                        wo_status: 1, // шалгалт үүсгэсэн төлөв
                        template_pm: task.id, // Энэ ажил аль загвараас үүссэнийг заах
                        priority: task.priority || 2,
                        status: task.status,
                        schedule: null,
                        other_amount: task.other_amount,
                        other_actual_amount: task.other_actual_amount,
                        budget: task.budget,
                        budget_actual_amount: task.budget_actual_amount,
                        budget_planned_amount: task.budget_planned_amount,
                      });

                      const pItem = await inspectionUsersService.createOne({
                        work_order: newWorkOrder,
                        shift_user: p_item.user,
                        // asset: finalAsset,
                        type:'generated',          
                        company_id: task.company_id,              
                        date_created: new Date(),
                      });

                      console.log(
                        `Created_by DIRECT PRIVATE INSPECTION ${newWorkOrder} based on template ${task.id}`,
                      );
                      // console.log(newWorkOrder);

                      // Загвар ажлын дэд таскуудыг авах (private inspection)
                      const templateItems =
                        await inspectionItemService.readByQuery({
                          filter: {
                            workorder: { _eq: task.id },
                          },
                          fields: ["*"],
                        });

                      // Нэмэгдэл таск үүсгэх (work_order_item.created_type='ins_generated')
                      for (const item of templateItems) {
                        const newItem = await inspectionItemService.createOne({
                          workorder: newWorkOrder, // Шинэ ажлын захиалгатай холбох
                          name: item.name,
                          company_id: item.company_id,
                          value: item.value,
                          status: item.status,
                          code: item.code,
                          priority: item.priority,
                          parent: item.parent,
                          children: item.children,
                          pos: item.pos,
                          active: item.active,
                          template_type: item.template_type,
                          estimated_hours: item.estimated_hours,
                          instructions: item.instructions,
                          created_type: "ins_generated",
                          date_created: new Date(),
                        });
                      }

                      // Ашигласан сэлбэгүүдийг хуулах
                      const parts = await inspectionPartService.readByQuery({
                        filter: {
                          work_order: { _eq: task.id },
                        },
                        fields: ["*"],
                      });
                      for (const p_item of parts) {
                        const pItem = await inspectionPartService.createOne({
                          work_order: newWorkOrder,
                          quantity: p_item.quantity,
                          price: p_item.price,
                          company_id: p_item.company_id,
                          status: p_item.status,
                          amount: p_item.amount,
                          parts: p_item.parts,
                          actual_quantity: p_item.actual_quantity,
                          actual_price: p_item.actual_price,
                          actual_amount: p_item.actual_amount,
                          date_created: new Date(),
                        });
                      }

                      // Файлуудыг хуулах
                      const files = await inspectionFileService.readByQuery({
                        filter: {
                          work_order: { _eq: task.id },
                        },
                        fields: ["*"],
                      });

                      for (const f_item of files) {
                        const fItem = await inspectionFileService.createOne({
                          work_order: newWorkOrder,
                          file: f_item.file,
                          status: f_item.status,
                          date_created: new Date(),
                        });
                      }
                    }
                  } // End of assetsToProcess loop

                  // Шинэчил: Дараачийн хуваарийн огноог тооцоож, Work_inspection_schedules-ын schedules_date-г шинэчил
                  if (wo_schedule.repeat_unit && wo_schedule.repeat_unit !== "daily") {
                    const nextScheduleDates = calculateNextScheduleDate(scheduleDates, wo_schedule.repeat_unit);
                    // For inspection private, update Work_inspection_schedules
                    try {
                      const inspectionScheduleService = new ItemsService("Work_inspection_schedules", {
                        schema,
                        knex: database,
                        accountability: null,
                      });
                      await inspectionScheduleService.updateOne(wo_schedule.id, {
                        schedules_date: JSON.stringify(nextScheduleDates)
                      });
                      console.log(`Updated Work_inspection_schedules ${wo_schedule.id} with new schedules_date (private)`);
                    } catch (err) {
                      console.error(`Error updating Work_inspection_schedules ${wo_schedule.id} (private):`, err);
                    }
                  } else if (wo_schedule.repeat_unit === "daily") {
                    // Persist the _lastFiredDate marker set by shouldGenerateAtTime so this
                    // time slot doesn't fire again today within the catch-up window
                    try {
                      await inspectionSchedule.updateOne(wo_schedule.id, {
                        schedules_date: JSON.stringify(scheduleDates),
                      });
                    } catch (err) {
                      console.error(`Error updating Work_inspection_schedules ${wo_schedule.id} (private daily):`, err);
                    }
                  }

                  // Only update last_generated for non-time-based schedules (weekly, monthly, yearly)
                  // For daily time-based schedules, allow multiple generations throughout the day
                  if (wo_schedule.repeat_unit !== "daily") {
                    await inspectionService.updateOne(task.id, {
                      last_generated: new Date(),
                    });
                  }
                }
              }
            } catch (error) {
              console.error(`Error direct template task ${task.id}:`, error);
            }
          }
        }
      } catch (error) {
        console.error("Error in INSPECTION cron job:", error);
      }
    } catch (error) {
      console.error("Error in CMMS cron job:", error);
    }
  });

  // ******** PDM Нөхцөл Шалгагч: 3 минут бүр ажиллах ********
  schedule("*/20 * * * *", async () => {
    try {
      console.log(`Running PDM scheduled ${new Date().toISOString()}`);
      const schema = await getSchema();
      const { ItemsService } = services;

      const predictiveConfigService = new ItemsService(
        "Predictive_tracking_configs",
        { schema, knex: database, accountability: null },
      );

      const assetFieldDataService = new ItemsService("Asset_field_data_json", {
        schema,
        knex: database,
        accountability: null,
      });

      const predictiveService = new ItemsService("Predictive", {
        schema,
        knex: database,
        accountability: null,
      });

      const deviceTrackingFieldsService = new ItemsService(
        "Device_tracking_fields",
        { schema, knex: database, accountability: null },
      );

      // Хамгийн сүүлийн датахаб мөрийг авах (утга + metadata)
      async function getLatestDatahubEntry(assetId, fieldKey) {
        const rows = await assetFieldDataService.readByQuery({
          filter: { asset: { _eq: assetId } },
          sort: ["-timestamp_date"],
          limit: 1,
          fields: ["id", "timestamp", "timestamp_date", "field_values"],
        });
        if (!rows || rows.length === 0) return null;
        const row = rows[0];
        const rawValue = row?.field_values?.[fieldKey];
        if (rawValue == null) return null;

        const value = parseFloat(rawValue);
        if (Number.isNaN(value)) return null;

        return {
          id: row?.id ?? null,
          timestamp: row?.timestamp ?? null,
          timestamp_date: row?.timestamp_date ?? null,
          value,
        };
      }

      // Хамгийн сүүлийн датахаб утгыг авах
      async function getLatestDatahub(assetId, fieldKey) {
        const entry = await getLatestDatahubEntry(assetId, fieldKey);
        return entry ? entry.value : null;
      }

      // start_date болон lastValue сууриас хойших хамгийн эхний тохирох датахаб мөрийг олох
      async function getNextDatahubAfterValue(
        assetId,
        fieldKey,
        lastValue,
        startDate = null,
        minValue = null,
      ) {
        const rows = await assetFieldDataService.readByQuery({
          filter: { asset: { _eq: assetId } },
          sort: ["timestamp_date"],
          limit: -1,
          fields: ["id", "timestamp", "timestamp_date", "field_values"],
        });

        if (!rows || rows.length === 0) return null;

        const parsedStartDate = startDate ? new Date(startDate) : null;
        const hasValidStartDate =
          parsedStartDate && !Number.isNaN(parsedStartDate.getTime());

        for (const row of rows) {
          const rowTimestamp = row?.timestamp_date
            ? new Date(row.timestamp_date)
            : null;
          const hasValidRowTimestamp =
            rowTimestamp && !Number.isNaN(rowTimestamp.getTime());

          if (
            hasValidStartDate &&
            hasValidRowTimestamp &&
            rowTimestamp < parsedStartDate
          ) {
            continue;
          }

          const raw = row?.field_values?.[fieldKey];
          const value = raw != null ? parseFloat(raw) : null;
          if (value == null || Number.isNaN(value)) continue;
          if (minValue != null && value < minValue) continue;
          if (value > lastValue) {
            return {
              id: row?.id ?? null,
              timestamp: row?.timestamp ?? null,
              timestamp_date: row?.timestamp_date ?? null,
              value,
            };
          }
        }

        return null;
      }

      // PDM ажлын захиалга үүсгэх
      async function createPDMWorkOrder(
        config,
        triggeredAtValue,
        datahubEntry = null,
      ) {
        let datahubHistory = "";
        if (datahubEntry) {
          const epochTs = datahubEntry.timestamp;
          const ts = datahubEntry.timestamp_date;
          const parsedTs = ts ? new Date(ts) : null;
          const dateOnly =
            parsedTs && !Number.isNaN(parsedTs.getTime())
              ? parsedTs.toISOString().split("T")[0]
              : "N/A";
          datahubHistory = `Asset_field_data_json id=${datahubEntry.id ?? "N/A"}, timestamp=${epochTs ?? "N/A"}, timestamp_date=${ts ?? "N/A"}, date=${dateOnly}`;
        }

        let location = null;
        let priority = null;
        let work_type = null;
        let department = null;
        let pmWo = null;
        if (config.pm_work_order) {
          try {
            const pmWoService = new ItemsService("Predictive", {
              schema,
              knex: database,
              accountability: null,
            });
            
            pmWo = await pmWoService.readOne(config.pm_work_order, {
              fields: ["*"]
            });
            // action_status=2 (approved) биш бол үүсгэхгүй
            if ((pmWo?.action_status ?? null) !== 2) {
              console.log(
                `[pdm-checker] Config #${config.id}: pm_work_order #${config.pm_work_order} action_status=${pmWo?.action_status} (approved биш), алгасав.`,
              );
              return null;
            }
            department = pmWo?.department ?? null;
            priority = pmWo?.priority ?? null;
            location = pmWo?.location ?? null;
            work_type = pmWo?.work_type ?? null;
            group_type = pmWo?.type ?? null;
          } catch (err) {
            console.error(
              `[pdm-checker] pm_work_order #${config.pm_work_order} уншихад алдаа: ${err.message}`,
            );
            return null;
          }
        }
        const createPayload = {
          name: `${config.pm_name || "PDM"}-${triggeredAtValue}`,
          type: 4,
          priority: priority,
          company_id: config.company_id,
          department: department,
          assigned_team: pmWo?.assigned_team ?? null,
          history_description: pmWo?.history_description ?? '',
          safety_notes: pmWo?.safety_notes ?? '',
          pm_type: "pdm_generated",
          created_type: "pdm_generated",
          action_status: 1,
          wo_status: 8,
          active: 1,
          asset: config.asset,
          location: location,
          work_type: work_type,
          type: group_type,
          datahub_info: datahubHistory,
          template_pm: config.pm_work_order,
          predictive_trigger_value: triggeredAtValue,
          predictive_config: config.id,
          other_amount: pmWo?.other_amount ?? '',
          other_actual_amount: pmWo?.other_actual_amount ?? '',
          budget: pmWo?.budget ?? '',
          budget_actual_amount: pmWo?.budget_actual_amount ?? '',
          budget_planned_amount: pmWo?.budget_planned_amount ?? '',
        };

        if (datahubEntry?.timestamp != null) {
          createPayload.timestamp = datahubEntry.timestamp;
        }

        const wo = await predictiveService.createOne(createPayload);

        // Template Predictive-аас холбоост бичлэгүүдийг хуулах
        if (config.pm_work_order) {
          try {
            const pdmItemService = new ItemsService("Predictive_item", {
              schema,
              knex: database,
              accountability: null,
            });
            const pdmTradeService = new ItemsService("Predictive_Tradecode", {
              schema,
              knex: database,
              accountability: null,
            });
            const pdmPartService = new ItemsService("Predictive_Parts", {
              schema,
              knex: database,
              accountability: null,
            });
            const pdmFileService = new ItemsService("Predictive_files", {
              schema,
              knex: database,
              accountability: null,
            });

            // Predictive_item хуулах
            const tmplItems = await pdmItemService.readByQuery({
              filter: { workorder: { _eq: config.pm_work_order } },
              fields: ["*"],
            });
            for (const item of tmplItems) {
              await pdmItemService.createOne({
                workorder: wo,
                name: item.name,
                company_id: item.company_id,
                value: item.value,
                status: item.status,
                code: item.code,
                priority: item.priority,
                parent: item.parent,
                pos: item.pos,
                active: item.active,
                children: item.children,
                template_type: item.template_type,
                estimated_hours: item.estimated_hours,
                instructions: item.instructions,
                created_type: "pdm_generated",
                date_created: new Date(),
              });
            }
            console.log(
              `[pdm-checker] Predictive #${wo}: ${tmplItems.length} item хуулав.`,
            );

            // Predictive_Tradecode хуулах
            const tmplTrades = await pdmTradeService.readByQuery({
              filter: { work_order: { _eq: config.pm_work_order } },
              fields: ["*"],
            });
            for (const t of tmplTrades) {
              await pdmTradeService.createOne({
                work_order: wo,
                name: t.name,
                company_id: t.company_id,
                duration: t.duration,
                status: t.status,
                rate: t.rate,
                total: t.total,
                trade: t.trade,
                actual_duration: t.actual_duration,
                actual_total: t.actual_total,
                actual_rate: t.actual_rate,
                date_created: new Date(),
              });
            }
            console.log(
              `[pdm-checker] Predictive #${wo}: ${tmplTrades.length} tradecode хуулав.`,
            );

            // Predictive_Parts хуулах
            const tmplParts = await pdmPartService.readByQuery({
              filter: { work_order: { _eq: config.pm_work_order } },
              fields: ["*"],
            });
            for (const p of tmplParts) {
              await pdmPartService.createOne({
                work_order: wo,
                quantity: p.quantity,
                company_id: p.company_id,
                price: p.price,
                status: p.status,
                amount: p.amount,
                parts: p.parts,
                actual_quantity: p.actual_quantity,
                actual_price: p.actual_price,
                actual_amount: p.actual_amount,
                date_created: new Date(),
              });
            }
            console.log(
              `[pdm-checker] Predictive #${wo}: ${tmplParts.length} part хуулав.`,
            );

            // Predictive_files хуулах
            const tmplFiles = await pdmFileService.readByQuery({
              filter: { work_order: { _eq: config.pm_work_order } },
              fields: ["*"],
            });
            for (const f of tmplFiles) {
              await pdmFileService.createOne({
                work_order: wo,
                file: f.file,
                status: f.status,
                date_created: new Date(),
              });
            }
            console.log(
              `[pdm-checker] Predictive #${wo}: ${tmplFiles.length} file хуулав.`,
            );
          } catch (err) {
            console.error(
              `[pdm-checker] Predictive #${wo} холбоост бичлэг хуулахад алдаа: ${err.message}`,
            );
          }
        }

        return wo;
      }

      // ── Interval тохиргоог боловсруулах (Тоолуортай) ──────────────────────
      let intervalConfigs = [];
      try {
        intervalConfigs = await predictiveConfigService.readByQuery({
          filter: { threshold_type: { _eq: "interval" } },
          limit: -1,
          fields: [
            "id",
            "asset",
            "field_key",
            "pm_name",
            "start_point",
            "trigger_interval",
            "last_triggered_value",
            "pm_work_order",
            "company_id",
          ],
        });
      } catch (err) {
        console.error(
          `[pdm-checker] Interval тохиргоо уншихад алдаа: ${err.message}`,
        );
      }

      if (intervalConfigs.length) {
        console.log(
          `[pdm-checker] ${intervalConfigs.length} interval тохиргоо боловсруулж байна...`,
        );
        for (const config of intervalConfigs) {
          try {
            const {
              id,
              asset,
              field_key,
              trigger_interval,
              pm_name,
              start_point,
              company_id,
            } = config;
            const startPoint = parseFloat(start_point);
            const hasStartPoint = !Number.isNaN(startPoint);

            let lastTriggered = parseFloat(config.last_triggered_value);
            if (Number.isNaN(lastTriggered)) {
              lastTriggered = hasStartPoint ? startPoint : 0;
            }
            const interval = parseFloat(trigger_interval);

            if (!interval || interval <= 0) {
              console.log(
                `[pdm-checker] Config #${id}: trigger_interval буруу (${trigger_interval}), алгасав.`,
              );
              continue;
            }

            const currentEntry = await getLatestDatahubEntry(asset, field_key);
            const currentValue = currentEntry ? currentEntry.value : null;
            if (currentValue === null) {
              console.log(
                `[pdm-checker] Config #${id} (asset ${asset}/${field_key}): датахаб өгөгдөл байхгүй, алгасав.`,
              );
              continue;
            }

            if (hasStartPoint && currentValue < startPoint) {
              console.log(
                `[pdm-checker] Config #${id}: current (${currentValue}) < start_point (${startPoint}), trigger хийхгүй.`,
              );
              continue;
            }

            console.log(
              `[pdm-checker] Config #${id} | asset=${asset} | field=${field_key} | current=${currentValue} | startPoint=${hasStartPoint ? startPoint : "null"} | lastTriggered=${lastTriggered} | interval=${interval}`,
            );

            let elapsed = currentValue - lastTriggered;
            let createdCount = 0;

            while (elapsed >= interval) {
              const triggerPoint = lastTriggered + interval;
              console.log(
                `[pdm-checker]   → "${pm_name}" PM үүсгэж байна, trigger point: ${triggerPoint}`,
              );

              let wo;
              try {
                wo = await createPDMWorkOrder(
                  config,
                  triggerPoint,
                  currentEntry,
                );
                if (wo === null) break;
                console.log(`[pdm-checker]   → Predictive #${wo} үүсгэлээ`);
              } catch (err) {
                console.error(
                  `[pdm-checker]   → Predictive үүсгэхэд алдаа: ${err.message}`,
                );
                break;
              }

              lastTriggered = triggerPoint;
              createdCount++;

              try {
                await predictiveConfigService.updateOne(id, {
                  last_triggered_value: lastTriggered,
                });
              } catch (err) {
                console.error(
                  `[pdm-checker]   → last_triggered_value шинэчлэхэд алдаа: ${err.message}`,
                );
                break;
              }

              elapsed = currentValue - lastTriggered;
            }

            if (createdCount > 0) {
              console.log(
                `[pdm-checker] Config #${id}: ${createdCount} PM үүсгэлээ, шинэ lastTriggered=${lastTriggered}`,
              );
            } else {
              console.log(
                `[pdm-checker] Config #${id}: PM шаардлагагүй (elapsed ${elapsed.toFixed(2)} < interval ${interval})`,
              );
            }
          } catch (err) {
            console.error(
              `[pdm-checker] Interval config #${config.id} алдаа: ${err.message}`,
            );
          }
        }
      } else {
        console.log("[pdm-checker] Interval тохиргоо олдсонгүй.");
      }

      // ── Threshold тохиргоог боловсруулах (Тоолуургүй) ────────────────────
      let thresholdConfigs = [];
      try {
        thresholdConfigs = await predictiveConfigService.readByQuery({
          filter: { threshold_type: { _nin: ["interval"] } },
          limit: -1,
          fields: [
            "id",
            "asset",
            "field_key",
            "field",
            "start_date",
            "threshold_value",
            "pm_name",
            "triggered_at",
            "pm_work_order",
          ],
        });
      } catch (err) {
        console.error(
          `[pdm-checker] Threshold тохиргоо уншихад алдаа: ${err.message}`,
        );
      }

      if (thresholdConfigs.length) {
        console.log(
          `[pdm-checker] ${thresholdConfigs.length} threshold тохиргоо боловсруулж байна...`,
        );
        for (const config of thresholdConfigs) {
          try {
            const {
              id,
              asset,
              field_key,
              field,
              start_date,
              threshold_value,
              pm_name,
              triggered_at,
            } = config;

            let nextPendingEntry = null;
            let latestGeneratedRecord = null;

            // Аль хэдийн trigger болсон бол, хамгийн сүүлийн generated PDM хаагдсан эсэхийг шалгана.
            if (triggered_at) {
              let latestGenerated = [];
              try {
                latestGenerated = await predictiveService.readByQuery({
                  filter: {
                    predictive_config: { _eq: id },
                    pm_type: { _eq: "pdm_generated" },
                    created_type: { _eq: "pdm_generated" },
                  },
                  sort: ["-id"],
                  limit: 1,
                  fields: ["id", "wo_status", "predictive_trigger_value"],
                });
              } catch (err) {
                console.error(
                  `[pdm-checker] Config #${id}: latest generated PDM шалгахад алдаа: ${err.message}`,
                );
                continue;
              }

              const latest = latestGenerated[0];
              latestGeneratedRecord = latest || null;
              if (latest && parseInt(latest.wo_status) === 3) {
                const lastGeneratedValue = parseFloat(
                  latest.predictive_trigger_value,
                );
                const baselineValue = Number.isNaN(lastGeneratedValue)
                  ? -Infinity
                  : lastGeneratedValue;

                try {
                  nextPendingEntry = await getNextDatahubAfterValue(
                    asset,
                    field_key,
                    baselineValue,
                    start_date,
                  );
                } catch (err) {
                  console.error(
                    `[pdm-checker] Config #${id}: next pending датахаб уншихад алдаа: ${err.message}`,
                  );
                  continue;
                }

                if (nextPendingEntry == null) {
                  console.log(
                    `[pdm-checker] Config #${id}: хаасны дараах шинэ датахаб утга алга, triggered_at хэвээр үлдээнэ.`,
                  );
                  continue;
                }

                try {
                  await predictiveConfigService.updateOne(id, {
                    triggered_at: null,
                  });
                  console.log(
                    `[pdm-checker] Config #${id}: latest generated PDM #${latest.id} хаагдсан (wo_status=3), шинэ pending утга олдсон тул triggered_at reset хийлээ.`,
                  );
                } catch (err) {
                  console.error(
                    `[pdm-checker] Config #${id}: triggered_at reset хийхэд алдаа: ${err.message}`,
                  );
                  continue;
                }
              } else {
                console.log(
                  `[pdm-checker] Config #${id} (threshold): ${triggered_at}-д аль хэдийн trigger болсон, latest PDM хаагдаагүй тул алгасав.`,
                );
                continue;
              }
            }

            if (!field || !threshold_value) {
              console.log(
                `[pdm-checker] Config #${id}: field эсвэл threshold_value байхгүй, алгасав.`,
              );
              continue;
            }

            let trackingField;
            try {
              trackingField = await deviceTrackingFieldsService.readOne(field, {
                fields: [threshold_value],
              });
            } catch (err) {
              console.log(
                `[pdm-checker] Config #${id}: Device_tracking_fields/${field} уншихад алдаа: ${err.message}`,
              );
              continue;
            }

            const threshold = parseFloat(trackingField[threshold_value]);
            if (!threshold && threshold !== 0) {
              console.log(
                `[pdm-checker] Config #${id}: Device_tracking_fields-аас threshold утга буруу (${trackingField[threshold_value]}), алгасав.`,
              );
              continue;
            }

            if (nextPendingEntry == null) {
              try {
                nextPendingEntry = await getNextDatahubAfterValue(
                  asset,
                  field_key,
                  -Infinity,
                  start_date,
                  threshold,
                );
              } catch (err) {
                console.error(
                  `[pdm-checker] Config #${id}: start_date-аас хойших threshold датахаб уншихад алдаа: ${err.message}`,
                );
                continue;
              }
            }

            const currentEntry =
              nextPendingEntry != null
                ? nextPendingEntry
                : await getLatestDatahubEntry(asset, field_key);
            const currentValue = currentEntry ? currentEntry.value : null;
            if (currentValue === null) {
              console.log(
                `[pdm-checker] Config #${id} (asset ${asset}/${field_key}): датахаб өгөгдөл байхгүй, алгасав.`,
              );
              continue;
            }

            console.log(
              `[pdm-checker] Config #${id} | threshold | asset=${asset} | field=${field_key} | current=${currentValue} | threshold=${threshold}`,
            );

            // Сүүлийн generated (closed) бичлэгтэй ижил/бага утгыг дахин үүсгэхээс хамгаална.
            if (!latestGeneratedRecord) {
              try {
                const latestGenerated = await predictiveService.readByQuery({
                  filter: {
                    predictive_config: { _eq: id },
                    pm_type: { _eq: "pdm_generated" },
                    created_type: { _eq: "pdm_generated" },
                  },
                  sort: ["-id"],
                  limit: 1,
                  fields: ["id", "wo_status", "predictive_trigger_value"],
                });
                latestGeneratedRecord = latestGenerated[0] || null;
              } catch (err) {
                console.error(
                  `[pdm-checker] Config #${id}: latest generated PDM давхардал шалгахад алдаа: ${err.message}`,
                );
              }
            }

            if (
              latestGeneratedRecord &&
              parseInt(latestGeneratedRecord.wo_status) === 3
            ) {
              const latestGeneratedValue = parseFloat(
                latestGeneratedRecord.predictive_trigger_value,
              );
              if (
                !Number.isNaN(latestGeneratedValue) &&
                currentValue <= latestGeneratedValue
              ) {
                console.log(
                  `[pdm-checker] Config #${id}: current (${currentValue}) <= last closed generated value (${latestGeneratedValue}), давхардуулж үүсгэхгүй.`,
                );
                continue;
              }
            }

            if (currentValue >= threshold) {
              console.log(
                `[pdm-checker]   → ${currentValue} >= ${threshold}, "${pm_name}" PM үүсгэж байна...`,
              );
              let wo;
              try {
                wo = await createPDMWorkOrder(
                  config,
                  currentValue,
                  currentEntry,
                );
                if (wo === null) continue;
                console.log(`[pdm-checker]   → Predictive #${wo} үүсгэлээ`);
              } catch (err) {
                console.error(
                  `[pdm-checker]   → Predictive үүсгэхэд алдаа: ${err.message}`,
                );
                continue;
              }

              try {
                const updatedId = await predictiveConfigService.updateOne(id, {
                  triggered_at: new Date(),
                });
                console.log(
                  `[pdm-checker]   → triggered_at тэмдэглэлээ (id=${updatedId}). Reset хийтэл дахин trigger болохгүй.`,
                );
              } catch (err) {
                console.error(
                  `[pdm-checker]   → triggered_at тохируулахад алдаа: ${err.message}`,
                );
              }
            } else {
              console.log(
                `[pdm-checker] Config #${id}: ${currentValue} < threshold ${threshold}, үйлдэл хийгдсэнгүй.`,
              );
            }
          } catch (err) {
            console.error(
              `[pdm-checker] Threshold config #${config.id} алдаа: ${err.message}`,
            );
          }
        }
      } else {
        console.log("[pdm-checker] Threshold тохиргоо олдсонгүй.");
      }

      console.log("[pdm-checker] Дууслаа.");
    } catch (err) {
      console.error("[pdm-checker] Боловсруулалтын алдаа:", err);
    }
  });

  

};
