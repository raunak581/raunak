import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController(); // New controller for mobile number
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('http://31.220.96.248:5002/api/auth/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'mobile': _mobileController.text, // Add mobile to request body
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('Registration successful: ${responseBody['token']}');
        Navigator.pop(context);
        // Optionally, navigate back to the login page or another page
      } else {
        print('Registration failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/imagebackground.jpg', // Make sure this matches your actual image path
              fit: BoxFit.cover,
            ),
          ),
          // Overlay content
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Create a New Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pacifico', // Optional, if you want a custom font
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Username',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.person, color: Colors.black),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.email, color: Colors.black),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _mobileController, // Mobile field
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Mobile Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.phone, color: Colors.black),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a mobile number';
                            } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                              return 'Please enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.lock, color: Colors.black),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            } else if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 30),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding:const  EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child:const  Center(
                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
        ],
      ),
    );
  }
}
