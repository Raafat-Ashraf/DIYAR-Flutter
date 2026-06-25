import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/platform/native_document_picker.dart';
import '../../domain/entities/showcase.dart';
import '../../domain/usecases/create_showcase_use_case.dart';

part 'create_showcase_state.dart';

class CreateShowcaseCubit extends Cubit<CreateShowcaseState> {
  CreateShowcaseCubit({required this.createShowcase})
    : super(const CreateShowcaseState());

  final CreateShowcaseUseCase createShowcase;

  static const _picker = NativeDocumentPicker();
  static const _allowedFileTypes = {
    'application/pdf',
  };
  static const _maxFileSize = 10 * 1024 * 1024;

  Future<void> pickCoverImage() async {
    try {
      final picked = await _picker.pickDocument();
      if (picked == null) return;
      if (!picked.contentType.startsWith('image/')) {
        emit(state.copyWith(errorMessage: 'اختر صورة فقط.'));
        return;
      }
      if (picked.size > _maxFileSize) {
        emit(
          state.copyWith(errorMessage: 'حجم الصورة يجب ألا يتجاوز 10 ميجابايت.'),
        );
        return;
      }
      emit(state.copyWith(coverImage: picked, clearMessages: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'تعذر اختيار الصورة. حاول مرة أخرى.'));
    }
  }

  void removeCoverImage() {
    emit(state.copyWith(clearCoverImage: true));
  }

  Future<void> pickFiles() async {
    try {
      final picked = await _picker.pickMultipleDocuments();
      if (picked.isEmpty) return;

      final valid = picked
          .where(
            (doc) =>
                (doc.contentType.startsWith('image/') ||
                    _allowedFileTypes.contains(doc.contentType)) &&
                doc.size <= _maxFileSize,
          )
          .map((doc) => PickedShowcaseFile(document: doc))
          .toList();

      final files = [...state.files, ...valid];
      if (valid.length != picked.length) {
        emit(
          state.copyWith(
            files: files,
            errorMessage: 'تم تجاهل بعض الملفات (صور أو PDF فقط، وحتى 10 ميجابايت).',
          ),
        );
        return;
      }
      emit(state.copyWith(files: files, clearMessages: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'تعذر اختيار الملفات. حاول مرة أخرى.'));
    }
  }

  void removeFile(int index) {
    final files = [...state.files]..removeAt(index);
    emit(state.copyWith(files: files));
  }

  void updateFileDescription(int index, String description) {
    final files = [...state.files];
    files[index] = files[index].copyWith(description: description);
    emit(state.copyWith(files: files));
  }

  Future<void> submit({
    required ShowcaseType type,
    required String title,
    required String description,
    double? price,
  }) async {
    final coverImage = state.coverImage;

    emit(
      state.copyWith(
        status: CreateShowcaseStatus.submitting,
        clearMessages: true,
      ),
    );
    try {
      await createShowcase(
        CreateShowcaseInput(
          type: type,
          title: title,
          description: description,
          price: price,
          coverImage: coverImage == null
              ? null
              : ShowcaseLocalFile(
                  path: coverImage.path,
                  name: coverImage.name,
                  contentType: coverImage.contentType,
                ),
          files: state.files
              .map(
                (file) => ShowcaseLocalFile(
                  path: file.document.path,
                  name: file.document.name,
                  contentType: file.document.contentType,
                  description: file.description,
                ),
              )
              .toList(),
        ),
      );
      emit(
        state.copyWith(
          status: CreateShowcaseStatus.initial,
          successMessage: 'تم إنشاء العرض بنجاح.',
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: CreateShowcaseStatus.initial,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CreateShowcaseStatus.initial,
          errorMessage: 'تعذر إنشاء العرض. حاول مرة أخرى.',
        ),
      );
    }
  }
}
