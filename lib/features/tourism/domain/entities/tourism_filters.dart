class TourismFilters {
  final String query;
  final String? city;
  final String? category;
  final bool popularOnly;
  final bool hiddenGemsOnly;
  final bool freeOnly;
  final bool foreignerFriendlyOnly;
  final bool openNowOnly;
  final double minimumRating;

  const TourismFilters({
    this.query = '',
    this.city,
    this.category,
    this.popularOnly = false,
    this.hiddenGemsOnly = false,
    this.freeOnly = false,
    this.foreignerFriendlyOnly = false,
    this.openNowOnly = false,
    this.minimumRating = 0,
  });

  TourismFilters copyWith({
    String? query,
    String? city,
    bool clearCity = false,
    String? category,
    bool clearCategory = false,
    bool? popularOnly,
    bool? hiddenGemsOnly,
    bool? freeOnly,
    bool? foreignerFriendlyOnly,
    bool? openNowOnly,
    double? minimumRating,
  }) {
    return TourismFilters(
      query: query ?? this.query,
      city: clearCity ? null : city ?? this.city,
      category: clearCategory ? null : category ?? this.category,
      popularOnly: popularOnly ?? this.popularOnly,
      hiddenGemsOnly: hiddenGemsOnly ?? this.hiddenGemsOnly,
      freeOnly: freeOnly ?? this.freeOnly,
      foreignerFriendlyOnly:
          foreignerFriendlyOnly ?? this.foreignerFriendlyOnly,
      openNowOnly: openNowOnly ?? this.openNowOnly,
      minimumRating: minimumRating ?? this.minimumRating,
    );
  }

  bool get hasActiveFilters =>
      city != null ||
      category != null ||
      popularOnly ||
      hiddenGemsOnly ||
      freeOnly ||
      foreignerFriendlyOnly ||
      openNowOnly ||
      minimumRating > 0;
}
