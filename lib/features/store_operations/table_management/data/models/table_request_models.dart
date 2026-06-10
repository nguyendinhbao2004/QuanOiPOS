class CreateTableRequestModel {
  final int storeId;
  final int areaId;
  final String name;
  final int capacity;

  const CreateTableRequestModel({
    required this.storeId,
    required this.areaId,
    required this.name,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'areaId': areaId,
      'name': name,
      'capacity': capacity,
    };
  }
}

class UpdateTableRequestModel {
  final int areaId;
  final String name;
  final int capacity;

  const UpdateTableRequestModel({
    required this.areaId,
    required this.name,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {'areaId': areaId, 'name': name, 'capacity': capacity};
  }
}

class UpdateTableStatusRequestModel {
  final int status;

  const UpdateTableStatusRequestModel({required this.status});

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}

class OpenTableSessionRequestModel {
  final int tableId;

  const OpenTableSessionRequestModel({required this.tableId});

  Map<String, dynamic> toJson() {
    return {'tableId': tableId};
  }
}
