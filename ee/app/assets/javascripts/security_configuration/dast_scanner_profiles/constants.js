import { s__ } from '~/locale';

export const SCAN_TYPE = {
  ACTIVE: 'ACTIVE',
  PASSIVE: 'PASSIVE',
};

export const SCAN_TYPE_LABEL = {
  [SCAN_TYPE.ACTIVE]: s__('DastProfiles|Active'),
  [SCAN_TYPE.PASSIVE]: s__('DastProfiles|Passive'),
};

export const SCAN_TYPE_OPTIONS = [
  {
    value: SCAN_TYPE.ACTIVE,
    text: SCAN_TYPE_LABEL[SCAN_TYPE.ACTIVE],
  },
  {
    value: SCAN_TYPE.PASSIVE,
    text: SCAN_TYPE_LABEL[SCAN_TYPE.PASSIVE],
  },
];
