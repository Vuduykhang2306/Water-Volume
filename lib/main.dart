final user = Supabase.instance.client.auth.currentUser;

await Supabase.instance.client.from('user_profiles').insert({
  'id': user!.id, // UUID từ auth.users
  'esp_id': 'ESP32_001',
  'email': user.email,
  'phone': '0123456789',
});


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://zkfchfopuqpngcyzdknd.supabase.co/rest/v1/water_quality';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprZmNoZm9wdXFwbmdjeXpka25kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNTcxODUsImV4cCI6MjA2ODgzMzE4NX0.HnT1gKtBSyxBTzz5JwcxuA5SK_LGDDj-K8fPt_jXlR0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Quality Monitor',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class WaterRecord {
  final String id;
  final String? deviceId;
  final double? turbidityAvg;
  final double? tdsAvg;
  final bool? vibration;
  final bool? relay1, relay2, relay3, relay4;
  final DateTime? createdAt;

  WaterRecord({
    required this.id,
    this.deviceId,
    this.turbidityAvg,
    this.tdsAvg,
    this.vibration,
    this.relay1,
    this.relay2,
    this.relay3,
    this.relay4,
    this.createdAt,
  });

  factory WaterRecord.fromMap(Map<String, dynamic> m) {
    return WaterRecord(
      id: (m['id'] ?? '').toString(),
      deviceId: m['device_id'] as String?,
      turbidityAvg: (m['turbidity_avg'] as num?)?.toDouble(),
      tdsAvg: (m['tds_avg'] as num?)?.toDouble(),
      vibration: m['vibration'] as bool?,
      relay1: m['relay1'] as bool?,
      relay2: m['relay2'] as bool?,
      relay3: m['relay3'] as bool?,
      relay4: m['relay4'] as bool?,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Stream<List<Map<String, dynamic>>> _stream;
  String? _lastShownId;

  @override
  void initState() {
    super.initState();

    // Realtime stream theo bảng water_quality
    _stream = supabase
        .from('water_quality')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50);

    // Nghe realtime theo kênh Postgres (tuỳ chọn) để hiện thông báo nhanh
    supabase.channel('water_quality_changes').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'water_quality',
      callback: (payload) {
        final id = payload.newRecord['id']?.toString();
        if (id != null && id != _lastShownId && mounted) {
          _lastShownId = id;
          final turb = payload.newRecord['turbidity_avg'];
          final tds = payload.newRecord['tds_avg'];
          _showSnack('Có bản ghi mới: turb=$turb, tds=$tds');
        }
      },
    ).subscribe();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _manualRefresh() async {
    // Trigger select một lần để đảm bảo kết nối sống (không bắt buộc)
    await supabase.from('water_quality').select('*').limit(1);
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${_2(dt.month)}-${_2(dt.day)} ${_2(dt.hour)}:${_2(dt.minute)}:${_2(dt.second)}';
  }

  String _2(int v) => v.toString().padLeft(2, '0');

  Color _pillColor(bool? b) => (b ?? false) ? Colors.green : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Quality Monitor'),
        actions: [
          IconButton(
            onPressed: _manualRefresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải dữ liệu:\n${snapshot.error}'),
            );
          }

          final rows = (snapshot.data ?? []);
          final items = rows.map((e) => WaterRecord.fromMap(e)).toList();

          if (items.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu'));
          }

          // Top card: hiển thị bản ghi mới nhất
          final latest = items.first;

          return RefreshIndicator(
            onRefresh: _manualRefresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _LatestCard(latest: latest),
                const SizedBox(height: 12),
                Text('Lịch sử gần đây', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...items.map((r) => _RecordTile(r: r)).toList(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.latest});
  final WaterRecord latest;

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${_2(dt.month)}-${_2(dt.day)} ${_2(dt.hour)}:${_2(dt.minute)}:${_2(dt.second)}';
  }

  static String _2(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final t = latest.turbidityAvg?.toStringAsFixed(2) ?? '-';
    final d = latest.tdsAvg?.toStringAsFixed(2) ?? '-';
    final created = _fmtDate(latest.createdAt);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bản ghi mới nhất',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _Metric(label: 'Turbidity', value: t, unit: 'V/NTU*'),
              _Metric(label: 'TDS', value: d, unit: 'V/ppm*'),
              _Pill(label: 'Rung', on: latest.vibration == true),
              _Pill(label: 'R1', on: latest.relay1 == true),
              _Pill(label: 'R2', on: latest.relay2 == true),
              _Pill(label: 'R3', on: latest.relay3 == true),
              _Pill(label: 'R4', on: latest.relay4 == true),
            ]),
            const SizedBox(height: 8),
            Text('Device: ${latest.deviceId ?? "-"}'),
            Text('Thời gian: $created'),
            const SizedBox(height: 6),
            Text(
              '*Ghi chú: giá trị hiển thị theo đơn vị bạn quy đổi trên ESP (hiện đang ở dạng điện áp/giá trị tính toán).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.r});
  final WaterRecord r;

  Color _dot(bool? on) => (on ?? false) ? Colors.green : Colors.grey;

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${_2(dt.month)}-${_2(dt.day)} ${_2(dt.hour)}:${_2(dt.minute)}:${_2(dt.second)}';
  }

  static String _2(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      title: Text(
        'Turb: ${r.turbidityAvg?.toStringAsFixed(2) ?? "-"} | '
        'TDS: ${r.tdsAvg?.toStringAsFixed(2) ?? "-"}',
      ),
      subtitle: Text('Device: ${r.deviceId ?? "-"} · ${_fmtDate(r.createdAt)}'),
      trailing: Wrap(spacing: 6, children: [
        _Dot(color: _dot(r.vibration)),
        _Dot(color: _dot(r.relay1)),
        _Dot(color: _dot(r.relay2)),
        _Dot(color: _dot(r.relay3)),
        _Dot(color: _dot(r.relay4)),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.unit});
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value${unit != null ? ' $unit' : ''}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.on});
  final String label;
  final bool on;
  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: on ? Colors.green.withOpacity(.15) : Colors.grey.withOpacity(.15),
      side: BorderSide(color: on ? Colors.green : Colors.grey),
      label: Text(label, style: TextStyle(color: on ? Colors.green.shade800 : Colors.grey.shade700)),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 6, backgroundColor: color);
  }
}
