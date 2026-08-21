import 'package:flutter/material.dart';
import '../models/risk.dart';
import '../models/trigger.dart';
import '../services/analysis_service.dart';
import '../services/api_client.dart';

class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService;

  RiskAnalysis? _riskAnalysis;
  List<TriggerAssociation> _triggers = [];
  List<RiskHistoryItem> _history = [];
  Map<String, dynamic>? _combinedData;

  bool _isLoadingRisk = false;
  bool _isLoadingTriggers = false;
  bool _isLoadingHistory = false;
  String? _riskErrorMessage;
  String? _triggerErrorMessage;

  AnalysisProvider(this._analysisService);

  RiskAnalysis? get riskAnalysis => _riskAnalysis;
  List<TriggerAssociation> get triggers => _triggers;
  List<RiskHistoryItem> get history => _history;
  Map<String, dynamic>? get combinedData => _combinedData;

  bool get isLoadingRisk => _isLoadingRisk;
  bool get isLoadingTriggers => _isLoadingTriggers;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get riskErrorMessage => _riskErrorMessage;
  String? get triggerErrorMessage => _triggerErrorMessage;

  Future<void> fetchDashboardData() async {
    await Future.wait([
      fetchRiskAnalysis(),
      fetchTriggers(),
      fetchCombinedData(),
    ]);
  }

  Future<void> fetchRiskAnalysis() async {
    _isLoadingRisk = true;
    _riskErrorMessage = null;
    notifyListeners();

    try {
      _riskAnalysis = await _analysisService.getRiskAnalysis();
    } on ApiException catch (e) {
      _riskErrorMessage = e.message;
    } catch (e) {
      _riskErrorMessage = 'Unable to load risk analysis.';
    } finally {
      _isLoadingRisk = false;
      notifyListeners();
    }
  }

  Future<void> fetchTriggers() async {
    _isLoadingTriggers = true;
    _triggerErrorMessage = null;
    notifyListeners();

    try {
      _triggers = await _analysisService.getPersonalizedTriggers();
    } on ApiException catch (e) {
      _triggerErrorMessage = e.message;
    } catch (e) {
      _triggerErrorMessage = 'Unable to load personalized triggers.';
    } finally {
      _isLoadingTriggers = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _history = await _analysisService.getRiskHistory();
    } catch (_) {} finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> fetchCombinedData() async {
    try {
      _combinedData = await _analysisService.getCombinedData();
      notifyListeners();
    } catch (_) {}
  }
}
