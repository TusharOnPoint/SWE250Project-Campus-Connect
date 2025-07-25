class UserModel {
    final String id;
    final String name;
    final String dateOfBirth;
    final String email;
    final String university;
    final String department;
    final String course;
    final String year;
    final String semester;
    final String profileImageUrl;
    final String coverImageUrl;
    final String bio;
    

    final List<String> interests;

    UserModel({
        required this.id,
        required this.name,
        required this.email,
        this.dateOfBirth = 'Not specified',
        this.university = 'Shahjalal University of Science and Technology',
        this.department = 'Not specified',
        this.course = 'Not specified',
        this.year = 'Not specified',
        this.semester = 'Not specified',
        this.profileImageUrl = 'https://th.bing.com/th/id/OIP.6UhgwprABi3-dz8Qs85FvwHaHa?rs=1&pid=ImgDetMain',
        this.coverImageUrl = 'https://placehold.net/600x400.png',
        this.bio = 'No bio available',
        
        this.interests = const [],
    });

    factory UserModel.fromJson(Map<String, dynamic> json) {
        return UserModel(
            id: json['id'] as String,
            name: json['name'] as String,
            email: json['email'] as String,
            university: json['university'] as String? ?? 'Shahjalal University of Science and Technology',
            profileImageUrl: json['profileImageUrl'] as String? ?? 'https://th.bing.com/th/id/OIP.6UhgwprABi3-dz8Qs85FvwHaHa?rs=1&pid=ImgDetMain',
            coverImageUrl: json[ 'coverImageUrl'] as String? ?? 'https://placehold.net/600x400.png',
            bio: json['bio'] as String? ?? 'No bio available',
            department: json['department'] as String? ?? 'Not specified',
            interests: List<String>.from(json['interests'] ?? []),
            course: json['course'],
            year: json['year'],
            semester: json['semester'],
            dateOfBirth: json['dob'],
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'name': name,
            'email': email,
            'university': university,
            'profileImageUrl': profileImageUrl,
            'coverImageUrl' : coverImageUrl,
            'bio': bio,
            'department': department,
            'interests': interests,
            'course': course,
            'year': year,
            'semester': semester,
            'dob': dateOfBirth,
        };
    }
}