import 'constants.dart';

String get getUserFcmApi => '${activeBaseUrl}items/user_device_tokens';
String get getUserLoginApi => '${activeBaseUrl}auth/login';

String get getUser => '${activeBaseUrl}users';
String get getUserInfoUrl => '${activeBaseUrl}users/me';
String get updateUserUrl => '${activeBaseUrl}users/update';
String get createUserUrl => '${activeBaseUrl}users/store';
String get deleteUserUrl => '${activeBaseUrl}users/destroy';

String get tododsUrl => '${activeBaseUrl}items/users_todos';
String get getUserSignUpApi => '${activeBaseUrl}users/signup';
String get getPasswordResetUpApi => '${activeBaseUrl}password/reset-request';
// String get resetPasswordApi => '${activeBaseUrl}password/reset';

String get getStatus => '${activeBaseUrl}items/Module_status';
String get createStatusUrl => '${activeBaseUrl}items/Module_status';
String get deleteStatusUrl => '${activeBaseUrl}items/Module_status';
String get updateStatusUrl => '${activeBaseUrl}items/Module_status';

// works
String get workUrl => '${activeBaseUrl}items/Work_order';
String get updateWorkUrl => '${activeBaseUrl}items/Work_order';
String get createWorkUrl => '${activeBaseUrl}items/Work_order';
String get deleteWorkUrl => '${activeBaseUrl}items/Work_order';
String get updatePinnedWorkUrl => '${activeBaseUrl}items/Work_order';
String get workMindMapUrl => '${activeBaseUrl}';
String get workComments => '${activeBaseUrl}items/Work_order_comments';
String get addUsersToWork => '${activeBaseUrl}items/Work_order_task_users';
String get getUsersToWork => '${activeBaseUrl}items/Work_order_task_users';

String get createTaskUrl => '${activeBaseUrl}items/Work_order_item';
String get getAllTaskUrl => '${activeBaseUrl}items/Work_order_item';
String get updateTaskUrl => '${activeBaseUrl}items/Work_order_item';
String get deleteTask => '${activeBaseUrl}items/Work_order_item';

String get partUrl => '${activeBaseUrl}items/Parts';
String get tradeUrl => '${activeBaseUrl}items/Trades';
String get workPartUrl => '${activeBaseUrl}items/Work_order_Parts';
String get workTradeUrl => '${activeBaseUrl}items/Work_order_Tradecode';

String get workTimelineStatusUrl => '${activeBaseUrl}items/Work_order_status_timeline';
String get workTaskTimelineStatusUrl => '${activeBaseUrl}items/Work_order_item_status_timeline';

String get workMediaUrl => '${activeBaseUrl}items/Work_order_files';
String get uploadWorkMediaUrl => '${activeBaseUrl}files';
String get deleteWorkMediaUrl => '${activeBaseUrl}items/Work_order_files/delete';

String get workMilestoneUrl => '${activeBaseUrl}milestones';
String get updateWorkMilestoneUrl => '${activeBaseUrl}milestones/update';
String get createWorkMilestoneUrl => '${activeBaseUrl}milestones/store';
String get deleteWorkMilestoneUrl => '${activeBaseUrl}milestones/destroy';

String get inspectionPartUrl => '${activeBaseUrl}items/Work_inpection_Parts';
String get inspectionTradeUrl => '${activeBaseUrl}items/Work_inspection_Tradecode';

String get inspectionTimelineStatusUrl => '${activeBaseUrl}items/Work_inspection_status_timeline';
String get inspectionTaskTimelineStatusUrl => '${activeBaseUrl}items/Work_inspection_item_status_timeline';

String get inspectionMediaUrl => '${activeBaseUrl}items/Work_inspection_files';
String get uploadInspectionMediaUrl => '${activeBaseUrl}files';
String get deleteInspectionMediaUrl => '${activeBaseUrl}items/Work_inspection_files/delete';

// work space
String get getmyWorkSpaceIdsUrl => '${activeBaseUrl}items/Teams_directus_users';
String get getTeamLeaderUrl => '${activeBaseUrl}items/Teams_directus_users_1';

