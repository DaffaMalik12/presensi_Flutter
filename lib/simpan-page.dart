import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:presensi/models/save-presensi-response.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:http/http.dart' as myHttp;
import 'package:shared_preferences/shared_preferences.dart';

class SimpanPage extends StatefulWidget {
  const SimpanPage({Key? key}) : super(key: key);

  @override
  State<SimpanPage> createState() => _SimpanPageState();
}

class _SimpanPageState extends State<SimpanPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });
  }

  Future<LocationData?> _currentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    Location location = Location();

    // Cek apakah service sudah aktif
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    // Cek apakah permission sudah diberikan
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    // Ambil lokasi sekarang
    return await location.getLocation();
  }

  Future savePresensi(double latitude, double longitude) async {
    SavePresensiResponseModel savePresensiResponseModel;
    Map<String, String> body = {
      "latitude": latitude.toString(),
      "longitude": longitude.toString(),
    };

    Map<String, String> headers = {
      'Authorization': 'Bearer ' + await _token,
    };

    var response = await myHttp.post(
      Uri.parse('http://10.0.2.2:8000/api/save-presensi'),
      body: body,
      headers: headers,
    );

    if (response.statusCode == 200) {
      savePresensiResponseModel = SavePresensiResponseModel.fromJson(json.decode(response.body));
      if (savePresensiResponseModel.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sukses Simpan Presensi")),
        );
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context); // Kembali ke halaman sebelumnya setelah delay
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Simpan Presensi")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Presensi", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<LocationData?>(
        future: _currentLocation(),
        builder: (BuildContext context, AsyncSnapshot<LocationData?> snapshot) {
          if (snapshot.hasData) {
            final LocationData currentLocation = snapshot.data!;
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Lokasi Anda Saat Ini",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          height: 300,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SfMaps(
                              layers: [
                                MapTileLayer(
                                  initialFocalLatLng: MapLatLng(
                                    currentLocation.latitude!,
                                    currentLocation.longitude!,
                                  ),
                                  initialZoomLevel: 15,
                                  initialMarkersCount: 1,
                                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  markerBuilder: (BuildContext context, int index) {
                                    return MapMarker(
                                      latitude: currentLocation.latitude!,
                                      longitude: currentLocation.longitude!,
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          savePresensi(currentLocation.latitude!, currentLocation.longitude!);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text("Simpan Presensi", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
