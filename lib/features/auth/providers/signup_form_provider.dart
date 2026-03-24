import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'signup_form_provider.freezed.dart';

@freezed
abstract class SignupFormState with _$SignupFormState {
  const factory SignupFormState({
    @Default('') String name,
    @Default('') String phone,
    String? email,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SignupFormState;
}

class SignupFormNotifier extends Notifier<SignupFormState> {
  @override
  SignupFormState build() => const SignupFormState();

  void setName(String name) => state = state.copyWith(name: name);
  void setPhone(String phone) => state = state.copyWith(phone: phone);
  void setEmail(String? email) => state = state.copyWith(email: email);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(errorMessage: error);

  bool get isValid => state.name.isNotEmpty && state.phone.isNotEmpty;
}

final signupFormProvider = NotifierProvider<SignupFormNotifier, SignupFormState>(SignupFormNotifier.new);
