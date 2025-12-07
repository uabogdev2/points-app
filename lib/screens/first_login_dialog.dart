import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';

class FirstLoginDialog extends StatefulWidget {
  final String currentName;
  final String? currentAvatarUrl;

  const FirstLoginDialog({
    super.key,
    required this.currentName,
    this.currentAvatarUrl,
  });

  @override
  State<FirstLoginDialog> createState() => _FirstLoginDialogState();
}

class _FirstLoginDialogState extends State<FirstLoginDialog> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidName(String name) {
    // Max 9 caractères, uniquement lettres et chiffres
    if (name.isEmpty || name.length > 9) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(name);
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    
    final newName = _nameController.text.trim();
    if (!_isValidName(newName)) {
      setState(() {
        _errorMessage = 'Le nom doit contenir entre 1 et 9 caractères (lettres et chiffres uniquement)';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    Navigator.of(context).pop(newName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Empêcher la fermeture
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.paperWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.gridLine.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: NotebookBackground(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Titre
                    Text(
                      'Bienvenue !',
                      style: GoogleFonts.caveat(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez votre nom de joueur',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppTheme.primaryColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Champ nom
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      maxLength: 9,
                      textCapitalization: TextCapitalization.none,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nom (max 9 caractères)',
                        hintText: 'Ex: MarcAurel, Pega225, Fred2x',
                        labelStyle: GoogleFonts.nunito(
                          color: AppTheme.primaryColor.withOpacity(0.7),
                        ),
                        hintStyle: GoogleFonts.nunito(
                          color: AppTheme.gridLine,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.gridLine,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.gridLine,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        if (!_isValidName(value.trim())) {
                          return 'Max 9 caractères, lettres et chiffres uniquement';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Message d'erreur
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (_errorMessage == null) const SizedBox(height: 16),
                    
                    // Bouton valider
                    ElevatedButton(
                      onPressed: _isLoading ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Valider',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

