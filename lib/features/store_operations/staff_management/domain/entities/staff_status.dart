enum StaffStatus { active, pending, other }

extension StaffStatusX on StaffStatus {
  bool get isActive => this == StaffStatus.active;

  bool get isPending => this == StaffStatus.pending;
}
