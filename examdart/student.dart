import 'dart:convert';
import 'dart:io';

class Student {
  String id;
  String name;
  List<Subject> subjects;

  Student({required this.id, required this.name, required this.subjects});

  // Factory constructor to convert from JSON to Student object
  factory Student.fromJson(Map<String, dynamic> json) {
    var subjectList = json['subjects'] as List;
    List<Subject> subjects = subjectList.map((i) => Subject.fromJson(i)).toList();

    return Student(
      id: json['id'].toString(),
      name: json['name'],
      subjects: subjects,
    );
  }

  // Method toJson to convert from Student object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
    };
  }
}

class Subject {
  String name;
  List<int> scores;

  Subject({required this.name, required this.scores});

  // Factory constructor to convert from JSON to Subject object
  factory Subject.fromJson(Map<String, dynamic> json) {
    List<int> scoreList = List<int>.from(json['scores'].map((item) => item as int));
    return Subject(
      name: json['name'],
      scores: scoreList,
    );
  }

  // Method toJson to convert from Subject object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'scores': scores,
    };
  }

  // Get the highest score in the subject
  int getHighestScore() {
    return scores.reduce((a, b) => a > b ? a : b);
  }
}

class StudentManager {
  List<Student> students = [];

  // Load students from JSON file
  void loadStudents(String filePath) {
    final file = File(filePath);
    final jsonString = file.readAsStringSync();
    final jsonData = jsonDecode(jsonString);

    print(jsonData); // Add this line to check the structure of jsonData

    if (jsonData['students'] is List<dynamic>) {
      students = (jsonData['students'] as List<dynamic>)
          .map((item) => Student.fromJson(item))
          .toList();
    } else {
      print('Error: Invalid JSON data.');
    }
  }

  // Save students to JSON file
  void saveStudents(String filePath) {
    final file = File(filePath);
    final jsonString = jsonEncode({'students': students.map((s) => s.toJson()).toList()});
    file.writeAsStringSync(jsonString);
  }

  // Display all students
  void displayAllStudents() {
    print('--- Student List ---');
    for (var student in students) {
      print('ID: ${student.id}, Name: ${student.name}');
      print('Subjects and Scores:');
      for (var subject in student.subjects) {
        print('  ${subject.name}: ${subject.scores}');
      }
      print(''); // Blank line between students for readability
    }
  }

  // Add new student
  void addStudent(Student student) {
    students.add(student);
  }

  // Edit student information
  void editStudent(String id, {String? newName, List<Subject>? newSubjects}) {
    final student = students.firstWhere((s) => s.id == id, orElse: () => throw Exception('Student not found'));
    if (newName != null) student.name = newName;
    if (newSubjects != null) student.subjects = newSubjects;
  }

  // Search student by ID or Name
  void searchStudent({String? id, String? name}) {
    final foundStudents = students.where((s) => (id != null && s.id == id) || (name != null && s.name.contains(name!)));
    print('--- Search Results ---');
    for (var student in foundStudents) {
      print('ID: ${student.id}, Name: ${student.name}');
      print('Subjects and Scores:');
      for (var subject in student.subjects) {
        print('  ${subject.name}: ${subject.scores}');
      }
    }
  }

  // Display students with the highest score in a subject
  void displayTopStudents(String subjectName) {
    final filteredStudents = students.where((s) => s.subjects.any((subject) => subject.name == subjectName)).toList();

    if (filteredStudents.isEmpty) {
      print('No students found for the subject $subjectName.');
      return;
    }

    int maxScore = -1;
    List<Student> topStudents = [];

    for (var student in filteredStudents) {
      for (var subject in student.subjects) {
        if (subject.name == subjectName) {
          int highestScore = subject.getHighestScore();
          if (highestScore > maxScore) {
            maxScore = highestScore;
            topStudents = [student];
          } else if (highestScore == maxScore) {
            topStudents.add(student);
          }
        }
      }
    }

    print('--- Students with the highest score in $subjectName ---');
    for (var student in topStudents) {
      print('ID: ${student.id}, Name: ${student.name}, $subjectName: $maxScore');
    }
  }
}

void main() {
  final manager = StudentManager();
  final filePath = 'Student.json';
  manager.loadStudents(filePath);

  while (true) {
    print('\n--- Student Management Menu ---');
    print('1. Display all students');
    print('2. Add a student');
    print('3. Edit student information');
    print('4. Search for a student by Name or ID');
    print('5. Display students with the highest score in a subject');
    print('6. Exit');
    print('Choose an option: ');

    final choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        manager.displayAllStudents();
        break;
      case '2':
        print('Enter ID: ');
        final id = stdin.readLineSync()!;
        print('Enter Name: ');
        final name = stdin.readLineSync()!;
        print('Enter subjects and scores (format: Math 85 90 70), end with a blank line:');
        final subjects = <Subject>[];
        while (true) {
          final subjectEntry = stdin.readLineSync();
          if (subjectEntry == null || subjectEntry.isEmpty) break;
          final parts = subjectEntry.split(' ');
          final subjectName = parts[0];
          final scores = parts.sublist(1).map((s) => int.parse(s)).toList();
          subjects.add(Subject(name: subjectName, scores: scores));
        }
        final newStudent = Student(id: id, name: name, subjects: subjects);
        manager.addStudent(newStudent);
        manager.saveStudents(filePath);
        print('New student added.');
        break;
      case '3':
        print('Enter the ID of the student to edit: ');
        final id = stdin.readLineSync()!;
        print('Enter new Name (or leave blank to keep current name): ');
        final newName = stdin.readLineSync();
        print('Enter new subjects and scores (format: Math 85 90 70), end with a blank line:');
        final newSubjects = <Subject>[];
        while (true) {
          final subjectEntry = stdin.readLineSync();
          if (subjectEntry == null || subjectEntry.isEmpty) break;
          final parts = subjectEntry.split(' ');
          final subjectName = parts[0];
          final scores = parts.sublist(1).map((s) => int.parse(s)).toList();
          newSubjects.add(Subject(name: subjectName, scores: scores));
        }
        manager.editStudent(id, newName: newName, newSubjects: newSubjects.isNotEmpty ? newSubjects : null);
        manager.saveStudents(filePath);
        print('Student information updated.');
        break;
      case '4':
        print('Enter the ID or Name of the student to search: ');
        final query = stdin.readLineSync()!;
        manager.searchStudent(id: query.isNotEmpty ? query : null, name: query.isNotEmpty ? query : null);
        break;
      case '5':
        print('Enter the name of the subject to find students with the highest score: ');
        final subjectName = stdin.readLineSync()!;
        manager.displayTopStudents(subjectName);
        break;
      case '6':
        print('Exiting program.');
        return;
      default:
        print('Invalid choice, please select again.');
    }
  }
}
