part of 'create_showcase_cubit.dart';

enum CreateShowcaseStatus { initial, submitting }

class PickedShowcaseFile extends Equatable {
  const PickedShowcaseFile({required this.document, this.description = ''});

  final PickedNativeDocument document;
  final String description;

  PickedShowcaseFile copyWith({String? description}) {
    return PickedShowcaseFile(
      document: document,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [document, description];
}

class CreateShowcaseState extends Equatable {
  const CreateShowcaseState({
    this.status = CreateShowcaseStatus.initial,
    this.coverImage,
    this.files = const [],
    this.errorMessage,
    this.successMessage,
  });

  final CreateShowcaseStatus status;
  final PickedNativeDocument? coverImage;
  final List<PickedShowcaseFile> files;
  final String? errorMessage;
  final String? successMessage;

  bool get isSubmitting => status == CreateShowcaseStatus.submitting;

  CreateShowcaseState copyWith({
    CreateShowcaseStatus? status,
    PickedNativeDocument? coverImage,
    bool clearCoverImage = false,
    List<PickedShowcaseFile>? files,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return CreateShowcaseState(
      status: status ?? this.status,
      coverImage: clearCoverImage ? null : (coverImage ?? this.coverImage),
      files: files ?? this.files,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    coverImage,
    files,
    errorMessage,
    successMessage,
  ];
}
