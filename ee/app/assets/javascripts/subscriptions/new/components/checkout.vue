<script>
import Tracking from '~/tracking';
import BillingAddress from 'jh_else_ee/subscriptions/new/components/checkout/billing_address.vue';
import ConfirmOrder from './checkout/confirm_order.vue';
import PaymentMethod from './checkout/payment_method.vue';
import SubscriptionDetails from './checkout/subscription_details.vue';

export default {
  components: { SubscriptionDetails, BillingAddress, PaymentMethod, ConfirmOrder },
  mixins: [Tracking.mixin()],
  mounted() {
    this.track('render', { label: 'saas_checkout' });
  },
};
</script>
<template>
  <div>
    <div class="flash-container"></div>
    <subscription-details />
    <billing-address />
    <payment-method />
    <confirm-order />
  </div>
</template>
