
import 'package:agrolens_version2/pages/loading_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
 
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();


  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);


  runApp(const AgrolensV2());
}

class AgrolensV2 extends StatefulWidget {
  const AgrolensV2({super.key});

  @override
  State<AgrolensV2> createState() => _AgrolensAppState();
} 

class _AgrolensAppState extends State<AgrolensV2> {
  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
   
    await Future.delayed(const Duration(seconds: 1));

    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoadingPage(),
    );
  }
}