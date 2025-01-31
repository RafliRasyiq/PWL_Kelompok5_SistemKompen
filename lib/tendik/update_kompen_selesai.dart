import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:sistem_kompen/config.dart';
import 'package:http/http.dart' as http;
import 'package:sistem_kompen/core/shared_prefix.dart';
import 'package:sistem_kompen/tendik/homepage_tendik.dart';

var allData = [];
String _searchQuery = ""; // Search query for filtering

class DataListScreen extends StatefulWidget {
  final String token;
  final String id;
  const DataListScreen({super.key, required this.token, required this.id});

  @override
  _DataListScreenState createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  // Fetch all tasks data
  Future<void> fetchAllData() async {
    final url = Uri.parse(Config.tendik_kompen_selesai_endpoint);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        if (data['success']) {
          print("masuk ke success");
          setState(() {
            // Parse the data['data'] list and assign it to allData
            allData = data['data'] as List<dynamic>;
          });
        } else {
          print("Data tidak ditemukan: ${response.body}");
          setState(() {
            allData = [];
          });
        }
      } else {
        print("Unexpected data format: ${response.body}");
        setState(() {
          allData = [];
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        allData = [];
      });
    }
  }

  // Function to filter data based on the search query
  List<dynamic> getFilteredData() {
    if (_searchQuery.isEmpty) {
      return allData; // Show all data if the search query is empty
    }
    return allData.where((item) {
      String tugasNama = item['tugas']['tugas_nama']?.toLowerCase() ?? '';
      String mahasiswaNama =
          item['mahasiswa']['mahasiswa_nama']?.toLowerCase() ?? '';
      return tugasNama.contains(_searchQuery.toLowerCase()) ||
          mahasiswaNama.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredData =
        getFilteredData(); // Data after applying filter

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Status Penugasan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2D2766),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DashboardTendik(token: widget.token, id: widget.id)),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Search Bar to filter the data based on task or student name
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari berdasarkan tugas atau mahasiswa...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value; // Update the search query
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: allData.isEmpty
                  ? const Center(child: Text("Tidak ada data yang ditampilkan"))
                  : RefreshIndicator(
                      onRefresh:
                          fetchAllData, // Refresh function to fetch data again
                      child: ListView.builder(
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          var data = filteredData[index];

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: data.isEmpty
                                ? const Center(
                                    child:
                                        Text("Tidak ada data yang ditampilkan"))
                                : ListTile(
                                    title: Text(
                                      data['tugas']
                                          ['tugas_nama'], // Display task name
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Nama Mahasiswa: ${data['mahasiswa']['mahasiswa_nama']}'),
                                        Text('Tanggal: ${data['tanggal']}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          data['status'] == 'terima'
                                              ? Icons.check_circle
                                              : data['status'] == 'tolak'
                                                  ? Icons.cancel
                                                  : Icons.hourglass_empty,
                                          color: data['status'] == 'terima'
                                              ? Colors.green
                                              : data['status'] == 'tolak'
                                                  ? Colors.red
                                                  : Colors.yellow,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          data['status'] == 'terima'
                                              ? 'Diterima'
                                              : data['status'] == 'tolak'
                                                  ? 'Ditolak'
                                                  : 'Belum Dicek',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      String id =
                                          data['pengumpulan_id'].toString();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TaskDetailScreen(
                                                  token: widget.token,
                                                  pengumpulanId: id, id: widget.id),
                                        ),
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final String id;
  final String pengumpulanId;

  const TaskDetailScreen(
      {super.key, required this.pengumpulanId, required this.token, required this.id});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  var taskDetail;
  bool isTaskAccepted = false;
  bool isTaskRejected = false;

  @override
  void initState() {
    super.initState();
    fetchTaskDetail();
  }

  // Fetch task details
  void fetchTaskDetail() async {
    final url = Uri.parse(Config.tendik_show_kompen_selesai_endpoint);
    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode({
            'pengumpulan_id': widget.pengumpulanId,
          }));

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        setState(() {
          taskDetail = data['data'];
          isTaskAccepted = taskDetail['status'] == 'terima';
          isTaskRejected = taskDetail['status'] == 'tolak';
        });
      } else {
        setState(() {
          taskDetail = null;
        });
      }
    } catch (e) {
      print("Error fetching task detail: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch task detail!')),
      );
    }
  }

  // Update task status to 'terima' (accepted)
  void updateStatusTerima() async {
    final url = Uri.parse(Config.tendik_update_kompen_selesai_endpoint);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'status': 'terima',
          'pengumpulan_id': widget.pengumpulanId,
        }),
      );
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        fetchTaskDetail(); // Refresh task detail after update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated to Terima!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status!')),
        );
      }
    } catch (e) {
      print("Error updating status to 'terima': $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status!')),
      );
    }
  }

  // Update task status to 'tolak' (rejected) with reason
  void updateStatusTolak(String alasan) async {
    final url = Uri.parse(Config.tendik_update_kompen_selesai_endpoint);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'status': 'tolak',
          'alasan': alasan,
          'pengumpulan_id': widget.pengumpulanId,
        }),
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        fetchTaskDetail(); // Refresh task detail after update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated to Tolak!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status!')),
        );
      }
    } catch (e) {
      print("Error updating status to 'tolak': $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (taskDetail == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detail Tugas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          backgroundColor: const Color(0xFF2D2766),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DataListScreen(token: widget.token, id: widget.id)),
              );
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Tugas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF2D2766),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DataListScreen(token: widget.token, id: widget.id)),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Tugas: ${taskDetail['tugas']['tugas_nama']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
                'Nama Mahasiswa: ${taskDetail['mahasiswa']['mahasiswa_nama']}'),
            const SizedBox(height: 10),
            Text('Tanggal Pengumpulan: ${taskDetail['tanggal']}'),
            const SizedBox(height: 10),
            Text('Status: ${taskDetail['status']}'),
            const SizedBox(height: 10),

            // Conditionally show the rejection reason (alasan) if the status is 'tolak'
            if (taskDetail['status'] == 'tolak')
              Text('Alasan Tolak: ${taskDetail['alasan']}'),
            const SizedBox(height: 20),
