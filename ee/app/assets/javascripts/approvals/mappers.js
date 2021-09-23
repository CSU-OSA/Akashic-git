import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { RULE_TYPE_REGULAR, RULE_TYPE_ANY_APPROVER } from './constants';

const visibleTypes = new Set([RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR]);

function withDefaultEmptyRule(rules = []) {
  if (rules && rules.length > 0) {
    return rules;
  }

  return [
    {
      id: null,
      name: '',
      approvalsRequired: 0,
      minApprovalsRequired: 0,
      approvers: [],
      containsHiddenGroups: false,
      users: [],
      groups: [],
      ruleType: RULE_TYPE_ANY_APPROVER,
      protectedBranches: [],
      overridden: false,
    },
  ];
}

export const mapApprovalRuleRequest = (req) => ({
  name: req.name,
  approvals_required: req.approvalsRequired,
  users: req.users,
  groups: req.groups,
  remove_hidden_groups: req.removeHiddenGroups,
  protected_branch_ids: req.protectedBranchIds,
  scanners: req.scanners,
  vulnerabilities_allowed: req.vulnerabilitiesAllowed,
  severity_levels: req.severityLevels,
});

export const mapApprovalFallbackRuleRequest = (req) => ({
  fallback_approvals_required: req.approvalsRequired,
});

export const mapApprovalRuleResponse = (res) => ({
  id: res.id,
  hasSource: Boolean(res.source_rule),
  name: res.name,
  approvalsRequired: res.approvals_required,
  minApprovalsRequired: 0,
  approvers: res.approvers,
  containsHiddenGroups: res.contains_hidden_groups,
  users: res.users,
  groups: res.groups,
  ruleType: res.rule_type,
  protectedBranches: res.protected_branches,
  overridden: res.overridden,
  scanners: res.scanners,
  vulnerabilitiesAllowed: res.vulnerabilities_allowed,
  severityLevels: res.severity_levels,
});

export const mapApprovalSettingsResponse = (res) => ({
  rules: withDefaultEmptyRule(res.rules.map(mapApprovalRuleResponse)),
  fallbackApprovalsRequired: res.fallback_approvals_required,
});

/**
 * Map the sourced approval rule response for the MR view
 *
 * This rule is sourced from project settings, which implies:
 * - Not a real MR rule, so no "id".
 * - The approvals required are the minimum.
 */
export const mapMRSourceRule = ({ id, ...rule }) => ({
  ...rule,
  hasSource: true,
  sourceId: id,
  minApprovalsRequired: 0,
});

/**
 * Map the approval settings response for the MR view
 *
 * - Only show regular rules.
 * - If needed, extract the fallback approvals required
 *   from the fallback rule.
 */
export const mapMRApprovalSettingsResponse = (res) => {
  const rules = res.rules.filter(({ rule_type }) => visibleTypes.has(rule_type));

  const fallbackApprovalsRequired = res.fallback_approvals_required || 0;

  return {
    rules: withDefaultEmptyRule(
      rules
        .map(mapApprovalRuleResponse)
        .map(res.approval_rules_overwritten ? (x) => x : mapMRSourceRule),
    ),
    fallbackApprovalsRequired,
    minFallbackApprovalsRequired: 0,
  };
};

const invertApprovalSetting = ({ value, ...rest }) => ({ value: !value, ...rest });

export const mergeRequestApprovalSettingsMappers = {
  mapDataToState: (data) =>
    convertObjectPropsToCamelCase(
      {
        preventAuthorApproval: invertApprovalSetting(data.allow_author_approval),
        preventMrApprovalRuleEdit: invertApprovalSetting(
          data.allow_overrides_to_approver_list_per_merge_request,
        ),
        requireUserPassword: data.require_password_to_approve,
        removeApprovalsOnPush: invertApprovalSetting(data.retain_approvals_on_push),
        preventCommittersApproval: invertApprovalSetting(data.allow_committer_approval),
      },
      { deep: true },
    ),
  mapStateToPayload: ({ settings }) => ({
    allow_author_approval: !settings.preventAuthorApproval.value,
    allow_overrides_to_approver_list_per_merge_request: !settings.preventMrApprovalRuleEdit.value,
    require_password_to_approve: settings.requireUserPassword.value,
    retain_approvals_on_push: !settings.removeApprovalsOnPush.value,
    allow_committer_approval: !settings.preventCommittersApproval.value,
  }),
};

export const projectApprovalsMappers = {
  mapDataToState: (data) => ({
    preventAuthorApproval: { value: !data.merge_requests_author_approval },
    preventMrApprovalRuleEdit: { value: data.disable_overriding_approvers_per_merge_request },
    requireUserPassword: { value: data.require_password_to_approve },
    removeApprovalsOnPush: { value: data.reset_approvals_on_push },
    preventCommittersApproval: { value: data.merge_requests_disable_committers_approval },
  }),
  mapStateToPayload: ({ settings }) => ({
    merge_requests_author_approval: !settings.preventAuthorApproval.value,
    disable_overriding_approvers_per_merge_request: settings.preventMrApprovalRuleEdit.value,
    require_password_to_approve: settings.requireUserPassword.value,
    reset_approvals_on_push: settings.removeApprovalsOnPush.value,
    merge_requests_disable_committers_approval: settings.preventCommittersApproval.value,
  }),
};