String get getWorkSpaceUrl => '${activeBaseUrl}items/Teams';
String get updaetWorkSpaceUrl => '${activeBaseUrl}items/Teams';
String get createWorkSpaceUrl => '${activeBaseUrl}items/Teams';
String get removeWorkSpaceUrl => '${activeBaseUrl}items/Teams';
String get removeMeWorkSpaceUrl => '${activeBaseUrl}remove-participant';

// Inspection work
String get inspectionUrl => '${activeBaseUrl}items/Work_inspections';
String get updateInspectionUrl => '${activeBaseUrl}items/Work_inspections';
String get createInspectionUrl => '${activeBaseUrl}items/Work_inspections';
String get deleteInspectionUrl => '${activeBaseUrl}items/Work_inspections';
String get updatePinnedInspectionUrl => '${activeBaseUrl}items/Work_inspections';
String get inspectionItem => '${activeBaseUrl}items/Work_inspection_item';
String get inspectionUsers => '${activeBaseUrl}items/Work_inspection_users';
String get inspectionComments => '${activeBaseUrl}items/Work_inspection_comments';
String get inspectionActions => '${activeBaseUrl}items/Work_inspection_actions';
String get inspectionActivityUrl => '${activeBaseUrl}items/Work_inspection_actions';

String get inspectionItemUploadTaskMediaUrl => '${activeBaseUrl}items/Work_inspection_files';
String get inspectionItemDeleteTaskMediaUrl => '${activeBaseUrl}items/Work_inspection_item_directus_files';

// location
String get getLocationUrl => '${activeBaseUrl}items/Location';
String get updaetLocationUrl => '${activeBaseUrl}items/Location';
String get createLocationUrl => '${activeBaseUrl}items/Location';
String get removeLocationUrl => '${activeBaseUrl}items/Location';

String get getassetIdsUrl => '${activeBaseUrl}items/Assets';
String get getassetUrl => '${activeBaseUrl}items/Assets';
String get updaetassetUrl => '${activeBaseUrl}items/Assets';
String get createassetUrl => '${activeBaseUrl}items/Assets';
String get removeassetUrl => '${activeBaseUrl}items/Assets';
String get removeassetMeassetUrl => '${activeBaseUrl}remove-participant';

String get getNotificationUrl => '${activeBaseUrl}items/Notify';
String get deleteNotificationUrl => '${activeBaseUrl}items/Notify/destroy';
String get markAsReadNotificationUrl => '${activeBaseUrl}items/Notify/mark-as-read';

// project discussion
String get projectUrl => '${activeBaseUrl}projects';
String get updateProjectUrl => '${activeBaseUrl}projects/update';
String get createProjectUrl => '${activeBaseUrl}projects/store';
String get deleteProjectUrl => '${activeBaseUrl}projects/destroy';
String get updatePinnedProjectUrl => '${activeBaseUrl}projects';
String get projectMindMapUrl => '${activeBaseUrl}';

String get projectMilestoneUrl => '${activeBaseUrl}milestones';
String get updateProjectMilestoneUrl => '${activeBaseUrl}milestones/update';
String get createProjectMilestoneUrl => '${activeBaseUrl}milestones/store';
String get deleteProjectMilestoneUrl => '${activeBaseUrl}milestones/destroy';

String get projectTimelineStatusUrl => '${activeBaseUrl}projects/';
String get taskTimelineStatusUrl => '${activeBaseUrl}tasks/';

String get projectMediaUrl => '${activeBaseUrl}projects/get-media';
String get uploadProjectMediaUrl => '${activeBaseUrl}projects/upload-media';
String get deleteProjectMediaUrl => '${activeBaseUrl}projects/delete-media';

String get getDiscussionUrl => '${activeBaseUrl}projects';
String get updateDiscussionUrl => '${activeBaseUrl}projects/comments/update';
String get createDiscussionUrl => '${activeBaseUrl}projects';
String get deleteDiscussionUrl => '${activeBaseUrl}projects/comments/destroy';
String get deleteDiscussionAttachmentUrl => '${activeBaseUrl}projects/comments/destroy-attachment';

