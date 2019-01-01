import 'package:scoped_model/scoped_model.dart';

class AppModel extends Model {
  String _token;

  String get token => _token;

  void setToken(String t) {
    _token = t;

    notifyListeners();
  }
}
