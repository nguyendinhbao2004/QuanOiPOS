import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/dio/dio_client.dart';
import 'package:quan_oi/features/subscription/data/datasources/subscription_remote_data_source.dart';
import 'package:quan_oi/features/subscription/data/models/active_subscription_model.dart';
import 'package:quan_oi/features/subscription/data/models/service_package_model.dart';

void main() {
  group('ServicePackageModel', () {
    test('maps subscription plans payload from backend', () {
      final packages = ServicePackageModel.listFromJson(_subscriptionPlansData);

      expect(packages, hasLength(3));

      final basic = packages.first;
      expect(basic.id, '1');
      expect(basic.name, 'Basic');
      expect(basic.priceAmount, 99000);
      expect(basic.durationDays, 30);
      expect(basic.maxStores, 1);
      expect(basic.maxUsers, 5);
      expect(basic.features, [
        'Dashboard',
        'Quản lý menu cơ bản',
        'Quản lý đơn hàng',
      ]);
      expect(basic.isActive, isTrue);
      expect(basic.isDeleted, isFalse);
      expect(basic.createdAt, isNotNull);
      expect(basic.updatedAt, isNull);

      final enterprise = packages.last.toEntity();
      expect(enterprise.id, '3');
      expect(enterprise.maxStores, 999);
      expect(enterprise.maxUsers, 999);
      expect(enterprise.features, contains('Advanced analytics'));
    });

    test('maps empty package list', () {
      expect(ServicePackageModel.listFromJson(null), isEmpty);
    });
  });

  group('ActiveSubscriptionModel', () {
    test('maps active subscription payload from backend', () {
      final subscription = ActiveSubscriptionModel.fromJson(
        _activeSubscriptionData,
      );

      expect(subscription.id, 2);
      expect(subscription.accountId, 8);
      expect(subscription.planId, 3);
      expect(subscription.planName, 'Enterprise');
      expect(subscription.price, 999000);
      expect(subscription.daysRemaining, 18);
      expect(subscription.isActive, isTrue);
      expect(subscription.isExpired, isFalse);
      expect(subscription.maxStores, 999);
      expect(subscription.maxUsers, 999);
      expect(subscription.status, 'Active');
      expect(subscription.autoRenew, isTrue);
      expect(subscription.cancelAt, isNull);

      final entity = subscription.toEntity();
      expect(entity.planName, 'Enterprise');
      expect(entity.endDate, isNotNull);
    });
  });

  group('SubscriptionRemoteDataSource', () {
    test('loads plans from /subscription-plans', () async {
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': true,
                  'message': 'Lay danh sach goi subscription thanh cong',
                  'data': _subscriptionPlansData,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = SubscriptionRemoteDataSource(DioClient(dio));

      final plans = await dataSource.getSubscriptionPlans();

      expect(requestedPath, '/subscription-plans');
      expect(plans, hasLength(3));
      expect(plans.first.name, 'Basic');
    });

    test('loads active subscription from /subscriptions/active', () async {
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': true,
                  'message': 'Lấy gói thành công',
                  'data': _activeSubscriptionData,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = SubscriptionRemoteDataSource(DioClient(dio));

      final subscription = await dataSource.getActiveSubscription();

      expect(requestedPath, '/subscriptions/active');
      expect(subscription, isNotNull);
      expect(subscription!.planName, 'Enterprise');
    });

    test('loads null active subscription when user has no package', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': true,
                  'message': 'Không có gói nào',
                  'data': null,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = SubscriptionRemoteDataSource(DioClient(dio));

      final subscription = await dataSource.getActiveSubscription();

      expect(subscription, isNull);
    });
  });
}

const _subscriptionPlansData = [
  {
    'id': 1,
    'name': 'Basic',
    'price': 99000,
    'durationDays': 30,
    'maxStores': 1,
    'maxUsers': 5,
    'features':
        '{"features": ["Dashboard", "Quản lý menu cơ bản", "Quản lý đơn hàng"]}',
    'isActive': true,
    'createdAt': '2026-05-14T06:06:42.703979Z',
    'updatedAt': null,
    'isDeleted': false,
  },
  {
    'id': 2,
    'name': 'Pro',
    'price': 299000,
    'durationDays': 30,
    'maxStores': 5,
    'maxUsers': 50,
    'features':
        '{"features": ["Dashboard nâng cao", "Quản lý menu đầy đủ", "Quản lý đơn hàng", "Báo cáo chi tiết", "Quản lý kho"]}',
    'isActive': true,
    'createdAt': '2026-05-14T06:06:42.704076Z',
    'updatedAt': null,
    'isDeleted': false,
  },
  {
    'id': 3,
    'name': 'Enterprise',
    'price': 999000,
    'durationDays': 30,
    'maxStores': 999,
    'maxUsers': 999,
    'features':
        '{"features": ["Tất cả tính năng Pro", "API access", "Custom integration", "Dedicated support", "Advanced analytics"]}',
    'isActive': true,
    'createdAt': '2026-05-14T06:06:42.704076Z',
    'updatedAt': null,
    'isDeleted': false,
  },
];

const _activeSubscriptionData = {
  'id': 2,
  'accountId': 8,
  'planId': 3,
  'planName': 'Enterprise',
  'price': 999000,
  'startDate': '2026-05-14T06:06:44.031744Z',
  'endDate': '2026-06-13T06:06:44.031744Z',
  'daysRemaining': 18,
  'isActive': true,
  'isExpired': false,
  'maxStores': 999,
  'maxUsers': 999,
  'status': 'Active',
  'autoRenew': true,
  'cancelAt': null,
};
