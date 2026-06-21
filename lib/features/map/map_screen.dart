import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';
import 'package:etrip/features/Itinerary/data/services/itinerary_storage_service.dart';
import 'package:etrip/features/auth/data/services/local_storage_service.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 交互式地图页面 - 仅展示景点
class MapScreen extends StatefulWidget {
  final PlaceModel? initialFocusPlace;

  const MapScreen({Key? key, this.initialFocusPlace}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // 当前位置
  LatLng? _currentPosition;
  bool _locationLoading = false;

  /// 是否有初始聚焦景点（来自景点详情跳转）
  bool _hasInitialFocus = false;

  /// 默认初始位置（中国中心）
  static const LatLng _defaultCenter = LatLng(35.86, 104.19);
  static const double _defaultZoom = 5;

  /// 用户位置附近的初始缩放
  static const double _userZoom = 10;

  /// 备用位置（四川大学江安校区）
  static const LatLng _fallbackCenter = LatLng(30.5505, 103.9985);

  // ── 行程路线面板 ──
  bool _panelOpen = false;
  List<SavedItinerary> _savedItineraries = [];
  SavedItinerary? _selectedItinerary;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadSavedItineraries();
    _checkLocationPermission();

    if (widget.initialFocusPlace != null &&
        widget.initialFocusPlace!.lat != 0.0 &&
        widget.initialFocusPlace!.lng != 0.0) {
      _hasInitialFocus = true;
      // 地图 initialCenter 已指向景点，只需延迟弹出详情
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final place = widget.initialFocusPlace!;
        Future.delayed(const Duration(milliseconds: 400), () {
          _showPlaceDetails(place);
        });
      });
    }
  }

  /// 检查位置权限
  Future<void> _checkLocationPermission() async {
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      _useFallbackLocation();
      return;
    }
    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission().timeout(const Duration(seconds: 5));
      } on TimeoutException {
        _useFallbackLocation();
        return;
      }
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    } else {
      _useFallbackLocation();
    }
  }

  /// 使用备用位置（成都）
  void _useFallbackLocation() {
    setState(() {
      _currentPosition = _fallbackCenter;
      _locationLoading = false;
    });
    if (!_hasInitialFocus) {
      _mapController.move(_fallbackCenter, _userZoom);
    }
  }

  /// 获取当前位置
  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);

    // 先尝试获取上次已知位置（更快）
    try {
      final lastPos = await Geolocator.getLastKnownPosition().timeout(const Duration(seconds: 3));
      if (lastPos != null) {
        final pos = LatLng(lastPos.latitude, lastPos.longitude);
        setState(() {
          _currentPosition = pos;
          _locationLoading = false;
        });
        if (!_hasInitialFocus) {
          _mapController.move(pos, _userZoom);
        }
        return;
      }
    } catch (_) {}

    // 再尝试获取当前位置（带超时）
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
      final pos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = pos;
        _locationLoading = false;
      });
      if (!_hasInitialFocus) {
        _mapController.move(pos, _userZoom);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _useFallbackLocation();
    }
  }

  /// 重置到默认视角（用户位置或中国中心）
  void _resetToDefault() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, _userZoom);
    } else {
      _mapController.move(_defaultCenter, _defaultZoom);
    }
  }

  // ── 行程路线逻辑 ──

  Future<void> _loadSavedItineraries() async {
    final uid = LocalStorageService().currentUid;
    if (uid == null || uid.isEmpty) return;
    final itineraries = await ItineraryStorageService.loadAll(uid);
    if (!mounted) return;
    setState(() => _savedItineraries = itineraries);
  }

  void _selectItinerary(SavedItinerary itinerary) {
    final places = itinerary.placeIds
        .map((id) => mockPlaces.firstWhere(
              (p) => p.id == id,
              orElse: () => PlaceModel(
                id: id, name: '', profileImage: '', carouselImages: [],
                tourismType: '', category: '', cityName: '',
                rate: 0, totalRates: 0, description: '', googleMapsLink: '',
              ),
            ))
        .where((p) => p.lat != 0.0 || p.lng != 0.0)
        .toList();

    final points = places.map((p) => LatLng(p.lat, p.lng)).toList();

    setState(() {
      _selectedItinerary = itinerary;
      _routePoints = points;
    });

    // 调整地图视野适配所有景点
    if (points.length >= 2) {
      final lats = points.map((p) => p.latitude);
      final lngs = points.map((p) => p.longitude);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(lats.reduce(min), lngs.reduce(min)),
            LatLng(lats.reduce(max), lngs.reduce(max)),
          ),
          padding: const EdgeInsets.all(60),
        ),
      );
    } else if (points.length == 1) {
      _mapController.move(points.first, 16);
    }
  }

  /// 计算从 from 到 to 的方向角（弧度），用于旋转箭头
  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    // atan2 结果减去 pi/2，使 Icons.play_arrow（默认朝右）对准实际方向
    return atan2(y, x) - pi / 2;
  }

  /// 计算两点间的距离（公里）
  double _distanceBetween(LatLng a, LatLng b) {
    const R = 6371.0; // 地球半径（公里）
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final sinLat = sin(dLat / 2);
    final sinLng = sin(dLng / 2);
    final a2 = sinLat * sinLat +
        cos(a.latitude * pi / 180) * cos(b.latitude * pi / 180) * sinLng * sinLng;
    final c = 2 * atan2(sqrt(a2), sqrt(1 - a2));
    return R * c;
  }

  /// 获取离用户最近的10个景点
  List<MapLocation> _getNearestPlaces() {
    final allLocations = mockPlaces
        .where((p) => p.lat != 0.0 && p.lng != 0.0)
        .map((p) => MapLocation(
              id: p.id,
              name: placeNamesZh[p.id] ?? p.name,
              nameEn: p.name,
              lat: p.lat,
              lng: p.lng,
              rating: p.rate,
              imageUrl: p.profileImage,
              description: placeDescriptionsZh[p.id] ?? p.description,
            ))
        .toList();

    if (_currentPosition == null) {
      return allLocations.take(10).toList();
    }

    allLocations.sort((a, b) {
      final distA = _distanceBetween(_currentPosition!, LatLng(a.lat, a.lng));
      final distB = _distanceBetween(_currentPosition!, LatLng(b.lat, b.lng));
      return distA.compareTo(distB);
    });

    return allLocations.take(10).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果有初始聚焦景点，地图直接以该景点为中心，避免 move() 导致瓦片不加载
    final hasFocus = widget.initialFocusPlace != null &&
        widget.initialFocusPlace!.lat != 0.0 &&
        widget.initialFocusPlace!.lng != 0.0;
    final initCenter = hasFocus
        ? LatLng(widget.initialFocusPlace!.lat, widget.initialFocusPlace!.lng)
        : _defaultCenter;
    final initZoom = hasFocus ? 16.0 : _defaultZoom;
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initCenter,
              initialZoom: initZoom,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, __) {
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://webrd01.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.etrip',
                maxZoom: 18,
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: mockPlaces
                    .where((p) => p.lat != 0.0 && p.lng != 0.0)
                    .map((place) => Marker(
                          point: LatLng(place.lat, place.lng),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () {
                              _showPlaceDetails(place);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.place,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              // 行程路线连线
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // 线段中点方向箭头
              if (_routePoints.length >= 2)
                MarkerLayer(
                  markers: _buildArrowMarkers(),
                ),
            ],
          ),
          // 右侧行程面板（叠加在地图上方）
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildRoutePanel(context, lang),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'location',
        onPressed: _resetToDefault,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
      bottomSheet: _buildNearestPlacesSheet(lang),
    );
  }

  /// 最近景点底部列表
  Widget _buildNearestPlacesSheet(String lang) {
    final nearest = _getNearestPlaces();

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentPosition != null ? Translations.tr('map_nearest', lang) : Translations.tr('map_place_list', lang),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _locationLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '${nearest.length} ${Translations.tr('map_results', lang)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 横向列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: nearest.length,
              itemBuilder: (context, index) {
                final location = nearest[index];
                return _PlaceCard(
                  location: location,
                  lang: lang,
                  onTap: () {
                    _mapController.move(
                      LatLng(location.lat, location.lng),
                      16,
                    );
                    // Find the full place and show details
                    final place = mockPlaces.firstWhere(
                      (p) => p.id == location.id,
                    );
                    _showPlaceDetails(place);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 显示景点详情
  void _showPlaceDetails(PlaceModel place) {
    final lang = context.read<LocaleCubit>().state.languageCode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlaceDetailSheet(place: place, lang: lang),
    );
  }

  // ── 行程路线面板 ──

  /// 构建线段中点方向箭头
  List<Marker> _buildArrowMarkers() {
    final markers = <Marker>[];
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final from = _routePoints[i];
      final to = _routePoints[i + 1];
      final mid = LatLng(
        (from.latitude + to.latitude) / 2,
        (from.longitude + to.longitude) / 2,
      );
      markers.add(
        Marker(
          point: mid,
          width: 24,
          height: 24,
          child: Transform.rotate(
            angle: _bearing(from, to),
            child: const Icon(Icons.play_arrow, color: Colors.blue, size: 24),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildRoutePanel(BuildContext context, String lang) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 2 / 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 切换按钮（始终显示在右侧边缘）
        GestureDetector(
          onTap: () => setState(() => _panelOpen = !_panelOpen),
          child: Container(
            width: 24,
            height: 80,
            margin: const EdgeInsets.only(top: 100),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Icon(
                _panelOpen
                    ? Icons.arrow_forward_ios
                    : Icons.arrow_back_ios,
                size: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
        // 面板内容
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _panelOpen ? panelWidth - 24 : 0,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(-2, 0)),
            ],
          ),
          child: _panelOpen ? _buildPanelContent(lang) : null,
        ),
      ],
    );
  }

  Widget _buildPanelContent(String lang) {
    return Column(
      children: [
        // 标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text(
                Translations.tr('map_route_plan', lang),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_selectedItinerary != null)
                Text(
                  '${_routePoints.length} ${Translations.tr('map_spots', lang)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 选中行程的路线概览
        if (_selectedItinerary != null && _routePoints.length >= 2)
          _buildRouteOverview(lang),

        if (_selectedItinerary != null && _routePoints.length >= 2)
          const Divider(),

        // 行程列表
        Expanded(
          child: _savedItineraries.isEmpty
              ? Center(
                  child: Text(
                    Translations.tr('map_no_saved', lang),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _savedItineraries.length,
                  itemBuilder: (context, index) =>
                      _buildItineraryCard(_savedItineraries[index], lang),
                ),
        ),
      ],
    );
  }

  Widget _buildRouteOverview(String lang) {
    final it = _selectedItinerary!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${localizedCityName(it.city, lang)} · ${it.noOfDays} ${Translations.tr('days', lang)} · ${Translations.tr(it.budget, lang)} · ${Translations.tr(it.withWho, lang)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue),
          ),
          const SizedBox(height: 6),
          ...List.generate(_routePoints.length, (i) {
            final place = mockPlaces.firstWhere(
              (p) =>
                  p.lat == _routePoints[i].latitude &&
                  p.lng == _routePoints[i].longitude,
              orElse: () => PlaceModel(
                id: '', name: '${Translations.tr('map_spot', lang)} ${i + 1}', profileImage: '',
                carouselImages: [], tourismType: '', category: '',
                cityName: '', rate: 0, totalRates: 0,
                description: '', googleMapsLink: '',
                lat: _routePoints[i].latitude,
                lng: _routePoints[i].longitude,
              ),
            );
            final nameZh =
                placeNamesZh[place.id] ?? place.name;
            final dayLabel = lang == 'zh'
                ? '第${(i ~/ 2) + 1}${Translations.tr('days', lang)}'
                : '${Translations.tr('day', lang)} ${(i ~/ 2) + 1}';
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.blue[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$dayLabel:  $nameZh',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(SavedItinerary itinerary, String lang) {
    final isSelected = _selectedItinerary?.id == itinerary.id;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isSelected ? Colors.blue.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${itinerary.noOfDays}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
        title: Text(
          '${localizedCityName(itinerary.city, lang)} · ${Translations.tr(itinerary.budget, lang)} · ${Translations.tr(itinerary.withWho, lang)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${itinerary.noOfDays} ${Translations.tr('days', lang)} · ${itinerary.placeIds.length} ${Translations.tr('map_spots', lang)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.route, size: 20, color: Colors.blue),
        onTap: () => _selectItinerary(itinerary),
      ),
    );
  }
}

/// 位置数据模型（景点用）
class MapLocation {
  final String id;
  final String name;
  final String nameEn;
  final double lat;
  final double lng;
  final double rating;
  final String imageUrl;
  final String description;

  MapLocation({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.imageUrl,
    required this.description,
  });
}

/// 景点卡片
class _PlaceCard extends StatelessWidget {
  final MapLocation location;
  final VoidCallback onTap;
  final String lang;

  const _PlaceCard({
    required this.location,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.place, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    Translations.tr('map_spot', lang),
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 1),
                    Text(
                      location.rating.toString(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              location.nameEn,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 景点详情底部弹窗
class _PlaceDetailSheet extends StatelessWidget {
  final PlaceModel place;
  final String lang;

  const _PlaceDetailSheet({required this.place, required this.lang});

  @override
  Widget build(BuildContext context) {
    final nameZh = placeNamesZh[place.id] ?? place.name;
    final descZh = placeDescriptionsZh[place.id] ?? place.description;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称
                  Text(
                    nameZh,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    place.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 评分
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        place.rate.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${place.totalRates} ${Translations.tr('map_reviews', lang)})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 描述
                  Text(
                    Translations.tr('map_intro', lang),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    descZh,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
