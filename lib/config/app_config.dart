class AppConfig {
  AppConfig._();

  static const String defaultSupabaseUrl =
      'https://yvwzentsmwwgcxmkdwjt.supabase.co';
  static const String defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2d3plbnRzbXd3Z2N4bWtkd2p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NzMyNTMsImV4cCI6MjA5MDI0OTI1M30.h1VPqAUKkebAH2bmElbsZAntITUKXAlA6CFoPWT9fJg';

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: defaultSupabaseUrl);

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: defaultSupabaseAnonKey,
  );

  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'production');
}
