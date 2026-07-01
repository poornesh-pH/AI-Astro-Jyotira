import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/prefs/birth_store.dart';
import '../domain/birth_details.dart';
 
class BirthForm extends ConsumerStatefulWidget {
  const BirthForm({super.key, this.redirectTo = '/'});
  final String redirectTo;
 
  @override
  ConsumerState<BirthForm> createState() => _BirthFormState();
}
 
class _BirthFormState extends ConsumerState<BirthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _placeCtrl = TextEditingController();
 
  String _gender = 'male';
  DateTime? _date;
  TimeOfDay? _time;
  City? _city;
 
  List<City> _cities = const [];
  List<City> _matches = const [];
  bool _loadingCities = true;
  bool _saving = false;
 
  @override
  void initState() {
    super.initState();
    _loadCities();
    _prefill();
  }
 
  Future<void> _prefill() async {
    final existing = await ref.read(birthStoreProvider.future);
    if (existing != null && mounted) {
      setState(() {
        _name.text = existing.name;
        _gender = existing.gender;
        _date = existing.date;
        _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
        _placeCtrl.text = existing.placeName;
        _city = City(existing.placeName, '', existing.lat, existing.lng,
            existing.tzId);
      });
    }
  }
 
  Future<void> _loadCities() async {
    final raw = await rootBundle.loadString('assets/data/cities_in.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
    if (mounted) {
      setState(() {
        _cities = list;
        _loadingCities = false;
      });
    }
  }
 
  void _search(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _matches = query.length < 2
          ? const []
          : _cities
              .where((c) => c.label.toLowerCase().contains(query))
              .take(8)
              .toList();
    });
  }
 
  @override
  void dispose() {
    _name.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (d != null) setState(() => _date = d);
  }
 
  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (t != null) setState(() => _time = t);
  }
 
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_date == null || _time == null || _city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all birth details.')),
      );
      return;
    }
    setState(() => _saving = true);
    final details = BirthDetails(
      name: _name.text.trim(),
      gender: _gender,
      date: _date!,
      hour: _time!.hour,
      minute: _time!.minute,
      placeName: _city!.name.isEmpty ? _placeCtrl.text.trim() : _city!.label,
      lat: _city!.lat,
      lng: _city!.lng,
      tzId: _city!.tzId,
    );
    await ref.read(birthStoreProvider.notifier).save(details);
    if (mounted) context.go(widget.redirectTo);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Birth Details')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'male', label: Text('Male')),
                  ButtonSegment(value: 'female', label: Text('Female')),
                  ButtonSegment(value: 'other', label: Text('Other')),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
              const SizedBox(height: 16),
              _PickerTile(
                icon: Icons.calendar_today,
                label: 'Date of birth',
                value: _date == null
                    ? 'Select date'
                    : DateFormat.yMMMMd().format(_date!),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              _PickerTile(
                icon: Icons.access_time,
                label: 'Time of birth',
                value: _time == null
                    ? 'Select time'
                    : _time!.format(context),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placeCtrl,
                decoration: InputDecoration(
                  labelText: 'Place of birth',
                  suffixIcon: _loadingCities
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: _search,
                validator: (_) => _city == null ? 'Select a city' : null,
              ),
              if (_matches.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      for (final c in _matches)
                        ListTile(
                          dense: true,
                          title: Text(c.label),
                          onTap: () {
                            setState(() {
                              _city = c;
                              _placeCtrl.text = c.label;
                              _matches = const [];
                            });
                            FocusScope.of(context).unfocus();
                          },
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Generate my kundli'),
              ),
              const SizedBox(height: 12),
              Text(
                'Accurate birth time is essential for a correct ascendant (lagna).',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
 
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
