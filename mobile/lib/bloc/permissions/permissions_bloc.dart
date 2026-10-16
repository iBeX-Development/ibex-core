import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/permissions/permissions_event.dart';
import '../../api_helper/api.dart';
import '../../data/repositories/permissions/permission_repo.dart';
import '../../utils/widgets/toast_widget.dart';
import 'permissions_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  bool? iscreateProject;
  bool? isManageProject;
  bool? iseditProject;
  bool? isdeleteProject;

  bool? iscreatetask;
  bool? isManageTask;
  bool? iseditTask;
  bool? isdeleteTask;

  bool? iscreateClient;
  String? isGuard;
  bool? isLeaveEditor;
  String? roleIS;
  bool? hasAllAccess;
  bool? isManageClient;
  bool? iseditClient;
  bool? isdeleteClient;

  bool? iscreatePriority;
  bool? isManagePriority;
  bool? iseditPriority;
  bool? isdeletePriority;

  bool? iscreateMeeting;
  bool? isManageMeeting;
  bool? iseditMeeting;
  bool? isdeleteMeeting;

  bool? iscreateStatus;
  bool? isManageStatus;
  bool? iseditStatus;
  bool? isdeleteStatus;

  bool? iscreateTags;
  bool? isManageTags;
  bool? iseditTags;
  bool? isdeleteTags;
  String? userId;

  bool? iscreateUser;
  bool? isManageUser;
  bool? iseditUser;
  bool? isdeleteUser;

  bool? iscreateWorkspace;
  bool? iscreateExpenses;
  bool? isManageWorkspace;
  bool? isManageExpenses;
  bool? iseditWorkspace;
  bool? iseditExpenses;
  bool? isdeleteWorkspace;
  bool? isdeleteExpenses;

  bool? isManageActivityLog;

  bool? isdeleteActivityLog;
  bool? isManageSystenNotification;
  bool? isDeleteSystenNotification;
  bool? isManageSystemNotification;
  bool? isdeleteSystemNotification;

  bool? iscreateContract;
  bool? isManageContract;
  bool? iseditContract;
  bool? isdeleteContract;

  bool? iscreateContractType;
  bool? isManageContractType;
  bool? iseditContractType;
  bool? isdeleteContractType;

  bool? iscreateTimesheet;
  bool? isManageTimesheet;
  bool? isdeleteTimesheet;

  bool? iscreateMedia;
  bool? isManageMedia;
  bool? isdeleteMedia;

  bool? iscreatePayslip;
  bool? isManagePayslip;
  bool? iseditPayslip;
  bool? isdeletePayslip;

  bool? iscreateAllowance;
  bool? isManageAllowance;
  bool? iseditAllowance;
  bool? isdeleteAllowance;

  bool? iscreateDeduction;
  bool? isManageDeduction;
  bool? iseditDeduction;
  bool? isdeleteDeduction;

  bool? iscreatePaymentMethod;
  bool? isManagePaymentMethod;
  bool? iseditPaymentMethod;
  bool? isdeletePaymentMethod;

  bool? iscreateEstimateInvoice;
  bool? isManageEstimateInvoice;
  bool? iseditEstimateInvoice;
  bool? isdeleteEstimateInvoice;

  bool? iscreatePayment;
  bool? isManagePayment;
  bool? iseditPayment;
  bool? isdeletePayment;

  bool? iscreateTax;
  bool? isManageTax;
  bool? iseditTax;
  bool? isdeleteTax;

  bool? iscreateUnit;
  bool? isManageUnit;
  bool? iseditUnit;
  bool? isdeleteUnit;

  bool? iscreateItem;
  bool? isManageItem;
  bool? iseditItem;
  bool? isdeleteItem;

  bool? iscreateExpenseType;
  bool? isManageExpenseType;
  bool? iseditExpenseType;
  bool? isdeleteExpenseType;

  bool? iscreateMilestone;
  bool? isManageMilestone;
  bool? iseditMilestone;
  bool? isdeleteMilestone;

  bool? iscreatePart;
  bool? isManagePart;
  bool? iseditPart;
  bool? isdeletePart;

  bool? iscreateTrade;
  bool? isManageTrade;
  bool? iseditTrade;
  bool? isdeleteTrade;

  bool? isCreateLeads;
  bool? isManageLeads;
  bool? isEditLeads;
  bool? isDeleteLeads;

  bool? isSendEmail;

  bool? isCreateEmailTemplate;
  bool? isManageEmailTemplate;
  bool? isDeleteEmailTemplate;

  bool? isCreateCandidate;
  bool? isManageCandidate;
  bool? isEditCandidate;
  bool? isDeleteCandidate;

  bool? isCreateCandidateStatus;
  bool? isManageCandidateStatus;
  bool? isEditCandidateStatus;
  bool? isDeleteCandidateStatus;

  bool? isCreateInterview;
  bool? isManageInterview;
  bool? isEditInterview;
  bool? isDeleteInterview;

  bool? isManageSystemNotifications;
  bool? isDeleteSystemNotifications;

  bool? iscreateInspection;
  bool? isManageInspection;
  bool? iseditInspection;
  bool? isdeleteInspection;

  bool? isManageWork;
  bool? iscreateWork;
  bool? iseditWork;
  bool? isdeleteWork;

  bool? iscreateAssign;
  bool? isManageAssign;
  bool? iseditAssign;
  bool? isdeleteAssign;

  PermissionsBloc() : super(PermissionsInitial()) {
    on<GetPermissions>(_getPermissions);
  }

  Future<void> _getPermissions(
    GetPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      Map<String, dynamic> result = await PermissionRepo().getPermissions(
        token: true,
      );

      if (result.containsKey('errors')) {
        flutterToastCustom(msg: result['message']);
        return;
      }

      // Check if data is an array and get first item (role info)
      var data = result['data'];
      bool isAdmin = false;
      Map<String, dynamic> permission = {};

      if (data is List && data.isNotEmpty) {
        var roleData = data[0];
        isAdmin = (roleData['admin_access'] == 1);
        permission = roleData['permissions'] ?? {};
      } else if (data is Map) {
        isAdmin = (data['admin_access'] == 1);
        permission = Map<String, dynamic>.from(data);
      }

      if (kDebugMode) {

        logger.d('Is Admin Access: $isAdmin');

      }

      // isManageWork = true;
      // iscreateWork = true;
      // iseditWork = true;
      // isdeleteWork = true;

      // isManageAssign = true;
      // isManageInspection = true;

      isManageWork = isAdmin ? true : (permission['manage_work'] ?? true);
      iscreateWork = isAdmin ? true : (permission['create_work'] ?? true);
      iseditWork = isAdmin ? true : (permission['edit_work'] ?? true);
      isdeleteWork = isAdmin ? true : (permission['delete_work'] ?? true);

      isManageAssign = isAdmin ? true : (permission['manage_assign'] ?? true);
      isManageInspection =
          isAdmin ? true : (permission['manage_inspection'] ?? true);

      isManageProject =
          isAdmin ? true : (permission['manage_projects'] ?? true);
      isManageActivityLog =
          isAdmin ? true : (permission['manage_activity_log'] ?? true);
      isdeleteActivityLog =
          isAdmin ? true : (permission['delete_activity_log'] ?? false);
      iscreateClient = isAdmin ? true : (permission['create_clients'] ?? false);
      isManageClient = isAdmin ? true : (permission['manage_clients'] ?? false);
      iseditClient = isAdmin ? true : (permission['edit_clients'] ?? false);
      isdeleteClient = isAdmin ? true : (permission['delete_clients'] ?? false);
      iscreateMeeting =
          isAdmin ? true : (permission['create_meetings'] ?? false);
      isManageMeeting =
          isAdmin ? true : (permission['manage_meetings'] ?? false);
      iseditMeeting = isAdmin ? true : (permission['edit_meetings'] ?? false);
      isdeleteMeeting =
          isAdmin ? true : (permission['delete_meetings'] ?? false);
      iscreatePriority =
          isAdmin ? true : (permission['create_priorities'] ?? false);
      isManagePriority =
          isAdmin ? true : (permission['manage_priorities'] ?? false);
      iseditPriority =
          isAdmin ? true : (permission['edit_priorities'] ?? false);
      isdeletePriority =
          isAdmin ? true : (permission['delete_priorities'] ?? false);
      iscreateProject =
          isAdmin ? true : (permission['create_projects'] ?? false);
      iseditProject = isAdmin ? true : (permission['edit_projects'] ?? false);
      isdeleteProject =
          isAdmin ? true : (permission['delete_projects'] ?? false);
      iscreateStatus =
          isAdmin ? true : (permission['create_statuses'] ?? false);
      isManageStatus =
          isAdmin ? true : (permission['manage_statuses'] ?? false);
      iseditStatus = isAdmin ? true : (permission['edit_statuses'] ?? false);
      isdeleteStatus =
          isAdmin ? true : (permission['delete_statuses'] ?? false);
      isManageSystemNotification =
          isAdmin ? true : (permission['manage_system_notifications'] ?? false);
      isdeleteSystemNotification =
          isAdmin ? true : (permission['delete_system_notifications'] ?? false);
      iscreateTags = isAdmin ? true : (permission['create_tags'] ?? false);
      isManageTags = isAdmin ? true : (permission['manage_tags'] ?? false);
      iseditTags = isAdmin ? true : (permission['edit_tags'] ?? false);
      isdeleteTags = isAdmin ? true : (permission['delete_tags'] ?? false);
      iscreatetask = isAdmin ? true : (permission['create_tasks'] ?? false);
      isManageTask = isAdmin ? true : (permission['manage_tasks'] ?? false);
      iseditTask = isAdmin ? true : (permission['edit_tasks'] ?? false);
      isdeleteTask = isAdmin ? true : (permission['delete_tasks'] ?? false);
      iscreateUser = isAdmin ? true : (permission['create_users'] ?? false);
      isManageUser = isAdmin ? true : (permission['manage_users'] ?? false);
      iseditUser = isAdmin ? true : (permission['edit_users'] ?? false);
      isdeleteUser = isAdmin ? true : (permission['delete_users'] ?? false);
      iscreateWorkspace =
          isAdmin ? true : (permission['create_workspaces'] ?? true);
      isManageWorkspace =
          isAdmin ? true : (permission['manage_workspaces'] ?? true);
      iseditWorkspace =
          isAdmin ? true : (permission['edit_workspaces'] ?? true);
      isdeleteWorkspace =
          isAdmin ? true : (permission['delete_workspaces'] ?? false);
      iseditExpenses = isAdmin ? true : (permission['edit_expenses'] ?? false);
      isManageExpenses =
          isAdmin ? true : (permission['manage_expenses'] ?? false);
      iscreateExpenses =
          isAdmin ? true : (permission['create_expenses'] ?? false);
      isdeleteExpenses =
          isAdmin ? true : (permission['delete_expenses'] ?? false);

      iscreateContract =
          isAdmin ? true : (permission['create_contracts'] ?? false);
      isManageContract =
          isAdmin ? true : (permission['manage_contracts'] ?? false);
      iseditContract = isAdmin ? true : (permission['edit_contracts'] ?? false);
      isdeleteContract =
          isAdmin ? true : (permission['delete_contracts'] ?? false);

      iscreateContractType =
          isAdmin ? true : (permission['create_contract_types'] ?? false);
      isManageContractType =
          isAdmin ? true : (permission['manage_contract_types'] ?? false);
      iseditContractType =
          isAdmin ? true : (permission['edit_contract_types'] ?? false);
      isdeleteContractType =
          isAdmin ? true : (permission['delete_contract_types'] ?? false);

      iscreateTimesheet =
          isAdmin ? true : (permission['create_timesheet'] ?? false);
      isManageTimesheet =
          isAdmin ? true : (permission['manage_timesheet'] ?? false);
      isdeleteTimesheet =
          isAdmin ? true : (permission['delete_timesheet'] ?? false);

      iscreateMedia = isAdmin ? true : (permission['create_media'] ?? true);
      isManageMedia = isAdmin ? true : (permission['manage_media'] ?? true);
      isdeleteMedia = isAdmin ? true : (permission['delete_media'] ?? true);

      iscreatePayslip =
          isAdmin ? true : (permission['create_payslips'] ?? false);
      isManagePayslip =
          isAdmin ? true : (permission['manage_payslips'] ?? false);
      iseditPayslip = isAdmin ? true : (permission['edit_payslips'] ?? false);
      isdeletePayslip =
          isAdmin ? true : (permission['delete_payslips'] ?? false);

      iscreateAllowance =
          isAdmin ? true : (permission['create_allowances'] ?? false);
      isManageAllowance =
          isAdmin ? true : (permission['manage_allowances'] ?? false);
      iseditAllowance =
          isAdmin ? true : (permission['edit_allowances'] ?? false);
      isdeleteAllowance =
          isAdmin ? true : (permission['delete_allowances'] ?? false);

      iscreateDeduction =
          isAdmin ? true : (permission['create_deductions'] ?? false);
      isManageDeduction =
          isAdmin ? true : (permission['manage_deductions'] ?? false);
      iseditDeduction =
          isAdmin ? true : (permission['edit_deductions'] ?? false);
      isdeleteDeduction =
          isAdmin ? true : (permission['delete_deductions'] ?? false);

      iscreatePaymentMethod =
          isAdmin ? true : (permission['create_payment_methods'] ?? false);
      isManagePaymentMethod =
          isAdmin ? true : (permission['manage_payment_methods'] ?? false);
      iseditPaymentMethod =
          isAdmin ? true : (permission['edit_payment_methods'] ?? false);
      isdeletePaymentMethod =
          isAdmin ? true : (permission['delete_payment_methods'] ?? false);

      iscreateEstimateInvoice =
          isAdmin ? true : (permission['create_estimates_invoices'] ?? false);
      isManageEstimateInvoice =
          isAdmin ? true : (permission['manage_estimates_invoices'] ?? false);
      iseditEstimateInvoice =
          isAdmin ? true : (permission['edit_estimates_invoices'] ?? false);
      isdeleteEstimateInvoice =
          isAdmin ? true : (permission['delete_estimates_invoices'] ?? false);

      iscreatePayment =
          isAdmin ? true : (permission['create_payments'] ?? false);
      isManagePayment =
          isAdmin ? true : (permission['manage_payments'] ?? false);
      iseditPayment = isAdmin ? true : (permission['edit_payments'] ?? false);
      isdeletePayment =
          isAdmin ? true : (permission['delete_payments'] ?? false);

      iscreateTax = isAdmin ? true : (permission['create_taxes'] ?? false);
      isManageTax = isAdmin ? true : (permission['manage_taxes'] ?? false);
      iseditTax = isAdmin ? true : (permission['edit_taxes'] ?? false);
      isdeleteTax = isAdmin ? true : (permission['delete_taxes'] ?? false);

      iscreateUnit = isAdmin ? true : (permission['create_units'] ?? false);
      isManageUnit = isAdmin ? true : (permission['manage_units'] ?? false);
      iseditUnit = isAdmin ? true : (permission['edit_units'] ?? false);
      isdeleteUnit = isAdmin ? true : (permission['delete_units'] ?? false);

      iscreateItem = isAdmin ? true : (permission['create_items'] ?? false);
      isManageItem = isAdmin ? true : (permission['manage_items'] ?? false);
      iseditItem = isAdmin ? true : (permission['edit_items'] ?? false);
      isdeleteItem = isAdmin ? true : (permission['delete_items'] ?? false);

      iscreateExpenseType =
          isAdmin ? true : (permission['create_expense_types'] ?? false);
      isManageExpenseType =
          isAdmin ? true : (permission['manage_expense_types'] ?? false);
      iseditExpenseType =
          isAdmin ? true : (permission['edit_expense_types'] ?? false);
      isdeleteExpenseType =
          isAdmin ? true : (permission['delete_expense_types'] ?? false);

      iscreateMilestone =
          isAdmin ? true : (permission['create_milestones'] ?? false);
      isManageMilestone =
          isAdmin ? true : (permission['manage_milestones'] ?? false);
      iseditMilestone =
          isAdmin ? true : (permission['edit_milestones'] ?? false);
      isdeleteMilestone =
          isAdmin ? true : (permission['delete_milestones'] ?? false);

      iscreatePart = isAdmin ? true : (permission['create_parts'] ?? true);
      isManagePart = isAdmin ? true : (permission['manage_parts'] ?? true);
      iseditPart = isAdmin ? true : (permission['edit_parts'] ?? true);
      isdeletePart = isAdmin ? true : (permission['delete_parts'] ?? true);

      iscreateTrade = isAdmin ? true : (permission['create_trades'] ?? true);
      isManageTrade = isAdmin ? true : (permission['manage_trades'] ?? true);
      iseditTrade = isAdmin ? true : (permission['edit_trades'] ?? true);
      isdeleteTrade = isAdmin ? true : (permission['delete_trades'] ?? true);

      isCreateLeads = isAdmin ? true : (permission['create_leads'] ?? false);
      isManageLeads = isAdmin ? true : (permission['manage_leads'] ?? false);
      isEditLeads = isAdmin ? true : (permission['edit_leads'] ?? false);
      isDeleteLeads = isAdmin ? true : (permission['delete_leads'] ?? false);

      isSendEmail = isAdmin ? true : (permission['send_email'] ?? false);

      isCreateEmailTemplate =
          isAdmin ? true : (permission['create_email_template'] ?? false);
      isManageEmailTemplate =
          isAdmin ? true : (permission['manage_email_template'] ?? false);
      isDeleteEmailTemplate =
          isAdmin ? true : (permission['delete_email_template'] ?? false);

      isCreateCandidate =
          isAdmin ? true : (permission['create_candidate'] ?? false);
      isManageCandidate =
          isAdmin ? true : (permission['manage_candidate'] ?? false);
      isEditCandidate =
          isAdmin ? true : (permission['edit_candidate'] ?? false);
      isDeleteCandidate =
          isAdmin ? true : (permission['delete_candidate'] ?? false);

      isCreateCandidateStatus =
          isAdmin ? true : (permission['create_candidate_status'] ?? false);
      isManageCandidateStatus =
          isAdmin ? true : (permission['manage_candidate_status'] ?? false);
      isEditCandidateStatus =
          isAdmin ? true : (permission['edit_candidate_status'] ?? false);
      isDeleteCandidateStatus =
          isAdmin ? true : (permission['delete_candidate_status'] ?? false);

      isCreateInterview =
          isAdmin ? true : (permission['create_interview'] ?? false);
      isManageInterview =
          isAdmin ? true : (permission['manage_interview'] ?? false);
      isEditInterview =
          isAdmin ? true : (permission['edit_interview'] ?? false);
      isDeleteInterview =
          isAdmin ? true : (permission['delete_interview'] ?? false);

      isManageSystemNotifications =
          isAdmin ? true : (permission['manage_system_notifications'] ?? false);
      isDeleteSystemNotifications =
          isAdmin ? true : (permission['delete_system_notifications'] ?? false);
      if (kDebugMode) {
        logger.d("tyghnj $isCreateLeads");
      }

      emit(PermissionsSuccess());
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((PermissionsError("Error: ${e.errorMessage}")));
    }
  }
}
