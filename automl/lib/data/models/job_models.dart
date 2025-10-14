import 'package:flutter/material.dart';

@immutable
class StatusResponse {
  final String taskId;
  final String status;
  final String progress;
  final Map<String, dynamic>? result;

  const StatusResponse({
    required this.taskId,
    required this.status,
    required this.progress,
    this.result,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      taskId: json['task_id'] as String,
      status: json['status'] as String,
      progress: json['progress'] as String,
      result: json['result'] is Map ? Map<String, dynamic>.from(json['result']) : null,
    );
  }
}

@immutable
class TrainingRequest {
  final String fileId;
  final String targetColumn;
  final List<String> modelsToTrain;
  final bool hyperparameterTuning;
  final Map<String, String> preprocessingConfig;

  const TrainingRequest({
    required this.fileId,
    required this.targetColumn,
    required this.modelsToTrain,
    this.hyperparameterTuning = true,
    this.preprocessingConfig = const {
      'missing_value_strategy': 'mean',
      'scaling_strategy': 'standard',
      'encoding_strategy': 'one_hot',
    },
  });

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'target_column': targetColumn,
      'models_to_train': modelsToTrain,
      'hyperparameter_tuning': hyperparameterTuning,
      'preprocessing_config': preprocessingConfig,
    };
  }
}