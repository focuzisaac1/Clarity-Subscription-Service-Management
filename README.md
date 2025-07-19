# Clarity Subscription Service Management

A comprehensive subscription service management system built with Clarity smart contracts on the Stacks blockchain.

## Overview

This system provides a complete subscription management solution with five core contracts that handle different aspects of subscription lifecycle management.

## Architecture

### Core Contracts

1. **service-activation.clar** - Enables access to subscription features
2. **billing-cycle.clar** - Manages recurring payment processing
3. **usage-tracking.clar** - Monitors service consumption and limits
4. **cancellation-processing.clar** - Handles subscription terminations
5. **upgrade-management.clar** - Processes plan changes and adjustments

### Key Features

- **Service Activation**: Secure subscription activation with plan validation
- **Billing Management**: Automated recurring payment processing
- **Usage Monitoring**: Real-time tracking of service consumption
- **Cancellation Handling**: Graceful subscription termination process
- **Plan Upgrades**: Seamless plan changes and adjustments

## Data Structures

### Subscription Plans
- Basic Plan: 100 units/month, 10 STX
- Premium Plan: 500 units/month, 25 STX
- Enterprise Plan: 2000 units/month, 75 STX

### Subscription Status
- active: Currently active subscription
- suspended: Temporarily suspended
- cancelled: Permanently cancelled
- expired: Billing period expired

## Contract Functions

### Service Activation
- \`activate-subscription\`: Activate new subscription
- \`get-subscription-status\`: Check activation status
- \`validate-access\`: Verify service access rights

### Billing Cycle
- \`process-payment\`: Handle recurring payments
- \`update-billing-cycle\`: Modify billing periods
- \`get-next-billing-date\`: Retrieve next payment date

### Usage Tracking
- \`record-usage\`: Log service consumption
- \`check-usage-limits\`: Verify usage against limits
- \`get-usage-stats\`: Retrieve consumption statistics

### Cancellation Processing
- \`cancel-subscription\`: Terminate subscription
- \`process-refund\`: Handle refund calculations
- \`cleanup-subscription\`: Remove subscription data

### Upgrade Management
- \`upgrade-plan\`: Change to higher tier plan
- \`downgrade-plan\`: Change to lower tier plan
- \`calculate-prorated-amount\`: Compute prorated charges

## Error Codes

- ERR-NOT-AUTHORIZED (u100): Unauthorized access
- ERR-INVALID-PLAN (u101): Invalid subscription plan
- ERR-INSUFFICIENT-FUNDS (u102): Insufficient payment
- ERR-SUBSCRIPTION-NOT-FOUND (u103): Subscription does not exist
- ERR-USAGE-LIMIT-EXCEEDED (u104): Usage limits exceeded
- ERR-INVALID-STATUS (u105): Invalid subscription status
- ERR-PAYMENT-FAILED (u106): Payment processing failed

## Testing

Run the test suite with:

\`\`\`bash
npm test
\`\`\`

Tests cover all contract functions and edge cases using Vitest framework.

## Deployment

1. Configure Clarinet.toml with contract settings
2. Deploy contracts in dependency order
3. Initialize contract parameters
4. Verify deployment on testnet

## Security Considerations

- All functions include proper authorization checks
- Input validation on all parameters
- Safe arithmetic operations to prevent overflow
- Secure payment processing with escrow mechanisms
