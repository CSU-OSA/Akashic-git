import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AddEscalationPolicyForm, {
  i18n,
} from 'ee/escalation_policies/components/add_edit_escalation_policy_form.vue';
import EscalationRule from 'ee/escalation_policies/components/escalation_rule.vue';
import { defaultEscalationRule } from 'ee/escalation_policies/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import mockPolicy from './mocks/mockPolicy.json';

describe('AddEscalationPolicyForm', () => {
  let wrapper;
  const projectPath = 'group/project';

  const createComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(AddEscalationPolicyForm, {
        propsData: {
          form: {
            name: mockPolicy.name,
            description: mockPolicy.description,
          },
          validationState: {
            name: true,
            rules: [],
          },
          ...props,
        },
        provide: {
          projectPath,
        },
        mocks: {
          $apollo: {
            queries: { schedules: { loading: false } },
          },
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findRules = () => wrapper.findAllComponents(EscalationRule);
  const findAddRuleLink = () => wrapper.findComponent(GlLink);

  describe('Escalation rules', () => {
    it('should render one default rule', () => {
      expect(findRules().length).toBe(1);
    });

    it('should contain a link to add escalation rules', () => {
      const link = findAddRuleLink();
      expect(link.exists()).toBe(true);
      expect(link.text()).toMatchInterpolatedText(i18n.addRule);
    });

    it('should add an empty rule to the rules list on click', async () => {
      findAddRuleLink().vm.$emit('click');
      await wrapper.vm.$nextTick();
      const rules = findRules();
      expect(rules.length).toBe(2);
      expect(rules.at(1).props('rule')).toMatchObject(defaultEscalationRule);
    });

    it('should NOT emit updates when rule is added', async () => {
      findAddRuleLink().vm.$emit('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('update-escalation-policy-form')).toBeUndefined();
    });

    it('on rule update emitted should update rules array and emit updates up', () => {
      const updatedRule = {
        status: 'TRIGGERED',
        elapsedTimeSeconds: 30,
        oncallScheduleIid: 2,
      };
      findRules().at(0).vm.$emit('update-escalation-rule', 0, updatedRule);
      expect(wrapper.emitted('update-escalation-policy-form')[0]).toEqual([
        { field: 'rules', value: [expect.objectContaining(updatedRule)] },
      ]);
    });

    it('on rule removal emitted should update rules array and emit updates up', () => {
      findRules().at(0).vm.$emit('remove-escalation-rule', 0);
      expect(wrapper.emitted('update-escalation-policy-form')[0]).toEqual([
        { field: 'rules', value: [] },
      ]);
    });
  });
});
