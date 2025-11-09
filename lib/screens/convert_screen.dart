import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_music_screen.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double? _convertedPrice;
  bool _isLoading = false;

  static const Color mainColor = Color(0xFF42A5F5);

  final List<String> _currencies = ['USD', 'IDR', 'EUR', 'JPY'];
  final NumberFormat _inputFormatter = NumberFormat('#,###', 'en_US');
  final NumberFormat _outputFormatter = NumberFormat('#,##0.00', 'en_US');
  bool _isFormatting = false;

  List<Map<String, dynamic>> _recentConversions = [];
  final String _currentUser = 'user_login_123';
  bool _showRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentConversions();

    _priceController.addListener(() {
      if (_isFormatting) return;
      String raw = _priceController.text.replaceAll(',', '');
      if (raw.isEmpty) return;
      final parsed = double.tryParse(raw);
      if (parsed == null) return;
      final formatted = _inputFormatter.format(parsed.round());
      if (formatted != _priceController.text) {
        _isFormatting = true;
        _priceController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        _isFormatting = false;
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentConversions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('conversions_$_currentUser');
    if (saved != null) {
      final List<dynamic> decoded = json.decode(saved);
      setState(() {
        _recentConversions = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveConversion(String name, double fromValue, double toValue) async {
    final prefs = await SharedPreferences.getInstance();

    final newItem = {
      'name': name,
      'from': '$_fromCurrency : ${_inputFormatter.format(fromValue)}',
      'to': '$_toCurrency : ${_outputFormatter.format(toValue)}',
    };

    _recentConversions.insert(0, newItem);
    if (_recentConversions.length > 3) {
      _recentConversions = _recentConversions.sublist(0, 3);
    }

    await prefs.setString('conversions_$_currentUser', json.encode(_recentConversions));
    setState(() {});
  }

  void _swapCurrencies() {
    setState(() {
      final tmp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tmp;
      _convertedPrice = null;
    });
  }

  Future<void> _convertPrice() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan harga terlebih dahulu!')),
      );
      return;
    }

    final cleanText = _priceController.text.replaceAll(',', '');
    final price = double.tryParse(cleanText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga tidak valid')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _convertedPrice = null;
    });

    final uri = Uri.parse('https://open.er-api.com/v6/latest/$_fromCurrency');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        if (rates.containsKey(_toCurrency)) {
          final rate = (rates[_toCurrency] as num).toDouble();
          final result = price * rate;
          setState(() {
            _convertedPrice = result;
          });
          await _saveConversion(_nameController.text, price, result);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan koneksi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _currencyDropdown(String value, bool isFrom) {
    return DropdownButton<String>(
      dropdownColor: Colors.grey[900],
      value: value,
      onChanged: (v) {
        if (v != null) {
          setState(() {
            if (isFrom) {
              _fromCurrency = v;
            } else {
              _toCurrency = v;
            }
            _convertedPrice = null;
          });
        }
      },
      items: _currencies
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Simplify guitar price checks, wherever music takes you.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 25),

              // Input gitar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Guitar Type',
                    hintStyle: TextStyle(color: Colors.white38),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input price
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _priceController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Price',
                    hintStyle: TextStyle(color: Colors.white38),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _currencyDropdown(_fromCurrency, true)),
                  IconButton(
                    onPressed: _swapCurrencies,
                    icon: const Icon(Icons.swap_horiz, color: Colors.lightBlueAccent),
                  ),
                  Expanded(child: _currencyDropdown(_toCurrency, false)),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol convert
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _convertPrice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Convert',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_convertedPrice != null)
                _buildResultCard(_nameController.text, _formatInputPriceSafely(), _convertedPrice!),

              if (_recentConversions.isNotEmpty) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => setState(() => _showRecent = !_showRecent),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Recent Converts',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Icon(
                        _showRecent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_showRecent)
                  for (var item in _recentConversions)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: mainColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'],
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 6),
                          Text(item['from'], style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          Text(item['to'], style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
              ],

              const SizedBox(height: 24),

              //Tombol find toko musik terdekat
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapMusicScreen()),
                    );
                  },
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text(
                    'Find the nearest music store',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String name, String fromVal, double toVal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gitar: $name', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 16)),
          const SizedBox(height: 8),
          Text('$_fromCurrency : $fromVal', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text('$_toCurrency : ${_outputFormatter.format(toVal)}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatInputPriceSafely() {
    final raw = _priceController.text.replaceAll(',', '');
    if (raw.isEmpty) return '0';
    final parsed = double.tryParse(raw);
    if (parsed == null) return _priceController.text;
    return _inputFormatter.format(parsed.round());
  }
}
