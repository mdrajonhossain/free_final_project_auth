abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;
  final String step;
  LoginSubmitted(this.email, this.password, [this.step = "validate"]);
}

class LoginVerifyOtp extends LoginEvent {
  final String email;
  final String code;
  final String? sessionToken;
  final String step;

  LoginVerifyOtp(
    this.code, {
    required this.email,
    this.sessionToken,
    this.step = "otp",
  });
}

class LoginSelectCompany extends LoginEvent {
  final String email;
  final String? companyId;
  final String? sessionToken;
  final String step;
  LoginSelectCompany({
    required this.email,
    this.companyId,
    this.sessionToken,
    this.step = "company",
  });
}
