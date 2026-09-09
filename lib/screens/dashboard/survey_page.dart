import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'survey_detail.dart';
import 'survey_form.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  static const String apiUrl =
      'https://sijala.biz.id/api/v1/surveys';

  static const Color primaryColor =
      Color(0xFF4F46E5);

  bool isLoading = true;
  String? errorMessage;

  List<dynamic> surveys = [];

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  // ============================================================
  // GET DATA SURVEY
  // ============================================================

  Future<void> fetchSurveys() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      // ========================================================
      // TOKEN TIDAK ADA
      // ========================================================

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage =
              'Token tidak ditemukan. Silakan login kembali.';
        });

        return;
      }

      // ========================================================
      // REQUEST API
      // ========================================================

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'STATUS SURVEY : ${response.statusCode}',
      );

      debugPrint(
        'RESPONSE SURVEY : ${response.body}',
      );

      if (!mounted) return;

      // ========================================================
      // BERHASIL
      // ========================================================

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(response.body);

        List<dynamic> result = [];

        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            result = decoded['data'];
          } else if (decoded['surveys'] is List) {
            result = decoded['surveys'];
          }
        } else if (decoded is List) {
          result = decoded;
        }

        setState(() {
          surveys = result;
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // UNAUTHORIZED
      // ========================================================

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage =
              'Sesi login sudah habis. Silakan login kembali.';
        });

        return;
      }

      // ========================================================
      // ERROR API
      // ========================================================

      setState(() {
        isLoading = false;
        errorMessage =
            'Gagal mengambil data survey '
            '(${response.statusCode})';
      });
    } catch (e) {
      debugPrint(
        'ERROR SURVEY : $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Terjadi kesalahan koneksi.';
      });
    }
  }

  // ============================================================
  // TAMBAH SURVEY
  // ============================================================

  Future<void> openAddSurvey() async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SurveyFormPage(),
      ),
    );

    if (result == true && mounted) {
      await fetchSurveys();
    }
  }

  // ============================================================
  // DETAIL SURVEY
  // ============================================================

  Future<void> openDetail(
    int surveyId,
  ) async {
    if (surveyId <= 0) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('ID survey tidak valid'),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SurveyDetailPage(
          surveyId: surveyId,
        ),
      ),
    );

    if (result == true && mounted) {
      await fetchSurveys();
    }
  }

  // ============================================================
  // AMBIL ID SURVEY
  // ============================================================

  int getSurveyId(
    dynamic survey,
  ) {
    if (survey is! Map) {
      return 0;
    }

    final id = survey['id'];

    if (id is int) {
      return id;
    }

    return int.tryParse(
          id?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // AMBIL TEXT DARI DATA
  // ============================================================

  String getStringValue(
    dynamic survey,
    List<String> keys, {
    String defaultValue = '-',
  }) {
    if (survey is! Map) {
      return defaultValue;
    }

    for (final key in keys) {
      final value = survey[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return defaultValue;
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
          const Color(0xFFF5F7FF),

      appBar: AppBar(
        title: const Text(
          'Survey',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        backgroundColor:
            primaryColor,

        foregroundColor:
            Colors.white,

        elevation: 0,

        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : fetchSurveys,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _buildBody(),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            openAddSurvey,

        backgroundColor:
            primaryColor,

        foregroundColor:
            Colors.white,

        icon: const Icon(
          Icons.add,
        ),

        label:
            const Text(
          'Tambah Survey',
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              ElevatedButton.icon(
                onPressed:
                    fetchSurveys,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryColor,
                  foregroundColor:
                      Colors.white,
                ),

                icon: const Icon(
                  Icons.refresh,
                ),

                label:
                    const Text(
                  'Coba Lagi',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // DATA KOSONG
    // ==========================================================

    if (surveys.isEmpty) {
      return RefreshIndicator(
        onRefresh:
            fetchSurveys,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: const [
            SizedBox(
              height: 180,
            ),

            Icon(
              Icons
                  .assignment_outlined,
              size: 80,
              color: Colors.grey,
            ),

            SizedBox(
              height: 16,
            ),

            Center(
              child: Text(
                'Belum ada data survey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            SizedBox(
              height: 8,
            ),

            Center(
              child: Text(
                'Silakan tambahkan survey baru',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // LIST DATA SURVEY
    // ==========================================================

    return RefreshIndicator(
      onRefresh:
          fetchSurveys,

      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(16),

        itemCount:
            surveys.length,

        itemBuilder:
            (context, index) {
          final survey =
              surveys[index];

          final surveyId =
              getSurveyId(
            survey,
          );

          final category =
              getStringValue(
            survey,
            [
              'category',
              'kategori',
              'category_name',
            ],
            defaultValue:
                'Survey',
          );

          final title =
              getStringValue(
            survey,
            [
              'title',
              'judul',
              'nama',
            ],
            defaultValue:
                '',
          );

          final description =
              getStringValue(
            survey,
            [
              'description',
              'keterangan',
            ],
            defaultValue:
                '-',
          );

          final latitude =
              getStringValue(
            survey,
            [
              'latitude',
            ],
          );

          final longitude =
              getStringValue(
            survey,
            [
              'longitude',
            ],
          );

          final createdAt =
              getStringValue(
            survey,
            [
              'created_at',
            ],
          );

          // ====================================================
          // CARD
          // ====================================================

          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 14,
            ),

            elevation: 2,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),

            child: InkWell(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),

              onTap: () {
                openDetail(
                  surveyId,
                );
              },

              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    // ==========================================
                    // HEADER CARD
                    // ==========================================

                    Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFEDE9FE,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons.assignment,
                            color:
                                primaryColor,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                category,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      17,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              if (title
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        13,
                                    color:
                                        Colors
                                            .black54,
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'ID Survey: $surveyId',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      12,
                                  color:
                                      Colors
                                          .grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons
                              .arrow_forward_ios,
                          size: 18,
                          color:
                              Colors.grey,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==========================================
                    // DESKRIPSI
                    // ==========================================

                    Text(
                      description,
                      maxLines: 3,
                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 14,
                        color:
                            Colors.black87,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 8,
                    ),

                    // ==========================================
                    // LOKASI
                    // ==========================================

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 18,
                          color:
                              Colors.grey,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Expanded(
                          child: Text(
                            '$latitude, $longitude',
                            style:
                                const TextStyle(
                              fontSize:
                                  13,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // ==========================================
                    // TANGGAL
                    // ==========================================

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .calendar_today_outlined,
                          size: 16,
                          color:
                              Colors.grey,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          createdAt,
                          style:
                              const TextStyle(
                            fontSize:
                                12,
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}