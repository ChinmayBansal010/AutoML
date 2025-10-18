import 'package:flutter/material.dart';
import 'package:automl/core/firebase_setup.dart';
import 'package:automl/screens/auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleSignup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      showSnackbar(context, 'Please fill in all fields.', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showSnackbar(context, 'Passwords do not match.', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      showSnackbar(context, 'Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final error = await signUp(_emailController.text, _passwordController.text);

    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      showSnackbar(context, 'Account created successfully! Please log in.', isError: false);
      Navigator.of(context).pop();
    } else {
      showSnackbar(context, 'Sign up Failed: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF111828),
                Color(0xFF3A0564),
              ]
          )
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          // Since this is a signup screen, it should allow navigation back to login
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3859FC), Color(0xFF8730FB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.hub_outlined,
                        size: 65,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15,),
                    const Text(
                      'AutoML Studio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Create your free account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Sign Up Form Container
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e2939),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        // Align labels to the start
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10,),
                          const Center(
                            child: Text(
                              'Sign up to start training your models',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Email Field
                          const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.blueAccent,
                            decoration: InputDecoration(
                              hintText: 'you@example.com',
                              hintStyle: const TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: const Color(0xFF1e2939),
                              prefixIcon: const Icon(Icons.mail_outline, color: Colors.white54),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Password Field
                          const Text('Password', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.blueAccent,
                            decoration: InputDecoration(
                              hintText: '•••••••• (min 6 chars)',
                              hintStyle: const TextStyle(color: Colors.white54, fontSize: 20),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: const Color(0xFF1e2939),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Confirm Password Field
                          const Text('Confirm Password', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_isPasswordVisible, // Reusing the same visibility state
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.blueAccent,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(color: Colors.white54, fontSize: 20),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: const Color(0xFF1e2939),
                              prefixIcon: const Icon(Icons.lock_reset, color: Colors.white54),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Sign Up Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
