import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallNumberView extends StatelessWidget {
  var phoneNumber;
  var color;
  var size;
  CallNumberView({Key? key, this.phoneNumber, this.color, this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final call = Uri.parse('tel:$phoneNumber');
        if (await canLaunchUrl(call)) {
          launchUrl(call);
        } else {
          throw 'Could not launch $call';
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_outlined,
            color: color ?? Colors.white,
            size: size,
          ),
          const SizedBox(width: 5),
          Text(
            phoneNumber,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: size ?? 15,
            ),
          ),
        ],
      ),
    );
  }
}
