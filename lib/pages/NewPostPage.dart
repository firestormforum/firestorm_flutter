import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class NewPostPage extends StatefulWidget {
  final String threadId;
  NewPostPage({final Key key, @required this.threadId}) : super(key: key);

  @override
  _NewPostPageState createState() {
    return _NewPostPageState();
  }
}

class _NewPostPageState extends State<NewPostPage> {
  final List<Widget> _myTabs = [Tab(text: "Edit"), Tab(text: "Preview")];
  final TextEditingController _bodyController = TextEditingController();
  String _body = "";

  @override
  initState() {
    super.initState();

    _bodyController.addListener(_updateBody);
  }

  @override
  dispose() {
    _bodyController.removeListener(_updateBody);
    _bodyController.dispose();
    super.dispose();
  }

  void _updateBody() => setState(() => _body = _bodyController.text);

  @override
  Widget build(BuildContext context) {
    String createPostMutation = """
    mutation CreatePost(\$threadId: ID!, \$body: String!){
      createPost(threadId: \$threadId, body: \$body){
        id
        body
        insertedAt
        user {
          id
          name
          avatarUrl
          __typename
        }
        __typename
      }
    }
    """;

    return Mutation(
        options: MutationOptions(document: createPostMutation),
        onCompleted: _onCompleted,
        builder: (RunMutation createPost, QueryResult result) =>
            DefaultTabController(
                length: _myTabs.length,
                child: Scaffold(
                  appBar: AppBar(
                      title: Text('New Post'), bottom: TabBar(tabs: _myTabs)),
                  floatingActionButton: FloatingActionButton(
                      tooltip: 'Send',
                      child: new Icon(Icons.send),
                      onPressed: () {
                        createPost(
                            {"threadId": widget.threadId, "body": _body});
                      }),
                  body: TabBarView(children: [
                    _Edit(bodyController: _bodyController),
                    _Preview(body: _body)
                  ]),
                )));
  }

  _onCompleted(QueryResult result) {
    if (result.hasErrors) {
      debugPrint(result.errors.toString());
      return null;
    }
    Navigator.of(context).pop();
  }
}

class _Edit extends StatelessWidget {
  final TextEditingController bodyController;

  _Edit({Key key, @required this.bodyController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.all(32.0), children: [
      TextField(
        controller: bodyController,
        maxLines: null,
        decoration: null,
      )
    ]);
  }
}

class _Preview extends StatelessWidget {
  final String body;

  _Preview({Key key, @required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Markdown(data: body);
  }
}
