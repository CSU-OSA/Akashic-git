export const testProjectPath = 'foo/bar';

export const testProviderIds = [101, 102, 103];

const createSecurityTrainingProviders = ({ providerOverrides = {} }) => [
  {
    id: testProviderIds[0],
    name: 'Vendor Name 1',
    description: 'Interactive developer security education',
    url: 'https://www.example.org/security/training',
    isEnabled: false,
    isPrimary: false,
    ...providerOverrides.first,
  },
  {
    id: testProviderIds[1],
    name: 'Vendor Name 2',
    description: 'Security training with guide and learning pathways.',
    url: 'https://www.vendornametwo.com/',
    isEnabled: false,
    isPrimary: false,
    ...providerOverrides.second,
  },
  {
    id: testProviderIds[2],
    name: 'Vendor Name 3',
    description: 'Security training for the everyday developer.',
    url: 'https://www.vendornamethree.com/',
    isEnabled: false,
    isPrimary: false,
    ...providerOverrides.third,
  },
];

export const getSecurityTrainingProvidersData = (providerOverrides = {}) => {
  const securityTrainingProviders = createSecurityTrainingProviders(providerOverrides);
  const response = {
    data: {
      project: {
        id: 1,
        securityTrainingProviders,
      },
    },
  };

  return {
    response,
    data: securityTrainingProviders,
  };
};

export const dismissUserCalloutResponse = {
  data: {
    userCalloutCreate: {
      errors: [],
      userCallout: {
        dismissedAt: '2022-02-02T04:36:57Z',
        featureName: 'SECURITY_TRAINING_FEATURE_PROMOTION',
      },
    },
  },
};

export const dismissUserCalloutErrorResponse = {
  data: {
    userCalloutCreate: {
      errors: ['Something went wrong'],
      userCallout: {
        dismissedAt: '',
        featureName: 'SECURITY_TRAINING_FEATURE_PROMOTION',
      },
    },
  },
};

export const updateSecurityTrainingProvidersResponse = {
  data: {
    securityTrainingUpdate: {
      errors: [],
      training: {
        id: 101,
        name: 'Acme',
        isEnabled: true,
        isPrimary: false,
      },
    },
  },
};

export const updateSecurityTrainingProvidersErrorResponse = {
  data: {
    securityTrainingUpdate: {
      errors: ['something went wrong!'],
      training: null,
    },
  },
};
