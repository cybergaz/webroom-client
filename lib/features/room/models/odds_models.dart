class Competition {
  final String id;
  final String name;

  const Competition({required this.id, required this.name});

  factory Competition.fromJson(Map<String, dynamic> json) {
    final comp = json['competition'] as Map<String, dynamic>;
    return Competition(
      id: comp['id'] as String,
      name: comp['name'] as String,
    );
  }
}

class SportEvent {
  final String id;
  final String name;
  final DateTime openDate;

  const SportEvent({required this.id, required this.name, required this.openDate});

  factory SportEvent.fromJson(Map<String, dynamic> json) {
    return SportEvent(
      id: json['id'] as String,
      name: (json['name'] as String).trim(),
      openDate: DateTime.parse(json['openDate'] as String),
    );
  }

  bool get isExpired => openDate.isBefore(DateTime.now());
}

class RunnerInfo {
  final int selectionId;
  final String name;

  const RunnerInfo({required this.selectionId, required this.name});
}

class PriceSize {
  final double price;
  final double size;

  const PriceSize({required this.price, required this.size});

  factory PriceSize.fromJson(Map<String, dynamic> json) {
    return PriceSize(
      price: (json['price'] as num).toDouble(),
      size: (json['size'] as num).toDouble(),
    );
  }
}

class RunnerOdds {
  final int selectionId;
  final String status;
  final List<PriceSize> back;
  final List<PriceSize> lay;

  const RunnerOdds({
    required this.selectionId,
    required this.status,
    required this.back,
    required this.lay,
  });

  factory RunnerOdds.fromJson(Map<String, dynamic> json) {
    return RunnerOdds(
      selectionId: json['selectionId'] as int,
      status: json['status'] as String? ?? 'ACTIVE',
      back: (json['back'] as List<dynamic>?)
              ?.map((e) => PriceSize.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lay: (json['lay'] as List<dynamic>?)
              ?.map((e) => PriceSize.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MarketOdds {
  final String marketId;
  final String status;
  final bool inPlay;
  final List<RunnerOdds> runners;

  const MarketOdds({
    required this.marketId,
    required this.status,
    required this.inPlay,
    required this.runners,
  });

  factory MarketOdds.fromJson(String marketId, Map<String, dynamic> json) {
    return MarketOdds(
      marketId: json['marketId'] as String? ?? marketId,
      status: json['status'] as String? ?? 'UNKNOWN',
      inPlay: json['inPlay'] as bool? ?? false,
      runners: (json['runners'] as List<dynamic>?)
              ?.map((e) => RunnerOdds.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
