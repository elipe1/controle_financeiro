import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class CurrencyService {
  static const String apiKey = '85b965060e1af655f59f1c862c23476fb8d3414bbdd1dcfdbb6f4d49941cebfe';
  static const String baseUrl = 'https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,GBP-BRL,JPY-BRL';

  static Future<double> convertCurrency(
    String fromCurrency,
    String toCurrency,
    double amount,
  ) async {
    if (fromCurrency == toCurrency) return amount;

    log('Converting $amount from $fromCurrency to $toCurrency');

    try {
      final response = await http
          .get(
            Uri.parse(baseUrl),
          )
          .timeout(Duration(seconds: 5));

      log('API response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (fromCurrency == 'BRL') {
          final key = '$toCurrency$fromCurrency'; // e.g. USDBRL
          if (data.containsKey(key)) {
            final rate = double.parse(data[key]['bid'] ?? '1.0');
            log('Conversion rate for $key: $rate. Inverting for BRL -> other.');
            return amount / rate;
          } else {
            log('Error: currency key $key not found in response');
            return amount;
          }
        } else {
          final key = '$fromCurrency$toCurrency'; // e.g. USDBRL
          if (data.containsKey(key)) {
            final rate = double.parse(data[key]['bid'] ?? '1.0');
            log('Conversion rate for $key: $rate');
            return amount * rate;
          } else {
            log('Error: currency key $key not found in response');
            return amount;
          }
        }
      }
      return amount;
    } catch (e) {
      log('Erro na conversão: $e');
      return amount;
    }
  }
}