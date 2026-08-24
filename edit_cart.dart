import 'dart:io';

void main() async {
  final file = File('lib/screens/cart_screen.dart');
  String content = await file.readAsString();

  final find1 = '''
        ],
      ),
    );
  }
''';

  final replace1 = '''
        ],
      ),
    );
  }

  Future<void> _showLocationError(BuildContext context, String message) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('????? ?????? ??', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('??? ?????????', style: TextStyle(fontFamily: 'Cairo', color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('?????', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
          ),
        ],
      ),
    );
  }
''';

  content = content.replaceFirst(find1, replace1);

  final find2 = '''
                                     double? lat;
                                     double? long;
                                     try {
                                       final serviceEnabled =
                                           await Geolocator.isLocationServiceEnabled();
                                       if (serviceEnabled) {
                                         var permission =
                                             await Geolocator.checkPermission();
                                         if (permission ==
                                             LocationPermission.denied) {
                                           permission =
                                               await Geolocator.requestPermission();
                                         }
                                         if (permission ==
                                                 LocationPermission.whileInUse ||
                                             permission ==
                                                 LocationPermission.always) {
                                           final pos =
                                               await Geolocator.getCurrentPosition(
                                                 desiredAccuracy:
                                                     LocationAccuracy.medium,
                                                 timeLimit: const Duration(
                                                   seconds: 3,
                                                 ),
                                               ).timeout(
                                                 const Duration(seconds: 3),
                                               );
                                           lat = pos.latitude;
                                           long = pos.longitude;
                                         }
                                       }
                                     } catch (_) {
                                       // Silent fallback
                                     }
''';

  final replace2 = '''
                                     double? lat;
                                     double? long;
                                     try {
                                       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                       if (!serviceEnabled) {
                                         if (mounted) setState(() => _isLoading = false);
                                         await _showLocationError(context, '???? ????? ????? ?????? (GPS) ??? ????? ?? ????? ????? ???? ????.');
                                         return;
                                       }
                                       var permission = await Geolocator.checkPermission();
                                       if (permission == LocationPermission.denied) {
                                         permission = await Geolocator.requestPermission();
                                       }
                                       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                                         if (mounted) setState(() => _isLoading = false);
                                         await _showLocationError(context, '???? ?????? ??????? ??????? ??? ?????? ??? ????? ?? ????? ?????.');
                                         return;
                                       }
                                       
                                       final pos = await Geolocator.getCurrentPosition(
                                         desiredAccuracy: LocationAccuracy.medium,
                                         timeLimit: const Duration(seconds: 5),
                                       ).timeout(const Duration(seconds: 5));
                                       lat = pos.latitude;
                                       long = pos.longitude;
                                       
                                       if (lat == null || long == null) {
                                         if (mounted) setState(() => _isLoading = false);
                                         await _showLocationError(context, '???? ????? ????? ????. ???? ?????? ?? ???? ????? ??? GPS ????????? ??? ????.');
                                         return;
                                       }
                                     } catch (e) {
                                       if (mounted) setState(() => _isLoading = false);
                                       await _showLocationError(context, '???? ????? ?????: ???? ?????? ?? ????? ??????? ?????? ????????? ??????.');
                                       return;
                                     }
''';

  content = content.replaceFirst(find2, replace2);

  await file.writeAsString(content);
  print('Done editing');
}
