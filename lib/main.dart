import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: "App Lista de Tarefas",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();
  var _todoList = [];
  var _lastRemoved = {};
  var _lastRemovedPos = 0;

  void _addTodo() {
    setState(() {
      _todoList.add({
        "title": _todoController.text,
        "ok": false,
      });
      _saveData();
      _todoController.text = "";
    });
  }

  Widget _buildItem(context, index) {
    var item = _todoList[index];

    return Dismissible(
      key: Key(index.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 10.0),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: CheckboxListTile(
        title: Text(item["title"]),
        value: item["ok"],
        secondary: CircleAvatar(
          child: Icon(item["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (ok) {
          setState(() {
            item["ok"] = ok;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(item);
          _lastRemovedPos = index;
          _todoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa\" ${_lastRemoved["title"]}\"Removida"),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<Null> _refresh() async {
    setState(() {
      _todoList.sort((a, b) => a.toString().compareTo(b.toString()));
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}\data.json");
    return file.writeAsString(data);
  }

  Future<String> _loadData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}\data.json");
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)),
                  controller: _todoController,
                )),
                TextButton(
                  child: Text("ADD", style: TextStyle(color: Colors.white)),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blueAccent)),
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: _buildItem),
          ))
        ],
      ),
    );
  }
}
