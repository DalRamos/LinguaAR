// screens/disability/disability_setup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/bloc/Disability/disability_bloc.dart';
import 'package:lingua_arv1/repositories/disability_repositories/disability_repository_impl.dart';
import 'package:lingua_arv1/screens/get_started/get_started_page2.dart';
import 'package:lingua_arv1/validators/token.dart';

class DisabilitySetupPage extends StatefulWidget {
  @override
  _DisabilitySetupPageState createState() => _DisabilitySetupPageState();
}

class _DisabilitySetupPageState extends State<DisabilitySetupPage> {
  String? selectedDisability;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DisabilityBloc(
        disabilityRepository: DisabilityRepositoryImpl(),
      ),
      child: _DisabilitySetupContent(),
    );
  }
}

class _DisabilitySetupContent extends StatefulWidget {
  @override
  __DisabilitySetupContentState createState() => __DisabilitySetupContentState();
}

class __DisabilitySetupContentState extends State<_DisabilitySetupContent> {
  String? selectedDisability;

  Future<void> _saveDisability() async {
    if (selectedDisability == null) {
      _navigateToGetStarted();
      return;
    }

    final token = await TokenService.getToken();
    if (token != null) {
      // Now we're inside the BlocProvider scope, so we can access the bloc
      context.read<DisabilityBloc>().add(
        SetDisabilityEvent(token: token, disability: selectedDisability!),
      );
    }
  }

  void _navigateToGetStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GetStartedPage2()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell Us About Yourself',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Color(0xFF273236),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This helps us personalize your experience',
              style: TextStyle(fontSize: 16, color: Color(0xFF4A90E2)),
            ),
            SizedBox(height: 40),
            Text(
              'Do you have any disability? (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Color(0xFF273236),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedDisability,
              decoration: InputDecoration(
                labelText: 'Select disability',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('No disability / Prefer not to say'),
                ),
                DropdownMenuItem<String>(
                  value: 'none',
                  child: Text('None'),
                ),
                DropdownMenuItem<String>(
                  value: 'deaf',
                  child: Text('Deaf'),
                ),
                DropdownMenuItem<String>(
                  value: 'hard_of_hearing',
                  child: Text('Hard of Hearing'),
                ),
                DropdownMenuItem<String>(
                  value: 'mute',
                  child: Text('Mute'),
                ),
                DropdownMenuItem<String>(
                  value: 'speech_impaired',
                  child: Text('Speech Impaired'),
                ),
                DropdownMenuItem<String>(
                  value: 'other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  selectedDisability = newValue;
                });
              },
            ),
            SizedBox(height: 30),
            BlocConsumer<DisabilityBloc, DisabilityState>(
              listener: (context, state) {
                if (state is DisabilitySetSuccess) {
                  TokenService.saveDisability(selectedDisability);
                  _navigateToGetStarted();
                } else if (state is DisabilityFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage)),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is DisabilityLoading ? null : _saveDisability,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A90E2),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state is DisabilityLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Continue',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: state is DisabilityLoading ? null : _navigateToGetStarted,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(fontSize: 16, color: Color(0xFF4A90E2)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}