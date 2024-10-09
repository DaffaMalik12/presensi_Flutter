import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:presensi/models/home-response.dart';
import 'package:presensi/simpan-page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as myHttp;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _name, _token;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });
    getData(); // Pastikan memanggil getData() di initState
  }

  Future<void> getData() async {
    final Map<String, String> headers = {
      'Authorization': 'Bearer ' + await _token,
      // Pastikan ada spasi setelah 'Bearer'
    };

    try {
      var response = await myHttp.get(
        Uri.parse('http://10.0.2.2:8000/api/get-presensi'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        homeResponseModel =
            HomeResponseModel.fromJson(json.decode(response.body));
        riwayat.clear();
        setState(() {
          riwayat.clear(); // Bersihkan list riwayat sebelum diisi ulang
          homeResponseModel!.data.forEach((element) {
            if (element.isHariIni) {
              hariIni = element;
            } else {
              riwayat.add(element); // Tambahkan ke riwayat
            }
          });
        });
      } else {
        print('Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _name,
                      builder: (BuildContext context, AsyncSnapshot<
                          String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasData) {
                          return Text(
                            "${snapshot.data ?? "-"}",
                            style: TextStyle(fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          );
                        } else {
                          return Text("-", style: TextStyle(fontSize: 20));
                        }
                      },
                    ),
                    SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              hariIni?.tanggal ?? '-',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        hariIni?.masuk ?? '-',
                                        style: TextStyle(color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Masuk",
                                        style: TextStyle(color: Colors.white70,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    children: [
                                      Text(
                                        hariIni?.pulang ?? '-',
                                        style: TextStyle(color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Pulang",
                                        style: TextStyle(color: Colors.white70,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Text("Riwayat Presensi", style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
                    SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) {
                          final presensi = riwayat[index];
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ListTile(
                                leading: Icon(
                                    Icons.date_range, color: Colors.blueAccent),
                                title: Text(presensi.tanggal ?? "-",
                                    style: TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Masuk: ${presensi.masuk ?? "-"}",
                                        style: TextStyle(fontSize: 16)),
                                    Text("Pulang: ${presensi.pulang ?? "-"}",
                                        style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => SimpanPage(),
            ),
          )
              .then((value) {
            setState(() {
              // Letakkan apa pun yang perlu diperbarui setelah kembali dari SimpanPage
            });
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

