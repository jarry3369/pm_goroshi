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
  @override
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
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
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // 정확도를 medium으로 설정하여 더 빠르게 응답
        timeLimit: const Duration(seconds: 5), // 5초 제한 시간 설정
      );
    } catch (e) {
      // 제한 시간 초과 시 마지막으로 알려진 위치 반환
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Future<String?> getFormattedAddress(Position position) async {
    try {
      // 좌표를 주소로 변환 (한국 도로명 주소 형식으로)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
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

        // 우편번호
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address += ' (${place.postalCode})';
        }

        return address.trim();
      }
    } catch (e) {
      print('주소 변환 오류: $e');
    }

    // 주소 변환 실패 시 좌표 반환
    return '위도: ${position.latitude.toStringAsFixed(6)}, 경도: ${position.longitude.toStringAsFixed(6)}';
  }
}
