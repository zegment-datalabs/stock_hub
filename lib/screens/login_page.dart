import 'package:flutter/material.dart';
import 'package:stock_hub/actions/authentication_actions.dart';
import 'package:stock_hub/screens/homepage.dart';
import 'package:stock_hub/screens/signup_page.dart';
import 'package:stock_hub/widgets/custom_button.dart';
import 'package:stock_hub/widgets/custom_form_fields.dart';
import 'package:stock_hub/screens/forgot_password_page.dart';
import 'package:stock_hub/theme/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  void _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      final inputText = _emailPhoneController.text.trim();

      // Validate Email Format
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(inputText)) {
        setState(() {
          _emailError = 'Please enter a valid email address.';
          _isLoading = false;
        });
        return;
      }

      String? errorMessage = await loginUser(inputText, _passwordController.text.trim());

      if (errorMessage == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _emailError = errorMessage;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme, // Apply theme here
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Login'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomTextFormField(
                    controller: _emailPhoneController,
                    labelText: 'Email or Phone Number',
                    icon: Icons.email,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 10.0),
                  CustomTextFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    icon: Icons.lock,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 20.0),
                  CustomElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    isLoading: _isLoading,
                    label: 'Login',
                  ),
                  const SizedBox(height: 10.0),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color.fromARGB(255, 10, 22, 2)),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                          );
                        },
                        child: const Text('Sign Up'),
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
