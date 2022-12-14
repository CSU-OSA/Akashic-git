<script>
import { uniqueId, orderBy } from 'lodash';
import ApprovalCheckRulePopover from 'ee/approvals/components/approval_check_rule_popover.vue';
import EmptyRuleName from 'ee/approvals/components/empty_rule_name.vue';
import { RULE_TYPE_CODE_OWNER, RULE_TYPE_ANY_APPROVER } from 'ee/approvals/constants';
import { sprintf, __, s__ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ApprovedIcon from './approved_icon.vue';
import NumberOfApprovals from './number_of_approvals.vue';

const INCLUDE_APPROVERS = 1;
const DO_NOT_INCLUDE_APPROVERS = 2;

export default {
  components: {
    UserAvatarList,
    ApprovedIcon,
    ApprovalCheckRulePopover,
    EmptyRuleName,
    NumberOfApprovals,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    approvalRules: {
      type: Array,
      required: true,
    },
    invalidApproversRules: {
      type: Array,
      required: true,
    },
    securityApprovalsHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    sections() {
      return [
        {
          id: uniqueId(),
          title: '',
          rules: this.approvalRules.filter((rule) => rule.rule_type !== RULE_TYPE_CODE_OWNER),
        },
        {
          id: uniqueId(),
          title: __('Code Owners'),
          rules: orderBy(
            this.approvalRules
              .filter((rule) => rule.rule_type === RULE_TYPE_CODE_OWNER)
              .map((rule) => ({ ...rule, nameClass: 'gl-font-monospace gl-word-break-all' })),
            [(o) => o.section === 'codeowners', 'name', 'section'],
            ['desc', 'asc', 'asc'],
          ),
        },
      ].filter((x) => x.rules.length);
    },
  },
  methods: {
    summaryText(rule) {
      return rule.approvals_required === 0
        ? this.summaryOptionalText(rule)
        : this.summaryRequiredText(rule);
    },
    summaryRequiredText(rule) {
      return sprintf(__('%{count} of %{required} approvals from %{name}'), {
        count: rule.approved_by.length,
        required: rule.approvals_required,
        name: rule.name,
      });
    },
    summaryOptionalText(rule) {
      return sprintf(__('%{count} approvals from %{name}'), {
        count: rule.approved_by.length,
        name: rule.name,
      });
    },
    sectionNameLabel(rule) {
      return sprintf(s__('Approvals|Section: %section'), { section: rule.section });
    },
    numberOfColumns(rule) {
      return rule.rule_type === this.$options.ruleTypeAnyApprover
        ? DO_NOT_INCLUDE_APPROVERS
        : INCLUDE_APPROVERS;
    },
  },
  ruleTypeAnyApprover: RULE_TYPE_ANY_APPROVER,
};
</script>

<template>
  <table class="table m-0">
    <thead class="thead-white text-nowrap">
      <tr class="d-md-table-row d-none">
        <th></th>
        <th class="gl-pl-0!">{{ s__('MRApprovals|Approvers') }}</th>
        <th></th>
        <th>{{ s__('MRApprovals|Approvals') }}</th>
        <th>{{ s__('MRApprovals|Commented by') }}</th>
        <th>{{ s__('MRApprovals|Approved by') }}</th>
      </tr>
    </thead>
    <tbody v-for="{ id, title, rules } in sections" :key="id" class="border-top-0">
      <tr v-if="title" class="js-section-title">
        <td class="w-0"></td>
        <td colspan="99">
          <strong>{{ title }}</strong>
        </td>
      </tr>
      <tr v-for="rule in rules" :key="rule.id">
        <td class="w-0 gl-pr-4!"><approved-icon class="gl-pl-2" :is-approved="rule.approved" /></td>
        <td :colspan="numberOfColumns(rule)" class="gl-pl-0! gl-vertical-align-middle!">
          <div class="d-md-flex d-none js-name align-items-center">
            <empty-rule-name
              v-if="rule.rule_type === $options.ruleTypeAnyApprover"
              :eligible-approvers-docs-path="eligibleApproversDocsPath"
            />
            <span v-else class="mt-n1">
              <span
                v-if="rule.section && rule.section !== 'codeowners'"
                :aria-label="sectionNameLabel(rule)"
                class="text-muted small d-block"
                data-testid="rule-section"
              >
                {{ rule.section }}
              </span>
              <span :class="rule.nameClass" :title="rule.name">{{ rule.name }}</span>
            </span>
            <approval-check-rule-popover
              :rule="rule"
              :security-approvals-help-page-path="securityApprovalsHelpPagePath"
            />
          </div>
          <div class="d-md-none d-flex flex-column js-summary">
            <empty-rule-name
              v-if="rule.rule_type === $options.ruleTypeAnyApprover"
              :eligible-approvers-docs-path="eligibleApproversDocsPath"
            />
            <span v-else>{{ summaryText(rule) }}</span>
            <user-avatar-list
              v-if="!rule.fallback"
              class="mt-2"
              :items="rule.approvers"
              :img-size="24"
              empty-text=""
            />
            <div v-if="rule.commented_by.length > 0" class="mt-2">
              <span>{{ s__('MRApprovals|Commented by') }}</span>
              <user-avatar-list
                class="d-inline-block align-middle"
                :items="rule.commented_by"
                :img-size="24"
              />
            </div>
            <div v-if="rule.approved_by.length" class="mt-2">
              <span>{{ s__('MRApprovals|Approved by') }}</span>
              <user-avatar-list
                class="d-inline-block align-middle"
                :items="rule.approved_by"
                :img-size="24"
              />
            </div>
          </div>
        </td>
        <td
          v-if="rule.rule_type !== $options.ruleTypeAnyApprover"
          class="d-md-table-cell d-none js-approvers"
        >
          <div><user-avatar-list :items="rule.approvers" :img-size="24" empty-text="" /></div>
        </td>
        <td class="d-md-table-cell w-0 d-none text-nowrap js-pending">
          <number-of-approvals :rule="rule" :invalid-approvers-rules="invalidApproversRules" />
        </td>
        <td class="d-md-table-cell d-none js-commented-by">
          <user-avatar-list :items="rule.commented_by" :img-size="24" empty-text="" />
        </td>
        <td class="d-none d-md-table-cell js-approved-by">
          <user-avatar-list :items="rule.approved_by" :img-size="24" empty-text="" />
        </td>
      </tr>
    </tbody>
  </table>
</template>
