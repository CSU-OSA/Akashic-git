import { shallowMount } from '@vue/test-utils';
import { componentNames } from '~/reports/components/issue_body';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import ReportItem from '~/reports/components/report_item.vue';
import { STATUS_SUCCESS } from '~/reports/constants';

describe('ReportItem', () => {
  describe('showReportSectionStatusIcon', () => {
    it('does not render CI Status Icon when showReportSectionStatusIcon is false', () => {
      const wrapper = shallowMount(ReportItem, {
        propsData: {
          issue: { foo: 'bar' },
          component: componentNames.TestIssueBody,
          status: STATUS_SUCCESS,
          showReportSectionStatusIcon: false,
        },
      });

      expect(wrapper.findComponent(IssueStatusIcon).exists()).toBe(false);
    });

    it('shows status icon when unspecified', () => {
      const wrapper = shallowMount(ReportItem, {
        propsData: {
          issue: { foo: 'bar' },
          component: componentNames.TestIssueBody,
          status: STATUS_SUCCESS,
        },
      });

      expect(wrapper.findComponent(IssueStatusIcon).exists()).toBe(true);
    });
  });
});
