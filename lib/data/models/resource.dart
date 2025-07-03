enum ResourceType { equipment, material, tool, furniture, technology }

enum ResourceStatus { available, inUse, maintenance, damaged, reserved }

class Resource {
  final String id;
  final String name;
  final String displayName;
  final ResourceType type;
  final String description;
  final String? roomId; // Which room it belongs to
  final ResourceStatus status;
  final int quantity;
  final int availableQuantity;
  final String? imageUrl;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final Map<String, dynamic> additionalInfo;

  Resource({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    required this.description,
    this.roomId,
    this.status = ResourceStatus.available,
    required this.quantity,
    required this.availableQuantity,
    this.imageUrl,
    this.lastMaintenance,
    this.nextMaintenance,
    this.additionalInfo = const {},
  });

  // Get resource type display name in Hebrew
  String getTypeDisplayName() {
    switch (type) {
      case ResourceType.equipment:
        return 'ציוד';
      case ResourceType.material:
        return 'חומרים';
      case ResourceType.tool:
        return 'כלים';
      case ResourceType.furniture:
        return 'ריהוט';
      case ResourceType.technology:
        return 'טכנולוגיה';
    }
  }

  // Check if resource is available
  bool get isAvailable =>
      status == ResourceStatus.available && availableQuantity > 0;

  // Get availability percentage
  double get availabilityPercentage =>
      quantity > 0 ? (availableQuantity / quantity) : 0.0;

  Resource copyWith({
    String? id,
    String? name,
    String? displayName,
    ResourceType? type,
    String? description,
    String? roomId,
    ResourceStatus? status,
    int? quantity,
    int? availableQuantity,
    String? imageUrl,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Resource(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      description: description ?? this.description,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'type': type.toString().split('.').last,
      'description': description,
      'roomId': roomId,
      'status': status.toString().split('.').last,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'imageUrl': imageUrl,
      'lastMaintenance': lastMaintenance?.millisecondsSinceEpoch,
      'nextMaintenance': nextMaintenance?.millisecondsSinceEpoch,
      'additionalInfo': additionalInfo,
    };
  }

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? '',
      type: _typeFromString(map['type'] ?? 'equipment'),
      description: map['description'] ?? '',
      roomId: map['roomId'],
      status: _statusFromString(map['status'] ?? 'available'),
      quantity: map['quantity'] ?? 0,
      availableQuantity: map['availableQuantity'] ?? 0,
      imageUrl: map['imageUrl'],
      lastMaintenance: map['lastMaintenance'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMaintenance'])
          : null,
      nextMaintenance: map['nextMaintenance'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextMaintenance'])
          : null,
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }

  static ResourceType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'equipment':
        return ResourceType.equipment;
      case 'material':
        return ResourceType.material;
      case 'tool':
        return ResourceType.tool;
      case 'furniture':
        return ResourceType.furniture;
      case 'technology':
        return ResourceType.technology;
      default:
        return ResourceType.equipment;
    }
  }

  static ResourceStatus _statusFromString(String statusStr) {
    switch (statusStr) {
      case 'available':
        return ResourceStatus.available;
      case 'inUse':
        return ResourceStatus.inUse;
      case 'maintenance':
        return ResourceStatus.maintenance;
      case 'damaged':
        return ResourceStatus.damaged;
      case 'reserved':
        return ResourceStatus.reserved;
      default:
        return ResourceStatus.available;
    }
  }
}
