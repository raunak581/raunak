import 'package:flutter/material.dart';

class Avtarwithname extends StatefulWidget {
  const Avtarwithname({Key? key, required this.imgPath, required this.imgName})
      : super(key: key);

  final String imgPath;
  final String imgName;

  @override
  _AvtarwithnameState createState() => _AvtarwithnameState();
}

class _AvtarwithnameState extends State<Avtarwithname> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxHeight = constraints.maxHeight;
        double maxWidth = constraints.maxWidth;

        return Container(
         
          // padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  maxRadius: maxWidth * 0.4, // Set radius to 30% of the container width
                  child: Image.asset(
                    widget.imgPath,
                    height: maxHeight * 0.8, // Set height to 40% of the container height
                    width: maxWidth * 0.8, // Set width to 40% of the container width
                    alignment: Alignment.center,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.imgName,
                style: const TextStyle(
                  fontSize: 10, // Increase font size for better visibility
                  fontFamily: 'MyriadPro',
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
