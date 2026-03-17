
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<String?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a new user document in Firestore
      await createUserInFirestore(userCredential.user, email);

      return null;
    } on FirebaseAuthException catch (e) {
      return _translateAuthError(e);
    } catch (e) {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  // Create user in Firestore
  Future<void> createUserInFirestore(User? user, String email) async {
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    final userJson = {
      'uid': user.uid,
      'email': email,
      'createdAt': Timestamp.now(),
    };

    await userDoc.set(userJson);
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _translateAuthError(e);
    } catch (e) {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  String _translateAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-credential':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Falha de conexao. Verifique sua internet.';
      default:
        return 'Erro de autenticacao. Tente novamente.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
