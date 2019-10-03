import 'package:absinthe_socket/absinthe_socket.dart';
import 'package:firestorm_flutter/pages/NewThreadPage.dart';
import 'package:firestorm_flutter/pages/ThreadPage.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CategoryPage extends StatefulWidget {
  final String categoryId;
  CategoryPage({final Key key, this.categoryId}) : super(key: key);

  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Map> _subscriptionThreads = [];
  List<Notifier> _notifiers = [];
  AbsintheSocket _socket;

  @override
  void initState() {
    super.initState();
    _socket = AbsintheSocket("ws://10.0.2.2:4000/socket/websocket");

    subscribeToCreateThread();
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
      _subscriptionThreads.insert(0, result["data"]["threadAdded"]);
    });
  }

  _onStart() {
    print("onStart");
  }

  void subscribeToCreateThread() {
    Observer _threadObserver = Observer(
        onAbort: _onAbort,
        onCancel: _onCancel,
        onError: _onError,
        onResult: _onResult,
        onStart: _onStart);

    Notifier notifier = _socket.send(GqlRequest(
        operation:
            "subscription ThreadAdded { threadAdded(categoryId: \"${widget.categoryId}\") { id, title } }"));
    notifier.observe(_threadObserver);
    _notifiers.add(notifier);
  }

  @override
  Widget build(BuildContext context) {
    String categoryQuery = """
    query CategoryQuery(\$id: ID!){
      category(id: \$id){
        id
        title
        threads {
          id
          title
          __typename
        }
        __typename
      }
    }
    """;
    return Query(
        options: QueryOptions(
            document: categoryQuery, variables: {"id": widget.categoryId}),
        builder: (QueryResult result, { VoidCallback refetch, FetchMore fetchMore }) {
          Widget body = _resultBody(result);
          Widget title = _resultTitle(result);

          return Scaffold(
              appBar: AppBar(title: title),
              body: body,
              floatingActionButton: FloatingActionButton(
                  tooltip: 'Add',
                  child: new Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (builder) =>
                            NewThreadPage(categoryId: widget.categoryId)));
                  }));
        });
  }

  Widget _resultBody(QueryResult result) {
    if (result.errors != null) {
      return Text('Error');
    }
    if (result.loading) {
      return Text('Loading...');
    }

    if (result.data['category']['threads'] == null) {
      return Text('Error');
    }
    return ThreadsList(
        threads: result.data['category']['threads']
          ..insertAll(0, _subscriptionThreads));
  }

  Widget _resultTitle(QueryResult result) {
    if (result.errors != null) {
      return Text('Error');
    }
    if (result.loading) {
      return Text('Loading...');
    }
    return Text(result.data['category']['title']);
  }
}

class ThreadsList extends StatelessWidget {
  ThreadsList({@required this.threads});

  final List threads;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];

          return ListTile(
              title: Text(thread['title']),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return ThreadPage(threadId: thread['id']);
                }));
              });
        });
  }
}
