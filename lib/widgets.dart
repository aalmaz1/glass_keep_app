import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Previously using withOpacity
        Opacity(opacity: withValues(0.5), child: Text('Hello')),  
        ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[ 
            // Example matrix values
            1.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0, 0.0
          ]),
          child: Image.asset('assets/image.png'),
        ),
        // Removed unnecessary Container
        // Container(
        //   child: Text('Some text'),
        // ),
      ],
    );
  }
}