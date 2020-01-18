import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocStateModel with ChangeNotifier {
  // Represent latest location
  Position _lastPos = Position(longitude: 0.0, latitude: 0.0);
  GeolocationStatus _geoAccessStatus;
  StreamSubscription<Position> _positionStreamSubscription;
  final Map<Position, Placemark> _pointList = Map<Position, Placemark>();

  double get latitude => _lastPos.latitude;
  double get longitude => _lastPos.longitude;
  bool get isPaused => _positionStreamSubscription.isPaused;
  List<Position> get positions => List.from(_pointList.keys);
  List<Placemark> get placemarks => List.from(_pointList.values);
  LinkedHashMap<Position, Placemark> get pointList => _pointList;

  Future<bool> available() async {
    _geoAccessStatus = await Geolocator().checkGeolocationPermissionStatus();
    if (_geoAccessStatus == GeolocationStatus.granted) {
      return true;
    }
    return false;
  }

  bool isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription.isPaused);

  void addLocation(Position pos) {
    _pointList[pos] = null;
    _lastPos = pos;
    Geolocator().placemarkFromCoordinates(pos.latitude, pos.longitude).then((pm) {
      _pointList[pos] = pm.first;
      notifyListeners();
    });
    notifyListeners();
  }

  Placemark getPlacemark(Position pos) {
    return _pointList[pos];
  }

  String getAddressString(Position pos) {
    if (pos == null) {
      return '';
    }
    final placemark = _pointList[pos];
    if (placemark == null) {
      return '';
    }
    final String name = placemark.name ?? '';
    final String street = placemark.thoroughfare ?? '';
    final String streetnumber = placemark.subThoroughfare ?? '';
    final String city = placemark.locality ?? '';
    final String state = placemark.administrativeArea ?? '';
    final String country = placemark.country ?? '';

    String address;
    if (state == city) {
      address = '$name, $streetnumber $street, $city, $country';
    } else {
      address = '$name, $streetnumber $street, $city, $state, $country';
    }
    return address;
  }

  void toggleListening() {
    if (_positionStreamSubscription == null) {
      const LocationOptions locationOptions =
          LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 10);
      final Stream<Position> positionStream =
          Geolocator().getPositionStream(locationOptions);
      _positionStreamSubscription =
          positionStream.listen((Position position) => addLocation(position));
      //_positionStreamSubscription.pause();
    }
    if (_positionStreamSubscription.isPaused) {
      _positionStreamSubscription.resume();
    } else {
      _positionStreamSubscription.pause();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription.cancel();
      _positionStreamSubscription = null;
    }
    super.dispose();
  }
}
