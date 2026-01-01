import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/program_template.dart';
import 'admin_program_template_form_view.dart';

class AdminProgramTemplatesView extends StatefulWidget {
  const AdminProgramTemplatesView({Key? key}) : super(key: key);

  @override
  State<AdminProgramTemplatesView> createState() =>
      _AdminProgramTemplatesViewState();
}

class _AdminProgramTemplatesViewState
    extends State<AdminProgramTemplatesView> {
  final AdminService _adminService = AdminService();

  List<ProgramTemplate> _templates = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _adminService.getAllProgramTemplates();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          action: SnackBarAction(
            label: 'Tekrar Dene',
            textColor: Colors.white,
            onPressed: _loadTemplates,
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<ProgramTemplate> get _filteredTemplates {
    if (_searchQuery.isEmpty) return _templates;
    final q = _searchQuery.toLowerCase();
    return _templates.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteTemplate(ProgramTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Program Şablonunu Sil'),
        content: Text(
          '"${template.name}" şablonunu silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteProgramTemplate(template.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program şablonu silindi')),
        );
        _loadTemplates();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Program ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AdminProgramTemplateFormView(),
                    ),
                  );
                  if (result == true) {
                    _loadTemplates();
                  }
                },
                tooltip: 'Yeni Program Şablonu',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTemplates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Henüz program şablonu yok'
                                : 'Arama sonucu bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTemplates,
                      child: ListView.builder(
                        itemCount: _filteredTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _filteredTemplates[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(template.name),
                              subtitle: Text(
                                '${template.totalWeeks} hafta · Haftada ${template.daysPerWeek} gün · ${template.recommendedSessionDurationMin} dk',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminProgramTemplateFormView(
                                            template: template,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadTemplates();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteTemplate(template),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}


