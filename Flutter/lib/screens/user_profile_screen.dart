import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../screens/navbar.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final _updateInfoFormKey = GlobalKey<FormState>();
  final _updatePasswordFormKey = GlobalKey<FormState>();
  final _deleteAccountFormKey = GlobalKey<FormState>();

  Map<String, dynamic> userData = {'name': '', 'email': ''};
  Map<String, String> updateInfoForm = {'name': '', 'email': ''};
  Map<String, String> updatePasswordForm = {
    'current_password': '',
    'new_password': '',
    'password_confirmation': '',
  };
  Map<String, String> deleteAccountForm = {'password': ''};

  String? updateInfoMessage;
  String? updatePasswordMessage;
  String? deleteAccountMessage;
  String? updateInfoMessageType;
  String? updatePasswordMessageType;
  String? deleteAccountMessageType;

  bool isLoading = true;
  bool loadingUpdateInfo = false;
  bool loadingUpdatePassword = false;
  bool loadingDeleteAccount = false;

  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;
  bool showDeletePassword = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _fetchUserProfile() async {
    setState(() => isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await authService.getProfile();
      setState(() {
        userData = response['user'];
        updateInfoForm = {'name': userData['name'], 'email': userData['email']};
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _onUpdateProfile() async {
    if (_updateInfoFormKey.currentState!.validate()) {
      setState(() {
        loadingUpdateInfo = true;
        updateInfoMessage = null;
        updateInfoMessageType = null;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        await authService.updateProfile(
          updateInfoForm['name']!,
          updateInfoForm['email']!,
        );
        setState(() {
          updateInfoMessage = 'Account updated successfully!';
          updateInfoMessageType = 'success';
          userData = Map.from(updateInfoForm);
          loadingUpdateInfo = false;
        });
      } catch (e) {
        setState(() {
          updateInfoMessage =
              e.toString().contains('email')
                  ? 'Email already in use.'
                  : 'Failed to update account. Please try again.';
          updateInfoMessageType = 'error';
          loadingUpdateInfo = false;
        });
      }
    } else {
      setState(() {
        updateInfoMessage = 'Please correct the errors in the form.';
        updateInfoMessageType = 'error';
        loadingUpdateInfo = false;
      });
    }
  }

  void _onUpdatePassword() async {
    if (_updatePasswordFormKey.currentState!.validate()) {
      if (updatePasswordForm['new_password'] !=
          updatePasswordForm['password_confirmation']) {
        setState(() {
          updatePasswordMessage = 'Passwords must match.';
          updatePasswordMessageType = 'error';
          loadingUpdatePassword = false;
        });
        return;
      }
      setState(() {
        loadingUpdatePassword = true;
        updatePasswordMessage = null;
        updatePasswordMessageType = null;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        await authService.updatePassword(
          updatePasswordForm['current_password']!,
          updatePasswordForm['new_password']!,
        );
        setState(() {
          updatePasswordMessage = 'Password updated successfully!';
          updatePasswordMessageType = 'success';
          updatePasswordForm = {
            'current_password': '',
            'new_password': '',
            'password_confirmation': '',
          };
          loadingUpdatePassword = false;
        });
      } catch (e) {
        setState(() {
          updatePasswordMessage = 'Current password is incorrect.';
          updatePasswordMessageType = 'error';
          loadingUpdatePassword = false;
        });
      }
    } else {
      setState(() {
        updatePasswordMessage = 'Please correct the errors in the form.';
        updatePasswordMessageType = 'error';
        loadingUpdatePassword = false;
      });
    }
  }

  void _onDeleteAccount() async {
    if (_deleteAccountFormKey.currentState!.validate()) {
      setState(() {
        loadingDeleteAccount = true;
        deleteAccountMessage = null;
        deleteAccountMessageType = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('This will permanently delete your account.'),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Yes, delete it!'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (confirmed == true) {
        try {
          await authService.deleteAccount(deleteAccountForm['password']!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account deleted successfully!')),
            );
            setState(() {
              loadingDeleteAccount = false;
            });
          }

          await authService.clearToken();

          if (mounted) {
            GoRouter.of(context).go('/login');
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              deleteAccountMessage = 'Incorrect password. Please try again.';
              deleteAccountMessageType = 'error';
              loadingDeleteAccount = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            loadingDeleteAccount = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          deleteAccountMessage = 'Please enter your password to proceed.';
          deleteAccountMessageType = 'error';
          loadingDeleteAccount = false;
        });
      }
    }
  }

  void _togglePasswordVisibility(String field) {
    setState(() {
      if (field == 'current') showCurrentPassword = !showCurrentPassword;
      if (field == 'new') showNewPassword = !showNewPassword;
      if (field == 'confirm') showConfirmPassword = !showConfirmPassword;
      if (field == 'delete') showDeletePassword = !showDeletePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (BuildContext appBarContext) {
            return Navbar(
              onMenuPressed: () => Scaffold.of(appBarContext).openDrawer(),
            );
          },
        ),
      ),
      drawer: Navbar.buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white.withAlpha(230),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'User Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Manage your account',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  if (isLoading)
                    const Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isLoading) ...[
                    // Update Information Card
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF8F9FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update Account Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (updateInfoMessage != null)
                                  AlertMessage(
                                    message: updateInfoMessage!,
                                    isError: updateInfoMessageType == 'error',
                                    onDismiss:
                                        () => setState(() {
                                          updateInfoMessage = null;
                                          updateInfoMessageType = null;
                                        }),
                                  ),
                                Form(
                                  key: _updateInfoFormKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Name',
                                          labelStyle: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color.fromRGBO(
                                            33,
                                            150,
                                            243,
                                            0.05,
                                          ),
                                        ),
                                        initialValue: updateInfoForm['name'],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Name is required.';
                                          }
                                          if (value.length < 2) {
                                            return 'Name must be at least 2 characters long.';
                                          }
                                          return null;
                                        },
                                        onChanged:
                                            (value) =>
                                                updateInfoForm['name'] = value,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          labelStyle: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color.fromRGBO(
                                            33,
                                            150,
                                            243,
                                            0.05,
                                          ),
                                        ),
                                        initialValue: updateInfoForm['email'],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Email is required.';
                                          }
                                          if (!RegExp(
                                            r'^[^@]+@[^@]+\.[^@]+',
                                          ).hasMatch(value)) {
                                            return 'Invalid email address.';
                                          }
                                          return null;
                                        },
                                        onChanged:
                                            (value) =>
                                                updateInfoForm['email'] = value,
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.blueAccent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed:
                                              loadingUpdateInfo
                                                  ? null
                                                  : _onUpdateProfile,
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(
                                              double.infinity,
                                              50,
                                            ),
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child:
                                              loadingUpdateInfo
                                                  ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : const Text(
                                                    'Update',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Update Password Card
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF8F9FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (updatePasswordMessage != null)
                                  AlertMessage(
                                    message: updatePasswordMessage!,
                                    isError:
                                        updatePasswordMessageType == 'error',
                                    onDismiss:
                                        () => setState(() {
                                          updatePasswordMessage = null;
                                          updatePasswordMessageType = null;
                                        }),
                                  ),
                                Form(
                                  key: _updatePasswordFormKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Current Password',
                                          labelStyle: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color.fromRGBO(
                                            33,
                                            150,
                                            243,
                                            0.05,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              showCurrentPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed:
                                                () => _togglePasswordVisibility(
                                                  'current',
                                                ),
                                          ),
                                        ),
                                        obscureText: !showCurrentPassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Current Password is required.';
                                          }
                                          return null;
                                        },
                                        onChanged:
                                            (value) =>
                                                updatePasswordForm['current_password'] =
                                                    value,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'New Password',
                                          labelStyle: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color.fromRGBO(
                                            33,
                                            150,
                                            243,
                                            0.05,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              showNewPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed:
                                                () => _togglePasswordVisibility(
                                                  'new',
                                                ),
                                          ),
                                        ),
                                        obscureText: !showNewPassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'New Password is required.';
                                          }
                                          if (value.length < 8) {
                                            return 'New Password must be at least 8 characters long.';
                                          }
                                          return null;
                                        },
                                        onChanged:
                                            (value) =>
                                                updatePasswordForm['new_password'] =
                                                    value,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Confirm New Password',
                                          labelStyle: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color.fromRGBO(
                                            33,
                                            150,
                                            243,
                                            0.05,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              showConfirmPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed:
                                                () => _togglePasswordVisibility(
                                                  'confirm',
                                                ),
                                          ),
                                        ),
                                        obscureText: !showConfirmPassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Confirmation is required.';
                                          }
                                          return null;
                                        },
                                        onChanged:
                                            (value) =>
                                                updatePasswordForm['password_confirmation'] =
                                                    value,
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.blueAccent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed:
                                              loadingUpdatePassword
                                                  ? null
                                                  : _onUpdatePassword,
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(
                                              double.infinity,
                                              50,
                                            ),
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child:
                                              loadingUpdatePassword
                                                  ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : const Text(
                                                    'Update Password',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Delete Account Card
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF8F9FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (deleteAccountMessage != null)
                                  AlertMessage(
                                    message: deleteAccountMessage!,
                                    isError:
                                        deleteAccountMessageType == 'error',
                                    onDismiss:
                                        () => setState(() {
                                          deleteAccountMessage = null;
                                          deleteAccountMessageType = null;
                                        }),
                                  ),
                                Form(
                                  key: _deleteAccountFormKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText:
                                              'Enter Password to Confirm',
                                          labelStyle: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color.fromRGBO(
                                            33,
                                            150,
                                            243,
                                            0.05,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              showDeletePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed:
                                                () => _togglePasswordVisibility(
                                                  'delete',
                                                ),
                                          ),
                                        ),
                                        obscureText: !showDeletePassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Password is required.';
                                          }
                                          return null;
                                        },
                                        onChanged:
                                            (value) =>
                                                deleteAccountForm['password'] =
                                                    value,
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.red,
                                              Colors.redAccent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed:
                                              loadingDeleteAccount
                                                  ? null
                                                  : _onDeleteAccount,
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(
                                              double.infinity,
                                              50,
                                            ),
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child:
                                              loadingDeleteAccount
                                                  ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : const Text(
                                                    'Delete Account',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusing AlertMessage from previous screens
class AlertMessage extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const AlertMessage({
    super.key,
    required this.message,
    required this.isError,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red : Colors.green,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red[900] : Colors.green[900],
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: isError ? Colors.red : Colors.green,
            ),
        ],
      ),
    );
  }
}
