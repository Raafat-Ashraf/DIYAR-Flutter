class BackendMessageTranslator {
  const BackendMessageTranslator._();

  static String translate(String message, {String? code, String? field}) {
    final codeTranslation = code == null ? null : _byCode[code.trim()];
    if (codeTranslation != null) return codeTranslation;

    final normalized = _normalize(message);
    final exactTranslation = _byMessage[normalized];
    if (exactTranslation != null) return exactTranslation;

    final fieldName = _fieldName(field) ?? _fieldFromMessage(message);
    final dynamicTranslation = _dynamicTranslation(normalized, fieldName);
    if (dynamicTranslation != null) return dynamicTranslation;

    return message;
  }

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[،.]+$'), '')
        .toLowerCase();
  }

  static String? _dynamicTranslation(String normalized, String? fieldName) {
    if (normalized.contains('must not be empty') ||
        normalized.contains('is required') ||
        normalized.contains('notemptyvalidator')) {
      return fieldName == null ? 'هذا الحقل مطلوب.' : '$fieldName مطلوب.';
    }

    if (normalized.contains('not a valid email') ||
        normalized.contains('not a valid e-mail') ||
        normalized.contains('emailaddressvalidator')) {
      return 'أدخل بريدًا إلكترونيًا صحيحًا.';
    }

    if (normalized.contains('must be between 3 and 100 characters')) {
      return fieldName == null
          ? 'يجب أن يكون طول هذا الحقل بين 3 و100 حرف.'
          : 'يجب أن يكون $fieldName بين 3 و100 حرف.';
    }

    if (normalized.contains('must be between 5 and 100 characters')) {
      return fieldName == null
          ? 'يجب أن يكون طول هذا الحقل بين 5 و100 حرف.'
          : 'يجب أن يكون $fieldName بين 5 و100 حرف.';
    }

    if (normalized.contains('must be 11 digits long')) {
      return 'رقم الهاتف يجب أن يتكون من 11 رقمًا.';
    }

    if (normalized.contains('must start with 010') ||
        normalized.contains('must start with 010, 011, 012, or 015')) {
      return 'رقم الهاتف يجب أن يبدأ بـ 010 أو 011 أو 012 أو 015.';
    }

    if (normalized.contains('password') &&
        normalized.contains('at least 8') &&
        (normalized.contains('lowercase') ||
            normalized.contains('uppercase') ||
            normalized.contains('nonalphanumeric'))) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف وتحتوي على حرف كبير وحرف صغير ورقم ورمز خاص.';
    }

    if (normalized.contains('passwords must be at least')) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف.';
    }

    if (normalized.contains('passwords must have at least one digit')) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل.';
    }

    if (normalized.contains('passwords must have at least one lowercase')) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل.';
    }

    if (normalized.contains('passwords must have at least one uppercase')) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل.';
    }

    if (normalized.contains(
      'passwords must have at least one non alphanumeric',
    )) {
      return 'كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل.';
    }

    if (normalized.contains('passwords do not match')) {
      return 'كلمتا المرور غير متطابقتين.';
    }

    if (normalized.contains('is already taken') ||
        normalized.contains('already exists')) {
      if (normalized.contains('email')) {
        return 'يوجد حساب آخر بنفس البريد الإلكتروني.';
      }
      if (normalized.contains('phone')) {
        return 'رقم الهاتف مستخدم بالفعل.';
      }
      return 'هذه البيانات مستخدمة بالفعل.';
    }

    if (normalized.contains('unable to create user')) {
      return 'تعذر إنشاء الحساب. راجع البيانات وحاول مرة أخرى.';
    }

    if (normalized.contains('unable to login user')) {
      return 'تعذر تسجيل الدخول باستخدام هذا الحساب.';
    }

    return null;
  }

  static String? _fieldFromMessage(String message) {
    final match = RegExp(r"'([^']+)'").firstMatch(message);
    return _fieldName(match?.group(1));
  }

  static String? _fieldName(String? field) {
    if (field == null || field.trim().isEmpty) return null;
    final normalized = field.trim().toLowerCase();
    return _fields[normalized] ?? _fields[normalized.replaceAll(' ', '')];
  }

  static const _fields = {
    'firstname': 'الاسم الأول',
    'first name': 'الاسم الأول',
    'lastname': 'اسم العائلة',
    'last name': 'اسم العائلة',
    'email': 'البريد الإلكتروني',
    'phonenumber': 'رقم الهاتف',
    'phone number': 'رقم الهاتف',
    'password': 'كلمة المرور',
    'confirmpassword': 'تأكيد كلمة المرور',
    'confirm password': 'تأكيد كلمة المرور',
    'otp': 'رمز التحقق',
    'newpassword': 'كلمة المرور الجديدة',
    'new password': 'كلمة المرور الجديدة',
    'username': 'اسم المستخدم',
    'user name': 'اسم المستخدم',
    'providertype': 'نوع الحساب',
    'provider type': 'نوع الحساب',
    'governorateid': 'المحافظة',
    'governorate id': 'المحافظة',
    'bio': 'النبذة',
    'companyname': 'اسم الشركة',
    'company name': 'اسم الشركة',
    'yearsofexperience': 'سنوات الخبرة',
    'years of experience': 'سنوات الخبرة',
    'officialdocumentrequests': 'المستندات',
    'documentname': 'اسم المستند',
    'document name': 'اسم المستند',
    'document': 'الملف',
  };

  static const _byCode = {
    'User.InvalidCredentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'User.DisabledUser': 'هذا الحساب معطل. برجاء التواصل مع المسؤول.',
    'User.LockedUser': 'هذا الحساب مقفل. برجاء التواصل مع المسؤول.',
    'User.InvalidJwtToken': 'جلسة الدخول غير صالحة.',
    'User.InvalidRefreshToken': 'جلسة الدخول غير صالحة.',
    'User.DuplicatedEmail': 'يوجد حساب آخر بنفس البريد الإلكتروني.',
    'User.EmailNotConfirmed': 'البريد الإلكتروني غير مؤكد.',
    'User.PhoneNumberAlreadyExists': 'رقم الهاتف مستخدم بالفعل.',
    'User.InvalidCode': 'رمز التحقق غير صحيح أو منتهي الصلاحية.',
    'User.DuplicatedConfirmation': 'تم تأكيد البريد الإلكتروني من قبل.',
    'User.NotFound': 'المستخدم غير موجود.',
    'User.InvalidRoles': 'الدور المحدد غير صالح.',
    'User.NotBranchRole': 'يجب أن يمتلك المستخدم دور الفرع.',
    'PasswordTooShort': 'كلمة المرور يجب ألا تقل عن 8 أحرف.',
    'PasswordRequiresNonAlphanumeric':
        'كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل.',
    'PasswordRequiresDigit': 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل.',
    'PasswordRequiresLower':
        'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل.',
    'PasswordRequiresUpper':
        'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل.',
    'DuplicateUserName': 'يوجد حساب آخر بنفس البريد الإلكتروني.',
    'DuplicateEmail': 'يوجد حساب آخر بنفس البريد الإلكتروني.',
    'InvalidUserName': 'البريد الإلكتروني غير صالح كاسم مستخدم.',
    'InvalidEmail': 'أدخل بريدًا إلكترونيًا صحيحًا.',
    'Google': 'تعذر تسجيل الدخول باستخدام Google.',
    'User.InvalidProviderType': 'نوع الحساب المحدد غير صالح.',
    'User.RoleAlreadySelected': 'تم اختيار نوع الحساب من قبل.',
    'Governorate.InvalidGovernorateId': 'المحافظة المحددة غير صالحة.',
  };

  static const _byMessage = {
    'invalid email/password': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'disabled user, please contact your administrator':
        'هذا الحساب معطل. برجاء التواصل مع المسؤول.',
    'locked user, please contact your administrator':
        'هذا الحساب مقفل. برجاء التواصل مع المسؤول.',
    'invalid jwt token': 'جلسة الدخول غير صالحة.',
    'invalid refresh token': 'جلسة الدخول غير صالحة.',
    'another user with the same email is already exists':
        'يوجد حساب آخر بنفس البريد الإلكتروني.',
    'email is not confirmed': 'البريد الإلكتروني غير مؤكد.',
    'phone number already exists': 'رقم الهاتف مستخدم بالفعل.',
    'invalid code': 'رمز التحقق غير صحيح أو منتهي الصلاحية.',
    'email already confirmed': 'تم تأكيد البريد الإلكتروني من قبل.',
    'user is not found': 'المستخدم غير موجود.',
    'invalid roles': 'الدور المحدد غير صالح.',
    'user must have the branch role': 'يجب أن يمتلك المستخدم دور الفرع.',
    'email is required': 'البريد الإلكتروني مطلوب.',
    'password is required': 'كلمة المرور مطلوبة.',
    'invalid phone number, must start with 010, 011, 012, or 015':
        'رقم الهاتف يجب أن يبدأ بـ 010 أو 011 أو 012 أو 015.',
    'invalid phone number, must be 11 digits long':
        'رقم الهاتف يجب أن يتكون من 11 رقمًا.',
    'password should be at least 8 digits and should contains lowercase, nonalphanumeric and uppercase':
        'كلمة المرور يجب ألا تقل عن 8 أحرف وتحتوي على حرف كبير وحرف صغير ورقم ورمز خاص.',
    'passwords do not match. please make sure both password fields are identical':
        'كلمتا المرور غير متطابقتين.',
    'account created successfully, please check your email to confirm your email address':
        'تم إنشاء الحساب بنجاح. برجاء مراجعة بريدك الإلكتروني لتأكيد الحساب.',
    'email confirmed successfully': 'تم تأكيد البريد الإلكتروني بنجاح.',
    'email sent successfully, please check your email to confirm your email address':
        'تم إرسال البريد بنجاح. برجاء مراجعة بريدك الإلكتروني لتأكيد الحساب.',
    'email sent successfully, please check your email to reset your password':
        'تم إرسال البريد بنجاح. برجاء مراجعة بريدك الإلكتروني لإعادة تعيين كلمة المرور.',
    'password reset successfully': 'تم تغيير كلمة المرور بنجاح.',
    'one or more validation errors occurred': 'راجع البيانات المطلوبة.',
    'provider type is required': 'نوع الحساب مطلوب.',
    'provider type must be either '
            'client'
            ', '
            'supplier'
            ', or '
            'freelancer'
            '':
        'نوع الحساب يجب أن يكون عميل أو مورد أو مستقل.',
    'governorate id must be greater than 0': 'اختر محافظة صحيحة.',
    'years of experience is required for freelancers':
        'سنوات الخبرة مطلوبة للمستقل.',
    'years of experience cannot be negative':
        'سنوات الخبرة لا يمكن أن تكون أقل من صفر.',
    'suppliers must upload both tax card and commercial register documents':
        'يجب على المورد رفع البطاقة الضريبية والسجل التجاري.',
    'freelancers can upload only syndicate id or qualification documents':
        'المستقل يمكنه رفع كارنيه النقابة أو مؤهل/شهادة خبرة فقط.',
    'document name is required': 'اسم المستند مطلوب.',
    'document file is required': 'ملف المستند مطلوب.',
    'document file cannot be empty': 'ملف المستند فارغ.',
    'document file size must not exceed 10 mb':
        'حجم الملف يجب ألا يتجاوز 10 ميجابايت.',
    'invalid file extension. allowed: pdf, jpg, jpeg, png':
        'امتداد الملف غير صالح. المسموح PDF أو JPG أو JPEG أو PNG.',
    'invalid file type. allowed: pdf and images only':
        'نوع الملف غير صالح. المسموح PDF أو صور فقط.',
  };
}
