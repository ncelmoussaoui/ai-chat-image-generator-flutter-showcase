import 'package:uuid/uuid.dart';

/// Status of image generation
enum ImageGenerationStatus {
  generating,
  completed,
  error,
}

/// Represents a generated image result
class ImageResult {
  final String id;
  final String prompt;
  final String? revisedPrompt;
  final String? imageUrl;
  final String? localPath;
  final String? base64Data;
  final String model;
  final String size;
  final ImageGenerationStatus status;
  final String? errorMessage;
  final DateTime createdAt;

  ImageResult({
    String? id,
    required this.prompt,
    this.revisedPrompt,
    this.imageUrl,
    this.localPath,
    this.base64Data,
    required this.model,
    required this.size,
    this.status = ImageGenerationStatus.completed,
    this.errorMessage,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a generating placeholder
  factory ImageResult.generating({
    required String prompt,
    required String model,
    required String size,
  }) {
    return ImageResult(
      prompt: prompt,
      model: model,
      size: size,
      status: ImageGenerationStatus.generating,
    );
  }

  /// Create an error result
  factory ImageResult.error({
    required String prompt,
    required String model,
    required String size,
    required String errorMessage,
  }) {
    return ImageResult(
      prompt: prompt,
      model: model,
      size: size,
      status: ImageGenerationStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Copy with new values
  ImageResult copyWith({
    String? id,
    String? prompt,
    String? revisedPrompt,
    String? imageUrl,
    String? localPath,
    String? base64Data,
    String? model,
    String? size,
    ImageGenerationStatus? status,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return ImageResult(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      revisedPrompt: revisedPrompt ?? this.revisedPrompt,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      base64Data: base64Data ?? this.base64Data,
      model: model ?? this.model,
      size: size ?? this.size,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'revisedPrompt': revisedPrompt,
      'imageUrl': imageUrl,
      'localPath': localPath,
      'model': model,
      'size': size,
      'status': status.name,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ImageResult.fromJson(Map<String, dynamic> json) {
    return ImageResult(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      revisedPrompt: json['revisedPrompt'] as String?,
      imageUrl: json['imageUrl'] as String?,
      localPath: json['localPath'] as String?,
      model: json['model'] as String,
      size: json['size'] as String,
      status: ImageGenerationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ImageGenerationStatus.completed,
      ),
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isGenerating => status == ImageGenerationStatus.generating;
  bool get isCompleted => status == ImageGenerationStatus.completed;
  bool get hasError => status == ImageGenerationStatus.error;

  /// Get the display image source (prefers local, then URL)
  String? get displaySource => localPath ?? imageUrl;

  /// Check if image data is available
  bool get hasImageData =>
      imageUrl != null || localPath != null || base64Data != null;
}
