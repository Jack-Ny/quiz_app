import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://pwlatilzbmzjkpgmvhrs.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3bGF0aWx6Ym16amtwZ212aHJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE1ODA3MDQsImV4cCI6MjA0NzE1NjcwNH0.SqTI8_giZnz6HpDHIsmyjpSArj_qBWr4ruyfCBIhw3Y';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
