const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Short day-month label used across Frigo, e.g. `20 Nov`.
String formatShortDate(DateTime date) => '${date.day} ${_months[date.month - 1]}';
