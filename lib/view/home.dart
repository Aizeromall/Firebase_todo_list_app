import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list_app/model/todo.dart';
import 'package:firebase_todo_list_app/view/delete_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  // Home 화면의 상태를 생성한다.
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController titleController = TextEditingController();

  @override
  // 화면이 종료될 때 입력 컨트롤러를 해제한다.
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  // Todo 목록, 삭제 목록 이동 버튼, 추가 버튼을 화면에 만든다.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo Lists'),
        actions: [
          IconButton(
            onPressed: () => Get.to(DeletePage()),
            icon: Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: () => _showDialog(),
            icon: Icon(Icons.add_outlined),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('todo')
            .orderBy('datetime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Todo 목록을 불러오지 못했습니다.'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final documents = snapshot.data!.docs;
          return ListView(
            padding: EdgeInsets.all(12),
            children: documents.map((e) => buildItemWidget(e)).toList(),
          );
        },
      ),
    );
  } // build

  // Firestore 문서를 Slidable 기능이 있는 Todo 카드로 만든다.
  Widget buildItemWidget(DocumentSnapshot doc) {
    final todo = Todo(
      code: doc['code'],
      title: doc['title'],
      date: getDate(doc['datetime']),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: BehindMotion(),
          children: [
            SlidableAction(
              backgroundColor: Colors.red,
              icon: Icons.delete_forever,
              label: '삭제',
              onPressed: (context) => deleteAction(doc.id, todo),
            ),
          ],
        ),
        child: Card(
          child: ListTile(
            leading: Icon(Icons.calendar_today_outlined),
            title: Text(todo.title),
            subtitle: Text(todo.date),
          ),
        ),
      ),
    );
  } // buildItemWidget

  // todo 컬렉션에 입력한 내용과 오늘 날짜를 저장한다.
  Future<void> insertAction() async {
    if (titleController.text.trim().isEmpty) {
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final todoCollection = firestore.collection('todo');
    final counterDocument = firestore.collection('todoCounter').doc('number');
    final currentTodos = await todoCollection.get();
    final lastTodoCode = getLastCode(currentTodos.docs);

    await firestore.runTransaction((transaction) async {
      final counter = await transaction.get(counterDocument);
      final lastCode = counter.exists
          ? (counter.data()?['lastCode'] as int? ?? lastTodoCode)
          : lastTodoCode;
      final nextCode = lastCode + 1;
      final document = todoCollection.doc();

      transaction.set(counterDocument, {'lastCode': nextCode});
      transaction.set(document, {
        'code': nextCode.toString(),
        'title': titleController.text.trim(),
        'datetime': Timestamp.now(),
      });
    });
    titleController.clear();
    Get.back();
  }

  // 컬렉션 문서에서 가장 큰 code 번호를 찾아 반환한다.
  int getLastCode(List<QueryDocumentSnapshot> documents) {
    var lastCode = 0;
    for (final document in documents) {
      final code = int.tryParse(document['code'].toString()) ?? 0;
      if (code > lastCode) {
        lastCode = code;
      }
    }
    return lastCode;
  }

  // 삭제 카드는 tododelete에 저장한 후 todo에서 삭제한다.
  Future<void> deleteAction(String documentId, Todo todo) async {
    final firestore = FirebaseFirestore.instance;
    final deleteCollection = firestore.collection('tododelete');
    final counterDocument = firestore
        .collection('todoDeleteCounter')
        .doc('number');
    final currentDeletes = await deleteCollection.get();
    final lastDeleteCode = getLastCode(currentDeletes.docs);

    await firestore.runTransaction((transaction) async {
      final counter = await transaction.get(counterDocument);
      final lastCode = counter.exists
          ? (counter.data()?['lastCode'] as int? ?? lastDeleteCode)
          : lastDeleteCode;
      final nextCode = lastCode + 1;

      transaction.set(counterDocument, {'lastCode': nextCode});
      final document = deleteCollection.doc();
      transaction.set(document, {
        'code': nextCode.toString(),
        'title': todo.title,
        'date': todo.date,
      });
      transaction.delete(firestore.collection('todo').doc(documentId));
    });
  }

  // Firestore Timestamp를 카드에 표시할 yyyy-MM-dd 날짜 문자열로 바꾼다.
  String getDate(Timestamp datetime) {
    final date = datetime.toDate();
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // 새 Todo 제목을 입력받는 다이얼로그를 표시한다.
  void _showDialog() {
    Get.defaultDialog(
      title: 'Todo List',
      middleText: '',
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(labelText: '추가할 내용'),
          onSubmitted: (value) => insertAction(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            titleController.clear();
            Get.back();
          },
          child: Text('취소'),
        ),
        TextButton(onPressed: () => insertAction(), child: Text('추가하기')),
      ],
    );
  }
} // class
