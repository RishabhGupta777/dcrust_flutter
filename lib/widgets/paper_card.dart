import 'package:flutter/material.dart';
import '../models/paper_model.dart';
// import 'package:url_launcher/url_launcher.dart'; // Add this dependency if opening URLs

class PaperCard extends StatelessWidget {
  final PaperModel paper;

  const PaperCard({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
        title: Text(paper.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${paper.course} | Sem: ${paper.semester} | Year: ${paper.year}'),
        trailing: IconButton(
          icon: const Icon(Icons.download, color: Colors.blue),
          onPressed: () {
            // launchUrl(Uri.parse(paper.pdfUrl));
          },
        ),
      ),
    );
  }
}
