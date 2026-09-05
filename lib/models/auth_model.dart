/// Teacher Profile & Session Model
class TeacherUser {
  final String uid;
  final String email;
  final String displayName;
  final String schoolName;
  final String district;
  final String photoUrl;
  final bool isEmailVerified;

  TeacherUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.schoolName,
    this.district = 'Dumka, Jharkhand',
    this.photoUrl = '',
    this.isEmailVerified = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'schoolName': schoolName,
      'district': district,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
    };
  }

  factory TeacherUser.fromJson(Map<String, dynamic> json) {
    return TeacherUser(
      uid: json['uid'] as String? ?? 'teacher_01',
      email: json['email'] as String? ?? 'teacher@palash.edu.in',
      displayName: json['displayName'] as String? ?? 'Shri Rajesh Murmu',
      schoolName: json['schoolName'] as String? ?? 'Govt. Primary Tribal School',
      district: json['district'] as String? ?? 'Dumka, Jharkhand',
      photoUrl: json['photoUrl'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? true,
    );
  }
}
