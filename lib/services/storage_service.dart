import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../catalogs/raceway_catalog.dart';
import '../l10n/app_strings.dart';
import '../models/calculation_results.dart';
import '../models/conductor.dart';
import '../models/raceway.dart';

/// Technician and company profile information stored locally
/// to automatically populate technical PDF compliance reports.
class TechnicianProfile {
  final String technicianName;
  final String companyName;
  final String licenseNumber;
  final String email;
  final String phone;
  final String agencyName;
  final String address;

  const TechnicianProfile({
    this.technicianName = '',
    this.companyName = '',
    this.licenseNumber = '',
    this.email = '',
    this.phone = '',
    this.agencyName = '',
    this.address = '',
  });

  TechnicianProfile copyWith({
    String? technicianName,
    String? companyName,
    String? licenseNumber,
    String? email,
    String? phone,
    String? agencyName,
    String? address,
  }) {
    return TechnicianProfile(
      technicianName: technicianName ?? this.technicianName,
      companyName: companyName ?? this.companyName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      agencyName: agencyName ?? this.agencyName,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
        'technicianName': technicianName,
        'companyName': companyName,
        'licenseNumber': licenseNumber,
        'email': email,
        'phone': phone,
        'agencyName': agencyName,
        'address': address,
      };

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      technicianName: json['technicianName'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      agencyName: json['agencyName'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  static const TechnicianProfile defaultProfile = TechnicianProfile();
}

/// Complete persistent record representing a saved project run or conduit calculation.
class SavedCalculation {
  final String id;
  final String title;
  final String notes;
  final DateTime timestamp;
  final RacewayProfile raceway;
  final List<ConductorGroup> conductors;
  final ConduitFillResult fillResult;
  final VoltageDropResult? voltageDropResult;
  final DeratingResult? deratingResult;

  // Electrical inputs for full state restore
  final double nominalVoltage;
  final CircuitPhase circuitPhase;
  final double circuitLengthFeet;
  final double loadCurrentAmps;
  final double powerFactor;
  final double ambientTempC;
  final double terminalRatingC;
  final bool isNipple;
  final String clientName;
  final String siteAddress;

  const SavedCalculation({
    required this.id,
    required this.title,
    this.notes = '',
    required this.timestamp,
    required this.raceway,
    required this.conductors,
    required this.fillResult,
    this.voltageDropResult,
    this.deratingResult,
    this.nominalVoltage = 120.0,
    this.circuitPhase = CircuitPhase.singlePhase,
    this.circuitLengthFeet = 100.0,
    this.loadCurrentAmps = 16.0,
    this.powerFactor = 0.90,
    this.ambientTempC = 30.0,
    this.terminalRatingC = 75.0,
    this.isNipple = false,
    this.clientName = '',
    this.siteAddress = '',
  });

  // Convenience getters
  RacewayType get racewayType => raceway.type;
  String get tradeSize => raceway.tradeSize;
  DateTime get createdAt => timestamp;
  DateTime get updatedAt => timestamp;

  SavedCalculation copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? timestamp,
    RacewayProfile? raceway,
    List<ConductorGroup>? conductors,
    ConduitFillResult? fillResult,
    VoltageDropResult? voltageDropResult,
    DeratingResult? deratingResult,
    double? nominalVoltage,
    CircuitPhase? circuitPhase,
    double? circuitLengthFeet,
    double? loadCurrentAmps,
    double? powerFactor,
    double? ambientTempC,
    double? terminalRatingC,
    bool? isNipple,
    String? clientName,
    String? siteAddress,
  }) {
    return SavedCalculation(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      raceway: raceway ?? this.raceway,
      conductors: conductors ?? this.conductors,
      fillResult: fillResult ?? this.fillResult,
      voltageDropResult: voltageDropResult ?? this.voltageDropResult,
      deratingResult: deratingResult ?? this.deratingResult,
      nominalVoltage: nominalVoltage ?? this.nominalVoltage,
      circuitPhase: circuitPhase ?? this.circuitPhase,
      circuitLengthFeet: circuitLengthFeet ?? this.circuitLengthFeet,
      loadCurrentAmps: loadCurrentAmps ?? this.loadCurrentAmps,
      powerFactor: powerFactor ?? this.powerFactor,
      ambientTempC: ambientTempC ?? this.ambientTempC,
      terminalRatingC: terminalRatingC ?? this.terminalRatingC,
      isNipple: isNipple ?? this.isNipple,
      clientName: clientName ?? this.clientName,
      siteAddress: siteAddress ?? this.siteAddress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
        'raceway': raceway.toJson(),
        'conductors': conductors.map((c) => c.toJson()).toList(),
        'fillResult': fillResult.toJson(),
        'voltageDropResult': voltageDropResult?.toJson(),
        'deratingResult': deratingResult?.toJson(),
        'nominalVoltage': nominalVoltage,
        'circuitPhase': circuitPhase.name,
        'circuitLengthFeet': circuitLengthFeet,
        'loadCurrentAmps': loadCurrentAmps,
        'powerFactor': powerFactor,
        'ambientTempC': ambientTempC,
        'terminalRatingC': terminalRatingC,
        'isNipple': isNipple,
        'clientName': clientName,
        'siteAddress': siteAddress,
      };

  factory SavedCalculation.fromJson(Map<String, dynamic> json) {
    // Raceway profile parsing with fallback to catalog
    RacewayProfile racewayProfile;
    if (json['raceway'] != null && json['raceway'] is Map<String, dynamic>) {
      racewayProfile = RacewayProfile.fromJson(json['raceway'] as Map<String, dynamic>);
    } else {
      final rType = json['racewayType'] != null
          ? RacewayType.values.firstWhere(
              (e) => e.name == json['racewayType'],
              orElse: () => RacewayType.emt,
            )
          : RacewayType.emt;
      final tSize = (json['tradeSize'] as String?) ?? '3/4';
      racewayProfile = RacewayCatalog.getProfile(rType, tSize);
    }

    final conductorsList = (json['conductors'] as List<dynamic>?)
            ?.map((c) => ConductorGroup.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    final time = json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : (json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now());

    return SavedCalculation(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Untitled Project',
      notes: json['notes'] as String? ?? '',
      timestamp: time,
      raceway: racewayProfile,
      conductors: conductorsList,
      fillResult: json['fillResult'] != null
          ? ConduitFillResult.fromJson(json['fillResult'] as Map<String, dynamic>)
          : const ConduitFillResult(
              totalConductorArea: 0.0,
              racewayInternalArea: 0.533,
              fillPercentage: 0.0,
              allowedFillPercentage: 40.0,
              allowedFillArea: 0.2132,
              isCompliant: true,
              totalConductorCount: 0,
            ),
      voltageDropResult: json['voltageDropResult'] != null
          ? VoltageDropResult.fromJson(json['voltageDropResult'] as Map<String, dynamic>)
          : null,
      deratingResult: json['deratingResult'] != null
          ? DeratingResult.fromJson(json['deratingResult'] as Map<String, dynamic>)
          : null,
      nominalVoltage: (json['nominalVoltage'] as num?)?.toDouble() ?? 120.0,
      circuitPhase: CircuitPhase.values.firstWhere(
        (e) => e.name == json['circuitPhase'],
        orElse: () => CircuitPhase.singlePhase,
      ),
      circuitLengthFeet: (json['circuitLengthFeet'] as num?)?.toDouble() ?? 100.0,
      loadCurrentAmps: (json['loadCurrentAmps'] as num?)?.toDouble() ?? 16.0,
      powerFactor: (json['powerFactor'] as num?)?.toDouble() ?? 0.90,
      ambientTempC: (json['ambientTempC'] as num?)?.toDouble() ?? 30.0,
      terminalRatingC: (json['terminalRatingC'] as num?)?.toDouble() ?? 75.0,
      isNipple: json['isNipple'] as bool? ?? false,
      clientName: json['clientName'] as String? ?? '',
      siteAddress: json['siteAddress'] as String? ?? '',
    );
  }
}

/// Abstract StorageService interface contract
abstract class StorageService implements Listenable {
  /// Global singleton instance
  static StorageService instance = SharedPreferencesStorageService();

  // Localization
  String get localeCode;
  Future<void> setLocale(String code);
  AppStrings get strings;

  // Saved Calculations
  Future<List<SavedCalculation>> getSavedCalculations();
  Future<SavedCalculation?> getCalculationById(String id);
  Future<void> saveCalculation(SavedCalculation item);
  Future<void> deleteCalculation(String id);
  Future<void> clearAll();

  // Technician Profile
  Future<TechnicianProfile> getProfile();
  Future<void> saveProfile(TechnicianProfile profile);

  // Pro Subscription & Store Monetization
  Future<bool> isProSubscriber();
  Future<void> setProSubscriber(bool value);
  Future<String?> getSubscriptionTier();
  Future<void> setSubscriptionTier(String? tier);
  Future<DateTime?> getTrialStartDate();
  Future<void> startTrial();
  Future<bool> isTrialActive();
  Future<int> getRemainingTrialDays();
  Future<bool> isDemoMode();
  Future<void> setDemoMode(bool enabled);
}

/// Concrete SharedPreferences-backed StorageService
class SharedPreferencesStorageService extends ChangeNotifier implements StorageService {
  static const String _keyCalculations = 'electronorm_saved_calculations';
  static const String _keyProfile = 'electronorm_technician_profile';
  static const String _keyIsPro = 'electronorm_is_pro_subscriber';
  static const String _keyTier = 'electronorm_subscription_tier';
  static const String _keyTrialStart = 'electronorm_trial_start_date';
  static const String _keyDemoMode = 'electronorm_demo_mode';
  static const String _keyLocale = 'electronorm_locale_code';

  final SharedPreferences? _injectedPrefs;
  String _localeCode = 'es';
  bool _localeInitialized = false;

  SharedPreferencesStorageService([this._injectedPrefs]) {
    if (_injectedPrefs != null) {
      _localeCode = _injectedPrefs.getString(_keyLocale) ?? 'es';
      _localeInitialized = true;
    }
  }

  /// Global static accessor
  static StorageService instance = SharedPreferencesStorageService();

  @override
  String get localeCode => _localeCode;

  @override
  AppStrings get strings => AppStrings.get(_localeCode);

  @override
  Future<void> setLocale(String code) async {
    if (_localeCode == code) return;
    _localeCode = code;
    _localeInitialized = true;
    final prefs = await _getPrefs();
    await prefs.setString(_keyLocale, code);
    notifyListeners();
  }

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _injectedPrefs ?? await SharedPreferences.getInstance();
    if (!_localeInitialized) {
      _localeInitialized = true;
      if (prefs.containsKey(_keyLocale)) {
        final saved = prefs.getString(_keyLocale);
        if (saved != null && saved.isNotEmpty) {
          _localeCode = saved;
        }
      }
    }
    return prefs;
  }

  // --- Saved Calculations ---

  @override
  Future<List<SavedCalculation>> getSavedCalculations() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyCalculations);
      if (jsonStr == null || jsonStr.trim().isEmpty) return [];

      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! List) return [];

