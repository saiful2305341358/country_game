/// Supabase project used for Internet rooms.
///
/// The publishable key is meant to be shipped inside the app: what it can do is
/// limited by the row-level security rules in `supabase/rooms.sql`. Never put a
/// secret / service_role key here.
abstract final class SupabaseConfig {
  static const String url = 'https://kmyxdngkvugxkfhowfpg.supabase.co';
  static const String publishableKey =
      'sb_publishable_DxJ1YoQ5m34jgZrnNKetWg_5TP_Efgp';
}
