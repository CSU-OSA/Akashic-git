<script>
import { GlCard } from '@gitlab/ui';
import { identity } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getTimeago, timeagoLanguageCode } from '~/lib/utils/datetime_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import SubscriptionDetailsTable from 'jh_else_ee/admin/subscriptions/show/components/subscription_details_table.vue';
import { getLicenseTypeLabel } from '../utils';

const timeagoFormatter = getTimeago().format;
const formatTime = (time) => timeagoFormatter(time, timeagoLanguageCode);

const subscriptionDetailsFormatRules = {
  id: getIdFromGraphQLId,
  expiresAt: formatTime,
  lastSync: formatTime,
  type: getLicenseTypeLabel,
  plan: capitalizeFirstCharacter,
};

export default {
  name: 'SubscriptionDetailsCard',
  components: {
    GlCard,
    SubscriptionDetailsTable,
  },
  props: {
    detailsFields: {
      type: Array,
      required: true,
    },
    headerText: {
      type: String,
      required: false,
      default: '',
    },
    subscription: {
      type: Object,
      required: true,
    },
    syncDidFail: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    details() {
      return this.detailsFields.map((detail) => {
        const formatter = subscriptionDetailsFormatRules[detail] || identity;
        const valueToFormat = this.subscription[detail];
        const value = valueToFormat ? formatter(valueToFormat) : '';
        return { detail, value };
      });
    },
  },
};
</script>

<template>
  <gl-card>
    <template v-if="headerText" #header>
      <h6 class="gl-m-0">{{ headerText }}</h6>
    </template>
    <subscription-details-table :details="details" :sync-did-fail="syncDidFail" />
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-card>
</template>
