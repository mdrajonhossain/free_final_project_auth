import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'LoginState.dart';
import 'LoginEven.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());
      try {
        final loginData = await ApiServer().login(
          email: event.email,
          password: event.password,
          step: event.step,
        );

        // Map the API response to the state
        emit(LoginSuccess(loginData));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });

    on<LoginVerifyOtp>((event, emit) async {
      emit(LoginLoading());
      try {
        final loginData = await ApiServer().login(
          email: event.email,
          code: event.code,
          sessionToken: event.sessionToken,
          step: event.step,
        );
        emit(LoginSuccess(loginData));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });

    on<LoginSelectCompany>((event, emit) async {
      emit(LoginLoading());
      try {
        final loginData = await ApiServer().login(
          email: event.email,
          companyId: event.companyId,
          sessionToken: event.sessionToken,
          step: event.step,
        );
        emit(LoginSuccess(loginData));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
  }
}
