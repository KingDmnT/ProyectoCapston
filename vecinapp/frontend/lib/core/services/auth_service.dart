import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vecinapp/core/models/user.dart';

// Servicio centralizado de autenticación
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // TEMPORAL: Usar base de datos predeterminada para debug
  // TODO: Configurar vecinappdb una vez funcione
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;
  
  // --- LOGIN ---
  // Inicia sesión y retorna el AppUser completo con rol desde Firestore
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // 1. Autenticar con Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 2. Obtener datos del usuario desde Firestore (incluyendo rol)
      final userData = await _getUserDataFromFirestore(userCredential.user!.uid);
      
      return userData;
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación: ${e.code}');
      throw _handleAuthException(e);
    }
  }
  
  // --- REGISTRO ---
  // Crea una cuenta y guarda el rol en Firestore
  Future<AppUser?> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? communityId,
  }) async {
    try {
      // 1. Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user!.uid;
      
      // 2. Crear documento en Firestore con el rol
      final appUser = AppUser(
        id: uid,
        name: name,
        email: email,
        role: role,
        communityId: communityId,
      );
      
      await _firestore.collection('users').doc(uid).set(appUser.toFirestore());
      
      // 3. Actualizar displayName en Firebase Auth
      await userCredential.user!.updateDisplayName(name);
      
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('Error en registro: ${e.code}');
      throw _handleAuthException(e);
    }
  }
  
  // --- OBTENER DATOS DE USUARIO ---
  // Obtiene los datos completos del usuario desde Firestore
  Future<AppUser?> _getUserDataFromFirestore(String uid) async {
    try {
      print('🔍 Buscando usuario en Firestore con UID: $uid');
      print('🔍 Database ID: vecinappdb');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      print('🔍 Documento existe: ${doc.exists}');
      if (doc.exists) {
        print('🔍 Datos del documento: ${doc.data()}');
      }
      
      if (!doc.exists) {
        print('❌ Usuario no encontrado en Firestore');
        throw Exception('Usuario no encontrado en Firestore');
      }
      
      final appUser = AppUser.fromFirestore(doc.data()!, uid);
      print('✅ Usuario cargado: ${appUser.name}, rol: ${appUser.role}');
      return appUser;
    } catch (e) {
      print('❌ Error obteniendo datos de usuario: $e');
      return null;
    }
  }
  
  // Método público para obtener datos del usuario actual
  Future<AppUser?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    
    return await _getUserDataFromFirestore(user.uid);
  }
  
  // --- LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // --- MANEJO DE ERRORES ---
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
