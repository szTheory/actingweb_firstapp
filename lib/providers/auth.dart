import 'dart:async';
import 'package:flutter_auth0/flutter_auth0.dart';
import 'package:first_app/models/appstate.dart';

class Auth0Client {
  var _result;
  final String clientId, domain;
  final AppStateModel appState;
  WebAuth authClient;

  Auth0Client(this.appState, {this.authClient,
        this.clientId:'PJVgy3Vh9jo7Wxl6sSUZsicE6S4TXZjB',
        this.domain:'actingweb.eu.auth0.com'}){
    if(authClient == null) {
      authClient = new WebAuth(clientId: clientId, domain: domain);
    }
  }

  Future<String> _delegationToken() async {
    if (_result == null) {
      return null;
    }
    String token = await authClient.delegate(token: _result['id_token'], api: 'firebase');
    return '''[Delegation Token Success] 
    Access Token: $token''';
  }

  Future<String> _userInfo() async {
    if (_result == null) {
      return null;
    }
    dynamic response = await authClient.userInfo(token: _result['access_token']);
    StringBuffer buffer = new StringBuffer();
    response.forEach((k, v) => buffer.writeln('$k: $v'));
    return '''[User Info] 
    ${buffer.toString()}''';
  }

  void _refreshToken() {
    authClient
        .refreshToken(refreshToken: _result['refresh_token'])
        .then((value) => print('response: $value'))
        .catchError((err) => print('Error: $err'));
  }

  void _closeSessions() {
    authClient.clearSession().catchError((err) => print(err));
  }

  Future<bool> authorize() async {
    var _result = await authClient.authorize(
      audience: 'https://$domain/userinfo',
      scope: 'openid email offline_access',
    );
    var res = Map.from(_result);
    if (res.containsKey('access_token')) {
      this.appState.logIn(res);
      return true;
    }
    return false;
  }

}