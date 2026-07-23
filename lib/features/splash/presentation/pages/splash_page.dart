import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/bloc/splash_bloc.dart';
import '../../logic/bloc/splash_event.dart';
import '../../logic/bloc/splash_state.dart';
import '../widgets/splash_content.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({required this.destination, super.key});

  final Widget destination;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  var _hasNavigated = false;

  void _openDestination(BuildContext context, SplashState state) {
    if (state is! SplashCompleted || !context.mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => widget.destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashBloc()..add(const SplashStarted()),
      child: BlocListener<SplashBloc, SplashState>(
        listenWhen: (previous, current) => current is SplashCompleted,
        listener: _openDestination,
        child: const SplashContent(),
      ),
    );
  }
}
