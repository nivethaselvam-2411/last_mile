// ─────────────────────────────────────────────────────────────────────────────
// passenger_home_screen.dart
// Core UI: State 1 (Booking) ↔ State 2 (Waiting / Matched).
// Uber-style UI Redesign.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'app_constants.dart';
import 'firestore_service.dart';
import 'models.dart';

// ─── App state enum ──────────────────────────────────────────────────────────

enum AppState { booking, waitingOrMatched }

// ─── Screen ──────────────────────────────────────────────────────────────────

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Local state ────────────────────────────────────────────────────────────
  AppState _appState = AppState.booking;
  String? _activeRequestId;
  StreamSubscription<List<SharedRide>>? _rideSubscription;
  SharedRide? _matchedRide;
  bool _isBooking = false; // loading guard for the Book button

  // ── Form state ─────────────────────────────────────────────────────────────
  String? _selectedPickup;
  String? _selectedDropoff;
  String _selectedVehicle = kVehicleAuto;

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _bookRide() async {
    if (_selectedPickup == null || _selectedDropoff == null) return;
    if (_selectedPickup == _selectedDropoff) return;

    setState(() => _isBooking = true);

    try {
      final requestId = await FirestoreService.instance.createRideRequest(
        pickupHub: _selectedPickup!,
        dropoffHub: _selectedDropoff!,
        vehiclePreference: _selectedVehicle,
      );

      _activeRequestId = requestId;
      _startListening();

      setState(() {
        _appState = AppState.waitingOrMatched;
        _matchedRide = null;
        _isBooking = false;
      });
    } catch (e) {
      setState(() => _isBooking = false);
      _showSnackBar('Failed to book ride: $e');
    }
  }

  void _startListening() {
    _rideSubscription?.cancel();
    _rideSubscription = FirestoreService.instance
        .listenToSharedRides(kPassengerId)
        .listen((rides) {
      setState(() => _matchedRide = rides.isNotEmpty ? rides.first : null);
    }, onError: (e) {
      _showSnackBar('Connection error: $e');
    });
  }

  Future<void> _cancelRide() async {
    if (_activeRequestId == null) return;

    try {
      await FirestoreService.instance.cancelRideRequest(_activeRequestId!);
    } catch (e) {
      _showSnackBar('Could not cancel: $e');
    }

    _rideSubscription?.cancel();
    _rideSubscription = null;

    setState(() {
      _appState = AppState.booking;
      _activeRequestId = null;
      _matchedRide = null;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map Placeholder (Top 60%) ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              color: const Color(0xFFE5E7EB), // Subtle grey
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.map_rounded,
                    size: 80,
                    color: Color(0xFF9CA3AF),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 20, color: Colors.black87),
                          const SizedBox(width: 8),
                          Text(
                            kPassengerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Sheet UI ──────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pull handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _appState == AppState.booking
                            ? _BookingForm(
                                key: const ValueKey('booking'),
                                selectedPickup: _selectedPickup,
                                selectedDropoff: _selectedDropoff,
                                selectedVehicle: _selectedVehicle,
                                isBooking: _isBooking,
                                onPickupChanged: (v) =>
                                    setState(() => _selectedPickup = v),
                                onDropoffChanged: (v) =>
                                    setState(() => _selectedDropoff = v),
                                onVehicleChanged: (v) =>
                                    setState(() => _selectedVehicle = v),
                                onBook: _bookRide,
                              )
                            : _WaitingPanel(
                                key: const ValueKey('waiting'),
                                matchedRide: _matchedRide,
                                pulseAnimation: _pulseAnimation,
                                onCancel: _cancelRide,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State 1 — Booking Form Widget (Uber Style)
// ─────────────────────────────────────────────────────────────────────────────

class _BookingForm extends StatelessWidget {
  final String? selectedPickup;
  final String? selectedDropoff;
  final String selectedVehicle;
  final bool isBooking;
  final ValueChanged<String?> onPickupChanged;
  final ValueChanged<String?> onDropoffChanged;
  final ValueChanged<String> onVehicleChanged;
  final VoidCallback onBook;

  const _BookingForm({
    super.key,
    required this.selectedPickup,
    required this.selectedDropoff,
    required this.selectedVehicle,
    required this.isBooking,
    required this.onPickupChanged,
    required this.onDropoffChanged,
    required this.onVehicleChanged,
    required this.onBook,
  });

  bool get _canBook =>
      selectedPickup != null &&
      selectedDropoff != null &&
      selectedPickup != selectedDropoff;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where to?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        
        // Location Inputs
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.black),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _hubDropdown(
                      value: selectedPickup,
                      hint: 'Pickup location',
                      excludeHub: selectedDropoff,
                      onChanged: onPickupChanged,
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                height: 24,
                width: 2,
                color: const Color(0xFFD1D5DB),
              ),
              Row(
                children: [
                  const Icon(Icons.stop, size: 12, color: Colors.black),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _hubDropdown(
                      value: selectedDropoff,
                      hint: 'Drop-off location',
                      excludeHub: selectedPickup,
                      onChanged: onDropoffChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        if (selectedPickup != null &&
            selectedDropoff != null &&
            selectedPickup == selectedDropoff)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Pickup and drop-off cannot be the same.',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
          
        const SizedBox(height: 24),
        
        // Vehicle Selection
        const Text(
          'Choose a ride',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _VehicleToggle(
          selected: selectedVehicle,
          onChanged: onVehicleChanged,
        ),
        
        const SizedBox(height: 24),
        
        // Book Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _canBook && !isBooking ? onBook : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF9CA3AF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isBooking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Find Co-Riders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _hubDropdown({
    required String? value,
    required String hint,
    required String? excludeHub,
    required ValueChanged<String?> onChanged,
  }) {
    final availableHubs = kHubs.where((h) => h != excludeHub).toList();
    final effectiveValue =
        (value != null && availableHubs.contains(value)) ? value : null;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: effectiveValue,
        hint: Text(hint,
            style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        isExpanded: true,
        dropdownColor: Colors.white,
        style: const TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        icon: const Icon(Icons.expand_more, color: Colors.black54),
        items: availableHubs
            .map(
              (hub) => DropdownMenuItem(
                value: hub,
                child: Text(kHubDisplayNames[hub] ?? hub),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State 2 — Waiting / Matched Panel Widget (Uber Style)
// ─────────────────────────────────────────────────────────────────────────────

class _WaitingPanel extends StatelessWidget {
  final SharedRide? matchedRide;
  final Animation<double> pulseAnimation;
  final VoidCallback onCancel;

  const _WaitingPanel({
    super.key,
    required this.matchedRide,
    required this.pulseAnimation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final ride = matchedRide;
    final isAccepted = ride?.status == kStatusAccepted;
    final isPending = ride?.status == kStatusPending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Status ──────────────────────────────────────────────────
        Row(
          children: [
            ScaleTransition(
              scale: pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : isPending
                          ? const Color(0xFFF59E0B).withOpacity(0.1)
                          : const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAccepted
                      ? Icons.check_circle_rounded
                      : isPending
                          ? Icons.people_rounded
                          : Icons.search_rounded,
                  size: 28,
                  color: isAccepted
                      ? const Color(0xFF10B981)
                      : isPending
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAccepted
                        ? 'Driver is on the way'
                        : isPending
                            ? 'Match found'
                            : 'Connecting you to co-riders...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAccepted
                        ? 'Meet at the pickup point.'
                        : isPending
                            ? 'Waiting for driver confirmation.'
                            : 'This might take a moment.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Ride Details Card ─────────────────────────────────────────────
        if (ride != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  Icons.route_rounded,
                  'Route',
                  '${kHubDisplayNames[ride.pickupHub] ?? ride.pickupHub} → ${kHubDisplayNames[ride.dropoffHub] ?? ride.dropoffHub}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
                _detailRow(
                  Icons.people_alt_rounded,
                  'Co-riders',
                  '${ride.passengers.length} passenger${ride.passengers.length != 1 ? 's' : ''}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _detailRow(
                      Icons.payments_rounded,
                      'Your fare',
                      '₹${ride.fareShare.toStringAsFixed(2)}',
                      valueColor: Colors.black,
                      valueBold: true,
                    ),
                    if (ride.totalFare > 0)
                      Text(
                        '(Total ₹${ride.totalFare.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
                if (isAccepted && ride.driverId.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  _detailRow(
                    Icons.badge_rounded,
                    'Driver ID',
                    ride.driverId,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Cancel button ──────────────────────────────────────────────────
        if (!isAccepted)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Toggle (Uber Style Cards)
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _VehicleToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _vehicleOption(
          label: 'Auto',
          icon: Icons.electric_rickshaw_rounded,
          value: kVehicleAuto,
          capacity: kMaxAutoCapacity,
        ),
        const SizedBox(width: 12),
        _vehicleOption(
          label: 'Cab',
          icon: Icons.local_taxi_rounded,
          value: kVehicleCab,
          capacity: kMaxCabCapacity,
        ),
      ],
    );
  }

  Widget _vehicleOption({
    required String label,
    required IconData icon,
    required String value,
    required int capacity,
  }) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.black : const Color(0xFFE5E7EB),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 12,
                    color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    capacity.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
