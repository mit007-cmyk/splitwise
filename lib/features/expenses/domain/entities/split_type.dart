enum SplitType { equally, unequally, percentage, shares, adjustment }

extension SplitTypeX on SplitType {
  String get label {
    switch (this) {
      case SplitType.equally:
        return 'Equally';
      case SplitType.unequally:
        return 'Unequally';
      case SplitType.percentage:
        return 'By percentage';
      case SplitType.shares:
        return 'By shares';
      case SplitType.adjustment:
        return 'By adjustment';
    }
  }

  String get description {
    switch (this) {
      case SplitType.equally:
        return 'Select which people owe an equal share.';
      case SplitType.unequally:
        return 'Specify exactly how much each person owes.';
      case SplitType.percentage:
        return "Enter the percentage split that's fair for your situation.";
      case SplitType.shares:
        return 'Great for time-based splitting and splitting across families.';
      case SplitType.adjustment:
        return 'Enter adjustments to reflect who owes extra; the remainder is split equally.';
    }
  }
}
