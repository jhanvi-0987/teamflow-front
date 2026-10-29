import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LabelModel extends Equatable {
  final String id;
  final String? workspaceId;
  final String name;
  final String colorHex;

  const LabelModel({
    required this.id,
    this.workspaceId,
    required this.name,
    required this.colorHex,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF790D16);
  }

  factory LabelModel.fromJson(Map<String, dynamic> json) {
    return LabelModel(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String?,
      name: json['name'] as String,
      colorHex: json['color'] as String? ?? json['colorHex'] as String? ?? '#790D16',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'name': name,
        'color': colorHex,
      };

  @override
  List<Object?> get props => [id, workspaceId, name, colorHex];
}

