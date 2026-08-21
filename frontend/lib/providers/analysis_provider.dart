import 'package:flutter/material.dart';
import '../models/risk.dart';
import '../models/trigger.dart';
import '../models/prediction.dart';
import '../models/ocular_analysis.dart';
import '../services/analysis_service.dart';
import '../services/prediction_service.dart';
import '../services/ocular_service.dart';
import '../services/api_client.dart';

class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService;
  final PredictionService _predictionService;
  final OcularService _ocularService;

  RiskAnalysis? _riskAnalysis;
  MLPredictionResult? _latestPrediction;
  PredictionComparisonResult? _comparisonResult;
  OcularAnalysisResult? _latestOcularAnalysis;

  List<TriggerAssociation> _triggers = [];
  List<RiskHistoryItem> _history = [];
  List<Map<String, dynamic>> _mlHistory = [];
  Map<String, dynamic>? _combinedData;

  bool _isLoadingRisk = false;
  bool _isLoadingTriggers = false;
  bool _isLoadingHistory = false;
  bool _isLoadingPrediction = false;
  bool _isLoadingOcular = false;

  String? _riskErrorMessage;
  String? _triggerErrorMessage;
  String? _predictionErrorMessage;
  String? _ocularErrorMessage;

  AnalysisProvider(
    this._analysisService, {
    PredictionService? predictionService,
    OcularService? ocularService,
  })  : _predictionService = predictionService ?? PredictionService(ApiClient()),
        _ocularService = ocularService ?? OcularService(ApiClient());

  RiskAnalysis? get riskAnalysis => _riskAnalysis;
  MLPredictionResult? get latestPrediction => _latestPrediction;
  PredictionComparisonResult? get comparisonResult => _comparisonResult;
  OcularAnalysisResult? get latestOcularAnalysis => _latestOcularAnalysis;
  List<TriggerAssociation> get triggers => _triggers;
  List<RiskHistoryItem> get history => _history;
  List<Map<String, dynamic>> get mlHistory => _mlHistory;
  Map<String, dynamic>? get combinedData => _combinedData;

  bool get isLoadingRisk => _isLoadingRisk;
  bool get isLoadingTriggers => _isLoadingTriggers;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingPrediction => _isLoadingPrediction;
  bool get isLoadingOcular => _isLoadingOcular;

  String? get riskErrorMessage => _riskErrorMessage;
  String? get triggerErrorMessage => _triggerErrorMessage;
  String? get predictionErrorMessage => _predictionErrorMessage;
  String? get ocularErrorMessage => _ocularErrorMessage;

  Future<void> fetchDashboardData() async {
    await Future.wait([
      fetchRiskAnalysis(),
      fetchTriggers(),
      fetchCombinedData(),
      fetchMlHistory(),
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

  Future<void> fetchMlHistory() async {
    try {
      _mlHistory = await _predictionService.getHistory();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchCombinedData() async {
    try {
      _combinedData = await _analysisService.getCombinedData();
      notifyListeners();
    } catch (_) {}
  }

  // --- Ocular CV Processing ---
  Future<OcularAnalysisResult?> analyzeOcularCapture({
    required List<int> bytes,
    required String filename,
    bool isVideo = false,
  }) async {
    _isLoadingOcular = true;
    _ocularErrorMessage = null;
    notifyListeners();

    try {
      if (isVideo) {
        _latestOcularAnalysis = await _ocularService.analyzeVideoBytes(bytes, filename);
      } else {
        _latestOcularAnalysis = await _ocularService.analyzeImageBytes(bytes, filename);
      }
      return _latestOcularAnalysis;
    } on ApiException catch (e) {
      _ocularErrorMessage = e.message;
      return null;
    } catch (e) {
      _ocularErrorMessage = 'Ocular analysis failed: $e';
      return null;
    } finally {
      _isLoadingOcular = false;
      notifyListeners();
    }
  }

  // --- Canonical ML Prediction Generation ---
  Future<MLPredictionResult?> runCanonicalPrediction({
    required Map<String, dynamic> canonicalFeatures,
    String? engine,
  }) async {
    _isLoadingPrediction = true;
    _predictionErrorMessage = null;
    notifyListeners();

    try {
      _latestPrediction = await _predictionService.generatePrediction(
        canonicalFeatures: canonicalFeatures,
        engine: engine,
      );
      await fetchMlHistory();
      return _latestPrediction;
    } on ApiException catch (e) {
      _predictionErrorMessage = e.message;
      return null;
    } catch (e) {
      _predictionErrorMessage = 'Prediction failed: $e';
      return null;
    } finally {
      _isLoadingPrediction = false;
      notifyListeners();
    }
  }

  // --- Research Comparison (ML vs Rule-Based) ---
  Future<void> compareEngines() async {
    try {
      _comparisonResult = await _predictionService.compareEngines();
      notifyListeners();
    } catch (_) {}
  }

  // --- Feedback Loop: Submit Outcome ---
  Future<bool> submitOutcomeFeedback({
    String? predictionId,
    required bool flareOccurred,
    String symptomSeverity = 'NONE',
    bool rescueMedicationUsed = false,
    bool doctorVisit = false,
    String? notes,
  }) async {
    try {
      final success = await _predictionService.submitOutcomeFeedback(
        predictionId: predictionId ?? _latestPrediction?.predictionId,
        flareOccurred: flareOccurred,
        symptomSeverity: symptomSeverity,
        rescueMedicationUsed: rescueMedicationUsed,
        doctorVisit: doctorVisit,
        notes: notes,
      );
      await fetchMlHistory();
      return success;
    } catch (_) {
      return false;
    }
  }
}
