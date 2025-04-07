class Task {
  String id;
  String title;
  bool completed;
  String priority;
  DateTime? dueDate;
  Map<String, List<String>> nested; // e.g. {'Monday 9-10am': ['HW1', 'Essay2']}

  Task({
    required this.id,
    required this.title,
    this.completed = false,
    this.priority = 'Medium',
    this.dueDate,
    required this.nested,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'completed': completed,
    'priority': priority,
    'dueDate': dueDate?.toIso8601String(),
    'nested': nested,
  };

  static Task fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'],
      completed: data['completed'],
      priority: data['priority'],
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      nested: Map<String, List<String>>.from(data['nested']?.map((k, v) => MapEntry(k, List<String>.from(v))) ?? {}),
    );
  }
}
