import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 375,
          height: 812,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 20),
                blurRadius: 40,
              ),
            ],
          ),
          padding: EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Container(
                  height: 44,
                  color: Color(0xFF1a5f3f),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('9:41', style: TextStyle(color: Colors.white)),
                      Text('••••• 100%', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  color: Color(0xFF1a5f3f),
                  padding: EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 15),
                      Text('Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  color: Color(0xFF1a5f3f),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))
                          ],
                        ),
                        child: Center(
                          child: Text('MR', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text('Md. Rahul Islam', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Student ID: 2019331042', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                      Text('Computer Science & Engineering', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('156', 'Posts'),
                          _buildStat('324', 'Following'),
                          _buildStat('892', 'Followers'),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildDetailSection(
                        'Academic Information',
                        [
                          _buildDetailItem(Icons.school, 'Year & Semester', '4th Year, 1st Semester'),
                          _buildDetailItem(Icons.grade, 'CGPA', '3.78/4.00'),
                        ],
                      ),
                      _buildDetailSection(
                        'Contact Information',
                        [
                          _buildDetailItem(Icons.email, 'Email', 'rahul.cse19@student.sust.edu'),
                          _buildDetailItem(Icons.phone, 'Phone', '+880 1712-345678'),
                        ],
                      ),
                      _buildDetailSection(
                        'Achievements',
                        [
                          _buildDetailItem(Icons.star, 'Latest Achievement', "Dean's List Fall 2023"),
                          _buildDetailItem(Icons.emoji_events, 'Competition', 'ICPC Dhaka Regional 2023'),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(child: ElevatedButton(onPressed: () {}, child: Text('Follow'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1a5f3f)))),
                            SizedBox(width: 12),
                            Expanded(child: ElevatedButton(onPressed: () {}, child: Text('Message'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black))),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: Color(0xFF1a5f3f),
                    child: Icon(Icons.edit),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(number, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, color: Color(0xFF1a5f3f)),
              SizedBox(width: 8),
              Text(title, style: TextStyle(color: Color(0xFF1a5f3f), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          SizedBox(height: 15),
          ...items
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}
