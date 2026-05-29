import '../../domain/entities/table_area_group.dart';
import 'area_model.dart';
import 'dining_table_model.dart';

class TableAreaGroupModel {
  final AreaModel area;
  final List<DiningTableModel> tables;

  const TableAreaGroupModel({required this.area, required this.tables});

  factory TableAreaGroupModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid table area group data');
    }

    return TableAreaGroupModel(
      area: AreaModel.fromJson(json),
      tables: DiningTableModel.listFromJson(json['tables']),
    );
  }

  static List<TableAreaGroupModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(TableAreaGroupModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['areas'] ?? json['data'];
      if (items is List) {
        return items.map(TableAreaGroupModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid table area group list data');
  }

  TableAreaGroup toEntity() {
    return TableAreaGroup(
      area: area.toEntity(),
      tables: tables.map((table) => table.toEntity()).toList(),
    );
  }
}