String get getTaskDiscussionUrl => '${activeBaseUrl}tasks';
String get updateTasksDiscussionUrl => '${activeBaseUrl}tasks/comments/update';
String get createTasksDiscussionUrl => '${activeBaseUrl}tasks';
String get deleteTasksDiscussionUrl => '${activeBaseUrl}tasks/comments/destroy';
String get deleteTasksDiscussionAttachmentUrl => '${activeBaseUrl}tasks/comments/destroy-attachment';

String get taskMediaUrl => '${activeBaseUrl}tasks/get-media';
String get uploadTaskMediaUrl => '${activeBaseUrl}tasks/upload-media';
String get deleteTaskMediaUrl => '${activeBaseUrl}tasks/delete-media';

// priority, notes, leave request, meeting later make modular
String get getPriorityUrl => '${activeBaseUrl}priorities';
String get createPriorityUrl => '${activeBaseUrl}priority/store';
String get deletePriorityUrl => '${activeBaseUrl}priority/destroy';
String get updatePriorityUrl => '${activeBaseUrl}priority/update';

String get createNotesUrl => '${activeBaseUrl}notes/store';
String get deleteNotesUrl => '${activeBaseUrl}notes/destroy';
String get updateNotesUrl => '${activeBaseUrl}notes/update';
String get listNotesUrl => '${activeBaseUrl}notes';

String get listLeaveRequestUrl => '${activeBaseUrl}leave-requests';
String get createLeaveRequestUrl => '${activeBaseUrl}leave-requests/store';
String get deleteLeaveRequestUrl => '${activeBaseUrl}leave-requests/destroy';
String get updateLeaveRequestUrl => '${activeBaseUrl}leave-requests/update';
String get memberOnLeaveRequestUrl => '${activeBaseUrl}members-on-leave';

String get listMeetingUrl => '${activeBaseUrl}meetings';
String get createMeetingUrl => '${activeBaseUrl}meetings/store';
String get deleteMeetingUrl => '${activeBaseUrl}meetings/destroy';
String get updateMeetingUrl => '${activeBaseUrl}meetings/update';

String get getRoleUrl => '${activeBaseUrl}roles';
String get getRoleUpdateUrl => '${activeBaseUrl}roles/update';
String get getSpecificRolePermissionsUrl => '${activeBaseUrl}roles/get';
String get getAllPermissionsListUrl => '${activeBaseUrl}permissions-list';
String get getDeleteRoleUrl => '${activeBaseUrl}roles/destroy';
String get createRoleUrl => '${activeBaseUrl}roles/store';

String get getTagUrl => '${activeBaseUrl}tags';
String get updateTagUrl => '${activeBaseUrl}tags/update';
String get createTagUrl => '${activeBaseUrl}tags/store';
String get deleteTagUrl => '${activeBaseUrl}tags/destroy';

String get getCustomFieldUrl => '${activeBaseUrl}custom-fields/list';
String get updateCustomFieldUrl => '${activeBaseUrl}custom-fields/update';
String get createCustomFieldUrl => '${activeBaseUrl}custom-fields';
String get deleteCustomFieldUrl => '${activeBaseUrl}custom-fields/destroy';

String get getLeadUrl => '${activeBaseUrl}leads/list';
String get updateLeadUrl => '${activeBaseUrl}leads/update';
String get createLeadUrl => '${activeBaseUrl}leads/store';
String get deleteLeadUrl => '${activeBaseUrl}leads/destroy';
String get convertLeadToClientUrl => '${activeBaseUrl}leads';

String get getLeadStageUrl => '${activeBaseUrl}lead-stages/list';
String get updateLeadStageUrl => '${activeBaseUrl}lead-stages/update';
String get createLeadStageUrl => '${activeBaseUrl}lead-stages/store';
String get deleteLeadStageUrl => '${activeBaseUrl}lead-stages/destroy';

String get createFollowUpLeadUrl => '${activeBaseUrl}leads/follow-up/store';
String get deleteFollowUpLeadUrl => '${activeBaseUrl}leads/follow-up/destroy';
String get updateFollowUpLeadUrl => '${activeBaseUrl}leads/follow-up/update';

