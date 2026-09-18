import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list_app/model/todo.dart';
import 'package:flutter/material.dart';

class DeletePage extends StatefulWidget {
  const DeletePage({super.key});

  @override
  // DeletePage 화면의 상태를 생성한다.
  State<DeletePage> createState() => _DeletePageState();
}

class _DeletePageState extends State<DeletePage> {
  @override
  // 삭제된 Todo 목록을 code 번호순으로 화면에 만든다.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delete Lists')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tododelete').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('삭제 목록을 불러오지 못했습니다.'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final documents =
              snapshot.data!.docs.where((document) {
                final data = document.data() as Map<String, dynamic>;
                return data['code'].toString().isNotEmpty &&
                    data['title'].toString().isNotEmpty &&
                    data['date'].toString().isNotEmpty;
              }).toList()..sort((a, b) {
                final firstCode = int.tryParse(a['code'].toString()) ?? 0;
                final secondCode = int.tryParse(b['code'].toString()) ?? 0;
                return firstCode.compareTo(secondCode);
              });

          if (documents.isEmpty) {
            return Center(child: Text('삭제된 Todo가 없습니다.'));
          }
          return ListView(
            padding: EdgeInsets.all(12),
            children: documents.map((e) => buildItemWidget(e)).toList(),
          );
        },
      ),
    );
  } // build

  // Firestore 문서를 삭제 목록 카드로 만든다.
  Widget buildItemWidget(DocumentSnapshot doc) {
    final todo = Todo(
      code: doc['code'],
      title: doc['title'],
      date: doc['date'],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        child: ListTile(
          leading: Icon(Icons.calendar_today_outlined),
          title: Text(todo.title),
          subtitle: Text(todo.date),
        ),
      ),
    );
  } // buildItemWidget
} // class
