/// Supabase project credentials.
///
/// Defaults point at the RemindMD project. The publishable (anon) key is
/// safe to ship client-side — access is enforced by the RLS policies in
/// supabase/schema.sql, not by keeping this key secret. Override either
/// value at build/run time if you need to point at a different project:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your-anon-key
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dmzmkfrfqtjsfezjrsow.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_dWrNf0pNQcidhM9SUzkVVw_rzrM9Fwv',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
