import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../../../core/config/app_config.dart';

enum LocationStatus {
  onCampus,
  offCampus,
  inPickupLoop,
  unknown,
}

class LocationService {
  StreamSubscription<Position>? _positionStream;
  late Box _locationBox;
  LocationStatus _currentStatus = LocationStatus.unknown;
  final StreamController<LocationStatus> _statusController = 
      StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get statusStream => _statusController.stream;
  LocationStatus get currentStatus => _currentStatus;

  Future<void> initialize() async {
    _locationBox = await Hive.openBox('location_data');
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  Future<void> startLocationTracking() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConfig.geofenceRadius.toInt(),
      ),
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        print('Location error: $error');
      },
    );
  }

  void _onPositionUpdate(Position position) {
    final newStatus = _determineLocationStatus(position);
    
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      _saveStatus();
    }
  }

  LocationStatus _determineLocationStatus(Position position) {
    if (_isWithinCampus(position)) {
      return LocationStatus.onCampus;
    }
    
    if (_isWithinPickupLoop(position)) {
      return LocationStatus.inPickupLoop;
    }
    
    return LocationStatus.offCampus;
  }

  bool _isWithinCampus(Position position) {
    // Placeholder - campus coordinates needed
    const campusLat = 37.7749;
    const campusLon = -122.4194;
    
    final distance = Geolocator.distanceBetween(
      campusLat,
      campusLon,
      position.latitude,
      position.longitude,
    );
    
    return distance <= AppConfig.geofenceRadius;
  }

  bool _isWithinPickupLoop(Position position) {
    // Placeholder - pickup loop coordinates needed
    const pickupLat = 37.7750;
    const pickupLon = -122.4195;
    
    final distance = Geolocator.distanceBetween(
      pickupLat,
      pickupLon,
      position.latitude,
      position.longitude,
    );
    
    return distance <= 50.0; // 50 meter radius
  }

  void _saveStatus() {
    _locationBox.put('last_status', _currentStatus.index);
    _locationBox.put('last_update', DateTime.now().toIso8601String());
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
  }

  void dispose() {
    _positionStream?.cancel();
    _statusController.close();
    _locationBox.close();
  }
}
