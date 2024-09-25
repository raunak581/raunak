import 'package:chatapp/Landing.dart';
import 'package:chatapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Register_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://31.220.96.248:5002/api/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Login successful: ${responseBody['token']}');
      final userId = responseBody['userId'];
      final userEmail = responseBody['userEmail'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseBody['token']);
      await prefs.setString('userId', userId.toString());
      await prefs.setString('userEmail', userEmail);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                Landing_page()), // Replace ChatScreen with your target screen
      );
    } else if (response.statusCode == 401) {
      print('User not found');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials or user not found.')),
      );
    } else {
      print('Login failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please try again.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  "assets/images/imagebackground.jpg",
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          // maxWidth: constraints.maxWidth * 0.9,
                          maxHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/My Sevak Logo Placeholder.png",
                              height: constraints.maxHeight * 0.2,
                            ),
                            const Text(
                              'SEVAK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pacifico',
                              ),
                            ),
                            Text(
                              'YOUR ASSISTANT 24 x 7',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.02),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.mail),
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: 'Email',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.02),
                                  TextField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.password),
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    obscureText: true,
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.03),
                                  _isLoading
                                      ? CircularProgressIndicator()
                                      : SizedBox(
                                          width: constraints.maxWidth * 0.5,
                                          child: ElevatedButton(
                                            onPressed: _login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  const Text(
                                    "OR",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  ElevatedButton(
                                      onPressed: () {},
                                      child: Container(
                                        child: Image.asset(
                                          "assets/images/google.png",
                                          height: 30,
                                          width: 30,
                                        ),
                                      )),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.02),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                RegisterPage()),
                                      );
                                    },
                                    child: RichText(
                                      text: const TextSpan(
                                        text: "Don't have an account? ",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Register',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.03),
                                ],
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
          );
        },
      ),
    );
  }
}
