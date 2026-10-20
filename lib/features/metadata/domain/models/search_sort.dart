/// Sort options for anime search corresponding to the UI filter chips.
enum SearchSort {
  match('match'),
  heat('heat'),
  score('score');

  final String apiValue;
  const SearchSort(this.apiValue);
}
