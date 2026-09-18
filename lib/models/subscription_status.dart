enum SubscriptionStatus {
  pending,
  approved,
  rejected,
  expired,
  cancelled,
}

extension SubscriptionStatusExtension
on SubscriptionStatus {
  String get value {
    switch (this) {
      case SubscriptionStatus.pending:
        return 'pending';

      case SubscriptionStatus.approved:
        return 'approved';

      case SubscriptionStatus.rejected:
        return 'rejected';

      case SubscriptionStatus.expired:
        return 'expired';

      case SubscriptionStatus.cancelled:
        return 'cancelled';
    }
  }
}