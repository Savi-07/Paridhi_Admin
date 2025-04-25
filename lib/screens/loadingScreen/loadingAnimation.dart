import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../widgets/animated_background.dart';

class Loadinganimation extends StatefulWidget {
  const Loadinganimation({super.key});

  @override
  State<Loadinganimation> createState() => _LoadinganimationState();
}

class _LoadinganimationState extends State<Loadinganimation> {
  // late VideoPlayerController _controller;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // padding: const EdgeInsets.all(26.0),
        height: double.infinity,
        width: double.infinity,
        child: AnimatedGradientBackground(
          child: Center(
            child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                      ),
                      const SizedBox(height: 10,),
                      Text("Loading..", style: TextStyle(fontSize: 16, color: Colors.white))  
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
