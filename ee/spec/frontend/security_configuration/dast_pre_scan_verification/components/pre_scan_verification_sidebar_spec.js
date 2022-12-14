import { GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationSidebar from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_sidebar.vue';
import PreScanVerificationSummary from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_summary.vue';
import { PRE_SCAN_VERIFICATION_STATUS } from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationSidebar', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(PreScanVerificationSidebar, {
      propsData: {
        ...propsData,
      },
      stubs: {
        GlDrawer: true,
      },
    });
  };

  const findPreScanVerificationSummary = () => wrapper.findComponent(PreScanVerificationSummary);
  const findDrawer = () => wrapper.findComponent(GlDrawer);

  beforeEach(() => {
    createComponent();
  });

  it('should render drawer', () => {
    expect(findDrawer().exists()).toBe(true);
  });

  it('should render drawer with proper z index', () => {
    expect(findDrawer().props('zIndex')).toBe(DRAWER_Z_INDEX);
  });

  it('should close drawer', async () => {
    expect(wrapper.emitted('close')).toBeUndefined();

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  describe('Verification summary', () => {
    it.each`
      status                                               | expectedResult
      ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${false}
      ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${true}
      ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${true}
      ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${true}
      ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${true}
      ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${true}
    `(
      'should render pre scan verification summary for certain statuses',
      ({ status, expectedResult }) => {
        createComponent({ status });

        expect(findPreScanVerificationSummary().exists()).toEqual(expectedResult);
      },
    );
  });
});
