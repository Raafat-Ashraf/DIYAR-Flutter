import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial});
  final LatLng? initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final MapController _mapCtrl;
  LatLng? _selected;
  bool _locating = false;

  static const _cairo = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _selected = widget.initial ?? _cairo;
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم منح إذن الموقع')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _selected = ll);
        _mapCtrl.move(ll, 16);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد الموقع')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حدد موقعك'),
          actions: [
            TextButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
              child: Text(
                'تأكيد',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _selected ?? _cairo,
                initialZoom: 14,
                onTap: (_, ll) => setState(() => _selected = ll),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.diyar',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Hint
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'اضغط على الخريطة لتحديد موقعك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            // GPS FAB
            Positioned(
              bottom: 24,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'gps',
                tooltip: 'استخدم موقعي الحالي',
                onPressed: _locating ? null : _useGps,
                child: _locating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
