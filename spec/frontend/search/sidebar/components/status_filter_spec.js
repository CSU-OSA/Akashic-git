import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import RadioFilter from '~/search/sidebar/components/radio_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter.vue';

Vue.use(Vuex);

describe('StatusFilter', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(StatusFilter, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findRadioFilter = () => wrapper.findComponent(RadioFilter);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      scope               | showFilter
      ${'issues'}         | ${true}
      ${'merge_requests'} | ${true}
      ${'projects'}       | ${false}
      ${'milestones'}     | ${false}
      ${'users'}          | ${false}
      ${'notes'}          | ${false}
      ${'wiki_blobs'}     | ${false}
      ${'blobs'}          | ${false}
    `(`dropdown`, ({ scope, showFilter }) => {
      beforeEach(() => {
        createComponent({ query: { scope } });
      });

      it(`does${showFilter ? '' : ' not'} render when scope is ${scope}`, () => {
        expect(findRadioFilter().exists()).toBe(showFilter);
      });
    });
  });
});
