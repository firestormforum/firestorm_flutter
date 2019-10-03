import 'package:absinthe_socket/absinthe_socket.dart';
import 'package:firestorm_flutter/pages/NewPostPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

String _basicDateString(DateTime datetime) {
  String year = datetime.year.toString();
  String month = datetime.month.toString().padLeft(2, '0');
  String day = datetime.day.toString().padLeft(2, '0');
  String hour = datetime.hour.toString().padLeft(2, '0');
  String minute = datetime.minute.toString().padLeft(2, '0');
  String second = datetime.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}

class ThreadPage extends StatefulWidget {
  final String threadId;

  ThreadPage({final Key key, this.threadId}) : super(key: key);

  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  List<Map> _subscriptionPosts = [];
  List<Notifier> _notifiers = [];
  AbsintheSocket _socket;

  @override
  void initState() {
    super.initState();
    _socket = AbsintheSocket("ws://10.0.2.2:4000/socket/websocket");

    subscribeToCreatePost();
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
      _subscriptionPosts.insert(0, result["data"]["postAdded"]);
    });
  }

  _onStart() {
    print("onStart");
  }

  void subscribeToCreatePost() {
    Observer _postObserver = Observer(
        onAbort: _onAbort,
        onCancel: _onCancel,
        onError: _onError,
        onResult: _onResult,
        onStart: _onStart);

    Notifier notifier = _socket.send(GqlRequest(operation: """
            subscription PostAdded { postAdded(threadId: \"${widget.threadId}\") {
              id
              body
              insertedAt
              __typename
              user {
                id
                name
                avatarUrl
                __typename
              }
            } }
            """));
    notifier.observe(_postObserver);
    _notifiers.add(notifier);
  }

  @override
  Widget build(BuildContext context) {
    String threadQuery = """
    query ThreadQuery(\$id: ID!){
      thread(id: \$id){
        id
        title
        posts {
          id
          body
          insertedAt
          user {
            id
            name
            avatarUrl
            __typename
          }
        }
        __typename
      }
    }
    """;

    return Query(
        options: QueryOptions(
            document: threadQuery, variables: {"id": widget.threadId}),
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
                            NewPostPage(threadId: widget.threadId)));
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
    return PostsList(
        posts: (result.data['thread']['posts'] ?? []) + _subscriptionPosts);
  }

  Widget _resultTitle(QueryResult result) {
    if (result.errors != null) {
      return Text('Error');
    }
    if (result.loading) {
      return Text('Loading...');
    }
    return Text(result.data['thread']['title']);
  }
}

class PostsList extends StatelessWidget {
  PostsList({this.posts});

  final List posts;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          return Post(post: post);
        });
  }
}

class Post extends StatelessWidget {
  Post({this.post});

  final Map post;

  @override
  Widget build(BuildContext context) {
    DateTime insertedAt = DateTime.parse(post['insertedAt']);

    return Card(
        child: Container(
            padding: EdgeInsets.all(16.0),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(post['user']['avatarUrl'])))),
              SizedBox(width: 20),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Text(post['user']['name'],
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Align(
                              alignment: Alignment.topRight,
                              child: Text(_basicDateString(insertedAt),
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor))))
                    ]),
                    MarkdownBody(onTapLink: _onTapLink, data: post['body'])
                  ]))
            ])));
  }

  _onTapLink(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
