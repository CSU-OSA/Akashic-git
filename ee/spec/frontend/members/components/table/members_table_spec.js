import { within } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import {
  member as memberMock,
  directMember,
  members,
  bannedMember,
} from 'ee_else_ce_jest/members/mock_data';
import MembersTable from '~/members/components/table/members_table.vue';
import { MEMBER_TYPES } from '~/members/constants';

Vue.use(Vuex);

describe('MemberList', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            members: [],
            tableFields: [],
            tableAttrs: {
              table: { 'data-qa-selector': 'members_list' },
              tr: { 'data-qa-selector': 'member_row' },
            },
            pagination: {},
            ...state,
          },
        },
      },
    });
  };

  const createComponent = (state) => {
    wrapper = mount(MembersTable, {
      store: createStore(state),
      provide: {
        sourceId: 1,
        currentUserId: 1,
        namespace: MEMBER_TYPES.user,
      },
      stubs: [
        'member-avatar',
        'member-source',
        'expires-at',
        'created-at',
        'member-action-buttons',
        'role-dropdown',
        'remove-group-link-modal',
        'remove-member-modal',
        'expiration-datepicker',
      ],
    });
  };

  const getByTestId = (id, options) =>
    createWrapper(within(wrapper.element).getByTestId(id, options));
  const findTableCellByMemberId = (tableCellLabel, memberId) =>
    getByTestId(`members-table-row-${memberId}`).find(
      `[data-label="${tableCellLabel}"][role="cell"]`,
    );

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('fields', () => {
    describe('"Actions" field', () => {
      const memberCanOverride = {
        ...directMember,
        canOverride: true,
      };

      const memberCanUnban = {
        ...bannedMember,
        canUnban: true,
      };

      const memberNoPermissions = {
        ...memberMock,
        id: 2,
      };

      describe.each([
        ['canOverride', memberCanOverride],
        ['canUnban', memberCanUnban],
      ])('when one of the members has `%s` permissions', (_, memberWithPermission) => {
        it('renders the "Actions" field', () => {
          createComponent({
            members: [memberNoPermissions, memberWithPermission],
            tableFields: ['actions'],
          });

          expect(within(wrapper.element).queryByTestId('col-actions')).not.toBe(null);

          expect(
            findTableCellByMemberId('Actions', memberNoPermissions.id).classes(),
          ).toStrictEqual(['col-actions', 'gl-display-none!', 'gl-lg-display-table-cell!']);
          expect(
            findTableCellByMemberId('Actions', memberWithPermission.id).classes(),
          ).toStrictEqual(['col-actions']);
        });
      });

      describe.each([['canOverride'], ['canUnban']])(
        'when none of the members has `%s` permissions',
        () => {
          it('does not render the "Actions" field', () => {
            createComponent({ members, tableFields: ['actions'] });

            expect(within(wrapper.element).queryByTestId('col-actions')).toBe(null);
          });
        },
      );
    });
  });
});
