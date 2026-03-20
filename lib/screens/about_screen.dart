import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Center(
              child: Column(
                children: [
                  // TODO: Replace with Higa Logo
                  const Icon(Icons.language, size: 60),
                  const SizedBox(height: 12),
                  const Text('Higa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Version 1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Text('Language Learning Platform', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Mission Statement
            _buildSectionTitle('Our Mission'),
            const SizedBox(height: 8),
            const Text(
              'Higa is dedicated to preserving and revitalizing the Higaonon language through innovative AI-powered learning tools. We believe that language is the heart of culture, and by making it accessible and engaging, we can help ensure that the Higaonon language thrives for generations to come.',
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),

            // Key Features
            _buildSectionTitle('Key Features'),
            _buildFeatureTile(
              icon: Icons.translate,
              title: 'Speech Translation',
              subtitle: 'Real-time translation using wav2vec 2.0 technology',
            ),
            _buildFeatureTile(
              icon: Icons.book,
              title: 'Comprehensive Dictionary',
              subtitle: 'Extensive Higaonon-English-Filipino dictionary',
            ),
            _buildFeatureTile(
              icon: Icons.school,
              title: 'Interactive Learning',
              subtitle: 'Engaging quizzes and personalized progress tracking',
            ),
            _buildFeatureTile(
              icon: Icons.favorite,
              title: 'Cultural Preservation',
              subtitle: 'Helping preserve and revitalize the Higaonon language',
            ),
            const SizedBox(height: 30),

            // Our Team
            _buildSectionTitle('Our Team'),
            _buildTeamTile(
              title: 'Development Team',
              subtitle: 'Built with care for language preservation',
            ),
            _buildTeamTile(
              title: 'Higaonon Community',
              subtitle: 'Language experts and cultural advisors',
            ),
            const SizedBox(height: 30),

            // Connect With Us
            _buildSectionTitle('Connect With Us'),
            _buildContactTile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'contact@higaononlearn.com',
              onTap: () {}, // TODO: Implement email functionality
            ),
            _buildContactTile(
              icon: Icons.code,
              title: 'GitHub',
              subtitle: 'Open Source Project',
              onTap: () {}, // TODO: Implement link to GitHub
            ),
            _buildContactTile(
              icon: Icons.alternate_email,
              title: 'Twitter',
              subtitle: '@HigaononLearn',
              onTap: () {}, // TODO: Implement link to Twitter
            ),
            const SizedBox(height: 40),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildFeatureTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }

  Widget _buildTeamTile({required String title, required String subtitle}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
    );
  }

  Widget _buildContactTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
            const Text('|'),
            TextButton(onPressed: () {}, child: const Text('Terms of Service')),
            const Text('|'),
            TextButton(onPressed: () {}, child: const Text('Licenses')),
          ],
        ),
        const SizedBox(height: 8),
        const Text('© 2024 Higa', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        const Text('Made with ❤️ for language preservation', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      ],
    );
  }
}

