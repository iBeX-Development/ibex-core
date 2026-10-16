const axios = require("axios");
const admin = require("firebase-admin");
const serviceAccount = require("../service_account.json"); // Firebase Admin SDK

module.exports = async function form_req(
  router,
  { services, exceptions, database, getSchema },
) {
  const { FieldsService, ItemsService } = services;
  const errors = await import("@directus/errors").then((errors) => errors);

  router.get("/new", async (_req, res, next) => {
    if (!_req.accountability.user) {
      const ForbiddenError = errors.createError(
        "FORBIDDEN",
        "You don't have permissions to see this.",
        403,
      );
      return next(new ForbiddenError());
    }
    // Template code
    const code = _req.query["code"] ? _req.query["code"] : "";
    const row = _req.query["row"] ? _req.query["row"] : "";
    const fields = _req.query["fields"] ? _req.query["fields"].split(",") : [];
    const result_fields = [];
    const fieldService = new FieldsService({
      schema: _req.schema,
      accountability: _req.accountability,
    });
    if (code != "") {
      // console.log(fieldService['schema']['relations'])
      const fieldRelations = fieldService["schema"]["relations"].filter(
        (item) =>
          item["collection"] === code || item["related_collection"] === code,
      );
      const directusService = new ItemsService("directus_fields", {
        schema: _req.schema,
        accountability: _req.accountability,
      });
      const rowService = new ItemsService(code, {
        schema: _req.schema,
        accountability: _req.accountability,
      });
      const directus_fields = await directusService
        .readByQuery({
          filter: {
            collection: code,
          },
          sort: ["id"],
          fields: ["*"],
        })
        .then((results) => {
          return results;
        })
        .catch((error) => {
          const ServiceUnavailableException = errors.createError(
            "Service unavailable",
            error.message,
            403,
          );
          return next(new ServiceUnavailableException(error.message));
        });
      const record = await rowService
        .readByQuery({
          filter: {
            id: row,
          },
          sort: ["id"],
          fields: ["*"],
        })
        .then((results) => {
          return results;
        })
        .catch((error) => {
          const ServiceUnavailableException = errors.createError(
            "Service unavailable",
            error.message,
            403,
          );
          return next(new ServiceUnavailableException(error.message));
        });
      // console.log(record)
      // console.log(directus_fields)
      // console.log(fieldService['schema']['collections'][code]['fields'])
      // console.log(fieldRelations)
      if (
        fieldService &&
        fieldService["schema"] &&
        fieldService["schema"]["collections"] &&
        fieldService["schema"]["collections"][code] &&
        fieldService["schema"]["collections"][code]["fields"]
      ) {
        for (const [key, value] of Object.entries(
          fieldService["schema"]["collections"][code]["fields"],
        )) {
          let temp_field = null;
          let directusField = directus_fields.filter(
            (item) => item["field"] === value["field"],
          );
          let is_o2m_includes = fieldRelations
            .map((item) => item.field)
            .includes(value["field"]);
          let is_m2m_includes = fieldRelations
            .map((item) => item.meta?.one_field)
            .filter(Boolean)
            .includes(value["field"]);
          //console.log(!is_o2m_includes && !is_m2m_includes)
          //console.log(value)
          console.log(is_o2m_includes, is_m2m_includes);
          if (!is_o2m_includes && !is_m2m_includes) {
            //Foreign key check
            //console.log("Condition in ...")
            if (
              value["defaultValue"] !== "AUTO_INCREMENT" &&
              value["field"] !== "active" &&
              (value["type"] === "float" || value["type"] === "integer")
            ) {
              temp_field = {
                $formkit: "number",
                label:
                  value["field"].charAt(0).toUpperCase() +
                  value["field"].slice(1),
                name: value["field"],
                help: value["note"] ? value["note"] : "",
              };
              if (directusField[0]?.["required"]) {
                temp_field["validation"] = "required";
              }
              if (value["type"] === "float") {
                temp_field["step"] = "any";
              } else {
                temp_field["step"] = "1";
              }
            } else if (value["type"] === "dateTime") {
              temp_field = {
                $formkit: "datetime-local",
                label:
                  value["field"].charAt(0).toUpperCase() +
                  value["field"].slice(1),
                name: value["field"],
                help: value["note"] ? value["note"] : "",
              };
              if (directusField[0]?.["required"]) {
                temp_field["validation"] = "required";
              }
            } else if (value["type"] === "date") {
              temp_field = {
                $formkit: "date-local",
                label:
                  value["field"].charAt(0).toUpperCase() +
                  value["field"].slice(1),
                name: value["field"],
                help: value["note"] ? value["note"] : "",
              };
              if (directusField[0]?.["required"]) {
                temp_field["validation"] = "required";
              }
            } else if (value["type"] === "text") {
              temp_field = {
                $formkit: "textarea",
                label:
                  value["field"].charAt(0).toUpperCase() +
                  value["field"].slice(1),
                name: value["field"],
                help: value["note"] ? value["note"] : "",
              };
              if (directusField[0]?.["required"]) {
                temp_field["validation"] = "required";
              }
            } else if (value["type"] === "string") {
              temp_field = {
                $formkit: "text",
                label:
                  value["field"].charAt(0).toUpperCase() +
                  value["field"].slice(1),
                name: value["field"],
                help: value["note"] ? value["note"] : "",
              };
              if (directusField[0]?.["required"]) {
                temp_field["validation"] = "required";
              }

              switch (directusField[0]?.["interface"]) {
                case "boolean":
                  temp_field["$formkit"] = "checkbox";
                  break;
                case "input":
                  temp_field["$formkit"] = "text";
                  break;
                case "datetime":
                  temp_field["$formkit"] = "datetime-local";
                  break;
                case "input-code":
                  temp_field["$formkit"] = "text";
                  break;
                case "input-multiline":
                  temp_field["$formkit"] = "textarea";
                  break;
                case "select-dropdown":
                  temp_field["$formkit"] = "select";
                  //temp_field["options"] = directusField[0]['options']['choices']
                  let options = directusField[0]?.["options"]?.["choices"]?.map(
                    (option, index) => {
                      let { value, text } = option;
                      return { value: value, label: text.replace("$t:", "") };
                    },
                  );
                  temp_field["options"] = options;
                  console.log(directusField);
                  break;
                default:
                  temp_field["$formkit"] = "text";
                  break;
              }
              // console.log(value['display'])
            }

            if (
              record &&
              record[0] &&
              record[0][value["field"]] &&
              temp_field
            ) {
              temp_field["value"] = record[0][value["field"]];
            }
            if (temp_field) {
              if (fields.length > 0) {
                if (fields.includes(temp_field.name)) {
                  result_fields.push(temp_field);
                }
              } else {
                result_fields.push(temp_field);
              }
            }
          } else if (is_o2m_includes) {
            // Foreign key
            let fieldRelation = fieldRelations.filter(
              (item) =>
                item["field"] === value["field"] &&
                value["related_collection"] !== "directus_files",
            );
            // console.log("O2M :", fieldRelation)
            if (
              !["user_created", "user_updated"].includes(value["field"]) &&
              fieldRelation[0]["related_collection"] != "directus_files"
            ) {
              // console.log(value)
              temp_field = {
                $formkit: "autocomplete",
                label:
                  value["field"].charAt(0).toUpperCase() +
                  value["field"].slice(1),
                name: value["field"],
                help: value["note"] ? value["note"] : "",
                collection_name: fieldRelation[0]["related_collection"],
                multiline:
                  value &&
                  value["special"].length > 0 &&
                  value["special"][0] === "m2o"
                    ? false
                    : true,
              };

              if (directusField[0]?.["required"]) {
                temp_field["validation"] = "required";
              }
              if (record && record[0] && record[0][value["field"]]) {
                temp_field["value"] = record[0][value["field"]];
              }
              if (temp_field) {
                if (fields.length > 0) {
                  if (fields.includes(temp_field.name)) {
                    result_fields.push(temp_field);
                  }
                } else {
                  result_fields.push(temp_field);
                }
              }
            } else if (value["special"][0] == "file") {
              // console.log(value)
              // console.log(fieldRelation)
              temp_field = {
                $cmp: "FileUpload",
                props: {
                  code: fieldRelation[0]["meta"]["many_collection"],
                  field: value["field"],
                },
              };
              if (fields.length > 0) {
                if (fields.includes(temp_field.name)) {
                  result_fields.push(temp_field);
                }
              } else {
                result_fields.push(temp_field);
              }
            }
          } else if (is_m2m_includes) {
            // M2M
            let fieldRelation = fieldRelations.filter(
              (item) => item["meta"]["one_field"] === value["field"],
            );
            console.log(fieldRelation);
            console.log(value["special"][0]);
            console.log("M2M FieldRelation", fieldRelation);
            console.log("Special value : ", value["special"][0]);
            if (
              fieldRelation &&
              fieldRelation[0] &&
              fieldRelation[0]["meta"] &&
              fieldRelation[0]["meta"]["junction_field"] &&
              value["special"][0] !== "files"
            ) {
              const splitArray = fieldRelation[0]["meta"]["junction_field"]
                .toString()
                .split("_");
              const resultArray = splitArray.slice(0, -1);
              const resultString = resultArray.join("_");

              temp_field = {
                $formkit: "autocomplete",
                label:
                  value["field"].charAt(0).toUpperCase() +
                  value["field"].slice(1),
                name: value["field"],
                help: value["note"] ? value["note"] : "",
                collection_name: resultString,
                multiline: true,
                m2m: true,
                many_field: fieldRelation[0]["meta"]["many_field"],
                junction_field: fieldRelation[0]["meta"]["junction_field"],
              };

              if (directusField[0]?.["required"]) {
                temp_field["validation"] = "required";
              }
              if (record && record[0] && record[0][value["field"]]) {
                let m2m_related_values = [];
                const headerService = new ItemsService(
                  fieldRelation[0]["collection"],
                  { schema: _req.schema, accountability: _req.accountability },
                );
                m2m_related_values = await headerService.readByQuery({
                  filter: {
                    id: {
                      _in: record[0][value["field"]],
                    },
                  },
                  sort: ["id"],
                  fields: ["*"],
                });
                // console.log("M2m", m2m_related_values)
                console.log("M2m", m2m_related_values);
                const junctionIds = m2m_related_values.map(
                  (item) => item[fieldRelation[0]["meta"]["junction_field"]],
                );
                temp_field["value"] = junctionIds;
                if (temp_field) {
                  if (fields.length > 0) {
                    if (fields.includes(temp_field.name)) {
                      result_fields.push(temp_field);
                    }
                  } else {
                    result_fields.push(temp_field);
                  }
                }
              } else {
                if (temp_field) {
                  if (fields.length > 0) {
                    if (fields.includes(temp_field.name)) {
                      result_fields.push(temp_field);
                    }
                  } else {
                    result_fields.push(temp_field);
                  }
                }
              }
            } else if (value["special"][0] === "files") {
              console.log(value);
              temp_field = {
                $cmp: "FileUpload",
                props: {
                  code: fieldRelation[0]["meta"]["many_collection"],
                  field: value["field"],
                  multiple: "multiple",
                },
              };
              if (fields.length > 0) {
                if (fields.includes(temp_field.name)) {
                  result_fields.push(temp_field);
                }
              } else {
                result_fields.push(temp_field);
              }
            }
          }
        }
      }
    } // code != ''
    return res.json(result_fields);
  });

  const updateWorkItemTree = async (_req, collection) => {
    const wo_item_service = new ItemsService(collection, {
      schema: await _req.schema,
      accountability: _req.accountability,
    });
    const wo_results = await wo_item_service.readByQuery({
      filter: {
        id: {
          _in: _req.body,
        },
      },
      sort: ["id"],
      fields: ["*"],
    });
    const template_header_service = new ItemsService("Template_header", {
      schema: _req.schema,
      accountability: _req.accountability,
    });
    const th_results = await template_header_service.readByQuery({
      filter: {
        id: {
          _in: wo_results.map((item) => item.code),
        },
        parent: {
          _neq: null,
        },
      },
      sort: ["id"],
      fields: ["*"],
    });

    await Promise.all(
      th_results.flatMap((th_result) => {
        const wo_items = wo_results.filter(
          (item) => item.code === th_result.id,
        );
        const wo_parent = wo_results.find(
          (item) => item.code === th_result.parent,
        );
        if (!wo_parent?.id) {
          return [];
        }
        return wo_items.map((wo_item) =>
          wo_item_service.updateOne(wo_item.id.toString(), {
            parent: wo_parent.id,
          }),
        );
      }),
    );
  };

  const workItemTreeRoutes = {
    "/work_order_items_tree": "Work_order_item",
    "/work_pm_item_tree": "Work_pm_item",
    "/work_inspection_item_tree": "Work_inspection_item",
    "/work_predictive_item_tree": "Predictive_item",
  };

  Object.entries(workItemTreeRoutes).forEach(([path, collection]) => {
    router.get(path, async (_req, res, next) => {
      try {
        await updateWorkItemTree(_req, collection);
        return res.json({});
      } catch (error) {
        return next(error);
      }
    });
  });

  router.get("/generate_number", async (_req, res, next) => {
    const codec = _req.query["codec"] ? _req.query["codec"] : "";
    const parts_number_service = new ItemsService("PartsNumber", {
      schema: await _req.schema,
      accountability: _req.accountability,
    });
    let parts_number = await parts_number_service
      .readByQuery({
        filter: {
          codec: {
            _eq: codec,
          },
        },
        sort: ["id"],
        limit: 1,
        fields: ["*"],
      })
      .then((results) => {
        return results[0];
      });
    if (!parts_number) {
      parts_number = {
        codec: codec,
        number: 1,
      };
      parts_number_service.createOne(parts_number);
    } else {
      parts_number.number = parts_number.number + 1;
      parts_number_service.updateOne(parts_number.id, {
        number: parts_number.number,
      });
    }
    return res.json({
      codec: parts_number.codec,
      number: parts_number.number,
    });
  });

  router.get("/manual_cron", async (_req, res, next) => {
    console.log("Running CMMS scheduled manual_cron");
    try {
      // Get the schema to initialize services
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

      // Get current date in different formats
      const today = new Date();

      const todayISO = today.toISOString().split("T")[0]; // "YYYY-MM-DD" format
      const todayDayOfMonth = today.getDate(); // Day of month (1-31)
      const todayOfmonth = today.getMonth() + 1; // 0-ээс эхэлдэг тул +1 нэмнэ
      const todayDayOfWeek = today.getDay() || 7; // Day of week (1-7, where 1=Monday, 7=Sunday)
      const monthsWith31Days = [1, 3, 5, 7, 8, 10, 12]; // 31 хоногтой сарууд
      const year = new Date().getFullYear();

      const daysOfWeek = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
      ];

      const todayDayOfWeekName = daysOfWeek[today.getDay()]; // Англиар өдөр авах

      // const currentDate = new Date().toLocaleString("en-US", { timeZone: "Asia/Ulaanbaatar" });

      console.log(
        `Today: ${todayISO}, Month: ${todayOfmonth}, day:${todayDayOfMonth} ,Day of Week: ${todayDayOfWeek}`,
      );

      let work_id = 0;
      if (_req.query.work_id) {
        work_id = _req.query.work_id;
      } else {
        console.log("work_all");
      }

      console.log("works__req_", _req.query);

      // Find tasks due today
      const templateTasks = await maintenanceService.readByQuery({
        filter: {
          ...(work_id ? { id: work_id } : {}), // Хэрэв work_id байхгүй бол нэмж хэрэггүй
          pm_type: "pm",
          template_pm: { _null: true },
          schedule: { _eq: 1 },
          wo_status: 8, //pm_draft
          action_status: 2, //approved
        },
        fields: ["*"],
      });

      if (templateTasks.length <= 0) {
        console.log("templateTasks", templateTasks.length);
        return res.json({
          status: 200,
          today: "err_no_work_id",
        });
      }

      // Process each workorder (example: update status)
      for (const task of templateTasks) {
        try {
          const woSchedules = await getWoSchedule.readByQuery({
            filter: {
              work_order: { _eq: task.id },
            },
            fields: ["*"],
          });

          console.log("woSchedules_result", woSchedules.length);
          if (woSchedules.length <= 0) continue;
          // let wo_schedule =woSchedules[0]

          for (const wo_schedule of woSchedules) {
            if (wo_schedule.type == "public") {
              const scheduleResult = await getSchedule.readByQuery({
                filter: {
                  id: wo_schedule.schedule_id,
                  active: "1",
                },
                fields: ["*"],
              });

              if (scheduleResult.length <= 0) continue;
              let schedule = scheduleResult[0];

              if (schedule.repeat_types != "direct") continue;
              let scheduleDates = [];
              try {
                // If it's stored as a JSON string in the database
                scheduleDates = JSON.parse(schedule.schedules_date);
              } catch (e) {
                // If it's already an array object
                scheduleDates = schedule.schedules_date || [];
              }

              let repeat_cnt = schedule.repeat;
              let shouldGenerateToday = false;

              if (schedule.repeat_unit == "daily") {
                shouldGenerateToday = true;
                console.log("daily", shouldGenerateToday);
              } else if (schedule.repeat_unit == "weekly") {
                shouldGenerateToday = scheduleDates.some(
                  (item) => parseInt(item.date) === todayDayOfWeek,
                );
                console.log("weekly_public", shouldGenerateToday);
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
                `Task ${task.id}: Should generate today: ${shouldGenerateToday}`,
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
                  console.warn("Skipping null/undefined asset ID");
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
                wo_status: 8, //pm_draft
                //   type:4, //pm
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

              console.log(
                `Created DIRECT_PUBLIC work_order ${newWorkOrder} based on template ${task.id}`,
              );

              // Get the template's task order items
              const templateItems = await taskService.readByQuery({
                filter: {
                  workorder: { _eq: task.id },
                },
                fields: ["*"],
              });

              console.log(
                `Found ${templateItems.length} template items to copy`,
              );

              // Create new work_order_items for each template item  work_order_item.created_type='pm_generated'
              for (const item of templateItems) {
                const newItem = await taskService.createOne({
                  workorder: newWorkOrder, // Link to the new work order
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
                  `Created DIRECT PUBLIC work_order_item ${newItem} of work_order ${newWorkOrder}`,
                );
              }

              // Select Work_pm_Tradecode
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

              // Select Work_pm_Parts
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

              // Select Work_pm_files
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

              await maintenanceService.updateOne(task.id, {
                last_generated: new Date(),
              });
            } else if (wo_schedule.type == "private") {
              if (wo_schedule.repeat_types != "direct") continue;
              let scheduleDates = [];

              try {
                // If it's stored as a JSON string in the database
                scheduleDates = JSON.parse(wo_schedule.schedules_date);
              } catch (e) {
                // If it's already an array object
                scheduleDates = wo_schedule.schedules_date || [];
              }

              let repeat_cnt = wo_schedule.repeat;
              let shouldGenerateToday = false;

              if (wo_schedule.repeat_unit == "daily") {
                shouldGenerateToday = true;
                console.log("daily_private", shouldGenerateToday);
              } else if (wo_schedule.repeat_unit == "weekly") {
                shouldGenerateToday = scheduleDates.some(
                  (item) => parseInt(item.date) === todayDayOfWeek,
                );
                console.log(
                  "weekly_private",
                  shouldGenerateToday,
                  todayDayOfWeek,
                );
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
                console.log(
                  "yearly_private",
                  shouldGenerateToday,
                  todayOfmonth,
                  todayDayOfMonth,
                );
              }

              if (!shouldGenerateToday) continue;
              console.log(
                `Task ${task.id}: generate today: ${shouldGenerateToday}`,
              );

              // Fetch assets from Work_pm_assets
              const templateAssets = await assetService.readByQuery({
                filter: {
                  work_order: { _eq: task.id },
                },
                fields: ["assets"],
              });
              console.log("templateAssets", templateAssets);

              // Determine assets to process
              let assetsToProcess = [task.asset]; // Default to template task asset
              if (templateAssets.length > 0) {
                const uniqueAssets = [
                  ...new Set(templateAssets.map((a) => a.assets)),
                ];
                console.log("uniqueAssets", uniqueAssets);
                assetsToProcess = uniqueAssets;
              }

              // Process each asset - create separate work order for each
              for (const finalAsset of assetsToProcess) {
                // Skip if asset ID is null/undefined
                if (!finalAsset) {
                  console.warn("Skipping null/undefined asset ID in private schedule");
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

                console.log("finalAsset", finalAsset);

                // Шинэ PM ажил үүсгэх
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
                  wo_status: 8, //pm_draft
                  //   type:4, //pm
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

              console.log(
                `Created DIRECT PRIVATE WO ${newWorkOrder} based on template ${task.id}`,
              );

              // Get the template's task order items
              const templateItems = await taskService.readByQuery({
                filter: {
                  workorder: { _eq: task.id },
                },
                fields: ["*"],
              });

              console.log(
                `Found ${templateItems.length} template items to copy`,
              );

              // Create new work_order_items for each template item  work_order_item.created_type='pm_generated'
              for (const item of templateItems) {
                const newItem = await taskService.createOne({
                  workorder: newWorkOrder, // Link to the new work order
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
                  `Created DIRECT_PRIVATE WO_ITEMS ${newItem} of work_order ${newWorkOrder}`,
                );
              }

              // Select Work_pm_Tradecode
              const trades = await tradeService.readByQuery({
                filter: {
                  work_order: { _eq: task.id },
                },
                fields: ["*"],
              });
              for (const t_item of trades) {
                const tItem = await tradeService.createOne({
                  name: t_item.name,
                  company_id: t_item.company_id,
                  work_order: newWorkOrder,
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

              // Select Work_pm_Parts
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

              // Select Work_pm_files
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

              await maintenanceService.updateOne(task.id, {
                last_generated: new Date(),
              });
            }
          }
        } catch (error) {
          console.error(`Error direct template task ${task.id}:`, error);
        }
      }

      return res.json({
        status: 200,
        today: today,
      });
    } catch (error) {
      console.error("Error in CMMS cron job:", error);
    }
  });

  router.get("/manual_cron_completed", async (_req, res, next) => {
    console.log("Running CMMS manual_cron_completed manual_cron");
    try {
      // Get the schema to initialize services
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

      // Get current date in different formats
      const today = new Date();
      const todayISO = today.toISOString().split("T")[0]; // "YYYY-MM-DD" format
      const todayDayOfMonth = today.getDate(); // Day of month (1-31)
      const todayDayOfWeek = today.getDay() || 7; // Day of week (1-7, where 1=Monday, 7=Sunday)

      // const currentDate = new Date().toLocaleString("en-US", { timeZone: "Asia/Ulaanbaatar" });

      console.log(
        `Today: ${todayISO}, Day: ${todayDayOfMonth}, Day of Week: ${todayDayOfWeek}`,
      );

      let work_id = 0;
      let first_work = false;
      if (_req.query.work_id) {
        work_id = _req.query.work_id;
        first_work = true;
      } else {
        console.log("work_all");
      }

      console.log("works__req", _req.query);
      console.log("filters", {
        ...(work_id ? { id: work_id } : {}),
        ...(work_id ? {} : { completed_at: { _nnull: true } }),
        ...(work_id ? { pm_type: "pm" } : { pm_type: "completed" }),
        // ...(work_id ? {  template_pm:{ _nnull: true } } : { template_pm:{ _null: true } }),
        ...(work_id ? {} : { schedule: { _eq: 1 } }),
      });

      // Find tasks completed today
      const templateCompletedTasks = await maintenanceService.readByQuery({
        filter: {
          ...(work_id ? { id: work_id } : {}),
          ...(work_id ? {} : { completed_at: { _nnull: true } }),
          ...(work_id ? { pm_type: "pm" } : { pm_type: "completed" }),
          // ...(work_id ? {  template_pm:{ _nnull: true } } : { template_pm:{ _null: true } }),
          ...(work_id ? {} : { schedule: { _eq: 1 } }),
          action_status: 2, //approved
          wo_status: 8, //pm_draft
        },
        fields: ["*"],
        sort: ["-completed_at"], // Sort by completed_at in descending order (latest first)
        limit: 1, // Limit to only the latest task
      });

      if (templateCompletedTasks.length <= 0) {
        console.log("templateCompletedTasks", templateCompletedTasks.length);
        return;
      }

      // Process each task
      for (const task of templateCompletedTasks) {
        try {
          const woSchedules = await getWoSchedule.readByQuery({
            filter: {
              work_order: { _eq: task.id },
            },
            fields: ["*"],
          });

          console.log("woSchedules_result", woSchedules.length);
          if (woSchedules.length <= 0) continue;
          let wo_schedule = woSchedules[0];

          if (wo_schedule.type == "public") {
            const scheduleResult = await getSchedule.readByQuery({
              filter: {
                id: wo_schedule.schedule_id,
                active: "1",
              },
              fields: ["*"],
            });

            console.log("scheduleResult", scheduleResult);

            if (scheduleResult.length <= 0) continue;
            const schedule = scheduleResult[0];
            if (schedule.repeat_types != "completed") continue;
            console.log("repeat_types", schedule.repeat_types);

            // `completed_at`-ийг `Date` объект болгон хөрвүүлэх
            const completedDate = new Date(task.completed_at);
            console.log("completedDate_1", completedDate.getDate());
            console.log("completedDate_2", completedDate);

            // Динамик өдрүүдийг тооцоолох (1 өдөр, 19 өдөр)
            const calculatedDates = schedule.schedules_date.map((dateObj) => {
              const nextDate = new Date(completedDate); // completedDate-ийн хуулбар үүсгэх
              nextDate.setDate(completedDate.getDate() + dateObj.date); // completedDate-аас хойшхи dateObj.date өдөр нэмэх
              return nextDate; // Бүтэн Date объектыг буцаах нь илүү хэрэгтэй
            });

            console.log("Calculated dates:", calculatedDates);
            const calculatedDatesISO = calculatedDates.map(
              (date) => date.toISOString().split("T")[0],
            );

            let hasTodaySchedule = calculatedDatesISO.includes(todayISO);
            if (first_work) {
              hasTodaySchedule = true;
            }

            console.log("hasTodaySchedule dates:", hasTodaySchedule); // Логдож байгаа өдрүүд

            if (!hasTodaySchedule) {
              console.log(
                `Skipping task ${task.id}: Today (${todayISO}) is not in schedules_date.`,
              );
              continue;
            }

            console.log(
              `New task ${task.id}: Today (${todayISO}) is not in schedules_date.`,
            );

            // Fetch assets from Work_pm_assets
            const templateAssets_pub = await assetService.readByQuery({
              filter: {
                work_order: { _eq: task.id },
              },
              fields: ["assets"],
            });

            // Determine assets to process
            let assetsToProcess_pub = [task.asset]; // Default to template task asset
            if (templateAssets_pub.length > 0) {
              const uniqueAssets_pub = [
                ...new Set(templateAssets_pub.map((a) => a.assets)),
              ];
              assetsToProcess_pub = uniqueAssets_pub;
            }

            // Process each asset - create separate work order for each
            for (const finalAsset_pub of assetsToProcess_pub) {
              // Skip if asset ID is null/undefined
              if (!finalAsset_pub) {
                console.warn("Skipping null/undefined asset ID in public completed schedule");
                continue;
              }

              // Fetch asset code
              let assetCode_pub = "";
              try {
                const assetDetail_pub = await assetDetailsService
                  .readOne(finalAsset_pub, {
                    fields: ["asset_code"],
                  })
                  .catch(() => null); // Return null if asset not found
                assetCode_pub = assetDetail_pub?.asset_code || "";
                if (!assetCode_pub) {
                  console.warn(`Asset code not found for ID: ${finalAsset_pub}`);
                }
              } catch (err) {
                console.warn(
                  `Error fetching asset details for ID: ${finalAsset_pub}:`,
                  err.message,
                );
              }

              // Шинэ ажил үүсгэх
              const newWorkOrder = await maintenanceService.createOne({
                name: `${task.name} - CT${assetCode_pub ? " - " + assetCode_pub : ""}`,
              history_description: task.history_description,
              safety_notes: task.safety_notes,
              company_id: task.company_id,
              asset: finalAsset_pub,
              assigned_team: task.assigned_team,
              department: task.department,
              location: task.location,
              type: task.type,
              work_type: task.work_type,
              active: task.active,
              pm_type: "completed",
              created_type: "pm_generated",
              wo_status: 8, //pm_draft
              // type:4, //pm
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
              `Created COMPLETED work_order ${newWorkOrder} based on template ${task.id}`,
            );

            // Get the template's task order items
            const templateItems_comp = await taskService.readByQuery({
              filter: {
                workorder: { _eq: task.id },
              },
              fields: ["*"],
            });

            console.log(
              `Found ${templateItems_comp.length} template items to copy`,
            );

            // Create new work_order_items for each template item
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
              // console.log(`Created DIRECT work_order_item of work_order ${newWorkOrder}`);
            }

            // Select Work_pm_Tradecode
            const trades = await tradeService.readByQuery({
              filter: {
                work_order: { _eq: task.id },
              },
              fields: ["*"],
            });
            for (const t_item of trades) {
              const tItem = await tradeService.createOne({
                name: t_item.name,
                company_id: t_item.company_id,
                work_order: newWorkOrder,
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

            // Select Work_pm_Parts
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

            // Select Work_pm_files
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

            } // End of assetsToProcess_pub loop

            await maintenanceService.updateOne(task.id, {
              last_generated: new Date(),
            });
          } else if (wo_schedule.type == "private") {
            const schedule = wo_schedule;

            console.log("scheduleResult", schedule);

            if (schedule.repeat_types != "completed") continue;
            console.log("repeat_types", schedule.repeat_types);

            // `completed_at`-ийг `Date` объект болгон хөрвүүлэх
            const completedDate = new Date(task.completed_at);
            console.log("completedDate_1", completedDate.getDate());
            console.log("completedDate_2", completedDate);

            // Динамик өдрүүдийг тооцоолох (1 өдөр, 19 өдөр)
            const calculatedDates = schedule.schedules_date.map((dateObj) => {
              const nextDate = new Date(completedDate); // completedDate-ийн хуулбар үүсгэх
              nextDate.setDate(completedDate.getDate() + dateObj.date); // completedDate-аас хойшхи dateObj.date өдөр нэмэх
              return nextDate; // Бүтэн Date объектыг буцаах нь илүү хэрэгтэй
            });

            console.log("Calculated dates:", calculatedDates);
            const calculatedDatesISO = calculatedDates.map(
              (date) => date.toISOString().split("T")[0],
            );

            let hasTodaySchedule = calculatedDatesISO.includes(todayISO);
            if (first_work) {
              hasTodaySchedule = true;
            }

            console.log("hasTodaySchedule dates:", hasTodaySchedule); // Логдож байгаа өдрүүд

            if (!hasTodaySchedule) {
              console.log(
                `Skipping task ${task.id}: Today (${todayISO}) is not in schedules_date.`,
              );
              continue;
            }

            console.log(
              `New task ${task.id}: Today (${todayISO}) is not in schedules_date.`,
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
                console.warn("Skipping null/undefined asset ID in private completed schedule");
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
              started_at: task.started_at,
              location: task.location,
              type: task.type,
              work_type: task.work_type,
              active: task.active,
              pm_type: "completed",
              created_type: "pm_generated",
              wo_status: 8, //pm_draft
              // type:4, //pm
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
              `Created COMPLETED_PRIVATE WO ${newWorkOrder} based on template ${task.id}`,
            );

            // Get the template's task order items
            const templateItems_comp = await taskService.readByQuery({
              filter: {
                workorder: { _eq: task.id },
              },
              fields: ["*"],
            });

            console.log(
              `Found ${templateItems_comp.length} template items to copy`,
            );

            // Create new work_order_items for each template item
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
              console.log(
                `Created COMPLETED_PRIVATE WO_ITEMS of work_order ${newWorkOrder}`,
              );
            }

            // Select Work_pm_Tradecode
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

            // Select Work_pm_Parts
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

            // Select Work_pm_files
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

            await maintenanceService.updateOne(task.id, {
              last_generated: new Date(),
            });
          }
        } catch (error) {
          console.error(`Error processing template task ${task.id}:`, error);
        }
      }
      return res.json({
        status: 200,
        today: today,
      });
    } catch (error) {
      console.error("Error in CMMS cron job:", error);
    }
  });

  router.get("/manual_inspection", async (_req, res, next) => {
    console.log("Running manual_inspection scheduled");
    try {
      // Get the schema to initialize services
      const schema = await getSchema();
      const { ItemsService } = services;

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

      const inspectionSchedule = new ItemsService("Work_inspection_schedules", {
        schema,
        knex: database,
        accountability: null,
      });

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

      const inspectionFileService = new ItemsService("Work_inspection_files", {
        schema,
        knex: database,
        accountability: null,
      });

      const inspectionUsersService = new ItemsService("Work_inspection_users", {
        schema,
        knex: database,
        accountability: null,
      });

      const inspectionAssetDetailsService = new ItemsService("Assets", {
        schema,
        knex: database,
        accountability: null,
      });

      // Get current date in different formats
      const today = new Date();

      const todayISO = today.toISOString().split("T")[0]; // "YYYY-MM-DD" format
      const todayDayOfMonth = today.getDate(); // Day of month (1-31)
      const todayOfmonth = today.getMonth() + 1; // 0-ээс эхэлдэг тул +1 нэмнэ
      const todayDayOfWeek = today.getDay() || 7; // Day of week (1-7, where 1=Monday, 7=Sunday)
      const monthsWith31Days = [1, 3, 5, 7, 8, 10, 12]; // 31 хоногтой сарууд
      const year = new Date().getFullYear();

      const daysOfWeek = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
      ];

      const todayDayOfWeekName = daysOfWeek[today.getDay()]; // Англиар өдөр авах

      // const currentDate = new Date().toLocaleString("en-US", { timeZone: "Asia/Ulaanbaatar" });

      console.log(
        `Today: ${todayISO}, Month: ${todayOfmonth}, day:${todayDayOfMonth} ,Day of Week: ${todayDayOfWeek}`,
      );
      let work_id = 0;
      if (_req.query.work_id) {
        work_id = _req.query.work_id;
      } else {
        console.log("work_all");
      }

      const templateInspection = await inspectionService.readByQuery({
        filter: {
          ...(work_id ? { id: work_id } : {}),
          pm_type: "inspection",
          template_pm: { _null: true },
          schedule: { _eq: 1 },
          wo_status: 1, //pm_create
          action_status: 2, //approved
        },
        fields: ["*"],
      });

      console.log("filter", {
        ...(work_id ? { id: work_id } : {}),
        pm_type: "inspection",
        template_pm: { _null: true },
        schedule: { _eq: 1 },
        wo_status: 1, //pm_create
        action_status: 2, //approved
      });

      if (templateInspection.length <= 0) {
        console.log("length", templateInspection.length);
        return res.json({
          status: 200,
          today: today,
          length: templateInspection.length,
        });
      }
      console.log("DIRECT templateInspection starting ...");

      // Process each task (example: update status)
      for (const task of templateInspection) {
        try {
          const woSchedules = await inspectionSchedule.readByQuery({
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
                // If it's stored as a JSON string in the database
                scheduleDates = JSON.parse(schedule.schedules_date);
              } catch (e) {
                // If it's already an array object
                scheduleDates = schedule.schedules_date || [];
              }

              let shouldGenerateToday = false;
              let repeat_cnt = schedule.repeat;

              if (schedule.repeat_unit == "daily") {
                shouldGenerateToday = true;
                console.log("daily", shouldGenerateToday);
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

              // Select users
              const users_inspec = await inspectionUsersService.readByQuery({
                filter: {
                  work_order: { _eq: task.id },
                },
                fields: ["*"],
              });

              if (users_inspec.length == 0) continue;

              // Determine assets to process from Work_inspection_users
              let assetsToProcess = [];
              if (users_inspec.length > 0) {
                const uniqueAssets = [
                  ...new Set(users_inspec.map((u) => u.asset).filter((a) => a)),
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
                  console.warn("Skipping null/undefined asset ID in public inspection");
                  continue;
                }

                // Fetch asset code
                let assetCode = "";
                if (finalAsset) {
                  try {
                    const assetDetail =
                      await inspectionAssetDetailsService.readOne(finalAsset, {
                        fields: ["asset_code"],
                      });
                    assetCode = assetDetail?.asset_code || "";
                  } catch (err) {
                    console.warn(`Asset details not found for ID: ${finalAsset}`);
                  }
                }

                for (const p_item of users_inspec) {
                // Шинэ ажил үүсгэх
                const newWorkOrder = await inspectionService.createOne({
                  name: `${task.name}${assetCode ? " - " + assetCode : ""}`,
                  history_description: task.history_description,
                  safety_notes: task.safety_notes,
                  company_id: task.company_id,
                  asset: finalAsset,
                  assigned_team: task.assigned_team,
                  department: task.department,
                  started_at: task.started_at,
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
                  user: p_item.user,
                  type: 'generated',
                  company_id: task.company_id,
                  date_created: new Date(),
                });

                console.log(
                  `Created_by DIRECT_PUBLIC INSPECTION ${newWorkOrder} based on template ${task.id}`,
                );
                // console.log(newWorkOrder);

                // Get the template's tasks order items
                const templateItems = await inspectionItemService.readByQuery({
                  filter: {
                    workorder: { _eq: task.id },
                  },
                  fields: ["*"],
                });

                // console.log(`Found ${templateItems.length} template items to copy`);

                // Шинэ task үүсгэх work_order_item.created_type='ins_generated'
                for (const item of templateItems) {
                  const newItem = await inspectionItemService.createOne({
                    workorder: newWorkOrder, // Link to the new work order
                    name: item.name,
                    company_id: item.company_id,
                    value: item.value,
                    status: item.status,
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

                // Select Work_inspection_Parts
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

                // Select Work_inspection_files
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
              } // End of users_inspec loop
              } // End of assetsToProcess loop

              await inspectionService.updateOne(task.id, {
                last_generated: new Date(),
              });
            } else if (wo_schedule.type == "private") {
              try {
                // If it's stored as a JSON string in the database
                scheduleDates = JSON.parse(wo_schedule.schedules_date);
              } catch (e) {
                // If it's already an array object
                scheduleDates = wo_schedule.schedules_date || [];
              }

              // console.log('scheduleDates', scheduleDates)

              let repeat_cnt = wo_schedule.repeat;
              let shouldGenerateToday = false;

              if (wo_schedule.repeat_unit == "daily") {
                shouldGenerateToday = true;
                console.log("daily_private", shouldGenerateToday);
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

              // Select by users
              const users_inspec = await inspectionUsersService.readByQuery({
                filter: {
                  work_order: { _eq: task.id },
                },
                fields: ["*"],
              });

              if (users_inspec.length == 0) continue;

              // Determine assets to process from Work_inspection_users
              let assetsToProcess = [];
              if (users_inspec.length > 0) {
                const uniqueAssets = [
                  ...new Set(users_inspec.map((u) => u.asset).filter((a) => a)),
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
                  console.warn("Skipping null/undefined asset ID in private inspection");
                  continue;
                }

                // Fetch asset code
                let assetCode = "";
                if (finalAsset) {
                  try {
                    const assetDetail =
                      await inspectionAssetDetailsService.readOne(finalAsset, {
                        fields: ["asset_code"],
                      });
                    assetCode = assetDetail?.asset_code || "";
                  } catch (err) {
                    console.warn(`Asset details not found for ID: ${finalAsset}`);
                  }
                }

                for (const p_item of users_inspec) {
                // Шинэ ажил үүсгэх neeh
                const newWorkOrder = await inspectionService.createOne({
                  name: `${task.name}${assetCode ? " - " + assetCode : ""}`,
                  history_description: task.history_description,
                  safety_notes: task.safety_notes,
                  company_id: task.company_id,
                  asset: finalAsset,
                  assigned_team: task.assigned_team,
                  department: task.department,
                  started_at: task.started_at,
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
                  user: p_item.user,
                  date_created: new Date(),
                  type: 'generated',
                  company_id: task.company_id,
                });

                console.log(
                  `Created_by DIRECT PRIVATE INSPECT ${newWorkOrder} based on template ${task.id}`,
                );
                // console.log(newWorkOrder);

                // Get the template's tasks order items
                const templateItems = await inspectionItemService.readByQuery({
                  filter: {
                    workorder: { _eq: task.id },
                  },
                  fields: ["*"],
                });

                // console.log(`Found_inspectionItemService ${templateItems.length} template items to copy`);
                // Шинэ task үүсгэх work_order_item.created_type='ins_generated'
                for (const item of templateItems) {
                  const newItem = await inspectionItemService.createOne({
                    workorder: newWorkOrder, // Link to the new work order
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

                  // console.log(`Created  INS_ITEMS  ${newItem} of work_order ${newWorkOrder}`);
                }

                // Select Work_inspection_Parts
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

                // Select Work_inspection_files
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
              } // End of users_inspec loop
              } // End of assetsToProcess loop

              await inspectionService.updateOne(task.id, {
                last_generated: new Date(),
              });
            }
          }
        } catch (error) {
          console.error(`Error direct template task ${task.id}:`, error);
        }
      }

      return res.json({
        status: 200,
        today: today,
      });
    } catch (error) {
      console.error("Error in CMMS cron job:", error);
    }
  });

  router.post("/send_notification", async (_req, res, next) => {
    // Admin SDK-г зөвхөн нэг удаа инициализ хий
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }

    // console.log('send_notification_req', _req)
    const from_user_id = _req.body.from_user_id;
    const to_user_id = _req.body.to_user_id;
    const title = _req.body.title;
    const msgText = _req.body.message;
    const work_order = _req.body.work_order ? _req.body.work_order : null;
    const notify_type = _req.body.type ? _req.body.type : "assigned";
    // console.log('work-order-notify_send_notification');

    // Notify- g baazad hadgalah eseh

    const schema = await getSchema();
    const { ItemsService } = services;
    const tokenService = new ItemsService("user_device_tokens", {
      schema,
      knex: database,
      accountability: null,
    });

    const notificationService = new ItemsService("Notify", {
      schema,
      knex: database,
      accountability: null,
    });

    const userDevice = await tokenService.readByQuery({
      filter: { user_id: { _eq: to_user_id } },
      limit: 1,
    });

    if (!userDevice || userDevice.length === 0 || !userDevice[0].token) {
      console.warn("⚠️ FCM token олдсонгүй");
      res.status(404).send({ error: "FCM token байхгүй" });
      return;
    }

    const fcmToken = userDevice[0].token;

    // Notification message
    const message = {
      notification: {
        title: title || "Шинэ мэдэгдэл",
        body: msgText || "Та шинэ үүрэг хүлээн авсан байна.",
      },
      token: fcmToken,
      data: {
        work_order: String(work_order ?? 0),
        from_user_id: String(from_user_id),
        to_user_id: String(to_user_id),
        type: String(notify_type),
      },
    };

    // Notify-г баазад заавал хадгална (push амжилтгүй байсан ч)
    try {
      await notificationService.createOne({
        from_user: from_user_id,
        to_user: to_user_id,
        title: title,
        message: msgText,
        work_order: work_order,
        type: notify_type,
        is_read: false,
      });
    } catch (dbErr) {
      console.error("❌ Notify баазад хадгалахад алдаа:", dbErr.message);
    }

    try {
      const response = await admin.messaging().send(message);
      console.log("✅ Notification илгээгдлээ:", response);
    } catch (err) {
      // Token хүчингүй болсон бол баазаас устгана
      const invalidTokenCodes = [
        "messaging/registration-token-not-registered",
        "messaging/invalid-registration-token",
        "messaging/invalid-argument",
      ];

      if (err.errorInfo && invalidTokenCodes.includes(err.errorInfo.code)) {
        console.warn(
          `⚠️ Хүчингүй FCM token (${err.errorInfo.code}), баазаас устгаж байна: user ${to_user_id}`,
        );
        try {
          await tokenService.deleteByQuery({
            filter: { token: { _eq: fcmToken } },
          });
          console.log("🗑️ Хүчингүй token устгагдлаа");
        } catch (delErr) {
          console.error("❌ Token устгахад алдаа:", delErr);
        }
      } else {
        console.error("❌ Notification илгээхэд алдаа:", err);
      }
    }

    // multi
    // const tokens = await tokenService.readByQuery({
    //   filter: { user_id: { _eq: userId } },
    // });

    // const fcmTokens = tokens.map((t) => t.token);

    // console.log('work-order-fcmTokens', fcmTokens);

    // if (fcmTokens.length > 0) {
    //     const payload = {
    //       title: 'Шинэ үүрэг оноогдлоо',
    //       body: `Та hi нэртэй ажлыг хүлээн авсан байна.`,
    //     };

    //     try {
    //       const response =  await admin.messaging().sendMulticast({
    //         tokens: fcmTokens,
    //         notification: {
    //           title:payload.title,
    //           body: payload.body,
    //         },
    //         data: {
    //           work_order: work_order, // нэмэлт өгөгдөл
    //         },
    //       });

    //       console.log('✅ Notification илгээгдлээ:', response);
    //     } catch (err) {
    //       console.error('❌ Notification илгээхэд алдаа:', err);
    //     }
    // }
  });

  router.get("/manual_pm_order", async (_req, res, next) => {
    console.log("Running manual_pm_order");
    try {
      const schema = await getSchema();
      const { ItemsService } = services;

      // Predictive_tracking_configs — тохиргооны эх сурвалж
      const configService = new ItemsService("Predictive_tracking_configs", {
        schema,
        knex: database,
        accountability: null,
      });
      // Predictive — үүсгэх PM collection
      const predictiveService = new ItemsService("Predictive", {
        schema,
        knex: database,
        accountability: null,
      });
      // Холбоос хүснэгтүүд (template Work_pm-ийг эх болгоно)
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
      // Template Work_pm-ийн нэмэлт мэдээлэл авах
      const workPmService = new ItemsService("Work_pm", {
        schema,
        knex: database,
        accountability: null,
      });

      const today = new Date();
      const todayISO = today.toISOString().split("T")[0];

      // config_id = Predictive_tracking_configs.id (front-oos irj bolno)
      const config_id = _req.query.config_id ? _req.query.config_id : 0;
      const forceCreate = !!config_id; // front-oos config_id irsen uyd schedule shalgahgui

      console.log(
        "manual_pm_order query:",
        _req.query,
        "forceCreate:",
        forceCreate,
      );

      // Predictive_tracking_configs-аас тохиргоо унших
      const configs = await configService.readByQuery({
        filter: {
          ...(config_id ? { id: config_id } : {}),
          pm_work_order: { _nnull: true }, // template WO заавал байх ёстой
        },
        fields: [
          "*",
          "asset.id",
          "asset.name",
          "pm_work_order.*",
          "field.id",
          "field.value1",
          "field.value2",
          "field.value3",
          "field.value4",
          "field.unit",
        ],
      });

      if (configs.length <= 0) {
        console.log("manual_pm_order: no configs found");
        return res.json({
          status: 200,
          message: "no_configs",
          today: todayISO,
        });
      }

      const createdOrders = [];

      for (const config of configs) {
        try {
          const tmplWoId =
            typeof config.pm_work_order === "object"
              ? config.pm_work_order.id
              : config.pm_work_order;
          const tmplWo =
            typeof config.pm_work_order === "object"
              ? config.pm_work_order
              : null;

          const assetId =
            typeof config.asset === "object" ? config.asset.id : config.asset;

          // threshold тохиргооны хувьд triggered_at байвал алгасна (forceCreate-аас бусад)
          if (!forceCreate && config.triggered_at) {
            console.log(
              `Skipping config ${config.id}: already triggered, waiting for reset`,
            );
            continue;
          }

          // Predictive collection-д шинэ PM үүсгэх
          const newWo = await predictiveService.createOne({
            name: `${config.pm_name || "PDM"} - MANUAL`,
            type: tmplWo?.type ?? 4,
            priority: tmplWo?.priority ?? 2,
            company_id: config?.company_id ?? null,
            department: tmplWo?.department ?? null,
            started_at: tmplWo?.started_at ?? null,
            assigned_team: tmplWo?.assigned_team ?? null,
            location: tmplWo?.location ?? null,
            type: tmplWo?.type ?? null,
            work_type: tmplWo?.work_type ?? null,
            asset: assetId,
            active: tmplWo?.active ?? 1,
            safety_notes: tmplWo?.safety_notes ?? null,
            history_description: tmplWo?.history_description ?? null,
            pm_type: "pdm_generated",
            created_type: forceCreate ? "manual" : "pdm_generated",
            action_status: 1,
            wo_status: 8, // pm_draft
            template_pm: tmplWoId, // эх Work_pm template
            predictive_config: config.id,
            predictive_trigger_value: config.custom_value ?? null,
            other_amount: tmplWo.other_amount,
            other_actual_amount: tmplWo.other_actual_amount,
            budget: tmplWo.budget,
            budget_actual_amount: tmplWo.budget_actual_amount,
            budget_planned_amount: tmplWo.budget_planned_amount,
          });

          console.log(
            `Created ${forceCreate ? "MANUAL" : "AUTO"}_PDM Predictive #${newWo} from config ${config.id} (template WO ${tmplWoId})`,
          );

          // Predictive_item — template WO-ийн items хуулах
          const tmplItems = await pdmItemService.readByQuery({
            filter: { workorder: { _eq: tmplWoId } },
            fields: ["*"],
          });
          for (const item of tmplItems) {
            await pdmItemService.createOne({
              workorder: newWo,
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
              created_type: forceCreate ? "manual" : "pdm_generated",
              date_created: new Date(),
            });
          }

          // Predictive_Tradecode хуулах
          const tmplTrades = await pdmTradeService.readByQuery({
            filter: { work_order: { _eq: tmplWoId } },
            fields: ["*"],
          });
          for (const t of tmplTrades) {
            await pdmTradeService.createOne({
              work_order: newWo,
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

          // Predictive_Parts хуулах
          const tmplParts = await pdmPartService.readByQuery({
            filter: { work_order: { _eq: tmplWoId } },
            fields: ["*"],
          });
          for (const p of tmplParts) {
            await pdmPartService.createOne({
              work_order: newWo,
              company_id: p.company_id,
              quantity: p.quantity,
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

          // Predictive_files хуулах
          const tmplFiles = await pdmFileService.readByQuery({
            filter: { work_order: { _eq: tmplWoId } },
            fields: ["*"],
          });
          for (const f of tmplFiles) {
            await pdmFileService.createOne({
              work_order: newWo,
              file: f.file,
              status: f.status,
              date_created: new Date(),
            });
          }

          // threshold горимд triggered_at тохируулна
          if (!forceCreate && config.threshold_type !== "interval") {
            await configService.updateOne(config.id, {
              triggered_at: new Date(),
            });
          }

          createdOrders.push(newWo);
        } catch (error) {
          console.error(
            `Error in manual_pm_order for config ${config.id}:`,
            error,
          );
        }
      }

      return res.json({
        status: 200,
        today: todayISO,
        created: createdOrders.length,
        work_orders: createdOrders,
      });
    } catch (error) {
      console.error("Error in CMMS manual_pm_order job:", error);
      return res.json({ status: 500, message: error.message });
    }
  });


 
  const wiseBuffers = new Map();
  const WISE_BUFFER_TTL_MS = 10 * 60 * 1000; // 10 минутын дотор дараагийн segment ирэхгүй бол хуучирсанд тооцно

  // Удаан хугацаанд дуусаагүй (эхний segment-ээс хойш дараагийн нь ирээгүй) buffer-уудыг
  // санах ойгоос цэвэрлэж, memory leak-ээс сэргийлнэ
  setInterval(() => {
    const now = Date.now();
    for (const [key, buf] of wiseBuffers.entries()) {
      if (now - buf.createdAt > WISE_BUFFER_TTL_MS) {
        wiseBuffers.delete(key);
      }
    }
  }, 60 * 1000).unref();

  function hexToBytes(hex) {
    const out = [];

    for (let i = 0; i < hex.length; i += 2) {
      out.push(parseInt(hex.slice(i, i + 2), 16));
    }

    return out;
  }

  function bytesToHex(bytes) {
    return bytes
      .map(v => v.toString(16).padStart(2, "0"))
      .join("");
  }

  function expectedLengthFromFirst(bytes) {
    if (!bytes || bytes.length < 3) return null;

    const frameControl = bytes[0];
    const hasFC2 = (frameControl & 0x20) !== 0;

    let index = 2;
    let totalLengthBytes = 1;

    if (hasFC2) {
      const fc2 = bytes[index++];

      if (fc2 & 0x01) {
        totalLengthBytes = 2;
      }
    }

    let totalLength;

    if (totalLengthBytes === 2) {
      totalLength = bytes[index] + (bytes[index + 1] << 8);
      index += 2;
    } else {
      totalLength = bytes[index++];
    }

    const addressMode = frameControl & 0x0c;

    let addressLength = 0;

    if (addressMode === 0x04) addressLength = 2;
    if (addressMode === 0x08) addressLength = 8;

    return (
      totalLength +
      3 +
      (hasFC2 ? 1 : 0) +
      totalLengthBytes +
      addressLength
    );
  }

  function reassembleWise2410(deviceKey, body) {
    const current = hexToBytes(body.raw_hex);
    const sequence = body.sequence;

    // First packet
    if (body.first_segment === true) {
      const expected =
        body.expected_length ||
        expectedLengthFromFirst(current);

      if (body.needs_reassembly === false) {
        return {
          complete: true,
          raw_hex: body.raw_hex,
        };
      }

      wiseBuffers.set(deviceKey, {
        bytes: current,
        expectedLength: expected,
        lastSequence: sequence,
        createdAt: Date.now(),
      });

      return {
        complete: false,
        status: "first_segment_saved",
      };
    }

    // Continuation packet
    const stored = wiseBuffers.get(deviceKey);

    if (!stored || Date.now() - stored.createdAt > WISE_BUFFER_TTL_MS) {
      wiseBuffers.delete(deviceKey);

      return {
        complete: false,
        status: "missing_first_segment",
      };
    }

    const expectedSequence =
      stored.lastSequence === 255
        ? 0
        : stored.lastSequence + 1;

    if (sequence !== expectedSequence) {
      wiseBuffers.delete(deviceKey);

      return {
        complete: false,
        status: "sequence_error",
      };
    }

    // Advantech continuation packet-ийн эхний 2 byte:
    // frame control + sequence
    const continuationData = current.slice(2);

    stored.bytes =
      stored.bytes.concat(continuationData);

    stored.lastSequence = sequence;

    if (
      stored.expectedLength &&
      stored.bytes.length >= stored.expectedLength
    ) {
      const completed =
        stored.bytes.slice(0, stored.expectedLength);

      wiseBuffers.delete(deviceKey);

      return {
        complete: true,
        raw_hex: bytesToHex(completed),
      };
    }

    wiseBuffers.set(deviceKey, stored);

    return {
      complete: false,
      status: "continuation_saved",
      receivedLength: stored.bytes.length,
      expectedLength: stored.expectedLength,
    };
  }

  function Decode(fPort, bytes) {

      var PAYLOAD_SENSOR_DATA = 0x50;
      var PAYLOAD_DEVICE_DATA = 0x60;

      var TEMP_C = 0x00;
      var TEMP_F = 0x01;
      var TEMP_K = 0x02;
      var HUMIDITY = 0x03;

      var ACC_G = 0x04;
      var ACC_MS2 = 0x05;

      var SENSOR_STATUS = 0x01;
      var SENSOR_EVENT = 0x02;
      var SENSOR_VALUE = 0x04;
      var SENSOR_MAX = 0x08;
      var SENSOR_MIN = 0x10;

      var AXIS_X = 0x01;
      var AXIS_Y = 0x02;
      var AXIS_Z = 0x04;

      var EXT_VELOCITY = 0x01;
      var EXT_PEAK = 0x02;
      var EXT_RMS = 0x04;
      var EXT_KURTOSIS = 0x08;
      var EXT_CREST = 0x10;
      var EXT_SKEWNESS = 0x20;
      var EXT_STDDEV = 0x40;
      var EXT_DISPLACEMENT = 0x80;

      var MASK2_LOGINDEX = 0x01;
      var MASK2_TIME = 0x02;

      var DEVICE_EVENT = 0x01;
      var DEVICE_POWER = 0x02;
      var DEVICE_BATTERY_LEVEL = 0x04;
      var DEVICE_BATTERY_VOLTAGE = 0x08;
      var DEVICE_TIMESTAMP = 0x10;
      var DEVICE_POSITION = 0x20;

      function u16(a, b) {
          return ((a & 0xff) | ((b & 0xff) << 8)) >>> 0;
      }

      function s16(a, b) {
          var v = u16(a, b);
          if (v & 0x8000) v -= 0x10000;
          return v;
      }

      function u32(a, b, c, d) {
          return (
              (a & 0xff) +
              ((b & 0xff) * 256) +
              ((c & 0xff) * 65536) +
              ((d & 0xff) * 16777216)
          ) >>> 0;
      }

      function s32(a, b, c, d) {
          var v = u32(a, b, c, d);
          if (v > 0x7fffffff) {
              v -= 0x100000000;
          }
          return v;
      }

      function hex2(v) {
          var h = (v & 0xff).toString(16);
          return h.length < 2 ? "0" + h : h;
      }

      function bytesToHex(arr) {
          var out = "";
          for (var i = 0; i < arr.length; i++) {
              out += hex2(arr[i]);
          }
          return out;
      }

      function bitCount(v) {
          var c = 0;
          for (var i = 0; i < 8; i++) {
              if (v & (1 << i)) c++;
          }
          return c;
      }

      function parseAxis(index, eventExists, extMask, range) {

          var result = {
              index: index,
              velocity_rms: null
          };

          if (eventExists) {
              result.index += 2;
          }

          if (extMask & EXT_VELOCITY) {
              result.velocity_rms =
                  u16(
                      bytes[result.index],
                      bytes[result.index + 1]
                  ) / 100;

              result.index += 2;
          }

          if (extMask & EXT_PEAK) {
              result.index += 2;
          }

          if (extMask & EXT_RMS) {
              result.index += 2;
          }

          if (extMask & EXT_KURTOSIS) {
              result.index += 2;
          }

          if (extMask & EXT_CREST) {
              result.index += 2;
          }

          if (extMask & EXT_SKEWNESS) {
              result.index += 2;
          }

          if (extMask & EXT_STDDEV) {
              result.index += 2;
          }

          if (extMask & EXT_DISPLACEMENT) {
              result.index += 2;
          }

          return result;
      }

      function parseEnvironment(index, version, range) {

          var start = index;
          var length = 0;

          if (version > 0) {
              index++;
              length = bytes[index++];
          } else {
              index++;
          }

          var mask = bytes[index++] & 0x1f;

          var value = null;

          if (mask & SENSOR_STATUS) {
              index++;
          }

          if (mask & SENSOR_EVENT) {
              index += 2;
          }

          if (mask & SENSOR_VALUE) {

              if (range === HUMIDITY) {
                  index += 4;
              } else {
                  value =
                      s32(
                          bytes[index],
                          bytes[index + 1],
                          bytes[index + 2],
                          bytes[index + 3]
                      ) / 1000;

                  index += 4;
              }
          }

          if (mask & SENSOR_MAX) {
              index += 4;
          }

          if (mask & SENSOR_MIN) {
              index += 4;
          }

          return {
              index:
                  version > 0
                      ? start + 2 + length
                      : index,
              value: value
          };
      }

      function parseVibration(index, version, range) {

          var start = index;
          var length = 0;

          if (version > 0) {
              index++;
              length = bytes[index++];
          } else {
              index++;
          }

          var axisAndMask = bytes[index++];

          var axisMask =
              (axisAndMask & 0xe0) >> 5;

          var mask =
              axisAndMask & 0x1f;

          var extMask =
              bytes[index++];

          // Massive/FFT frame
          if (mask & 0x01) {
              return {
                  index:
                      version > 0
                          ? start + 2 + length
                          : bytes.length - 1,
                  massive: true
              };
          }

          var eventExists =
              (mask & SENSOR_EVENT) !== 0;

          var out = {
              x: null,
              y: null,
              z: null,
              timestamp: null
          };

          if (axisMask & AXIS_X) {
              var x =
                  parseAxis(
                      index,
                      eventExists,
                      extMask,
                      range
                  );

              out.x =
                  x.velocity_rms;

              index =
                  x.index;
          }

          if (axisMask & AXIS_Y) {
              var y =
                  parseAxis(
                      index,
                      eventExists,
                      extMask,
                      range
                  );

              out.y =
                  y.velocity_rms;

              index =
                  y.index;
          }

          if (axisMask & AXIS_Z) {
              var z =
                  parseAxis(
                      index,
                      eventExists,
                      extMask,
                      range
                  );

              out.z =
                  z.velocity_rms;

              index =
                  z.index;
          }

          var axisCount =
              bitCount(axisMask);

          var metricCount =
              bitCount(extMask);

          var consumed =
              2 +
              axisCount *
              (
                  metricCount * 2 +
                  (eventExists ? 2 : 0)
              );

          var remaining =
              length - consumed;

          if (
              version > 0 &&
              remaining > 0 &&
              index < bytes.length - 1
          ) {
              var mask2 =
                  bytes[index++];

              remaining--;

              if (
                  mask2 &
                  MASK2_LOGINDEX
              ) {
                  index += 4;
                  remaining -= 4;
              }

              if (
                  (mask2 & MASK2_TIME) &&
                  remaining >= 4
              ) {
                  out.timestamp =
                      u32(
                          bytes[index],
                          bytes[index +1],
                          bytes[index + 2],
                          bytes[index + 3]
                      );

                  index += 4;
                  remaining -= 4;
              }
          }

          return {
              index:
                  version > 0
                      ? start + 2 + length
                      : index,
              value: out
          };
      }

      function parseDevice(index, version) {

          var start = index;

          index++;

          var length = 0;

          if (version > 0) {
              length =
                  bytes[index++];
          }

          var mask =
              bytes[index++];

          var timestamp = null;

          if (mask & DEVICE_EVENT) {
              index++;
          }

          if (mask & DEVICE_POWER) {
              index++;
          }

          if (mask & DEVICE_BATTERY_LEVEL) {
              index++;
          }

          if (mask & DEVICE_BATTERY_VOLTAGE) {
              index += 2;
          }

          if (mask & DEVICE_TIMESTAMP) {
              timestamp =
                  u32(
                      bytes[index],
                      bytes[index + 1],
                      bytes[index + 2],
                      bytes[index + 3]
                  );

              index += 4;
          }

          if (mask & DEVICE_POSITION) {
              index += 7;
          }

          return {
              index:
                  version > 0
                      ? start + 2 + length
                      : index,
              timestamp: timestamp
          };
      }

      // ============================================================
      // Main
      // ============================================================

      var output = {
          device_type: "WISE-2410",
          fPort: fPort,
          timestamp: null,
          temperature: null,
          temperature_unit: "C",
          vibration_x: null,
          vibration_y: null,
          vibration_z: null,
          vibration_unit: "mm/s",
          raw_hex: bytesToHex(bytes)
      };

      if (!bytes || bytes.length < 3) {
          output.error = "frame too short";
          return output;
      }

      var frameControl =
          bytes[0];

      var firstSegment =
          (frameControl & 0x80) !== 0;

      output.first_segment =
          firstSegment;

      output.sequence =
          bytes[1];

      // continuation packet
      if (!firstSegment) {

          output.needs_reassembly =
              true;

          output.decode_status =
              "waiting_for_previous_segment";

          return output;
      }

      var version =
          frameControl & 0x03;

      var index = 2;

      var hasFC2 =
          (frameControl & 0x20) !== 0;

      var totalLengthBytes = 1;

      if (hasFC2) {

          var fc2 =
              bytes[index++];

          if (fc2 & 0x01) {
              totalLengthBytes = 2;
          }
      }

      var totalLength;

      if (totalLengthBytes === 2) {
          totalLength =
              u16(
                  bytes[index],
                  bytes[index + 1]
              );

          index += 2;
      } else {
          totalLength =
              bytes[index++];
      }

      var addressMode =
          frameControl & 0x0c;

      var addressLength = 0;

      if (addressMode === 0x04) {
          addressLength = 2;
      }

      if (addressMode === 0x08) {
          addressLength = 8;
      }

      index += addressLength;

      var expectedLength =
          totalLength +
          3 +
          (hasFC2 ? 1 : 0) +
          totalLengthBytes +
          addressLength;

      output.expected_length =
          expectedLength;

      output.received_length =
          bytes.length;

      if (
          bytes.length <
          expectedLength
      ) {

          output.needs_reassembly =
              true;

          output.decode_status =
              "first_segment_incomplete";

          return output;
      }

      output.needs_reassembly =
          false;

      output.decode_status =
          "complete";

      var payloadEnd =
          bytes.length - 1;

      var safety = 0;

      while (
          index < payloadEnd &&
          safety < 20
      ) {

          safety++;

          var type =
              bytes[index] & 0xf0;

          var range =
              bytes[index] & 0x0f;

          // Temperature
          if (
              type === PAYLOAD_SENSOR_DATA &&
              (
                  range === TEMP_C ||
                  range === TEMP_F ||
                  range === TEMP_K ||
                  range === HUMIDITY
              )
          ) {

              var env =
                  parseEnvironment(
                      index,
                      version,
                      range
                  );

              if (
                  range === TEMP_C
              ) {
                  output.temperature =
                      env.value;
              }

              index =
                  env.index;

              continue;
          }

          // Vibration
          if (
              type === PAYLOAD_SENSOR_DATA &&
              (
                  range === ACC_G ||
                  range === ACC_MS2
              )
          ) {

              var vib =
                  parseVibration(
                      index,
                      version,
                      range
                  );

              if (!vib.massive) {

                  output.vibration_x =
                      vib.value.x;

                  output.vibration_y =
                      vib.value.y;

                  output.vibration_z =
                      vib.value.z;

                  if (
                      vib.value.timestamp !==
                      null
                  ) {
                      output.timestamp =
                          vib.value.timestamp;
                  }
              }

              index =
                  vib.index;

              continue;
          }

          // Device timestamp
          if (
              type ===
              PAYLOAD_DEVICE_DATA
          ) {

              var dev =
                  parseDevice(
                      index,
                      version
                  );

              if (
                  output.timestamp === null &&
                  dev.timestamp !== null
              ) {
                  output.timestamp =
                      dev.timestamp;
              }

              index =
                  dev.index;

              continue;
          }

          break;
      }

      return output;
  }

  router.post("/sensor_data", async (_req, res, next) => {
    console.log("Running iBeX sensor_data");
    console.log("sensor_data_req.body ", _req.body);
    console.log("sensor_data_req.headers ", _req.headers);

    try {
      // Get the schema to initialize services
      const schema = await getSchema();
      const { ItemsService } = services;

      const sensorDataService = new ItemsService("Sensor_data", {
        schema,
        knex: database,
        accountability: null,
      });

      const newRecord = await sensorDataService.createOne({
        sensor_data: _req.body,
        date_created: new Date(),
      });
      
      console.log("newRecord:", newRecord);

      let deviceKey = _req.body.device_type || "unknown";
      let xIotKey = _req.headers["x-iot-key"] || null;

      // body.device_type тодорхойгүй/буруу ирсэн ч x-iot-key header нь
      // WISE-2410 төхөөрөмжийнх мөн эсэхийг давхар шалгаж deviceKey-г засна.
      // if (deviceKey !== "WISE-2410" && xIotKey === "WISE-2410-EB-IBEX") {
      //   deviceKey = "WISE-2410";
      // }

      const sensorReadingService = new ItemsService("Sensor_reading", {
        schema,
        knex: database,
        accountability: null,
      });

      const deviceId =
        _req.body.imei ||
        _req.body.device_id ||
        _req.body.unit_id ||
        _req.body.id ||
        _req.body.id ||
        xIotKey ||
        null;

      // WISE-2410-оос бусад төрлийн device/sensor integration-ийг raw
      // хэлбэрээр нь json_data-д хадгална (byte-level decode хийхгүй).
      if (deviceKey !== "WISE-2410") {
        const newLivedata = await sensorReadingService.createOne({
          device_type: deviceKey,
          device_id: deviceId,
          json_data: _req.body,
          date_created: new Date(),
        });

        return res.status(200).json({
          status: 200,
          received: true,
          reading_id: newLivedata,
        });
      }

      const assembled = reassembleWise2410(
        deviceKey,
        _req.body
      );

    console.log("ASSEMBLY:", assembled);

    // Бүтэн болоогүй packet-ийг decode хийх боломжгүй бөгөөд
    // Sensor_reading-д зөвхөн completed үед л create хийх ёстой тул
    // энд юу ч хадгалахгүйгээр зогсоно.
    if (!assembled.complete) {
      console.log("packet_is_notcompleted:", assembled);

      return res.status(200).json({
        status: 200,
        received: true,
        assembly_status: assembled.status,
      });
    }

    console.log("FULL FRAME:", assembled.raw_hex);

    // Full frame угсрагдсан тул byte-level decode хийж,
    // temperature / vibration_x / vibration_y / vibration_z-ийн
    // бодит утгыг гаргаж авна.
    const decoded = Decode(
      _req.body.fPort ?? null,
      hexToBytes(assembled.raw_hex)
    );

    console.log("DECODED:", decoded);

    const newReading = await sensorReadingService.createOne({
      device_type: deviceKey,
      device_id: deviceId,
      raw_hex: assembled.raw_hex,
      temperature: decoded.temperature,
      temperature_unit: decoded.temperature_unit,
      vibration_x: decoded.vibration_x,
      vibration_y: decoded.vibration_y,
      vibration_z: decoded.vibration_z,
      vibration_unit: decoded.vibration_unit,
      timestamp: decoded.timestamp !== null ? decoded.timestamp : null,
      timestamp_datetime:
        decoded.timestamp !== null
          ? new Date(decoded.timestamp * 1000)
          : null,
      json_data: decoded,
      date_created: new Date(),
    });

    console.log("newReading:", newReading);

    return res.status(200).json({
      status: 200,
      complete: true,
      reading_id: newReading,
    });
    } catch (error) {
      console.error("Error in CMMS sensor:", error);
      return res.json({ status: 500, message: error.message });
    }
  });

};
