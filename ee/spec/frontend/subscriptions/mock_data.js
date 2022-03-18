import { STEPS } from 'ee/subscriptions/constants';
import {
  CUSTOMER_TYPE,
  NAMESPACE_TYPE,
  PAYMENT_METHOD_TYPE,
  PLAN_TYPE,
  SUBSCRIPTION_TYPE,
  ORDER_PREVIEW_TYPE,
} from 'ee/subscriptions/buy_addons_shared/constants';

export const accountId = '111111111111';
export const subscriptionName = 'A-000000000';

export const mockCiMinutesPlans = [
  {
    id: 'ciMinutesPackPlanId',
    code: 'ci_minutes',
    isAddon: true,
    pricePerYear: 10,
    name: 'CI minutes pack',
    __typename: PLAN_TYPE,
  },
];

export const mockStoragePlans = [
  {
    id: 'storagePackPlanId',
    code: 'storage',
    pricePerYear: 60,
    name: 'Storage pack',
    __typename: PLAN_TYPE,
  },
];

export const mockNamespaces = `
  [{"id":132,"accountId":"${accountId}","name":"Gitlab Org"},
  {"id":483,"accountId":null,"name":"Gnuwget"}]
`;

export const mockParsedNamespaces = JSON.parse(mockNamespaces).map((namespace) => ({
  ...namespace,
  __typename: NAMESPACE_TYPE,
}));

export const mockNewUser = 'false';
export const mockSetupForCompany = 'true';

export const mockDefaultCache = {
  groupData: mockNamespaces,
  namespaceId: 132,
  redirectAfterSuccess: '/',
};

export const mockOrderPreview = {
  targetDate: '2022-12-15',
  amount: 59.67,
  amountWithoutTax: 60.0,
  prorationCredit: 0.33,
  priceBeforeProration: 60.0,
  __typename: ORDER_PREVIEW_TYPE,
};

export const stateData = {
  eligibleNamespaces: [],
  subscription: {
    quantity: 1,
    __typename: SUBSCRIPTION_TYPE,
  },
  activeSubscription: {
    name: subscriptionName,
    __typename: SUBSCRIPTION_TYPE,
  },
  redirectAfterSuccess: '/path/to/redirect/',
  selectedNamespaceId: '30',
  selectedPlan: {
    id: null,
    isAddon: true,
  },
  paymentMethod: {
    id: null,
    creditCardExpirationMonth: null,
    creditCardExpirationYear: null,
    creditCardType: null,
    creditCardMaskNumber: null,
    __typename: PAYMENT_METHOD_TYPE,
  },
  customer: {
    country: null,
    address1: null,
    address2: null,
    city: null,
    state: null,
    zipCode: null,
    company: null,
    __typename: CUSTOMER_TYPE,
  },
  fullName: 'Full Name',
  isNewUser: false,
  isSetupForCompany: true,
  stepList: STEPS,
  activeStep: STEPS[0],
};
