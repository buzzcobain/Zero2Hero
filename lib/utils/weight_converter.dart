class WeightConverter {
  static const double _kgToLbs = 2.20462;

  static String format(double weightKg, bool useMetric) {
    double val = useMetric ? weightKg : weightKg * _kgToLbs;
    String str = val.toStringAsFixed(1);
    if (str.endsWith('.0')) {
      str = str.substring(0, str.length - 2);
    }
    return useMetric ? '$str kg' : '$str lbs';
  }

  static double displayToKg(double inputWeight, bool isMetric) {
    if (isMetric) {
      return inputWeight;
    } else {
      return inputWeight / _kgToLbs;
    }
  }
}
