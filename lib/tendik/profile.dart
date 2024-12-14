import 'package:flutter/material.dart';
import 'package:sistem_kompen/controller/tendik_controller.dart';
import 'package:sistem_kompen/tendik.dart';
import 'package:sistem_kompen/core/shared_prefix.dart';
import 'package:sistem_kompen/tendik/homepage_tendik.dart';
import 'package:sistem_kompen/login/login.dart';
import '../config.dart';

final TextEditingController _idController = TextEditingController();

class ProfileTendik extends StatefulWidget {
  final String token;
  final String id;

  const ProfileTendik({super.key, required this.token, required this.id});

  @override
  _ProfileTendikState createState() => _ProfileTendikState();
}

class _ProfileTendikState extends State<ProfileTendik> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final url = Uri.parse(Config.base_domain);

  String userId = '';
  String nama = 'Loading...';
  String username = 'Loading...';
  String noInduk = 'Loading...';
  String foto = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfileData(); // Fetch data when the screen loads
  }

  Future<void> fetchProfileData() async {
    try {
      // Ambil token dari SharedPreferences jika diperlukan
      final token = await Sharedpref.getToken();
      final user_id = await Sharedpref.getUserId();

      if (token == '') {
        throw Exception('Token is missing');
      }

      final data = await TendikController.profile(token, user_id);

      setState(() {
        userId = data['user_id'] ?? '-';
        nama = data['nama'] ?? '-';
        username = data['username'] ?? '-';
        noInduk = data['no_induk'] ?? '-';
        foto = data['foto'] ?? '-';
      });
      print(data['message']);
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: foto != null && foto.isNotEmpty
                  ? NetworkImage("$url/$foto")
                  : const AssetImage('assets/images/default_profile.png')
                      as ImageProvider,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: <Widget>[
                  ProfileInfoField(label: "Username", value: username),
                  ProfileInfoField(label: "Nama Lengkap", value: nama),
                  ProfileInfoField(label: "No Induk", value: noInduk),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _idController.text = userId;
                _showEditProfileDialog(context);
              },
              child: const Text("Ubah Profil"),
            ),
            ElevatedButton(
              onPressed: () {
                _idController.text = userId;
                _showEditPasswordDialog(context);
              },
              child: const Text("Ubah Password"),
            ),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text("Log out"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditProfileDialog(token: widget.token, id: widget.id);
      },
    );
  }

  void _showEditPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPasswordDialog(token: widget.token, id: widget.id);
      },
    );
  }

  void _logout(BuildContext context) {
    // Handle logout logic here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

class ProfileInfoField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class EditProfileDialog extends StatelessWidget {
  String token;
  String id;

  EditProfileDialog({super.key, required this.token, required this.id});

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TendikController _tendikController =
      TendikController(Config.tendik_update_profile_endpoint);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Profil'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () {
            print("object");
            if (_usernameController.text == "" || _nameController.text == "") {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inputan masih kosong')),
              );
              Navigator.of(context).pop();
            } else {
              _tendikController.updateProfileData(token, _idController.text,
                  _usernameController.text, _nameController.text);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileTendik(token: token, id: id)),
              );
            }
          },
          child: const Text("Ubah"),
        ),
      ],
    );
  }
}

class EditPasswordDialog extends StatelessWidget {
  String token;
  String id;

  EditPasswordDialog({super.key, required this.token, required this.id});

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TendikController _tendikController =
      TendikController(Config.tendik_update_password_endpoint);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Password'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password Baru'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration:
                  const InputDecoration(labelText: 'Konfirmasi Password Baru'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () {
            print("object");
            if (_passwordController.text == "") {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inputan masih kosong')),
              );
            } else if (_passwordController.text !=
                _confirmPasswordController.text) {
                  Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Konfirmasi password tidak sesuai')),
              );
            } else {
              _tendikController.updatePassword(
                  token, _idController.text, _passwordController.text);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileTendik(token: token, id: id)),
              );
            }
          },
          child: const Text("Ubah"),
        ),
      ],
    );
  }
}
