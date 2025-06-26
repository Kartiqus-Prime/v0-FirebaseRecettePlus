import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _language = 'Français';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Notifications
            _buildSectionHeader('Notifications'),
            _buildSettingsCard([
              _buildSwitchTile(
                title: 'Notifications',
                subtitle: 'Activer toutes les notifications',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                icon: Icons.notifications,
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'Notifications par email',
                subtitle: 'Recevoir des emails de notification',
                value: _emailNotifications,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                } : null,
                icon: Icons.email,
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'Notifications push',
                subtitle: 'Recevoir des notifications sur l\'appareil',
                value: _pushNotifications,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                } : null,
                icon: Icons.phone_android,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Section Apparence
            _buildSectionHeader('Apparence'),
            _buildSettingsCard([
              _buildSwitchTile(
                title: 'Mode sombre',
                subtitle: 'Utiliser le thème sombre',
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                icon: Icons.dark_mode,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Langue',
                subtitle: _language,
                icon: Icons.language,
                onTap: () {
                  _showLanguageDialog();
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Section Compte
            _buildSectionHeader('Compte'),
            _buildSettingsCard([
              _buildListTile(
                title: 'Changer le mot de passe',
                subtitle: 'Modifier votre mot de passe',
                icon: Icons.lock,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Confidentialité',
                subtitle: 'Gérer vos données personnelles',
                icon: Icons.privacy_tip,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Supprimer le compte',
                subtitle: 'Supprimer définitivement votre compte',
                icon: Icons.delete_forever,
                onTap: () {
                  _showDeleteAccountDialog();
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                textColor: Colors.red,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Section À propos
            _buildSectionHeader('À propos'),
            _buildSettingsCard([
              _buildListTile(
                title: 'Version de l\'application',
                subtitle: '1.0.0',
                icon: Icons.info,
                onTap: null,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Conditions d\'utilisation',
                subtitle: 'Lire nos conditions',
                icon: Icons.description,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Politique de confidentialité',
                subtitle: 'Lire notre politique',
                icon: Icons.policy,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onChanged != null ? AppColors.textPrimary : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: onChanged != null ? AppColors.textSecondary : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.border,
      indent: 70,
      endIndent: 20,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'Français',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
