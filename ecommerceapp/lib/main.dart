
import 'package:ecommerceapp/screens/ChekoutPage.dart' as checkout_page;
import 'package:ecommerceapp/screens/intro.dart';
import 'package:ecommerceapp/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'screens/admin_order.dart';
import 'screens/admin_return.dart';
import 'screens/login.dart';
import 'screens/admin_dashboard.dart';
import 'screens/orders_page.dart';
import 'screens/register.dart';
import 'screens/profile.dart';


void main() {
    runApp(EcommerceShoesApp());
 

}


class EcommerceShoesApp extends StatelessWidget {
    final String userRole = 'admin'; // or 'user'
  final String token = 'user-auth-token';
  const EcommerceShoesApp({super.key});

  @override
  Widget build(BuildContext context) {
// or 'user'
    
    return MaterialApp(
        debugShowCheckedModeBanner: false,
      title: 'E-commerce Shoes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => IntroPage(),
        '/login': (context) => LoginScreen(),
        '/admin/dashboard': (context) =>AdminDashboard(token:'',),
        '/admin/products': (context) => AdminOrdersScreen(token: ''),
        '/admin/orders': (context) => AdminOrdersScreen(token: ''),
        '/admin/returns': (context) => AdminReturnsScreen(token:''),
        '/register': (context) => RegisterScreen(),
      '/order-placement': (context) => OrderConfirmationScreen(
        cartItems: [],
        userToken: '',
        userId: '',
        subtotal: 0,
        shippingFee: 0,
        phoneNumber: '',
        address: '',
        paymentMethod: '',
        totalPrice: 0,
      
        order: null,
      ),
         '/checkout': (context) => checkout_page.CheckoutScreen(token: '', userId: '', orderId: '', totalPrice: 0, cartItems: [],),
         '/profile': (context) => ProfileScreen(token: '', userId: ''), 
          '/notification': (context) => NotificationsScreen(token: '', userId: '')// Placeholder
        // Other routes can be added here as needed
      },
    );
  }
}

