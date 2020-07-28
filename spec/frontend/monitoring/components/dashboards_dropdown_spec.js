import { shallowMount } from '@vue/test-utils';
import { GlDeprecatedDropdownItem, GlIcon } from '@gitlab/ui';

import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';

import { dashboardGitResponse } from '../mock_data';

const defaultBranch = 'master';
const starredDashboards = dashboardGitResponse.filter(({ starred }) => starred);
const notStarredDashboards = dashboardGitResponse.filter(({ starred }) => !starred);

describe('DashboardsDropdown', () => {
  let wrapper;
  let mockDashboards;
  let mockSelectedDashboard;

  function createComponent(props, opts = {}) {
    const storeOpts = {
      computed: {
        allDashboards: () => mockDashboards,
        selectedDashboard: () => mockSelectedDashboard,
      },
    };

    return shallowMount(DashboardsDropdown, {
      propsData: {
        ...props,
        defaultBranch,
      },
      sync: false,
      ...storeOpts,
      ...opts,
    });
  }

  const findItems = () => wrapper.findAll(GlDeprecatedDropdownItem);
  const findItemAt = i => wrapper.findAll(GlDeprecatedDropdownItem).at(i);
  const findSearchInput = () => wrapper.find({ ref: 'monitorDashboardsDropdownSearch' });
  const findNoItemsMsg = () => wrapper.find({ ref: 'monitorDashboardsDropdownMsg' });
  const findStarredListDivider = () => wrapper.find({ ref: 'starredListDivider' });
  const setSearchTerm = searchTerm => wrapper.setData({ searchTerm });

  beforeEach(() => {
    mockDashboards = dashboardGitResponse;
    mockSelectedDashboard = null;
  });

  describe('when it receives dashboards data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(dashboardGitResponse.length);
    });

    it('displays items with the dashboard display name, with starred dashboards first', () => {
      expect(findItemAt(0).text()).toBe(starredDashboards[0].display_name);
      expect(findItemAt(1).text()).toBe(notStarredDashboards[0].display_name);
      expect(findItemAt(2).text()).toBe(notStarredDashboards[1].display_name);
    });

    it('displays separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(true);
    });

    it('displays a search input', () => {
      expect(findSearchInput().isVisible()).toBe(true);
    });

    it('hides no message text by default', () => {
      expect(findNoItemsMsg().isVisible()).toBe(false);
    });

    it('filters dropdown items when searched for item exists in the list', () => {
      const searchTerm = 'Default';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick().then(() => {
        expect(findItems()).toHaveLength(1);
      });
    });

    it('shows no items found message when searched for item does not exists in the list', () => {
      const searchTerm = 'does-not-exist';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick().then(() => {
        expect(findNoItemsMsg().isVisible()).toBe(true);
      });
    });
  });

  describe('when the dashboard is missing a display name', () => {
    beforeEach(() => {
      mockDashboards = dashboardGitResponse.map(d => ({ ...d, display_name: undefined }));
      wrapper = createComponent();
    });

    it('displays items with the dashboard path, with starred dashboards first', () => {
      expect(findItemAt(0).text()).toBe(starredDashboards[0].path);
      expect(findItemAt(1).text()).toBe(notStarredDashboards[0].path);
      expect(findItemAt(2).text()).toBe(notStarredDashboards[1].path);
    });
  });

  describe('when it receives starred dashboards', () => {
    beforeEach(() => {
      mockDashboards = starredDashboards;
      wrapper = createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(starredDashboards.length);
    });

    it('displays a star icon', () => {
      const star = findItemAt(0).find(GlIcon);
      expect(star.exists()).toBe(true);
      expect(star.attributes('name')).toBe('star');
    });

    it('displays no separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(false);
    });
  });

  describe('when it receives only not-starred dashboards', () => {
    beforeEach(() => {
      mockDashboards = notStarredDashboards;
      wrapper = createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(notStarredDashboards.length);
    });

    it('displays no star icon', () => {
      const star = findItemAt(0).find(GlIcon);
      expect(star.exists()).toBe(false);
    });

    it('displays no separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(false);
    });
  });

  describe('when a dashboard gets selected by the user', () => {
    beforeEach(() => {
      wrapper = createComponent();
      findItemAt(1).vm.$emit('click');
    });

    it('emits a "selectDashboard" event', () => {
      expect(wrapper.emitted().selectDashboard).toBeTruthy();
    });
    it('emits a "selectDashboard" event with dashboard information', () => {
      expect(wrapper.emitted().selectDashboard[0]).toEqual([dashboardGitResponse[0]]);
    });
  });
});
