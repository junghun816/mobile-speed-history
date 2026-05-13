enum SpeedMode {
  normal,
  lowSpeed;

  String get label {
    switch (this) {
      case SpeedMode.normal:
        return '자전거';
      case SpeedMode.lowSpeed:
        return '런닝';
    }
  }

  String get description {
    switch (this) {
      case SpeedMode.normal:
        return '자전거·킥보드 등 일반 주행';
      case SpeedMode.lowSpeed:
        return '런닝·워킹 등 느린 이동';
    }
  }

  static SpeedMode fromString(String value) {
    return SpeedMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SpeedMode.normal,
    );
  }
}
