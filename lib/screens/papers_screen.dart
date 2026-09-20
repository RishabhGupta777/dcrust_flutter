import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/paper_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/paper_card.dart';

class PapersScreen extends StatefulWidget {
  const PapersScreen({super.key});

  @override
  State<PapersScreen> createState() => _PapersScreenState();
}

class _PapersScreenState extends State<PapersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaperProvider>().fetchPapers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Papers'),
      ),
      drawer: const AppDrawer(),
      body: Consumer<PaperProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.papers.isEmpty) {
            return const Center(child: Text('No papers found.'));
          }
          
          return ListView.builder(
            itemCount: provider.papers.length,
            itemBuilder: (context, index) {
              return PaperCard(paper: provider.papers[index]);
            },
          );
        },
      ),
    );
  }
}