String get getLeadSourceUrl => '${activeBaseUrl}lead-sources/list';
String get updateLeadSourceUrl => '${activeBaseUrl}lead-sources/update';
String get createLeadSourceUrl => '${activeBaseUrl}lead-sources/store';
String get deleteLeadSourceUrl => '${activeBaseUrl}lead-sources/destroy';
String get incomeVsExpenseUrl => '${activeBaseUrl}reports/income-vs-expense-report-data';

String get getClientUrl => '${activeBaseUrl}clients';
String get updateClientUrl => '${activeBaseUrl}clients/update';
String get createClientUrl => '${activeBaseUrl}clients/store';
String get deleteClientUrl => '${activeBaseUrl}clients/destroy';

String get getCandidateUrl => '${activeBaseUrl}candidate/list';
String get getAttachmentCandidateUrl => '${activeBaseUrl}candidate/';
String get getCandidateInteviewUrl => '${activeBaseUrl}candidate';
String get getInterviewCandidateUrl => '${activeBaseUrl}candidate/';
String get updateCandidateUrl => '${activeBaseUrl}candidate/update';
String get createCandidateUrl => '${activeBaseUrl}candidate/store';
String get deleteCandidateUrl => '${activeBaseUrl}candidate/destroy';
String get deleteCandidateAttachmentUrl => '${activeBaseUrl}candidate/candidate-media/destroy';

String get getCandidateStatusUrl => '${activeBaseUrl}candidate_status/list';
String get updateCandidateStatusUrl => '${activeBaseUrl}candidate_status/update';
String get createCandidateStatusUrl => '${activeBaseUrl}candidate_status/store';
String get deleteCandidateStatusUrl => '${activeBaseUrl}candidate_status/destroy';

String get getInterviewsUrl => '${activeBaseUrl}interviews/list';
String get updateInterviewsUrl => '${activeBaseUrl}interviews/update';
String get createInterviewsUrl => '${activeBaseUrl}interviews/store';
String get deleteInterviewsUrl => '${activeBaseUrl}interviews/destroy';

String get getStatisticsUrl => '${activeBaseUrl}dashboard/statistics';

String get getBirthdayUrl => '${activeBaseUrl}upcoming-birthdays';
String get getWorkAnniUrl => '${activeBaseUrl}upcoming-work-anniversaries';

String get activityUrl => '${activeBaseUrl}items/Work_order_actions';
String get listActivityUrl => '${activeBaseUrl}activity-log';
String get deleteActivityUrl => '${activeBaseUrl}activity-log/destroy';

String get updateProfileUrl => '${activeBaseUrl}users';
String get getUserDetailUrl => '${activeBaseUrl}users/me';
String get updateProfilDetailsUrl => '${activeBaseUrl}users';

String get expenseUrl => '${activeBaseUrl}expenses';
String get createExpenseUrl => '${activeBaseUrl}expenses/store';
String get updateExpenseUrl => '${activeBaseUrl}expenses/update';
String get deleteExpenseUrl => '${activeBaseUrl}expenses/destroy';

String get allowanceUrl => '${activeBaseUrl}allowances/list';
String get createAllowanceUrl => '${activeBaseUrl}allowances/store';
String get updateAllowanceUrl => '${activeBaseUrl}allowances/update';
String get deleteAllowanceUrl => '${activeBaseUrl}allowances/destroy';

String get deductionUrl => '${activeBaseUrl}deductions/list';
String get createDeductionUrl => '${activeBaseUrl}deductions/store';
String get updateDeductionUrl => '${activeBaseUrl}deductions/update';
String get deleteDeductionUrl => '${activeBaseUrl}deductions/destroy';

String get payslipUrl => '${activeBaseUrl}payslips/list';
String get createPayslipUrl => '${activeBaseUrl}payslips/store';
String get updatePayslipUrl => '${activeBaseUrl}payslips/update';
String get deletePayslipUrl => '${activeBaseUrl}payslips/destroy';