// Display Foto Sebelum and Foto Sesudah images if available
            if (taskDetail['foto_sebelum'] != null &&
                taskDetail['foto_sebelum'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foto Sebelum:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 200, // Adjust width as needed
                    height: 200, // Adjust height as needed
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: taskDetail['foto_sebelum'] != null &&
                                taskDetail['foto_sebelum'].isNotEmpty
                            ? NetworkImage(
                                "http://your-backend-domain/${taskDetail['foto_sebelum']}")
                            : const AssetImage('assets/images/default.jpg')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius
                          .zero, // This makes it a square with sharp edges
                      border: Border.all(
                        color: Colors.grey, // Optional: Add border if you want
                        width: 1,
                      ),
                    ),
                    child: taskDetail['foto_sebelum'] == null ||
                            taskDetail['foto_sebelum'].isEmpty
                        ? const Center(
                            child: Text(
                              "FS", // Placeholder text
                              style:
                                  TextStyle(fontSize: 40, color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (taskDetail['foto_sesudah'] != null &&
                taskDetail['foto_sesudah'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foto Sesudah:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 200, // Adjust width as needed
                    height: 200, // Adjust height as needed
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: taskDetail['foto_sesudah'] != null &&
                                taskDetail['foto_sesudah'].isNotEmpty
                            ? NetworkImage(
                                "http://your-backend-domain/${taskDetail['foto_sesudah']}")
                            : const AssetImage('assets/images/default.jpg')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius
                          .zero, // This makes it a square with sharp edges
                      border: Border.all(
                        color: Colors.grey, // Optional: Add border if you want
                        width: 1,
                      ),
                    ),
                    child: taskDetail['foto_sesudah'] == null ||
                            taskDetail['foto_sesudah'].isEmpty
                        ? const Center(
                            child: Text(
                              "FS", // Placeholder text
                              style:
                                  TextStyle(fontSize: 40, color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Buttons for changing the status
            if (!isTaskAccepted && !isTaskRejected)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: updateStatusTerima,
                    child: const Text('Terima',
                        style: TextStyle(color: Colors.white)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Show dialog to get rejection reason
                      String alasan = '';
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Alasan Tolak'),
                          content: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan alasan',
                            ),
                            onChanged: (value) {
                              setState(() {
                                alasan = value;
                              });
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, ''),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, alasan),
                              child: const Text('Tolak'),
                            ),
                          ],
                        ),
                      );

                      // If a reason is provided, update the status to 'tolak'
                      if (result != null && result.isNotEmpty) {
                        updateStatusTolak(result);
                      }
                    },
                    child: const Text('Tolak',
                        style: TextStyle(color: Colors.white)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
