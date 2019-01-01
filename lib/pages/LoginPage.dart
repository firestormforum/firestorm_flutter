import 'package:firestorm_flutter/models/AppModel.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:scoped_model/scoped_model.dart';

class LoginPageState extends State<LoginPage> {
  String _email = "";
  String _password = "";
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateEmail);
    _passwordController.addListener(_updatePassword);
  }

  @override
  dispose() {
    _emailController.removeListener(_updateEmail);
    _emailController.dispose();
    _passwordController.removeListener(_updatePassword);
    _passwordController.dispose();
    super.dispose();
  }

  _updateEmail() => setState(() => _email = _emailController.text);
  _updatePassword() => setState(() => _password = _passwordController.text);

  _body() {
    return Stack(children: [
      Positioned(
        right: 24.0,
        bottom: 24.0,
        child: Container(child: _logInButton()),
      ),
      _loginForm()
    ]);
  }

  _logInButton() {
    String authenticateMutation = """
    mutation Authenticate(\$email: String!, \$password: String!){
      authenticate(email: \$email, password: \$password)
    }
    """;
    return ScopedModelDescendant<AppModel>(
        builder: (context, child, model) => Mutation(
            options: MutationOptions(document: authenticateMutation),
            onCompleted: _onCompleted(model.setToken),
            builder: (RunMutation authenticate, QueryResult result) {
              return RaisedButton(
                  color: Theme.of(context).primaryColor,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: () =>
                      authenticate({"email": _email, "password": _password}),
                  child: Text('Log in'));
            }));
  }

  _onCompleted(Function setToken) => (QueryResult result) {
        if (result.hasErrors) {
          return null;
        }
        setToken(result.data['authenticate']);
        Navigator.of(context).pop();
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).canvasColor,
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            elevation: 0.0),
        body: Builder(builder: (BuildContext context) {
          return _body();
        }));
  }

  Widget _loginForm() {
    return Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email')),
            TextField(
                obscureText: true,
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password')),
          ],
        )));
  }
}

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() {
    return LoginPageState();
  }
}
