import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../services/admission_service.dart';
import '../../services/students_service.dart';
import '../../services/wallet_service.dart';
import '../../models/admission_models.dart';
import '../../models/student_models.dart';
import '../../models/wallet_models.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();

  // Observable data
  final _allApplications = <Application>[].obs;
  final _relatedChildren = <Student>[].obs;
  final _wallet = Rxn<Wallet>();
  
  // Loading states
  final _isLoadingApplications = false.obs;
  final _isLoadingChildren = false.obs;
  final _isLoadingWallet = false.obs;
  final _isTakingLong = false.obs; // To show "Slow Connection"
  
  // Error states
  final _applicationsError = ''.obs;
  final _childrenError = ''.obs;
  final _walletError = ''.obs;
  final _isTimeout = false.obs;

  // Cache storage
  final _storage = GetStorage();
  static const String _childrenCacheKey = 'dashboard_children';
  static const String _appsCacheKey = 'dashboard_applications';
  static const String _walletCacheKey = 'dashboard_wallet';

  // Getters
  RxList<Application> get allApplications => _allApplications;
  RxList<Student> get relatedChildren => _relatedChildren;
  Rxn<Wallet> get wallet => _wallet;
  bool get isLoading => _isLoadingApplications.value || _isLoadingChildren.value || _isLoadingWallet.value;
  bool get isTakingLong => _isTakingLong.value;
  bool get isTimeout => _isTimeout.value;
  String get applicationsError => _applicationsError.value;
  String get childrenError => _childrenError.value;
  String get walletError => _walletError.value;

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    refreshAll();
  }

  void _loadFromCache() {
    try {
      final cachedChildren = _storage.read(_childrenCacheKey);
      final cachedApps = _storage.read(_appsCacheKey);

      if (cachedChildren != null) {
        final List<dynamic> list = cachedChildren;
        _relatedChildren.assignAll(list.map((e) => Student.fromJson(e)).toList());
        print('📊 [DASHBOARD] Loaded children from cache');
      }

      if (cachedApps != null) {
        final List<dynamic> list = cachedApps;
        _allApplications.assignAll(list.map((e) => Application.fromJson(e)).toList());
        print('📊 [DASHBOARD] Loaded applications from cache');
      }

      if (_storage.hasData(_walletCacheKey)) {
        final cachedWallet = _storage.read(_walletCacheKey);
        if (cachedWallet != null) {
          _wallet.value = Wallet.fromJson(cachedWallet);
          print('📊 [DASHBOARD] Loaded wallet from cache');
        }
      }
    } catch (e) {
      print('📊 [DASHBOARD] Error loading cache: $e');
    }
  }

  Future<void> refreshAll() async {
    _isTakingLong.value = false;
    _isTimeout.value = false;
    await Future.wait([
      loadApplications(),
      loadChildren(),
      loadWallet(),
    ]);
  }

  Future<void> loadApplications() async {
    try {
      _isLoadingApplications.value = true;
      _applicationsError.value = '';
      final response = await AdmissionService.getApplications();
      _allApplications.assignAll(response.applications);
      
      // Update cache
      _storage.write(_appsCacheKey, response.applications.map((e) => e.toJson()).toList());
    } catch (e) {
      print('📊 [DASHBOARD] Error loading applications: $e');
      if (e.toString().contains('TimeoutException')) {
        _isTimeout.value = true;
      }
      _applicationsError.value = e.toString();
    } finally {
      _isLoadingApplications.value = false;
    }
  }

  Future<void> loadChildren() async {
    try {
      _isLoadingChildren.value = true;
      _childrenError.value = '';
      final response = await StudentsService.getRelatedChildren();
      if (response.success) {
        _relatedChildren.assignAll(response.students);
        
        // Update cache
        _storage.write(_childrenCacheKey, response.students.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      print('📊 [DASHBOARD] Error loading children: $e');
      if (e.toString().contains('TimeoutException')) {
        _isTimeout.value = true;
      }
      _childrenError.value = e.toString();
    } finally {
      _isLoadingChildren.value = false;
    }
  }

  Future<void> loadWallet() async {
    try {
      _isLoadingWallet.value = true;
      _walletError.value = '';
      final response = await WalletService.getWallet();
      _wallet.value = response.wallet;
      
      // Update cache
      _storage.write(_walletCacheKey, response.wallet.toJson());
    } catch (e) {
      print('📊 [DASHBOARD] Error loading wallet: $e');
      if (e.toString().contains('TimeoutException')) {
        _isTimeout.value = true;
      }
      _walletError.value = e.toString();
    } finally {
      _isLoadingWallet.value = false;
    }
  }
}