String get expenseTypeListUrl => '${activeBaseUrl}expenses/expense-types/list';
String get createExpenseTypeUrl => '${activeBaseUrl}expenses/expense-types/store';
String get destroyExpenseTypeUrl => '${activeBaseUrl}expenses/expense-types/destroy';
String get updateExpenseTypeUrl => '${activeBaseUrl}expenses/expense-types/update';

String get EstimatesInvoicesUrl => '${activeBaseUrl}estimates-invoices';
String get createEstimatesInvoicesUrl => '${activeBaseUrl}estimates-invoices/store';
String get updateEstimatesInvoicesUrl => '${activeBaseUrl}estimates-invoices/update';
String get deleteEstimatesInvoicesUrl => '${activeBaseUrl}estimates-invoices/destroy';

String get itemsUrl => '${activeBaseUrl}items';
String get createItemsUrl => '${activeBaseUrl}items/store';
String get updateItemsUrl => '${activeBaseUrl}items/update';
String get deleteItemsUrl => '${activeBaseUrl}items/destroy';

String get unitUrl => '${activeBaseUrl}units';
String get createUnitUrl => '${activeBaseUrl}units/store';
String get updateUnitUrl => '${activeBaseUrl}units/update';
String get deleteUnitUrl => '${activeBaseUrl}units/destroy';

String get taxesUrl => '${activeBaseUrl}taxes';
String get createTaxesUrl => '${activeBaseUrl}taxes/store';
String get updateTaxesUrl => '${activeBaseUrl}taxes/update';
String get deleteTaxesUrl => '${activeBaseUrl}taxes/destroy';

String get paymentMethodsUrl => '${activeBaseUrl}payment-methods';
String get createPaymentMethodsUrl => '${activeBaseUrl}payment-methods/store';
String get updatePaymentMethodsUrl => '${activeBaseUrl}payment-methods/update';
String get deletePaymentMethodsUrl => '${activeBaseUrl}payment-methods/destroy';

String get paymentUrl => '${activeBaseUrl}payments';
String get createPaymentUrl => '${activeBaseUrl}payments/store';
String get updatePaymentUrl => '${activeBaseUrl}payments/update';
String get deletePaymentUrl => '${activeBaseUrl}payments/destroy';

String get contractTypeUrl => '${activeBaseUrl}contracts/contract-types-list';
String get createContractTypeUrl => '${activeBaseUrl}contracts/store-contract-type';
String get updateContractTypeUrl => '${activeBaseUrl}contracts_type/update-contract-type';
String get deleteContractTypeUrl => '${activeBaseUrl}contracts/delete-contract-type';

String get contractUrl => '${activeBaseUrl}contracts/list';
String get createContractUrl => '${activeBaseUrl}contracts/store';
String get updateContractUrl => '${activeBaseUrl}contracts/update';
String get deleteContractUrl => '${activeBaseUrl}contracts/destroy';
String get signContractUrl => '${activeBaseUrl}contracts/create-sign?isApi=1';
String get deleteSignContractUrl => '${activeBaseUrl}contracts/delete-sign';

String get assignedPermissionsurl => '${activeBaseUrl}roles'; //forced

// String get assignedPermissionsurl => '${activeBaseUrl}permissions'; //?
String get settingsurl => '${activeBaseUrl}items/settings_app';
String get settingUpdateurl => '${activeBaseUrl}items/settings_app/update';
String get companyInfourl => '${activeBaseUrl}items/settings_app';
String get emailComapnyurl => '${activeBaseUrl}items/settings_app';
String get smsGatewayurl => '${activeBaseUrl}items/settings_app';
String get whatsappurl => '${activeBaseUrl}items/settings_app';
String get slackappurl => '${activeBaseUrl}items/settings_app';
String get mediaStorageUrl => '${activeBaseUrl}items/settings_app';
String get privacyPolicyUrl => '${activeBaseUrl}items/settings_app';
String get aboutUsUrl => '${activeBaseUrl}items/settings_app';
String get termsAndConditionUrl => '${activeBaseUrl}items/settings_app';
String get newsUrl => '${activeBaseUrl}items/news';
String get accountdeletionsurl => '${activeBaseUrl}account/destroy';
String get forgetPasswordUrl => '${activeBaseUrl}forgot-password';
