import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tunisia_places.dart';
import '../../models/society_place.dart';
import '../../models/user_account.dart';
import '../../services/auth_provider.dart';
import '../../services/queue_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluid_motion.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isRegisterMode = false;
  UserRole _selectedRole = UserRole.user;
  PlaceCategory _societyCategory = PlaceCategory.post;
  String _selectedGovernorate = 'Sousse';
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _guichetsController = TextEditingController(text: '4');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _guichetsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final queue = context.read<QueueProvider>();

    String? error;

    if (_isRegisterMode) {
      String? createdPlaceId;

      if (_selectedRole == UserRole.society) {
        final guichets = int.tryParse(_guichetsController.text.trim()) ?? 3;
        final place = await queue.addSocietyPlace(
          name: _nameController.text.trim(),
          city: _selectedGovernorate,
          address: _addressController.text.trim(),
          category: _societyCategory,
          guichetCount: guichets < 1 ? 1 : guichets,
        );
        createdPlaceId = place.id;
      }

      error = await auth.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        city: _selectedGovernorate,
        societyPlaceId: createdPlaceId,
      );

      if (error == null) {
        queue.setCustomUserLocation(
          TunisiaDirectory.governorateByName(_selectedGovernorate),
        );
      }
    } else {
      error = await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  Future<void> _loginDemo(String email, String password) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await context.read<AuthProvider>().login(
          email: email,
          password: password,
        );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transparent Feregh logo floating directly on the clean canvas
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 78,
                      height: 78,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Feregh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Know the wait before you go.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Main Form Card with smooth height animation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Clean sliding segmented mode bar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ToggleTab(
                                      label: 'Sign in',
                                      active: !_isRegisterMode,
                                      onTap: () => setState(() {
                                        _isRegisterMode = false;
                                        _errorMessage = null;
                                      }),
                                    ),
                                  ),
                                  Expanded(
                                    child: _ToggleTab(
                                      label: 'Create account',
                                      active: _isRegisterMode,
                                      onTap: () => setState(() {
                                        _isRegisterMode = true;
                                        _errorMessage = null;
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (_isRegisterMode) ...[
                              const Text(
                                'I am signing up as',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleSelectorCard(
                                      icon: Icons.person_outline_rounded,
                                      title: 'Citizen',
                                      subtitle: 'Check live queues',
                                      selected: _selectedRole == UserRole.user,
                                      onTap: () => setState(
                                        () => _selectedRole = UserRole.user,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _RoleSelectorCard(
                                      icon: Icons.storefront_outlined,
                                      title: 'Establishment',
                                      subtitle: 'Post, Hospital, Bank',
                                      selected:
                                          _selectedRole == UserRole.society,
                                      onTap: () => setState(
                                        () => _selectedRole = UserRole.society,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: _selectedRole == UserRole.society
                                      ? 'Establishment name'
                                      : 'Full name',
                                  hintText: _selectedRole == UserRole.society
                                      ? 'e.g. LA POSTE - Monastir'
                                      : 'e.g. Khalil Ben Ali',
                                  prefixIcon: Icon(
                                    _selectedRole == UserRole.society
                                        ? Icons.business_outlined
                                        : Icons.person_outline_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().length < 2) {
                                    return 'Please enter a valid name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedGovernorate,
                                decoration: const InputDecoration(
                                  labelText: 'Governorate (Tunisia)',
                                  prefixIcon: Icon(
                                    Icons.location_city_outlined,
                                    size: 20,
                                  ),
                                ),
                                items: TunisiaDirectory.governorateNames
                                    .map((gov) {
                                  return DropdownMenuItem(
                                    value: gov,
                                    child: Text(gov),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedGovernorate = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              if (_selectedRole == UserRole.society) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<PlaceCategory>(
                                        initialValue: _societyCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'Category',
                                          prefixIcon: Icon(
                                            Icons.category_outlined,
                                            size: 20,
                                          ),
                                        ),
                                        items: PlaceCategory.values.map((cat) {
                                          return DropdownMenuItem(
                                            value: cat,
                                            child: Text(cat.label),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _societyCategory = val,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _guichetsController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Guichets',
                                          prefixIcon: Icon(
                                            Icons.desk_outlined,
                                            size: 20,
                                          ),
                                        ),
                                        validator: (v) {
                                          final n =
                                              int.tryParse(v?.trim() ?? '');
                                          if (n == null || n < 1) {
                                            return 'Min 1';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Address (optional)',
                                    prefixIcon: Icon(
                                      Icons.pin_drop_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.tn',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                              ),
                              validator: (v) {
                                if (v == null || !v.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 4) {
                                  return 'At least 4 characters required';
                                }
                                return null;
                              },
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.crowdedBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.crowdedText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),
                            PressScale(
                              onTap: _isSubmitting ? null : _submit,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isRegisterMode
                                            ? 'Create account'
                                            : 'Continue',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Quiet, understated preview access buttons
                  const Text(
                    'Or explore with a demo account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PressScale(
                          onTap: _isSubmitting
                              ? null
                              : () => _loginDemo('khalil@user.tn', '123456'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 17,
                                  color: AppColors.textPrimary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Khalil (Citizen)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PressScale(
                          onTap: _isSubmitting
                              ? null
                              : () => _loginDemo('poste@society.tn', '123456'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  size: 17,
                                  color: AppColors.textPrimary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'La Poste (Staff)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? AppTheme.softShadow : const [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleSelectorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyDark.withAlpha(12) : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.navyDark : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.navyDark : AppColors.textSecondary,
              size: 21,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.navyDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
