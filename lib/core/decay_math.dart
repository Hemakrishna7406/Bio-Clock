import 'dart:math' as math;

class DecayEngine {
  final Map<String, double> _baseShelfLifeHours = {
    "Tomato": 168.0,      
    "Onion": 336.0,       
    "Spinach": 72.0,      
    "Snake_Gourd": 120.0, 
    "Ridge_Gourd": 120.0, 
    "Bitter_Gourd": 168.0,
    "Apple": 336.0,       
  };

  Map<String, dynamic> calculateRemainingLife({
    required String itemName,
    required double visualFreshnessProbability, 
    required double currentTempC,               
    required double currentHumidity,            
    required double ethyleneGasPPM,             
  }) {
    double baseHours = _baseShelfLifeHours[itemName] ?? 120.0;
    double aiAdjustedHours = baseHours * visualFreshnessProbability;

    double tempMultiplier = 1.0;
    if (currentTempC > 20.0) {
      double tempDelta = currentTempC - 20.0;
      tempMultiplier = _calculateQ10(tempDelta); 
    } else if (currentTempC < 15.0) {
      tempMultiplier = 0.5; 
    }

    double gasMultiplier = 1.0;
    if (ethyleneGasPPM > 50.0 && ethyleneGasPPM <= 150.0) {
      gasMultiplier = 1.5; 
    } else if (ethyleneGasPPM > 150.0) {
      gasMultiplier = 3.0; 
    }

    double humidityMultiplier = 1.0;
    if (currentHumidity > 85.0) {
      humidityMultiplier = 1.2; 
    } else if (currentHumidity < 30.0) {
      humidityMultiplier = 1.1; 
    }

    double totalStressFactor = tempMultiplier * gasMultiplier * humidityMultiplier;
    double finalRemainingHours = aiAdjustedHours / totalStressFactor;

    if (finalRemainingHours < 0) finalRemainingHours = 0;

    int days = (finalRemainingHours / 24).floor();
    int hours = (finalRemainingHours % 24).floor();

    String statusAlert = "Optimal";
    if (finalRemainingHours < 48) statusAlert = "CRITICAL: Consume Immediately";
    else if (totalStressFactor > 2.0) statusAlert = "WARNING: Hostile Storage Environment";

    return {
      "remaining_hours_raw": finalRemainingHours,
      "formatted_time": "$days Days, $hours Hours",
      "status_alert": statusAlert,
      "stress_factor": totalStressFactor,
    };
  }

  double _calculateQ10(double delta) {
    return math.pow(2.0, delta / 10.0).toDouble();
  }
}