import 'package:absinthe_socket/absinthe_socket.dart';
import 'package:firestorm_flutter/pages/CategoryPage.dart';
import 'package:firestorm_flutter/pages/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CategoriesPage extends StatefulWidget {
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map> _subscriptionCategories = [];
  List<Notifier> _notifiers = [];
  AbsintheSocket _socket;

  @override
  void initState() {
    super.initState();
    _socket = AbsintheSocket("ws://10.0.2.2:4000/socket/websocket");

    subscribeToCreateCategory();
  }

  @override
  void dispose() {
    _notifiers.forEach((Notifier notifier) => _socket.cancel(notifier));
    _notifiers = [];
    super.dispose();
  }

  _onAbort() {
    print("onAbort");
  }

  _onCancel() {
    print("onCancel");
  }

  _onError(error) {
    print("onError");
  }

  _onResult(result) {
    setState(() {
      _subscriptionCategories.insert(0, result["data"]["categoryAdded"]);
    });
  }

  _onStart() {
    print("onStart");
  }

  void subscribeToCreateCategory() {
    Observer _categoryObserver = Observer(
        onAbort: _onAbort,
        onCancel: _onCancel,
        onError: _onError,
        onResult: _onResult,
        onStart: _onStart);

    Notifier notifier = _socket.send(GqlRequest(
        operation:
            "subscription CategoryAdded { categoryAdded { id, title } }"));
    notifier.observe(_categoryObserver);
    _notifiers.add(notifier);
  }

  @override
  Widget build(BuildContext context) {
    String categoriesQuery = """
    query {
      categories {
        entries {
          id
          title
          __typename
        }
      }
    }
    """;

    return Query(
        options: QueryOptions(document: categoriesQuery),
        builder: (QueryResult result) {
          Widget body = _resultBody(result);

          return Scaffold(
              appBar: AppBar(title: Text('Categories'), actions: [
                IconButton(
                    icon: Icon(Icons.person),
                    tooltip: 'Login',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => LoginPage()));
                    }),
              ]),
              body: body);
        });
  }

  Widget _resultBody(QueryResult result) {
    if (result.errors != null) {
      return Text('Error');
    }
    if (result.loading) {
      return Text('Loading...');
    }
    return CategoriesList(
        categories: result.data['categories']['entries']
          ..insertAll(0, _subscriptionCategories));
  }
}

class CategoriesList extends StatelessWidget {
  const CategoriesList({Key key, @required this.categories}) : super(key: key);

  final List categories;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return ListTile(
              title: Text(category['title']),
              onTap: () {
                Navigator.of(context).push(new MaterialPageRoute(
                    builder: (context) =>
                        CategoryPage(categoryId: category['id'])));
              });
        });
  }
}
