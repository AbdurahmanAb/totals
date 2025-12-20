import 'package:flutter/material.dart';
import 'package:totals/models/profile.dart';
import 'package:totals/repositories/profile_repository.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final ProfileRepository _profileRepo = ProfileRepository();
  List<Profile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final profiles = await _profileRepo.getProfiles();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    }
  }

  Future<void> _createProfile() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CreateProfileDialog(),
    );

    if (result != null && result.isNotEmpty) {
      final newProfile = Profile(
        name: result,
        createdAt: DateTime.now(),
      );
      await _profileRepo.saveProfile(newProfile);
      _loadProfiles();
    }
  }

  Future<void> _renameProfile(Profile profile) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RenameProfileDialog(currentName: profile.name),
    );

    if (result != null && result.isNotEmpty && result != profile.name) {
      final updatedProfile = profile.copyWith(
        name: result,
        updatedAt: DateTime.now(),
      );
      await _profileRepo.saveProfile(updatedProfile);
      _loadProfiles();
    }
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${profile.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && profile.id != null) {
      await _profileRepo.deleteProfile(profile.id!);
      _loadProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groupColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Create Profile Button
                Container(
                  decoration: BoxDecoration(
                    color: groupColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _createProfile,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Create Profile',
                              style: TextStyle(
                                fontSize: 17,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Profiles List
                if (_profiles.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No profiles yet',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: groupColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _profiles.length; i++) ...[
                          _buildProfileItem(
                            context: context,
                            profile: _profiles[i],
                            isFirst: i == 0,
                            isLast: i == _profiles.length - 1,
                          ),
                          if (i < _profiles.length - 1)
                            Divider(
                              height: 0.5,
                              thickness: 0.5,
                              indent: 50,
                              endIndent: 16,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildProfileItem({
    required BuildContext context,
    required Profile profile,
    required bool isFirst,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final initials = _getInitials(profile.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _renameProfile(profile),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile.name,
                  style: TextStyle(
                    fontSize: 17,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () => _renameProfile(profile),
              ),
              if (_profiles.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  onPressed: () => _deleteProfile(profile),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _CreateProfileDialog extends StatefulWidget {
  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Profile'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Profile Name',
            hintText: 'Enter profile name',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a profile name';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _RenameProfileDialog extends StatefulWidget {
  final String currentName;

  const _RenameProfileDialog({required this.currentName});

  @override
  State<_RenameProfileDialog> createState() => _RenameProfileDialogState();
}

class _RenameProfileDialogState extends State<_RenameProfileDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Profile'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Profile Name',
            hintText: 'Enter profile name',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a profile name';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

