import 'package:firestorm_flutter/pages/ThreadPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class NewThreadPage extends StatefulWidget {
  final String categoryId;
  NewThreadPage({final Key key, @required this.categoryId}) : super(key: key);

  @override
  _NewThreadPageState createState() {
    return _NewThreadPageState();
  }
}

class _NewThreadPageState extends State<NewThreadPage> {
  final List<Widget> _myTabs = [Tab(text: "Edit"), Tab(text: "Preview")];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _title = "";
  String _body = "";

  @override
  initState() {
    super.initState();

    _titleController.addListener(_updateTitle);
    _bodyController.addListener(_updateBody);
  }

  @override
  dispose() {
    _titleController.removeListener(_updateTitle);
    _bodyController.removeListener(_updateBody);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _updateTitle() => setState(() => _title = _titleController.text);
  void _updateBody() => setState(() => _body = _bodyController.text);

  @override
  Widget build(BuildContext context) {
    String createThreadMutation = """
    mutation CreateThread(\$categoryId: ID!, \$title: String!, \$body: String!){
      createThread(categoryId: \$categoryId, title: \$title, body: \$body) {
        id
        title
        posts {
          id
          body
          insertedAt
          user {
            id
            name
            __typename
          }
          __typename
        }
        __typename
      }
    }
    """;
    return Mutation(
        options: MutationOptions(document: createThreadMutation),
        onCompleted: _onCompleted,
        builder: (RunMutation createThread, QueryResult result) =>
            DefaultTabController(
                length: _myTabs.length,
                child: Scaffold(
                  appBar: AppBar(
                      title: Text('New Thread'), bottom: TabBar(tabs: _myTabs)),
                  floatingActionButton: FloatingActionButton(
                      tooltip: 'Send',
                      child: new Icon(Icons.send),
                      onPressed: () {
                        createThread({
                          "categoryId": widget.categoryId,
                          "title": _title,
                          "body": _body
                        });
                      }),
                  body: TabBarView(children: [
                    _Edit(
                        titleController: _titleController,
                        bodyController: _bodyController),
                    _Preview(title: _title, body: _body)
                  ]),
                )));
  }

  _onCompleted(QueryResult result) {
    if (result.hasErrors) {
      return null;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
      return ThreadPage(threadId: result.data["createThread"]["id"]);
    }));
  }
}

class _Edit extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;

  _Edit(
      {Key key, @required this.titleController, @required this.bodyController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.all(32.0), children: [
      TextField(
        controller: titleController,
        decoration: InputDecoration(labelText: 'Title'),
      ),
      TextField(
        controller: bodyController,
        decoration: InputDecoration(labelText: 'Create the first post'),
        maxLines: null,
      )
    ]);
  }
}

class _Preview extends StatelessWidget {
  final String title;
  final String body;

  _Preview({Key key, @required this.title, @required this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Markdown(data: "## $title\n$body");
  }
}
