<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import {
  GlAlert,
  GlAvatarLabeled,
  GlAvatarLink,
  GlBadge,
  GlButton,
  GlPagination,
  GlModal,
  GlModalDirective,
  GlLoadingIcon,
} from '@gitlab/ui';
import { sprintf } from '~/locale';
import { AVATAR_SIZE } from 'ee/usage_quotas/seats/constants';
import {
  AWAITING_MEMBER_SIGNUP_TEXT,
  LABEL_APPROVE,
  LABEL_CONFIRM,
  LABEL_CONFIRM_APPROVE,
} from 'ee/pending_members/constants';

export default {
  name: 'PendingMembersApp',
  components: {
    GlAlert,
    GlAvatarLabeled,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlPagination,
    GlModal,
    GlLoadingIcon,
  },
  directives: {
    GlModalDirective,
  },
  computed: {
    ...mapState([
      'isLoading',
      'alertMessage',
      'alertVariant',
      'page',
      'perPage',
      'total',
      'namespaceName',
      'namespaceId',
      'seatUsageExportPath',
      'pendingMembersPagePath',
      'pendingMembersCount',
      'search',
    ]),
    ...mapGetters(['tableItems']),
    currentPage: {
      get() {
        return this.page;
      },
      set(val) {
        this.setCurrentPage(val);
      },
    },
  },
  created() {
    this.fetchPendingMembersList();
  },
  methods: {
    ...mapActions(['fetchPendingMembersList', 'setCurrentPage', 'approveMember', 'dismissAlert']),
    avatarLabel(member) {
      if (member.invited) {
        return member.email;
      }
      return member.name ?? '';
    },
    approveUserQuestion(member) {
      return sprintf(LABEL_CONFIRM_APPROVE, {
        user: member.name || member.email,
      });
    },
  },
  avatarSize: AVATAR_SIZE,
  AWAITING_MEMBER_SIGNUP_TEXT,
  LABEL_APPROVE,
  LABEL_CONFIRM,
};
</script>
<template>
  <div>
    <div v-if="isLoading" class="gl-text-center loading">
      <gl-loading-icon class="mt-5" size="lg" />
    </div>
    <template v-else>
      <div>
        <gl-alert v-if="alertMessage" :variant="alertVariant" @dismiss="dismissAlert">
          {{ alertMessage }}
        </gl-alert>
        <div
          v-for="item in tableItems"
          :key="item.id"
          class="gl-p-5 gl-border-0 gl-border-b-1! gl-border-gray-100 gl-border-solid gl-display-flex gl-justify-content-space-between"
          data-testid="pending-members-row"
        >
          <gl-avatar-link target="blank" :href="item.web_url" :alt="item.name">
            <gl-avatar-labeled
              :src="item.avatar_url"
              :size="$options.avatarSize"
              :label="avatarLabel(item)"
            >
              <template #meta>
                <gl-badge v-if="item.invited && item.approved" size="sm" variant="muted">
                  {{ $options.AWAITING_MEMBER_SIGNUP_TEXT }}
                </gl-badge>
              </template>
            </gl-avatar-labeled>
          </gl-avatar-link>
          <gl-button
            v-gl-modal-directive="`approve-confirmation-modal-${item.id}`"
            :loading="item.loading"
            :disabled="item.approved"
          >
            {{ $options.LABEL_APPROVE }}
          </gl-button>
          <gl-modal
            :modal-id="`approve-confirmation-modal-${item.id}`"
            :title="$options.LABEL_CONFIRM"
            no-fade
            @primary="approveMember(item.id)"
          >
            <p>{{ approveUserQuestion(item) }}</p>
          </gl-modal>
        </div>
      </div>
    </template>

    <gl-pagination
      v-if="currentPage"
      v-model="currentPage"
      :per-page="perPage"
      :total-items="total"
      align="center"
      class="gl-mt-5"
    />
  </div>
</template>
