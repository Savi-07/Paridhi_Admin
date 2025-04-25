// //using video_player: ^2.7.0 imoplement background video
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class BackgroundVideo extends StatefulWidget {
//   @override
//   _BackgroundVideoState createState() => _BackgroundVideoState();
// }

// class _BackgroundVideoState extends State<BackgroundVideo> {  
//   late VideoPlayerController _controller;
//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.asset('assets/animations/video.mp4')
//       ..initialize().then((_) {
//         _controller.setLooping(true);
//         _controller.setVolume(0); // mute
//         _controller.play();
//         setState(() {});
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Background Video
//           _controller.value.isInitialized
//               ? SizedBox.expand(
//                   child: FittedBox(
//                     fit: BoxFit.cover,
//                     child: SizedBox(
//                       width: _controller.value.size.width,
//                       height: _controller.value.size.height,
//                       child: VideoPlayer(_controller),
//                     ),
//                   ),
//                 )
//               : Center(child: CircularProgressIndicator()),

//           // Foreground content
//           Center(
//             child: Text(
//               'Your Foreground UI',
//               style: TextStyle(color: Colors.white, fontSize: 24),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
