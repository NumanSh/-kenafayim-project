import 'package:flutter/material.dart';
import '../../../config/themes.dart';
import '../../../services/custom_auth_service.dart';
import '../../../config/service_locator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;
  final CustomAuthService _authService = serviceLocator<CustomAuthService>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _resetSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('שחזור סיסמה'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _resetSent ? _buildSuccessMessage() : _buildResetForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'שכחת את הסיסמה?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'הזן את כתובת האימייל שלך ואנו נשלח לך קישור לאיפוס הסיסמה',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'אימייל',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'נא להזין אימייל';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'נא להזין אימייל תקין';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('שלח קישור לאיפוס סיסמה'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('חזרה להתחברות'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'הוראות לאיפוס סיסמה נשלחו',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'שלחנו הוראות לאיפוס הסיסמה לכתובת ${_emailController.text}. אנא בדוק את תיבת הדואר הנכנס שלך ועקוב אחר ההוראות.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('חזרה להתחברות'),
        ),
      ],
    );
  }
}
