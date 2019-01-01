import 'package:firestorm_flutter/models/AppModel.dart';
import 'package:firestorm_flutter/pages/CategoriesPage.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:scoped_model/scoped_model.dart';

void main() => runApp(ScopedModel<AppModel>(
    model: AppModel(),
    child: ScopedModelDescendant<AppModel>(
        builder: (context, child, model) => MyApp(token: model.token))));

class MyApp extends StatelessWidget {
  final String token;
  MyApp({this.token});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    HttpLink link;
    String graphqlUri = 'http://10.0.2.2:4000/graphql';
    if (token == null) {
      link = HttpLink(uri: graphqlUri);
    } else {
      link = HttpLink(
          uri: graphqlUri, headers: {"authorization": "Bearer $token"});
    }

    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        cache: NormalizedInMemoryCache(
            dataIdFromObject: _typenameDataIdFromObject),
        link: link,
      ),
    );

    return GraphQLProvider(
        client: client,
        child: CacheProvider(
            child: MaterialApp(
                title: 'Firestorm',
                theme: ThemeData(
                  primarySwatch: Colors.red,
                ),
                home: CategoriesPage())));
  }

  String _typenameDataIdFromObject(Object object) {
    if (object is Map<String, Object> &&
        object.containsKey('__typename') &&
        object.containsKey('id')) {
      return "${object['__typename']}/${object['id']}";
    }
    return null;
  }
}
