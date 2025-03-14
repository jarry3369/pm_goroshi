import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geocoding/geocoding.dart';

part 'location_service.g.dart';

abstract class LocationService {
  Future<Position?> getCurrentPosition();
  Future<String?> getFormattedAddress(Position position);
}

@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationServiceImpl();
}

class LocationServiceImpl implements LocationService {
  // 마지막으로 가져온 위치 정보를 캐싱
  Position? _lastPosition;
  String? _lastAddress;
  DateTime? _lastFetchTime;

  // 진행 중인 위치 정보 요청을 캐싱하여 동일한 요청이 중복 발생하지 않도록 함
  Future<Position?>? _pendingPositionRequest;
  Map<String, Future<String?>> _pendingAddressRequests = {};

  // 캐시 유효 시간 (15초로 증가)
  static const _cacheValidDuration = Duration(seconds: 15);

  // 동일 위치로 간주할 거리 (20m로 증가)
  static const _sameLocationDistanceThreshold = 20.0;

  @override
  Future<Position?> getCurrentPosition() async {
    // 이미 진행 중인 요청이 있으면 해당 요청 결과 반환
    if (_pendingPositionRequest != null) {
      return _pendingPositionRequest;
    }

    // 캐시된 위치 정보가 있고, 유효 시간 내라면 캐시된 정보 반환
    if (_lastPosition != null && _lastFetchTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastFetchTime!) < _cacheValidDuration) {
        return _lastPosition;
      }
    }

    // 새로운 위치 정보 요청 시작
    _pendingPositionRequest = _fetchPosition();
    final result = await _pendingPositionRequest;
    _pendingPositionRequest = null;
    return result;
  }

  // 실제 위치 정보를 가져오는 내부 메서드
  Future<Position?> _fetchPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 위치 권한 확인
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 현재 위치 가져오기 - 더 빠른 응답을 위해 정확도 낮춤
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // 정확도를 low로 낮춤
        timeLimit: const Duration(seconds: 4), // 시간 제한 줄임
      );

      // 위치 정보 캐싱
      _lastPosition = position;
      _lastFetchTime = DateTime.now();

      return position;
    } catch (e) {
      // 제한 시간 초과 또는 오류 발생 시 마지막으로 알려진 위치 반환
      try {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          // 위치 정보 캐싱
          _lastPosition = position;
          _lastFetchTime = DateTime.now();
        }
        return position;
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Future<String?> getFormattedAddress(Position position) async {
    // 캐시된 주소가 있고, 위치가 동일하다면 캐시된 주소 반환
    if (_lastAddress != null && _lastPosition != null) {
      // 위치 차이가 미미하다면 (임계값 이내) 캐시된 주소 반환
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < _sameLocationDistanceThreshold) {
        return _lastAddress;
      }
    }

    // 위치의 고유 식별자 생성
    final positionKey =
        '${position.latitude.toStringAsFixed(5)}_${position.longitude.toStringAsFixed(5)}';

    // 동일한 위치에 대한 요청이 이미 진행 중이면 해당 요청의 결과 반환
    if (_pendingAddressRequests.containsKey(positionKey)) {
      return _pendingAddressRequests[positionKey];
    }

    // 새로운 주소 변환 요청 시작
    _pendingAddressRequests[positionKey] = _fetchFormattedAddress(position);
    final result = await _pendingAddressRequests[positionKey];
    _pendingAddressRequests.remove(positionKey);
    return result;
  }

  // 실제 주소 변환을 수행하는 내부 메서드
  Future<String?> _fetchFormattedAddress(Position position) async {
    try {
      // 좌표를 주소로 변환 (한국 도로명 주소 형식으로)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'ko_KR', // 한국어 주소로 설정
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // 도로명 주소 형식으로 구성
        String address = '';

        // 도/시
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          address += place.administrativeArea!;
        }

        // 구/군
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += ' ${place.locality}';
        }

        // 동/읍/면
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += ' ${place.subLocality}';
        }

        // 도로명
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          address += ' ${place.thoroughfare}';
        }

        // 건물번호
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty) {
          address += ' ${place.subThoroughfare}';
        }

        // 주소 캐싱
        _lastPosition = position; // 위치도 함께 캐싱
        _lastAddress = address.trim();
        return _lastAddress;
      }
    } catch (e) {
      print('주소 변환 오류: $e');
    }

    // 주소 변환 실패 시 좌표 반환
    final fallbackAddress =
        '위도: ${position.latitude.toStringAsFixed(6)}, 경도: ${position.longitude.toStringAsFixed(6)}';
    _lastPosition = position;
    _lastAddress = fallbackAddress;
    return fallbackAddress;
  }
}
