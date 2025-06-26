// lib/screens/restaurant_map_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:kosankenyang_rebuild/services/recommendation_service.dart';

class RestaurantMapPage extends StatefulWidget {
  final LatLng? initialLocation;
  final double initialZoom;
  final String? restaurantName;

  const RestaurantMapPage({
    super.key,
    this.initialLocation,
    this.initialZoom = 13.0,
    this.restaurantName,
  });

  @override
  State<RestaurantMapPage> createState() => _RestaurantMapPageState();
}

class _RestaurantMapPageState extends State<RestaurantMapPage> {
  final MapController _mapController = MapController();
  final RecommendationService _recommendationService = RecommendationService();
  final List<Marker> _markers = [];

  LatLng? _mapCenter;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() { _isLoading = true; _errorMessage = ''; _markers.clear(); });

    try {
      if (widget.initialLocation != null && widget.restaurantName != null) {
        _mapCenter = widget.initialLocation;
        _markers.add(_createMarker(widget.initialLocation!, widget.restaurantName!, isHighlighted: true));
        final userPosition = await _recommendationService.getCurrentLocation();
        if (userPosition != null) {
          _markers.add(_createUserMarker(LatLng(userPosition.latitude, userPosition.longitude)));
        }
      }
      else {
        final userPosition = await _recommendationService.getCurrentLocation();
        if (userPosition == null) {
          throw Exception('Tidak dapat mendapatkan lokasi Anda. Pastikan izin lokasi diberikan.');
        }
        _mapCenter = LatLng(userPosition.latitude, userPosition.longitude);
        _markers.add(_createUserMarker(LatLng(userPosition.latitude, userPosition.longitude)));

        final allRestaurants = await _recommendationService.getAllRestaurants();
        if (allRestaurants.isEmpty) {
          throw Exception('Tidak ada data restoran yang dapat dimuat.');
        }

        for (var resto in allRestaurants) {
          final lat = resto['koordinat']?['latitude'];
          final lon = resto['koordinat']?['longitude'];
          final name = resto['nama_warung'];
          if (lat != null && lon != null && name != null) {
            _markers.add(_createMarker(LatLng(lat, lon), name));
          }
        }
      }

      setState(() { _isLoading = false; });

    } catch (e) {
      if(mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Marker _createMarker(LatLng point, String name, {bool isHighlighted = false}) {
    return Marker(
      point: point,
      width: 100.0,
      height: 80.0,
      child: GestureDetector(
          onTap: () {
            Get.snackbar(
              'Restoran', name,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: orangeColor,
              colorText: Colors.white,
              margin: const EdgeInsets.all(10),
              borderRadius: 8,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHighlighted ? Icons.restaurant_menu : Icons.location_pin,
                color: isHighlighted ? Colors.redAccent[700] : orangeColor,
                size: 40.0,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 5.0, offset: Offset(2.0, 2.0))],
              ),
            ],
          )
      ),
    );
  }

  Marker _createUserMarker(LatLng point) {
    return Marker(
      point: point,
      width: 80.0,
      height: 80.0,
      child: const Column(
        children: [
          Icon(Icons.my_location, color: Colors.blueAccent, size: 30.0),
          Text("Anda", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName ?? 'Peta Restoran', style: const TextStyle(color: Colors.white)),
        backgroundColor: orangeColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: orangeColor))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        ),
      )
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _mapCenter ?? const LatLng(-7.443, 112.672), // Default Sidoarjo
          initialZoom: widget.initialZoom,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.kosankenyang_rebuild',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoomInBtn',
            onPressed: () {
              final currentZoom = _mapController.zoom;
              _mapController.move(_mapController.center, currentZoom + 1);
            },
            backgroundColor: orangeColor.withOpacity(0.9),
            child: const Icon(Icons.add, color: Colors.white),
            mini: true,
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOutBtn',
            onPressed: () {
              final currentZoom = _mapController.zoom;
              _mapController.move(_mapController.center, currentZoom - 1);
            },
            backgroundColor: orangeColor.withOpacity(0.9),
            child: const Icon(Icons.remove, color: Colors.white),
            mini: true,
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'myLocationBtn',
            onPressed: () async {
              final userPosition = await _recommendationService.getCurrentLocation();
              if (userPosition != null) {
                _mapController.move(LatLng(userPosition.latitude, userPosition.longitude), 15.0);
              } else {
                Get.snackbar('Error', 'Tidak dapat memusatkan peta. Lokasi tidak tersedia.', snackPosition: SnackPosition.BOTTOM);
              }
            },
            backgroundColor: Colors.blueAccent,
            tooltip: 'Lokasi Saya',
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}