      final List<SavedCalculation> results = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            results.add(SavedCalculation.fromJson(item));
          } catch (_) {
            // Gracefully ignore corrupt individual entries
          }
        }
      }
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    } catch (_) {
      // Graceful corrupted JSON recovery: return empty list
      return [];
    }
  }

  @override
  Future<SavedCalculation?> getCalculationById(String id) async {
    final all = await getSavedCalculations();
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> saveCalculation(SavedCalculation item) async {
    final all = await getSavedCalculations();
    final index = all.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      all[index] = item;
    } else {
      all.insert(0, item);
    }
    final prefs = await _getPrefs();
    final encoded = jsonEncode(all.map((e) => e.toJson()).toList());
    await prefs.setString(_keyCalculations, encoded);
  }

  @override
  Future<void> deleteCalculation(String id) async {
    final all = await getSavedCalculations();
    all.removeWhere((e) => e.id == id);
    final prefs = await _getPrefs();
    final encoded = jsonEncode(all.map((e) => e.toJson()).toList());
    await prefs.setString(_keyCalculations, encoded);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCalculations);
    await prefs.remove(_keyProfile);
    await prefs.remove(_keyIsPro);
    await prefs.remove(_keyTier);
    await prefs.remove(_keyTrialStart);
    await prefs.remove(_keyDemoMode);
    await prefs.remove(_keyLocale);
    _localeCode = 'es';
    notifyListeners();
  }

  // --- Technician Profile ---

  @override
  Future<TechnicianProfile> getProfile() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyProfile);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return TechnicianProfile.defaultProfile;
      }
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return TechnicianProfile.fromJson(decoded);
      }
      return TechnicianProfile.defaultProfile;
    } catch (_) {
      return TechnicianProfile.defaultProfile;
    }
  }

  @override
  Future<void> saveProfile(TechnicianProfile profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  // --- Pro Subscription & Store Monetization ---

  @override
  Future<bool> isProSubscriber() async {
    try {
      final isDemo = await isDemoMode();
      if (isDemo) return true;

      final prefs = await _getPrefs();
      final isPro = prefs.getBool(_keyIsPro) ?? false;
      if (isPro) return true;

      final trial = await isTrialActive();
      return trial;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setProSubscriber(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyIsPro, value);
    if (value) {
      final currentTier = prefs.getString(_keyTier);
      if (currentTier == null) {
        await prefs.setString(_keyTier, 'annual');
      }
    }
    notifyListeners();
  }

  @override
  Future<String?> getSubscriptionTier() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyTier);
  }

  @override
  Future<void> setSubscriptionTier(String? tier) async {
    final prefs = await _getPrefs();
    if (tier == null) {
      await prefs.remove(_keyTier);
    } else {
      await prefs.setString(_keyTier, tier);
    }
    notifyListeners();
  }

  @override
  Future<DateTime?> getTrialStartDate() async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_keyTrialStart);
      if (str == null) return null;
      return DateTime.tryParse(str);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> startTrial() async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyTrialStart, DateTime.now().toIso8601String());
    await prefs.setString(_keyTier, 'trial_14d');
    await prefs.setBool(_keyIsPro, true);
    notifyListeners();
  }

  @override
  Future<bool> isTrialActive() async {
    final start = await getTrialStartDate();
    if (start == null) return false;
    final elapsed = DateTime.now().difference(start);
    return elapsed.inDays < 14;
  }

  @override
  Future<int> getRemainingTrialDays() async {
    final start = await getTrialStartDate();
    if (start == null) return 0;
    final elapsed = DateTime.now().difference(start);
    final remaining = 14 - elapsed.inDays;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Future<bool> isDemoMode() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_keyDemoMode) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setDemoMode(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyDemoMode, enabled);
    if (enabled) {
      await prefs.setBool(_keyIsPro, true);
    }
    notifyListeners();
  }
}

/// Type alias for backward compatibility and semantic clarity
typedef LocalStorageService = SharedPreferencesStorageService;
