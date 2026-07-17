// lib/screens/driver_home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../models/ride_model.dart';
import '../services/firestore_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with TickerProviderStateMixin {
  // ── Driver Identity (constant) ─────────────────────────────────────────────
  final String _driverId = AppConstants.driverId;
  final String _vehicleType = AppConstants.vehicleType;

  // ── Online/Offline ─────────────────────────────────────────────────────────
  bool _isOnline = false;

  // ── Ride Feed ──────────────────────────────────────────────────────────────
  List<RideModel> _pendingRides = [];
  StreamSubscription<List<RideModel>>? _feedSubscription;
  bool _isLoadingFeed = false;

  // ── Active Ride ────────────────────────────────────────────────────────────
  RideModel? _activeRide;
  bool _isAccepting = false;
  bool _isCompleting = false;

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Toggle Online/Offline ──────────────────────────────────────────────────
  void _onToggleOnline(bool value) {
    if (value) {
      setState(() {
        _isOnline = true;
        _isLoadingFeed = true;
      });

      _feedSubscription = FirestoreService.getPendingRidesStream(_vehicleType)
          .listen(
        (rides) {
          if (mounted) {
            setState(() {
              _pendingRides = rides;
              _isLoadingFeed = false;
            });
          }
        },
        onError: (Object error) {
          if (mounted) {
            setState(() => _isLoadingFeed = false);
            _showSnackBar('Stream error: ${error.toString()}');
          }
        },
      );
    } else {
      _feedSubscription?.cancel();
      _feedSubscription = null;
      setState(() {
        _isOnline = false;
        _pendingRides = [];
        _activeRide = null;
        _isLoadingFeed = false;
      });
    }
  }

  // ── Accept Ride ────────────────────────────────────────────────────────────
  Future<void> _onAcceptRide(RideModel ride) async {
    setState(() => _isAccepting = true);
    try {
      await FirestoreService.acceptRide(ride.id, _driverId);
      if (mounted) {
        setState(() {
          _activeRide = ride;
          _isAccepting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        _showSnackBar('Ride no longer available — another driver got it first.');
      }
    }
  }

  // ── Navigate to Dropoff ────────────────────────────────────────────────────
  Future<void> _onNavigate() async {
    if (_activeRide == null) return;
    final hubLabel =
        AppConstants.hubLabels[_activeRide!.dropoffHub] ?? _activeRide!.dropoffHub;
    final query = Uri.encodeComponent('$hubLabel, Chennai');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not open Maps. Please check your internet connection.');
    }
  }

  // ── Complete Ride ──────────────────────────────────────────────────────────
  Future<void> _onCompleteRide() async {
    if (_activeRide == null) return;
    setState(() => _isCompleting = true);
    try {
      await FirestoreService.completeRide(_activeRide!.id);
      if (mounted) {
        setState(() {
          _activeRide = null;
          _isCompleting = false;
        });
        _showSnackBar('✓ Ride completed! Great job.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        _showSnackBar('Error completing ride. Please try again.');
      }
    }
  }

  // ── SnackBar Helper ────────────────────────────────────────────────────────
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildBody(),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.accentColor,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.highlightColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.electric_rickshaw,
              color: AppConstants.highlightColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'AutoShare Driver',
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      _isOnline ? AppConstants.onlineColor : AppConstants.offlineColor,
                ),
                child: Text(_isOnline ? 'ONLINE' : 'OFFLINE'),
              ),
              const SizedBox(width: 6),
              Switch(
                value: _isOnline,
                onChanged: _onToggleOnline,
                activeColor: AppConstants.onlineColor,
                activeTrackColor: AppConstants.onlineColor.withOpacity(0.3),
                inactiveThumbColor: AppConstants.offlineColor,
                inactiveTrackColor: AppConstants.offlineColor.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Body Router ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (!_isOnline) {
      return _buildOfflineState();
    }
    if (_activeRide != null) {
      return _buildActiveRidePanel(_activeRide!);
    }
    return _buildFeedView();
  }

  // ── Offline State ──────────────────────────────────────────────────────────
  Widget _buildOfflineState() {
    return Center(
      key: const ValueKey('offline'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.offlineColor.withOpacity(0.15),
                border: Border.all(color: AppConstants.offlineColor, width: 2),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppConstants.offlineColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'You are Offline',
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toggle the switch to start\nreceiving shared rides',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Feed View ──────────────────────────────────────────────────────────────
  Widget _buildFeedView() {
    return Column(
      key: const ValueKey('feed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppConstants.onlineColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isLoadingFeed
                    ? 'Searching for rides…'
                    : 'Available Rides (${_pendingRides.length})',
                style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoadingFeed
              ? _buildLoadingState()
              : _pendingRides.isEmpty
                  ? _buildEmptyState()
                  : _buildRideList(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppConstants.onlineColor),
          SizedBox(height: 16),
          Text(
            'Finding shared rides near you…',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: AppConstants.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No rides available right now',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay online — new rides appear instantly',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRideList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _pendingRides.length,
      itemBuilder: (context, index) {
        return _RideCard(
          ride: _pendingRides[index],
          isAccepting: _isAccepting,
          onAccept: () => _onAcceptRide(_pendingRides[index]),
        );
      },
    );
  }

  // ── Active Ride Panel ──────────────────────────────────────────────────────
  Widget _buildActiveRidePanel(RideModel ride) {
    final pickupLabel =
        AppConstants.hubLabels[ride.pickupHub] ?? ride.pickupHub;
    final dropoffLabel =
        AppConstants.hubLabels[ride.dropoffHub] ?? ride.dropoffHub;

    return SingleChildScrollView(
      key: const ValueKey('active'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status Banner ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: AppConstants.onlineColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppConstants.onlineColor.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppConstants.onlineColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ACTIVE RIDE — IN PROGRESS',
                  style: TextStyle(
                    color: AppConstants.onlineColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Route Card ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.07), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Row(
                  children: [
                    const Icon(Icons.trip_origin,
                        color: AppConstants.onlineColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pickupLabel,
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Container(
                    width: 1,
                    height: 24,
                    color: AppConstants.textSecondary.withOpacity(0.3),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppConstants.highlightColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dropoffLabel,
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),

                // Fare & Seats row
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.currency_rupee,
                      label: 'Total Fare',
                      value: '₹${ride.totalFare.toStringAsFixed(0)}',
                      valueColor: AppConstants.fareColor,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.people_alt_outlined,
                      label: 'Seats',
                      value: '${ride.filledSeats} / ${ride.maxSeats}',
                      valueColor: ride.isFull
                          ? AppConstants.fullBadgeColor
                          : AppConstants.onlineColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Passenger list
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PASSENGERS',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...ride.passengers.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  color: AppConstants.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                p.name,
                                style: const TextStyle(
                                  color: AppConstants.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₹${p.fareShare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppConstants.fareColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Navigate Button ─────────────────────────────────────────────
          _ActionButton(
            label: 'Navigate to Dropoff',
            icon: Icons.navigation_rounded,
            color: AppConstants.highlightColor,
            isLoading: false,
            onPressed: _onNavigate,
          ),
          const SizedBox(height: 12),

          // ── Complete Ride Button ────────────────────────────────────────
          _ActionButton(
            label: 'Complete Ride',
            icon: Icons.check_circle_outline,
            color: AppConstants.successColor,
            isLoading: _isCompleting,
            onPressed: _isCompleting ? null : _onCompleteRide,
          ),
          const SizedBox(height: 16),

          // Disclaimer
          const Text(
            'Complete the ride only after dropping off all passengers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── RideCard Widget ────────────────────────────────────────────────────────────

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final bool isAccepting;
  final VoidCallback onAccept;

  const _RideCard({
    required this.ride,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final pickupLabel =
        AppConstants.hubLabels[ride.pickupHub] ?? ride.pickupHub;
    final dropoffLabel =
        AppConstants.hubLabels[ride.dropoffHub] ?? ride.dropoffHub;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ride.isFull
              ? AppConstants.fullBadgeColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Route Row ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.trip_origin,
                          color: AppConstants.onlineColor, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          pickupLabel,
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward,
                            size: 13, color: AppConstants.textSecondary),
                      ),
                      Flexible(
                        child: Text(
                          dropoffLabel,
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Vehicle type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.highlightColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppConstants.highlightColor.withOpacity(0.5),
                        width: 1),
                  ),
                  child: Text(
                    ride.vehicleType.toUpperCase(),
                    style: const TextStyle(
                      color: AppConstants.highlightColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Passenger names ──────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    size: 14, color: AppConstants.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ride.passengers.map((p) => p.name).join(', '),
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Fare & Seats ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.currency_rupee,
                    size: 14, color: AppConstants.fareColor),
                const SizedBox(width: 4),
                Text(
                  '₹${ride.totalFare.toStringAsFixed(0)} total',
                  style: const TextStyle(
                    color: AppConstants.fareColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Seats filled indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (ride.isFull
                            ? AppConstants.fullBadgeColor
                            : AppConstants.onlineColor)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (ride.isFull
                              ? AppConstants.fullBadgeColor
                              : AppConstants.onlineColor)
                          .withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${ride.filledSeats}/${ride.maxSeats} seats'
                    '${ride.isFull ? ' · FULL' : ''}',
                    style: TextStyle(
                      color: ride.isFull
                          ? AppConstants.fullBadgeColor
                          : AppConstants.onlineColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),

            // ── Accept Button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAccepting ? null : onAccept,
                icon: isAccepting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(isAccepting ? 'Accepting…' : 'Accept Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.highlightColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppConstants.highlightColor.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Info Chip ─────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: valueColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Action Button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(isLoading ? 'Please wait…' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
