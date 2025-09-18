import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/objet.dart';
import '../services/database_service.dart';

class EditProductScreen extends StatefulWidget {
  final Objet objet;

  const EditProductScreen({super.key, required this.objet});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _commentsController = TextEditingController();
  String _selectedCategory = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _productNameController.text = widget.objet.nom;
    _quantityController.text = widget.objet.quantite.toString();
    _commentsController.text = widget.objet.commentaires ?? '';
    _selectedCategory = widget.objet.categorie ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProduct,
          ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du produit',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom de produit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une quantité';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (widget.objet.type == TypeObjet.durable) ...[
              DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Électroménager', child: Text('Électroménager')),
                  DropdownMenuItem(value: 'Mobilier', child: Text('Mobilier')),
                  DropdownMenuItem(value: 'Électronique', child: Text('Électronique')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedObjet = widget.objet.copyWith(
        nom: _productNameController.text.trim(),
        quantite: int.parse(_quantityController.text),
        commentaires: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
        categorie: _selectedCategory.isEmpty ? null : _selectedCategory,
      );

      final database = Provider.of<DatabaseService>(context, listen: false);
      await database.updateObjet(updatedObjet);

      if (mounted) {
        Navigator.of(context).pop(updatedObjet);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue lors de la mise à jour du produit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _commentsController.dispose();
    super.dispose();
  }
}
