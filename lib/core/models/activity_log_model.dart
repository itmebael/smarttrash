

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActivityLogModel {
  final String id;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String action; // INSERT, UPDATE, DELETE
  final String entityType; // 'user', 'trashcan', 'task', 'notification'
  final String? entityId;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    this.userId,
    this.userName,
    this.userEmail,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    // Handle both snake_case (from database) and camelCase (from app)
    final createdAtStr = map['created_at'] ?? map['createdAt'];
    
    // Handle user relation if present
    final user = map['users'];
    String? userName;
    String? userEmail;
    
    if (user != null) {
      if (user is Map) {
        userName = user['name']?.toString();
        userEmail = user['email']?.toString();
      }
    }

    return ActivityLogModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString(),
      userName: userName ?? map['user_name']?.toString(),
      userEmail: userEmail ?? map['user_email']?.toString(),
      action: map['action']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? map['entityType']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? map['entityId']?.toString(),
      details: map['details'],
      ipAddress: map['ip_address']?.toString() ?? map['ipAddress']?.toString(),
      userAgent: map['user_agent']?.toString() ?? map['userAgent']?.toString(),
      createdAt: createdAtStr != null 
          ? (createdAtStr is DateTime 
              ? createdAtStr 
              : DateTime.parse(createdAtStr.toString()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionText {
    switch (action.toUpperCase()) {
      case 'INSERT':
        return 'Created';
      case 'UPDATE':
        return 'Updated';
      case 'DELETE':
        return 'Deleted';
      default:
        return action;
    }
  }

  String get entityTypeText {
    switch (entityType.toLowerCase()) {
      case 'users':
        return 'User';
      case 'trashcans':
        return 'Trashcan';
      case 'tasks':
        return 'Task';
      case 'notifications':
        return 'Notification';
      default:
        return entityType;
    }
  }

  IconData get actionIcon {
    switch (action.toUpperCase()) {
      case 'INSERT':
        return Icons.add_circle;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color get actionColor {
    switch (action.toUpperCase()) {
      case 'INSERT':
        return AppTheme.successGreen;
      case 'UPDATE':
        return AppTheme.secondaryBlue;
      case 'DELETE':
        return AppTheme.dangerRed;
      default:
        return AppTheme.neutralGray;
    }
  }
}

