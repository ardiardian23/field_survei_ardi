import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({
    super.key,
    required this.token,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;
  bool isUpdating = false;

  String name = '';
  String username = '';
  String email = '';
  String phone = '';
  String gender = '';
  String photo = '';
  String birthPlace = '';
  String birthDate = '';

  XFile? selectedPhoto;
  Uint8List? selectedPhotoBytes;

  // Foto yang diambil dari API menggunakan endpoint photo
  Uint8List? profilePhotoBytes;

  // Untuk cache busting foto
  int photoVersion = 0;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  // ============================================================
  // GET PHOTO URL
  // ============================================================

  String getPhotoUrl(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    String url = value.trim();

    // Kalau URL lengkap
    if (url.startsWith('http://') ||
        url.startsWith('https://')) {
      return url;
    }

    // Kalau diawali /
    if (url.startsWith('/')) {
      return 'https://sijala.biz.id$url';
    }

    // Kalau storage/...
    if (url.startsWith('storage/')) {
      return 'https://sijala.biz.id/$url';
    }

    // Default
    return 'https://sijala.biz.id/storage/$url';
  }

  // ============================================================
  // CACHE BUSTING
  // ============================================================

  String addCacheBust(String url) {
    if (url.isEmpty) {
      return url;
    }

    if (photoVersion == 0) {
      return url;
    }

    final separator =
        url.contains('?') ? '&' : '?';

    return '$url${separator}v=$photoVersion';
  }

  // ============================================================
  // PARSE TANGGAL
  // ============================================================

  DateTime? parseBirthDate(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    try {
      // dd-MM-yyyy
      if (RegExp(
        r'^\d{2}-\d{2}-\d{4}$',
      ).hasMatch(text)) {
        final parts = text.split('-');

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      // yyyy-MM-dd
      if (RegExp(
        r'^\d{4}-\d{2}-\d{2}$',
      ).hasMatch(text)) {
        return DateTime.parse(text);
      }
    } catch (e) {
      debugPrint(
        'PARSE DATE ERROR: $e',
      );
    }

    return null;
  }

  // ============================================================
  // FORMAT TANGGAL UNTUK API
  // ============================================================

  String formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // FORMAT TANGGAL UNTUK DISPLAY
  // ============================================================

  String formatDateForDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year.toString().padLeft(4, '0')}';
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  Future<void> getProfile() async {
    try {
      debugPrint('================================');
      debugPrint('MEMULAI GET PROFILE');
      debugPrint('================================');

      final response = await http.get(
        Uri.parse(
          'https://sijala.biz.id/api/v1/profile',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization':
              'Bearer ${widget.token}',
        },
      );

      if (!mounted) {
        return;
      }

      debugPrint('================================');
      debugPrint('GET PROFILE RESULT');
      debugPrint(
        'STATUS: ${response.statusCode}',
      );
      debugPrint(
        'BODY: ${response.body}',
      );
      debugPrint('================================');

      if (response.statusCode != 200) {
        setState(() {
          isLoading = false;
        });

        showMessage(
          'Gagal mengambil profil.\n'
          'Status: ${response.statusCode}',
        );

        return;
      }

      // ==========================================================
      // DECODE RESPONSE
      // ==========================================================

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        debugPrint(
          'RESPONSE BUKAN OBJECT',
        );

        setState(() {
          isLoading = false;
        });

        showMessage(
          'Format data profil tidak valid',
        );

        return;
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(decoded);

      // ==========================================================
      // AMBIL DATA
      // ==========================================================

      dynamic profileData = data['data'];

      if (profileData is! Map) {
        profileData = data;
      }

      if (profileData is! Map) {
        setState(() {
          isLoading = false;
        });

        showMessage(
          'Data profil tidak ditemukan',
        );

        return;
      }

      final Map<String, dynamic> profile =
          Map<String, dynamic>.from(
        profileData,
      );

      // ==========================================================
      // AMBIL FIELD DENGAN AMAN
      // ==========================================================

      final String nameResult =
          profile['name'] == null
              ? ''
              : '${profile['name']}';

      final String usernameResult =
          profile['username'] == null
              ? ''
              : '${profile['username']}';

      final String emailResult =
          profile['email'] == null
              ? ''
              : '${profile['email']}';

      final String phoneResult =
          profile['phone'] == null
              ? ''
              : '${profile['phone']}';

      final String photoResult =
          profile['photo'] == null
              ? ''
              : '${profile['photo']}';

      final String birthPlaceResult =
          profile['birth_place'] == null
              ? ''
              : '${profile['birth_place']}';

      String birthDateResult =
          profile['birth_date'] == null
              ? ''
              : '${profile['birth_date']}';

      // ==========================================================
      // GENDER
      // ==========================================================

      final String genderValue =
          profile['gender'] == null
              ? ''
              : '${profile['gender']}'
                  .trim()
                  .toUpperCase();

      String genderResult = '';

      if (genderValue == 'L' ||
          genderValue == 'LAKI-LAKI' ||
          genderValue == 'LAKI LAKI') {
        genderResult = 'L';
      } else if (genderValue == 'P' ||
          genderValue == 'PEREMPUAN') {
        genderResult = 'P';
      }

      // ==========================================================
      // TANGGAL
      // ==========================================================

      final parsedDate =
          parseBirthDate(
        birthDateResult,
      );

      if (parsedDate != null) {
        birthDateResult =
            formatDateForDisplay(
          parsedDate,
        );
      }

      // ==========================================================
      // DEBUG
      // ==========================================================

      debugPrint(
        'NAME       : $nameResult',
      );

      debugPrint(
        'USERNAME   : $usernameResult',
      );

      debugPrint(
        'EMAIL      : $emailResult',
      );

      debugPrint(
        'PHONE      : $phoneResult',
      );

      debugPrint(
        'GENDER     : $genderResult',
      );

      debugPrint(
        'PHOTO      : $photoResult',
      );

      debugPrint(
        'BIRTH PLACE: $birthPlaceResult',
      );

      debugPrint(
        'BIRTH DATE : $birthDateResult',
      );

      // ==========================================================
      // SET STATE
      // ==========================================================

      setState(() {
        name = nameResult;
        username = usernameResult;
        email = emailResult;
        phone = phoneResult;
        gender = genderResult;
        photo = photoResult;
        birthPlace = birthPlaceResult;
        birthDate = birthDateResult;
        isLoading = false;
      });

      // ==========================================================
      // LOAD FOTO
      // ==========================================================

      if (photoResult.isNotEmpty) {
        if (photoResult.startsWith(
              'http://',
            ) ||
            photoResult.startsWith(
              'https://',
            )) {
          // Foto sudah URL lengkap
          debugPrint(
            'FOTO BERUPA URL',
          );

          if (mounted) {
            setState(() {
              profilePhotoBytes = null;
            });
          }
        } else {
          // Foto berupa nama file
          debugPrint(
            'FOTO BERUPA NAMA FILE',
          );

          await loadProfilePhoto(
            photoResult,
          );
        }
      } else {
        if (mounted) {
          setState(() {
            profilePhotoBytes = null;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('GET PROFILE ERROR');
      debugPrint('ERROR: $e');
      debugPrint(
        'STACK: $stackTrace',
      );
      debugPrint('================================');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal mengambil data profil.\n$e',
      );
    }
  }

  // ============================================================
  // LOAD FOTO DARI API
  // ============================================================

  Future<void> loadProfilePhoto(
    String fileName,
  ) async {
    try {
      final cleanFileName =
          fileName.trim();

      if (cleanFileName.isEmpty) {
        return;
      }

      debugPrint('================================');
      debugPrint('LOAD PROFILE PHOTO');
      debugPrint(
        'FILE: $cleanFileName',
      );
      debugPrint('================================');

      final response = await http.get(
        Uri.parse(
          'https://sijala.biz.id/api/v1/profile/photo/'
          '${Uri.encodeComponent(cleanFileName)}',
        ),
        headers: {
          'Accept': 'image/*',
          'Authorization':
              'Bearer ${widget.token}',
        },
      );

      debugPrint(
        'PHOTO STATUS: ${response.statusCode}',
      );

      debugPrint(
        'PHOTO SIZE: ${response.bodyBytes.length}',
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        setState(() {
          profilePhotoBytes =
              response.bodyBytes;
        });

        debugPrint(
          'FOTO BERHASIL DILOAD',
        );
      } else {
        setState(() {
          profilePhotoBytes = null;
        });

        debugPrint(
          'FOTO GAGAL DILOAD',
        );

        debugPrint(
          'PHOTO BODY: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint(
        'LOAD PROFILE PHOTO ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        profilePhotoBytes = null;
      });
    }
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> pickProfilePhoto(
    void Function(void Function())
        setModalState,
  ) async {
    try {
      final picker =
          ImagePicker();

      final XFile? pickedFile =
          await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile == null) {
        return;
      }

      final Uint8List bytes =
          await pickedFile.readAsBytes();

      if (bytes.isEmpty) {
        showMessage(
          'Foto yang dipilih kosong',
        );

        return;
      }

      setModalState(() {
        selectedPhoto = pickedFile;
        selectedPhotoBytes = bytes;
      });

      debugPrint('================================');
      debugPrint('FOTO DIPILIH');
      debugPrint(
        'NAMA: ${pickedFile.name}',
      );
      debugPrint(
        'SIZE: ${bytes.length} bytes',
      );
      debugPrint('================================');
    } catch (e) {
      debugPrint(
        'PICK PHOTO ERROR: $e',
      );

      showMessage(
        'Gagal memilih foto.\n$e',
      );
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile({
    required BuildContext modalContext,
    required void Function(
      void Function(),
    ) setModalState,
    required String newName,
    required String newEmail,
    required String newPhone,
    required String newGender,
    required String newBirthPlace,
    required String newBirthDate,
  }) async {
    setModalState(() {
      isUpdating = true;
    });

    try {
      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://sijala.biz.id/api/v1/profile/update',
        ),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization':
            'Bearer ${widget.token}',
      });

      // ==========================================================
      // FIELD PROFILE
      // ==========================================================

      request.fields['name'] =
          newName;

      request.fields['email'] =
          newEmail;

      request.fields['phone'] =
          newPhone;

      request.fields['gender'] =
          newGender;

      request.fields['birth_place'] =
          newBirthPlace;

      request.fields['birth_date'] =
          newBirthDate;

      // ==========================================================
      // FOTO
      // ==========================================================

      if (selectedPhoto != null &&
          selectedPhotoBytes != null &&
          selectedPhotoBytes!.isNotEmpty) {
        final String fileName =
            selectedPhoto!.name.isNotEmpty
                ? selectedPhoto!.name
                : 'profile.jpg';

        debugPrint('================================');
        debugPrint('UPLOAD FOTO');
        debugPrint(
          'FIELD: photo',
        );
        debugPrint(
          'FILENAME: $fileName',
        );
        debugPrint(
          'SIZE: ${selectedPhotoBytes!.length} bytes',
        );
        debugPrint('================================');

        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedPhotoBytes!,
            filename: fileName,
          ),
        );
      } else {
        debugPrint(
          'TIDAK ADA FOTO BARU',
        );
      }

      // ==========================================================
      // DEBUG REQUEST
      // ==========================================================

      debugPrint('================================');
      debugPrint('MENGIRIM UPDATE PROFILE');
      debugPrint(
        'NAME: $newName',
      );
      debugPrint(
        'EMAIL: $newEmail',
      );
      debugPrint(
        'PHONE: $newPhone',
      );
      debugPrint(
        'GENDER: $newGender',
      );
      debugPrint(
        'BIRTH PLACE: $newBirthPlace',
      );
      debugPrint(
        'BIRTH DATE: $newBirthDate',
      );
      debugPrint(
        'ADA FOTO: ${selectedPhotoBytes != null}',
      );
      debugPrint(
        'JUMLAH FILE: ${request.files.length}',
      );
      debugPrint('================================');

      // ==========================================================
      // SEND REQUEST
      // ==========================================================

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      if (!mounted) {
        return;
      }

      debugPrint('================================');
      debugPrint('UPDATE PROFILE RESULT');
      debugPrint(
        'STATUS: ${response.statusCode}',
      );
      debugPrint(
        'BODY: ${response.body}',
      );
      debugPrint('================================');

      // ==========================================================
      // BERHASIL
      // ==========================================================

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        debugPrint(
          'UPDATE PROFILE BERHASIL',
        );

        // ========================================================
        // RESPONSE FOTO
        // ========================================================

        try {
          final dynamic result =
              jsonDecode(response.body);

          if (result is Map) {
            dynamic resultData =
                result['data'];

            if (resultData is! Map) {
              resultData = result;
            }

            if (resultData is Map) {
              final dynamic newPhoto =
                  resultData['photo'];

              if (newPhoto != null) {
                debugPrint(
                  'FOTO BARU DARI RESPONSE: '
                  '$newPhoto',
                );
              }
            }
          }
        } catch (e) {
          debugPrint(
            'RESPONSE BUKAN JSON: $e',
          );
        }

        // ========================================================
        // FOTO CACHE
        // ========================================================

        photoVersion =
            DateTime.now()
                .millisecondsSinceEpoch;

        // ========================================================
        // TUTUP MODAL
        // ========================================================

        if (Navigator.of(
          modalContext,
        ).canPop()) {
          Navigator.of(
            modalContext,
          ).pop();
        }

        // ========================================================
        // RESET FOTO
        // ========================================================

        selectedPhoto = null;
        selectedPhotoBytes = null;
        profilePhotoBytes = null;

        // ========================================================
        // REFRESH PROFILE
        // ========================================================

        if (mounted) {
          setState(() {
            isLoading = true;
          });
        }

        await getProfile();

        if (!mounted) {
          return;
        }

        showMessage(
          'Profil berhasil diperbarui',
        );

        return;
      }

      // ==========================================================
      // GAGAL
      // ==========================================================

      setModalState(() {
        isUpdating = false;
      });

      String message =
          'Gagal memperbarui profil.\n'
          'Status: ${response.statusCode}';

      try {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          final dynamic apiMessage =
              decoded['message'];

          if (apiMessage != null) {
            message =
                '$apiMessage';
          }

          final dynamic errorData =
              decoded['errors'];

          if (errorData is Map) {
            final List<String>
                errorMessages = [];

            errorData.forEach(
              (key, value) {
                if (value is List) {
                  for (final item
                      in value) {
                    errorMessages.add(
                      '$key: $item',
                    );
                  }
                } else {
                  errorMessages.add(
                    '$key: $value',
                  );
                }
              },
            );

            if (errorMessages.isNotEmpty) {
              message =
                  errorMessages.join(
                '\n',
              );
            }
          }
        }
      } catch (e) {
        debugPrint(
          'ERROR PARSE RESPONSE: $e',
        );
      }

      showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('UPDATE PROFILE ERROR');
      debugPrint('ERROR: $e');
      debugPrint(
        'STACK: $stackTrace',
      );
      debugPrint('================================');

      if (!mounted) {
        return;
      }

      setModalState(() {
        isUpdating = false;
      });

      showMessage(
        'Gagal terhubung ke server.\n$e',
      );
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void showEditProfile() {
    final nameController =
        TextEditingController(
      text: name,
    );

    final emailController =
        TextEditingController(
      text: email,
    );

    final phoneController =
        TextEditingController(
      text: phone,
    );

    final birthPlaceController =
        TextEditingController(
      text: birthPlace,
    );

    final parsedBirthDate =
        parseBirthDate(
      birthDate,
    );

    final birthDateController =
        TextEditingController(
      text: parsedBirthDate != null
          ? formatDateForDisplay(
              parsedBirthDate,
            )
          : birthDate,
    );

    selectedPhoto = null;
    selectedPhotoBytes = null;

    String selectedGender =
        gender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (
            modalContext,
            setModalState,
          ) {
            return Container(
              height:
                  MediaQuery.of(
                        modalContext,
                      ).size.height *
                      0.90,
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFF4F46E5),
                      borderRadius:
                          BorderRadius.vertical(
                        top: Radius.circular(
                          25,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        modalContext,
                                      );
                                    },
                          icon:
                              const Icon(
                            Icons.close,
                            color:
                                Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Edit Profil',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 48,
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // FORM
                  // ==================================================

                  Expanded(
                    child:
                        SingleChildScrollView(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          // ==================================================
                          // FOTO
                          // ==================================================

                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 65,
                                  backgroundColor:
                                      const Color(
                                    0xFFE0F2EF,
                                  ),
                                  child:
                                      ClipOval(
                                    child:
                                        selectedPhotoBytes !=
                                                null
                                            ? Image.memory(
                                                selectedPhotoBytes!,
                                                width:
                                                    130,
                                                height:
                                                    130,
                                                fit:
                                                    BoxFit.cover,
                                              )
                                            : profilePhotoBytes !=
                                                    null
                                                ? Image.memory(
                                                    profilePhotoBytes!,
                                                    width:
                                                        130,
                                                    height:
                                                        130,
                                                    fit:
                                                        BoxFit.cover,
                                                  )
                                                : photo.isNotEmpty &&
                                                        (photo.startsWith(
                                                              'http://',
                                                            ) ||
                                                            photo.startsWith(
                                                              'https://',
                                                            ))
                                                    ? Image.network(
                                                        addCacheBust(
                                                          photo,
                                                        ),
                                                        width:
                                                            130,
                                                        height:
                                                            130,
                                                        fit:
                                                            BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          debugPrint(
                                                            'ERROR FOTO: $error',
                                                          );

                                                          return const Icon(
                                                            Icons.person,
                                                            size:
                                                                75,
                                                            color:
                                                                Color(0xFF4F46E5),
                                                          );
                                                        },
                                                      )
                                                    : const Icon(
                                                        Icons.person,
                                                        size:
                                                            75,
                                                        color:
                                                            Color(0xFF4F46E5),
                                                      ),
                                  ),
                                ),

                                // ==================================================
                                // CAMERA
                                // ==================================================

                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child:
                                      GestureDetector(
                                    onTap:
                                        isUpdating
                                            ? null
                                            : () {
                                                pickProfilePhoto(
                                                  setModalState,
                                                );
                                              },
                                    child:
                                        Container(
                                      width:
                                          45,
                                      height:
                                          45,
                                      decoration:
                                          const BoxDecoration(
                                        color:
                                            Color(0xFF4F46E5),
                                        shape:
                                            BoxShape.circle,
                                      ),
                                      child:
                                          const Icon(
                                        Icons
                                            .camera_alt,
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Center(
                            child:
                                TextButton.icon(
                              onPressed:
                                  isUpdating
                                      ? null
                                      : () {
                                          pickProfilePhoto(
                                            setModalState,
                                          );
                                        },
                              icon:
                                  const Icon(
                                Icons
                                    .photo_library_outlined,
                                color:
                                    Color(
                                  0xFF4F46E5,
                                ),
                              ),
                              label:
                                  const Text(
                                'Ubah Foto Profil',
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF4F46E5,
                                  ),
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==================================================
                          // NAMA
                          // ==================================================

                          _inputField(
                            controller:
                                nameController,
                            label:
                                'Nama',
                            icon:
                                Icons
                                    .person_outline,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==================================================
                          // USERNAME
                          // ==================================================

                          TextField(
                            enabled: false,
                            controller:
                                TextEditingController(
                              text:
                                  username,
                            ),
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Username',
                              prefixIcon:
                                  const Icon(
                                Icons
                                    .account_circle_outlined,
                              ),
                              filled:
                                  true,
                              fillColor:
                                  Colors
                                      .grey
                                      .shade200,
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    BorderSide
                                        .none,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==================================================
                          // EMAIL
                          // ==================================================

                          _inputField(
                            controller:
                                emailController,
                            label:
                                'Email',
                            icon:
                                Icons
                                    .email_outlined,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==================================================
                          // TELEPON
                          // ==================================================

                          _inputField(
                            controller:
                                phoneController,
                            label:
                                'Nomor Telepon',
                            icon:
                                Icons
                                    .phone_outlined,
                            keyboardType:
                                TextInputType.phone,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==================================================
                          // GENDER
                          // ==================================================

                          DropdownButtonFormField<
                              String>(
                            value:
                                selectedGender ==
                                            'L' ||
                                        selectedGender ==
                                            'P'
                                    ? selectedGender
                                    : null,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Jenis Kelamin',
                              prefixIcon:
                                  const Icon(
                                Icons.wc_outlined,
                              ),
                              filled:
                                  true,
                              fillColor:
                                  const Color(
                                0xFFF8F9FA,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    BorderSide
                                        .none,
                              ),
                            ),
                            items:
                                const [
                              DropdownMenuItem(
                                value: 'L',
                                child: Text(
                                  'Laki-Laki',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'P',
                                child: Text(
                                  'Perempuan',
                                ),
                              ),
                            ],
                            onChanged:
                                isUpdating
                                    ? null
                                    : (value) {
                                        setModalState(
                                          () {
                                            selectedGender =
                                                value ??
                                                    '';
                                          },
                                        );
                                      },
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==================================================
                          // TEMPAT LAHIR
                          // ==================================================

                          _inputField(
                            controller:
                                birthPlaceController,
                            label:
                                'Tempat Lahir',
                            icon:
                                Icons
                                    .location_on_outlined,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==================================================
                          // TANGGAL LAHIR
                          // ==================================================

                          TextField(
                            controller:
                                birthDateController,
                            readOnly: true,
                            onTap:
                                isUpdating
                                    ? null
                                    : () async {
                                        final initialDate =
                                            parsedBirthDate ??
                                                DateTime(
                                                  2000,
                                                  1,
                                                  1,
                                                );

                                        final selectedDate =
                                            await showDatePicker(
                                          context:
                                              modalContext,
                                          initialDate:
                                              initialDate,
                                          firstDate:
                                              DateTime(
                                            1950,
                                          ),
                                          lastDate:
                                              DateTime.now(),
                                        );

                                        if (selectedDate !=
                                            null) {
                                          setModalState(
                                            () {
                                              birthDateController
                                                      .text =
                                                  formatDateForDisplay(
                                                selectedDate,
                                              );
                                            },
                                          );
                                        }
                                      },
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Tanggal Lahir',
                              prefixIcon:
                                  const Icon(
                                Icons
                                    .calendar_today_outlined,
                              ),
                              suffixIcon:
                                  const Icon(
                                Icons
                                    .arrow_drop_down,
                              ),
                              filled:
                                  true,
                              fillColor:
                                  const Color(
                                0xFFF8F9FA,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    BorderSide
                                        .none,
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(
                                    0xFF4F46E5,
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          // ==================================================
                          // SIMPAN
                          // ==================================================

                          SizedBox(
                            width:
                                double.infinity,
                            height: 55,
                            child:
                                ElevatedButton(
                              onPressed:
                                  isUpdating
                                      ? null
                                      : () async {
                                          final newName =
                                              nameController
                                                  .text
                                                  .trim();

                                          final newEmail =
                                              emailController
                                                  .text
                                                  .trim();

                                          final newPhone =
                                              phoneController
                                                  .text
                                                  .trim();

                                          final newBirthPlace =
                                              birthPlaceController
                                                  .text
                                                  .trim();

                                          final dateText =
                                              birthDateController
                                                  .text
                                                  .trim();

                                          // ==================================================
                                          // VALIDASI
                                          // ==================================================

                                          if (newName
                                              .isEmpty) {
                                            showMessage(
                                              'Nama harus diisi',
                                            );
                                            return;
                                          }

                                          if (newEmail
                                              .isEmpty) {
                                            showMessage(
                                              'Email harus diisi',
                                            );
                                            return;
                                          }

                                          final emailRegex =
                                              RegExp(
                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                          );

                                          if (!emailRegex
                                              .hasMatch(
                                            newEmail,
                                          )) {
                                            showMessage(
                                              'Format email tidak valid',
                                            );
                                            return;
                                          }

                                          if (newPhone
                                              .isEmpty) {
                                            showMessage(
                                              'Nomor telepon harus diisi',
                                            );
                                            return;
                                          }

                                          if (selectedGender !=
                                                  'L' &&
                                              selectedGender !=
                                                  'P') {
                                            showMessage(
                                              'Jenis kelamin harus dipilih',
                                            );
                                            return;
                                          }

                                          if (newBirthPlace
                                              .isEmpty) {
                                            showMessage(
                                              'Tempat lahir harus diisi',
                                            );
                                            return;
                                          }

                                          if (dateText
                                              .isEmpty) {
                                            showMessage(
                                              'Tanggal lahir harus diisi',
                                            );
                                            return;
                                          }

                                          final parsedDate =
                                              parseBirthDate(
                                            dateText,
                                          );

                                          if (parsedDate ==
                                              null) {
                                            showMessage(
                                              'Tanggal lahir tidak valid',
                                            );
                                            return;
                                          }

                                          final formattedBirthDate =
                                              formatDateForApi(
                                            parsedDate,
                                          );

                                          debugPrint(
                                            'TANGGAL FORM: $dateText',
                                          );

                                          debugPrint(
                                            'TANGGAL API: $formattedBirthDate',
                                          );

                                          // ==================================================
                                          // UPDATE
                                          // ==================================================

                                          await updateProfile(
                                            modalContext:
                                                modalContext,
                                            setModalState:
                                                setModalState,
                                            newName:
                                                newName,
                                            newEmail:
                                                newEmail,
                                            newPhone:
                                                newPhone,
                                            newGender:
                                                selectedGender,
                                            newBirthPlace:
                                                newBirthPlace,
                                            newBirthDate:
                                                formattedBirthDate,
                                          );
                                        },
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xFF4F46E5,
                                ),
                                foregroundColor:
                                    Colors.white,
                                disabledBackgroundColor:
                                    const Color(
                                  0xFF80AFA4,
                                ),
                                elevation: 0,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    15,
                                  ),
                                ),
                              ),
                              child: isUpdating
                                  ? const SizedBox(
                                      width: 25,
                                      height: 25,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth:
                                            3,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Perubahan',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      birthPlaceController.dispose();
      birthDateController.dispose();

      selectedPhoto = null;
      selectedPhotoBytes = null;

      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    });
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor:
            const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF4F46E5),
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Logout'),
          content:
              const Text(
            'Apakah kamu yakin ingin logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                try {
                  final response =
                      await http.post(
                    Uri.parse(
                      'https://sijala.biz.id/api/v1/logout',
                    ),
                    headers: {
                      'Accept':
                          'application/json',
                      'Authorization':
                          'Bearer ${widget.token}',
                    },
                  );

                  if (response.statusCode ==
                          200 ||
                      response.statusCode ==
                          204 ||
                      response.statusCode ==
                          401) {
                    final prefs =
                        await SharedPreferences
                            .getInstance();

                    await prefs.remove(
                      'token',
                    );

                    if (!mounted) {
                      return;
                    }

                    Navigator
                        .pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const LoginPage(),
                      ),
                      (route) => false,
                    );
                  } else {
                    if (!mounted) {
                      return;
                    }

                    showMessage(
                      'Logout gagal. '
                      'Status: '
                      '${response.statusCode}',
                    );
                  }
                } catch (e) {
                  if (!mounted) {
                    return;
                  }

                  showMessage(
                    'Gagal terhubung ke server.\n$e',
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF4F46E5),
        foregroundColor:
            Colors.white,
        elevation: 0,
        title:
            const Text(
          'Profil',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF4F46E5),
              ),
            )
          : RefreshIndicator(
              color:
                  const Color(
                0xFF4F46E5,
              ),
              onRefresh:
                  getProfile,
              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child:
                    Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // FOTO PROFIL
                    // ==================================================

                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          const Color(
                        0xFFE0F2EF,
                      ),
                      child:
                          ClipOval(
                        child:
                            profilePhotoBytes !=
                                    null
                                ? Image.memory(
                                    profilePhotoBytes!,
                                    width:
                                        120,
                                    height:
                                        120,
                                    fit:
                                        BoxFit.cover,
                                  )
                                : photo.isNotEmpty &&
                                        (photo.startsWith(
                                              'http://',
                                            ) ||
                                            photo.startsWith(
                                              'https://',
                                            ))
                                    ? Image.network(
                                        addCacheBust(
                                          photo,
                                        ),
                                        width:
                                            120,
                                        height:
                                            120,
                                        fit:
                                            BoxFit.cover,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          debugPrint(
                                            'ERROR FOTO PROFILE: $error',
                                          );

                                          return const Icon(
                                            Icons.person,
                                            size:
                                                70,
                                            color:
                                                Color(0xFF4F46E5),
                                          );
                                        },
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size:
                                            70,
                                        color:
                                            Color(0xFF4F46E5),
                                      ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ==================================================
                    // NAMA
                    // ==================================================

                    Text(
                      name.isNotEmpty
                          ? name
                          : '-',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(
                          0xFF263238,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // ==================================================
                    // USERNAME
                    // ==================================================

                    Text(
                      username.isNotEmpty
                          ? '@$username'
                          : '-',
                      style:
                          const TextStyle(
                        fontSize: 15,
                        color:
                            Color(
                          0xFF78909C,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ==================================================
                    // EDIT BUTTON
                    // ==================================================

                    OutlinedButton.icon(
                      onPressed:
                          showEditProfile,
                      icon:
                          const Icon(
                        Icons
                            .edit_outlined,
                      ),
                      label:
                          const Text(
                        'Edit Profil',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(
                          0xFF4F46E5,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Color(
                            0xFF4F46E5,
                          ),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // ==================================================
                    // INFORMASI AKUN
                    // ==================================================

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                              0.04,
                            ),
                            blurRadius:
                                10,
                            offset:
                                const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Informasi Akun',
                            style:
                                TextStyle(
                              fontSize:
                                  20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          _profileItem(
                            icon: Icons
                                .person_outline,
                            title:
                                'Nama',
                            value:
                                name,
                          ),

                          const Divider(
                            height: 30,
                          ),

                          _profileItem(
                            icon: Icons
                                .account_circle_outlined,
                            title:
                                'Username',
                            value:
                                username,
                          ),

                          const Divider(
                            height: 30,
                          ),

                          _profileItem(
                            icon: Icons
                                .email_outlined,
                            title:
                                'Email',
                            value:
                                email,
                          ),

                          const Divider(
                            height: 30,
                          ),

                          _profileItem(
                            icon: Icons
                                .phone_outlined,
                            title:
                                'Nomor Telepon',
                            value:
                                phone,
                          ),

                          const Divider(
                            height: 30,
                          ),

                          _profileItem(
                            icon: Icons
                                .wc_outlined,
                            title:
                                'Jenis Kelamin',
                            value:
                                gender == 'L'
                                    ? 'Laki-Laki'
                                    : gender == 'P'
                                        ? 'Perempuan'
                                        : '',
                          ),

                          const Divider(
                            height: 30,
                          ),

                          _profileItem(
                            icon: Icons
                                .location_on_outlined,
                            title:
                                'Tempat Lahir',
                            value:
                                birthPlace,
                          ),

                          const Divider(
                            height: 30,
                          ),

                          _profileItem(
                            icon: Icons
                                .calendar_today_outlined,
                            title:
                                'Tanggal Lahir',
                            value:
                                birthDate,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ==================================================
                    // LOGOUT
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 55,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            logout,
                        icon:
                            const Icon(
                          Icons.logout,
                        ),
                        label:
                            const Text(
                          'Logout',
                          style:
                              TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors
                                  .red
                                  .shade600,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PROFILE ITEM
  // ============================================================

  Widget _profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFE0F2EF,
            ),
            borderRadius:
                BorderRadius
                    .circular(
              12,
            ),
          ),
          child:
              Icon(
            icon,
            color:
                const Color(
              0xFF4F46E5,
            ),
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      Color(
                    0xFF90A4AE,
                  ),
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                value.isNotEmpty
                    ? value
                    : '-',
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(
                    0xFF263238,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}