import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chord_detail_screen.dart';

class ChordsScreen extends StatefulWidget {
  const ChordsScreen({super.key});

  @override
  State<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends State<ChordsScreen> {
  List<dynamic> _chords = [];
  List<dynamic> _filteredChords = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchChords();
  }

  Future<void> fetchChords() async {
    final Uri url = Uri.parse("https://guitar-chords-api-kaize.vercel.app/");

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        String body = response.body.trim();

        if (body.startsWith('{') || body.startsWith('[')) {
          final jsonResponse = jsonDecode(body);

          if (jsonResponse is List) {
            setState(() {
              _chords = jsonResponse;
              _filteredChords = _chords;
              _isLoading = false;
            });
          } else if (jsonResponse is Map &&
              jsonResponse["status"] == "success" &&
              jsonResponse["data"] != null) {
            setState(() {
              _chords = jsonResponse["data"];
              _filteredChords = _chords;
              _isLoading = false;
            });
          } else {
            throw Exception("Invalid JSON structure");
          }
        } else {
          throw Exception("Invalid response format (not JSON)");
        }
      } else {
        throw Exception("Failed to connect to API (${response.statusCode})");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading chords: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _filterChords(String query) {
    setState(() {
      _filteredChords = _chords
          .where((chord) =>
              chord['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      if (_selectedFilter != 'All') {
        _filteredChords = _filteredChords
            .where((chord) =>
                chord['name'].toString().startsWith(_selectedFilter))
            .toList();
      }
    });
  }

  void _applyLetterFilter(String letter) {
    setState(() {
      _selectedFilter = letter;
      if (letter == 'All') {
        _filteredChords = _chords;
      } else {
        _filteredChords =
            _chords.where((c) => c['name'].toString().startsWith(letter)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Let your fingers tell the story through every chord.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),

                // Search Box
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.lightBlueAccent),
                      hintText: 'Search chord...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    ),
                    onChanged: _filterChords,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Filter by:", style: TextStyle(color: Colors.white70)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF2B2B2B),
                          value: _selectedFilter,
                          items: ['All', 'A', 'B', 'C', 'D', 'E', 'F', 'G']
                              .map((letter) => DropdownMenuItem(
                                    value: letter,
                                    child:
                                        Text(letter, style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) _applyLetterFilter(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
                      : _filteredChords.isEmpty
                          ? const Center(
                              child: Text('No chords found', style: TextStyle(color: Colors.white70)),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: _filteredChords.length,
                              itemBuilder: (context, index) {
                                final chord = _filteredChords[index];
                                final imageUrl = chord['image_url'] ?? '';

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChordDetailScreen(
                                          name: chord['name'],
                                          imageUrl: imageUrl,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D1D1D),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        imageUrl.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  imageUrl,
                                                  height: 100,
                                                  width: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Icon(Icons.music_note,
                                                color: Colors.lightBlueAccent, size: 60),
                                        const SizedBox(height: 14),
                                        Text(
                                          chord['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
