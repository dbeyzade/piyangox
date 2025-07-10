import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../core/navigation.dart';

class CreateTicketPage extends StatefulWidget {
  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _countController =
      TextEditingController(text: '100');
  bool _loading = false;
  final _random = Random();

  Set<String> _generateUniqueNumbers(int count) {
    final Set<String> numbers = {};
    while (numbers.length < count) {
      final number = List.generate(6, (_) => _random.nextInt(10)).join();
      numbers.add(number);
    }
    return numbers;
  }

  Future<void> _createTickets() async {
    final count = int.tryParse(_countController.text);
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Geçerli bir sayı girin')));
      return;
    }

    setState(() => _loading = true);

    final numbers = _generateUniqueNumbers(count);

    // Yarın saat 20:00'de çekiliş yapılacak
    final drawDate = DateTime.now().add(Duration(days: 1)).copyWith(
          hour: 20,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );

    final inserts = numbers
        .map((n) => {
              'number': n,
              'status': 'musaid',
              'published': false,
              'draw_date': drawDate.toIso8601String(),
            })
        .toList();

    try {
      await supabase.from('tickets').insert(inserts);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$count bilet oluşturuldu')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bilet Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: 'Kaç adet bilet oluşturulsun?'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _createTickets,
              child: _loading
                  ? CircularProgressIndicator()
                  : Text('Biletleri Oluştur'),
            )
          ],
        ),
      ),
    );
  }
}
