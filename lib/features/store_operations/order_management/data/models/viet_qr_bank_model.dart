import '../../domain/entities/session_invoice.dart';

class VietQrBankModel {
  final VietQrBank entity;

  const VietQrBankModel(this.entity);

  factory VietQrBankModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid VietQR bank data');
    }
    final code = json['code']?.toString() ?? '';
    return VietQrBankModel(
      VietQrBank(
        bin: json['bin']?.toString() ?? '',
        code: code,
        name: json['name']?.toString() ?? '',
        shortName:
            json['shortName']?.toString() ??
            json['short_name']?.toString() ??
            code,
        logo: _logoUrl(json['logo']?.toString() ?? ''),
      ),
    );
  }

  VietQrBank toEntity() => entity;

  static List<VietQrBankModel> listFromJson(Object? json) {
    if (json is! List) return const [];
    return json.map(VietQrBankModel.fromJson).toList();
  }

  static String _logoUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host != 'cdn.vietqr.io') return value;
    return uri.replace(host: 'api.vietqr.io').toString();
  }
}
