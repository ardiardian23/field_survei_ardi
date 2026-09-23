import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/auth/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  final Map<String, dynamic>? survey;

  const SurveyFormPage({super.key, this.survey});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  // ============================================================
  // API URL
  // ============================================================

  static const String baseUrl = 'https://sijala.biz.id/api/v1';

  static const String categoryUrl = '$baseUrl/categories';

  static const String saveSurveyUrl = '$baseUrl/surveys/save';

  static const String imageUrl = 'https://sijala.biz.id/api/image';

  // ============================================================
  // WARNA
  // ============================================================

  static const Color primaryColor = Color.fromARGB(255, 217, 217, 220);

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController latitudeController = TextEditingController();

  final TextEditingController longitudeController = TextEditingController();

  // ============================================================
  // CATEGORY
  // ============================================================

  List<Map<String, dynamic>> categories = [];

  int? selectedCategoryId;

  bool isLoadingCategories = true;

  // ============================================================
  // IMAGE
  // ============================================================

  final ImagePicker picker = ImagePicker();

  XFile? selectedImage;

  Uint8List? selectedImageBytes;

  Uint8List? existingImageBytes;

  bool isLoadingImage = false;

  // ============================================================
  // STATE
  // ============================================================

  bool isSubmitting = false;

  bool get isEdit => widget.survey != null;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    fillSurveyData();

    fetchCategories();
  }

  // ============================================================
  // ISI DATA JIKA EDIT
  // ============================================================

  void fillSurveyData() {
    if (!isEdit) return;

    final survey = widget.survey!;

    titleController.text = survey['title']?.toString() ?? '';

    descriptionController.text = survey['description']?.toString() ?? '';

    latitudeController.text = survey['latitude']?.toString() ?? '';

    longitudeController.text = survey['longitude']?.toString() ?? '';

    selectedCategoryId = int.tryParse(survey['category_id']?.toString() ?? '');

    final photoName = survey['photo']?.toString() ?? '';

    if (photoName.isNotEmpty &&
        photoName != 'null' &&
        photoName != 'placeholder.jpg') {
      fetchExistingImage(photoName);
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    titleController.dispose();

    descriptionController.dispose();

    latitudeController.dispose();

    longitudeController.dispose();

    super.dispose();
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token') ?? '';
  }

  // ============================================================
  // GET CATEGORY
  // ============================================================

  Future<void> fetchCategories() async {
    try {
      if (mounted) {
        setState(() {
          isLoadingCategories = true;
        });
      }

      final token = await getToken();

      final response = await http.get(
        Uri.parse(categoryUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('================================');

      debugPrint('GET CATEGORY');

      debugPrint('STATUS: ${response.statusCode}');

      debugPrint('BODY: ${response.body}');

      debugPrint('================================');

      if (response.statusCode == 401) {
        await logout();

        return;
      }

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> rawCategories = [];

        if (decoded is Map && decoded['data'] is List) {
          rawCategories = decoded['data'];
        } else if (decoded is List) {
          rawCategories = decoded;
        }

        if (!mounted) return;

        setState(() {
          categories = rawCategories
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          // Pastikan category ID yang dipilih ada
          if (selectedCategoryId != null) {
            final categoryExists = categories.any((category) {
              final id = int.tryParse(category['id']?.toString() ?? '');

              return id == selectedCategoryId;
            });

            if (!categoryExists) {
              selectedCategoryId = null;
            }
          }

          isLoadingCategories = false;
        });

        return;
      }

      throw Exception('Gagal mengambil kategori.');
    } catch (e) {
      debugPrint('CATEGORY ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
      });

      showErrorSnackBar('Gagal memuat kategori.');
    }
  }

  // ============================================================
  // GET FOTO LAMA
  // ============================================================

  Future<void> fetchExistingImage(String photoName) async {
    try {
      if (mounted) {
        setState(() {
          isLoadingImage = true;
        });
      }

      final token = await getToken();

      final fileName = photoName.contains('/')
          ? photoName.split('/').last
          : photoName;

      final response = await http.get(
        Uri.parse('$imageUrl/$fileName'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'image/*'},
      );

      debugPrint(
        'PHOTO STATUS: '
        '${response.statusCode}',
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          existingImageBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      debugPrint('PHOTO ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingImage = false;
        });
      }
    }
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = image;

        selectedImageBytes = bytes;
      });
    } catch (e) {
      showErrorSnackBar('Gagal memilih foto.');
    }
  }

  // ============================================================
  // DIALOG FOTO
  // ============================================================

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ListTile(
                  leading: const Icon(Icons.photo_library, color: primaryColor),
                  title: const Text('Galeri'),
                  onTap: () {
                    Navigator.pop(bottomContext);

                    pickImage(ImageSource.gallery);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.camera_alt, color: primaryColor),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(bottomContext);

                    pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HAPUS FOTO
  // ============================================================

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;

      selectedImageBytes = null;

      existingImageBytes = null;
    });
  }

  // ============================================================
  // SIMPAN SURVEY
  // ============================================================

  Future<void> saveSurvey() async {
    if (!formKey.currentState!.validate()) {
      showErrorSnackBar('Lengkapi data yang wajib diisi.');

      return;
    }

    if (selectedCategoryId == null) {
      showErrorSnackBar('Silakan pilih kategori.');

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final token = await getToken();

      if (token.isEmpty) {
        await logout();

        return;
      }

      final request = http.MultipartRequest('POST', Uri.parse(saveSurveyUrl));

      // ========================================================
      // HEADER
      // ========================================================

      request.headers.addAll({
        'Accept': 'application/json',

        'Authorization': 'Bearer $token',
      });

      // ========================================================
      // DATA
      // ========================================================

      request.fields['title'] = titleController.text.trim();

      request.fields['category_id'] = selectedCategoryId.toString();

      request.fields['description'] = descriptionController.text.trim();

      if (latitudeController.text.trim().isNotEmpty) {
        request.fields['latitude'] = latitudeController.text.trim();
      }

      if (longitudeController.text.trim().isNotEmpty) {
        request.fields['longitude'] = longitudeController.text.trim();
      }

      // ========================================================
      // EDIT
      // ========================================================

      if (isEdit) {
        request.fields['id'] = widget.survey!['id'].toString();

        request.fields['_method'] = 'PUT';
      }

      // ========================================================
      // FOTO
      // ========================================================

      if (selectedImage != null && selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint('================================');

      debugPrint(isEdit ? 'UPDATE SURVEY' : 'TAMBAH SURVEY');

      debugPrint(
        'TITLE: '
        '${titleController.text}',
      );

      debugPrint(
        'CATEGORY: '
        '$selectedCategoryId',
      );

      debugPrint(
        'DESCRIPTION: '
        '${descriptionController.text}',
      );

      debugPrint(
        'LATITUDE: '
        '${latitudeController.text}',
      );

      debugPrint(
        'LONGITUDE: '
        '${longitudeController.text}',
      );

      debugPrint(
        'IMAGE: '
        '${selectedImage != null}',
      );

      debugPrint('================================');

      // ========================================================
      // SEND
      // ========================================================

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        'SAVE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'SAVE BODY: '
        '${response.body}',
      );

      dynamic responseData;

      try {
        responseData = jsonDecode(response.body);
      } catch (_) {}

      // ========================================================
      // BERHASIL
      // ========================================================

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Survey berhasil diperbarui!'
                  : 'Survey berhasil ditambahkan!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pop(context, true);

        return;
      }

      // ========================================================
      // ERROR MESSAGE
      // ========================================================

      String message = 'Gagal menyimpan survey.';

      if (responseData is Map) {
        if (responseData['message'] != null) {
          message = responseData['message'].toString();
        }

        if (responseData['errors'] != null) {
          message += '\n${responseData['errors']}';
        }
      }

      throw Exception(
        '$message '
        '(Kode: ${response.statusCode})',
      );
    } catch (e) {
      debugPrint('SAVE ERROR: $e');

      if (!mounted) return;

      showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');

    await prefs.remove('user');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // ============================================================
  // SNACKBAR ERROR
  // ============================================================

  void showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ========================================================
      // APPBAR
      // ========================================================
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Survey' : 'Tambah Survey'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // ==================================================
              // DATA UTAMA
              // ==================================================
              buildMainDataCard(),

              const SizedBox(height: 16),

              // ==================================================
              // FOTO
              // ==================================================
              buildPhotoCard(),

              const SizedBox(height: 16),

              // ==================================================
              // LOKASI
              // ==================================================
              buildLocationCard(),

              const SizedBox(height: 24),

              // ==================================================
              // SIMPAN
              // ==================================================
              SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: isSubmitting ? null : saveSurvey,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,

                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit ? 'Simpan Perubahan' : 'Simpan Survey',

                          style: const TextStyle(
                            fontSize: 16,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DATA UTAMA
  // ============================================================

  Widget buildMainDataCard() {
    return Card(
      elevation: 0,

      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),

        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Data Utama Survey',

              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 18),

            // JUDUL
            TextFormField(
              controller: titleController,

              decoration: InputDecoration(
                labelText: 'Judul Survey *',

                hintText: 'Contoh: Jalan Berlubang',

                prefixIcon: const Icon(Icons.title),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul survey wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // CATEGORY
            if (isLoadingCategories)
              const LinearProgressIndicator(color: primaryColor)
            else
              DropdownButtonFormField<int>(
                value: selectedCategoryId,

                isExpanded: true,

                decoration: InputDecoration(
                  labelText: 'Kategori Survey *',

                  prefixIcon: const Icon(Icons.category),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                items: categories
                    .map((category) {
                      final id = int.tryParse(category['id']?.toString() ?? '');

                      final name = category['name']?.toString() ?? 'Tanpa Nama';

                      if (id == null) {
                        return null;
                      }

                      return DropdownMenuItem<int>(
                        value: id,

                        child: Text(name, overflow: TextOverflow.ellipsis),
                      );
                    })
                    .whereType<DropdownMenuItem<int>>()
                    .toList(),

                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },

                validator: (value) {
                  if (value == null) {
                    return 'Pilih kategori survey';
                  }

                  return null;
                },
              ),

            const SizedBox(height: 16),

            // DESKRIPSI
            TextFormField(
              controller: descriptionController,

              maxLines: 4,

              decoration: InputDecoration(
                labelText: 'Deskripsi Survey',

                hintText: 'Masukkan keterangan survey',

                alignLabelWithHint: true,

                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 65),

                  child: Icon(Icons.notes),
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD FOTO
  // ============================================================

  Widget buildPhotoCard() {
    return Card(
      elevation: 0,

      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),

        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Foto Survey',

              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            if (isLoadingImage)
              const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            else if (selectedImageBytes != null || existingImageBytes != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: Image.memory(
                      selectedImageBytes ?? existingImageBytes!,

                      width: double.infinity,

                      height: 200,

                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: showImageSourceDialog,

                          icon: const Icon(Icons.edit),

                          label: const Text('Ganti Foto'),
                        ),
                      ),

                      const SizedBox(width: 10),

                      OutlinedButton.icon(
                        onPressed: removeSelectedImage,

                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),

                        icon: const Icon(Icons.delete),

                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              )
            else
              InkWell(
                onTap: showImageSourceDialog,

                borderRadius: BorderRadius.circular(12),

                child: Container(
                  height: 150,

                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),

                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(Icons.add_a_photo, size: 42, color: primaryColor),

                      SizedBox(height: 10),

                      Text('Ketuk untuk memilih foto'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD LOKASI
  // ============================================================

  Widget buildLocationCard() {
    return Card(
      elevation: 0,

      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),

        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Lokasi Survey',

              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              'Masukkan koordinat latitude dan longitude.',

              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: latitudeController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,

                signed: true,
              ),

              decoration: InputDecoration(
                labelText: 'Latitude',

                hintText: '-7.360680',

                prefixIcon: const Icon(Icons.my_location),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: longitudeController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,

                signed: true,
              ),

              decoration: InputDecoration(
                labelText: 'Longitude',

                hintText: '108.105797',

                prefixIcon: const Icon(Icons.location_on),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}