// Firestore에서 읽은 Todo 카드 한 개의 데이터를 보관한다.
class Todo {
  String code;
  String title;
  String date;

  // Todo 데이터 객체를 생성한다.
  Todo({required this.code, required this.title, required this.date});
}
