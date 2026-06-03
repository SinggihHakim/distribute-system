import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/data/auth_service.dart';
import 'features/products/data/product_repository.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final client = Supabase.instance.client;
  final authService = AuthService();
  final productRepo = ProductRepository();

  final testEmail = 'test_admin_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final testPassword = 'Password123!';

  try {
    print('Registering test store and admin: $testEmail...');
    final adminUser = await authService.registerStore(
      email: testEmail,
      password: testPassword,
      name: 'Test Admin',
      namaToko: 'Toko Test Kece',
    );

    print('Successfully registered! User ID: ${adminUser.id}, Store ID: ${adminUser.storeId}');

    print('Attempting to add new product...');
    final product = await productRepo.addProduct(
      name: 'Product Test',
      satuan: 'pcs',
      hargaModal: 5000,
      hargaJual: 7500,
      stokMinimum: 5,
      stokAwal: 10,
    );

    print('Product successfully created: ${product.name}, ID: ${product.id}, Stok: ${product.stokGudang}');

  } catch (e, stack) {
    print('ERROR ENCOUNTERED:');
    print(e);
    print(stack);
  } finally {
    // Clean up if logged in
    try {
      await client.auth.signOut();
    } catch (_) {}
  }
}
