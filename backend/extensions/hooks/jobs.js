module.exports = function registerHook({ schedule }, { services, database, getSchema }) {
  // Schedule a job to run every day at midnight
  // You can adjust the schedule as needed
  schedule('* * * * *', async () => {
    try {
      console.log('Running CMMS scheduled maintenance task');
      
      // Get the schema to initialize services
      const schema = await getSchema();
      const { ItemsService } = services;
      
      const maintenanceService = new ItemsService('Work_order', {
        schema,
        knex: database,
        accountability:null
      });

      const taskService = new ItemsService('Work_order_item', {
        schema,
        knex: database,
        accountability:null
      });
      
      // Get current date
      const today = new Date().toISOString().split('T')[0];
      
      console.log('maintenanceService', today)

      // Find tasks due today
      const templateTasks = await maintenanceService.readByQuery({
        filter: {
          type: { _eq: 4 },
          pm_type:'pm',
          template_pm:{
            _null: true,
          },
          schedule: { 
            _nnull: true,
            start_date: { _starts_with: today }  // Use the date string prefix 
          }
        },
        fields: [
          '*',
          'schedule.*'
        ]
      });

      console.log(`templateTasks`, templateTasks);
      console.log(`Found ${templateTasks.length} maintenance tasks due today`);
      

      // Process each task (example: update status)
      for (const task of templateTasks) {
        try {
          // Create a new work_order based on the template task
          const newWorkOrder = await maintenanceService.createOne({
            name: `${task.name} - ${today}`, 
            description: task.description,
            asset: task.asset_id,
            location: task.location,
            type: task.type,
            active: task.active,
            pm_type:'generated',
            template_pm:task.id,
            priority: task.priority || 2,
            status: task.status, 
            schedule: null,
          });

          console.log(`Created new work order ${newWorkOrder} based on template ${task.id}`);
          
          // Get the template's work order items
          const templateItems = await taskService.readByQuery({
            filter: {
              workorder: { _eq: task.id }
            },
            fields: ['*']
          });
          
          console.log(`Found ${templateItems.length} template items to copy`);
          
          // Create new work_order_items for each template item
          for (const item of templateItems) {
            const newItem = await taskService.createOne({
              workorder: newWorkOrder, // Link to the new work order
              name: item.name,
              value: item.value,
              status: item.status,
              code: item.code,
              priority: item.priority,
              parent: item.parent,
              active:item.active,
              children: item.children,
              template_type: item.template_type,
              estimated_hours: item.estimated_hours,
              instructions: item.instructions,
              created_type:'system',
              date_created:new Date()
            });
            
            console.log(`Created new work order item ${newItem} for work order ${newWorkOrder}`);
          }
          
          // Update the template task if needed
          // const currentDate = new Date().toLocaleString("en-US", { timeZone: "Asia/Ulaanbaatar" });

          await maintenanceService.updateOne(task.id, {
            priority: 1,
            last_generated: new Date()
          });

          console.log(`Updated template task-id ${task.id} after generating new work order`);
        } catch (error) {
          console.error(`Error processing template task ${task.id}:`, error);
        }
      }


      console.log('CMMS scheduled maintenance task completed');
    } catch (error) {
      console.error('Error in CMMS cron job:', error);
    }
  });
};