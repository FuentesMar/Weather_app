import 'package:flutter/foundation.dart';

class CityNotifier extends ChangeNotifier {
  /// Llamar cuando la lista de ciudades cambie (por ejemplo, se agregó/eliminó una ciudad).
  void notifyCitiesChanged() {
    notifyListeners();
  }
}
