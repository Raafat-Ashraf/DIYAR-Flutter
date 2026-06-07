import 'package:diyar/src/core/errors/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper', () {
    test('translates ASP.NET validation error maps', () {
      final failure = ErrorMapper.fromResponseBody({
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': {
          'FirstName': ["'First Name' must not be empty."],
          'PhoneNumber': [
            'Invalid phone number, must start with 010, 011, 012, or 015.',
            'Invalid phone number, must be 11 digits long.',
          ],
          'Password': [
            'Password should be at least 8 digits and should contains Lowercase, NonAlphanumeric and Uppercase',
          ],
        },
      }, 400);

      expect(failure, isNotNull);
      expect(failure!.message, contains('الاسم الأول مطلوب'));
      expect(failure.message, contains('رقم الهاتف يجب أن يبدأ'));
      expect(failure.message, contains('كلمة المرور يجب ألا تقل'));
      expect(failure.message, isNot(contains('Invalid phone number')));
    });

    test('translates domain errors by code', () {
      final failure = ErrorMapper.fromResponseBody({
        'status': 409,
        'errors': [
          {
            'code': 'User.DuplicatedEmail',
            'description': 'Another user with the same email is already exists',
            'statusCode': 409,
          },
        ],
      }, 409);

      expect(failure, isNotNull);
      expect(failure!.message, 'يوجد حساب آخر بنفس البريد الإلكتروني.');
    });

    test('translates ASP.NET Identity password errors', () {
      final failure = ErrorMapper.fromResponseBody({
        'status': 400,
        'errors': [
          {
            'code': 'PasswordRequiresUpper',
            'description': "Passwords must have at least one uppercase ('A'-'Z').",
            'statusCode': 400,
          },
        ],
      }, 400);

      expect(failure, isNotNull);
      expect(
        failure!.message,
        'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل.',
      );
    });
  });
}
