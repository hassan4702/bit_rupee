import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:http/http.dart' as http;

class Signup extends StatefulWidget {
  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  String _cnic = '';
  late String _secretKey = '';

  Future<void> makeApiRequest(
      Uint8List publicKey, Uint8List signature, Uint8List messageBytes) async {
    final url =
        'http://172.16.2.46:8080/bitrupee/api/Test/${hex.encode(publicKey)}/${hex.encode(signature)}/${hex.encode(messageBytes)}';

    try {
      print('Making API request.');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // API call was successful
        final responseData = json.decode(response.body);
        print('API Response  in JAVA: $responseData');
      } else {
        // API call failed
        print('API Request failed with status code : ${response.statusCode}');
      }
    } catch (e) {
      // Exception occurred during API call
      print('API Request failed with exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sign up",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 85, 209, 89),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration:
            const BoxDecoration(color: Color.fromARGB(255, 85, 209, 89)),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Please enter your valid credentials',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              const Icon(
                Icons.wallet,
                size: 78,
                color: Colors.white,
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                          const BorderSide(width: 2, color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(width: 2, color: Colors.blue),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    labelText: 'Enter CNIC',
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your CNIC.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _cnic = value!;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  obscureText: true,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                          const BorderSide(width: 2, color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(width: 2, color: Colors.blue),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    labelText: 'Enter Secret_key',
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your secret key.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _secretKey = value!;
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      Uint8List privateKey =
                          generatePrivateKey(_cnic, _secretKey);
                      print('Private Key: 0x${hex.encode(privateKey)}');

                      Uint8List publicKey =
                          generatePublicKey(privateKey).Q!.getEncoded(true);
                      print('Public Key: 0x${hex.encode(publicKey)}');
                      // print(
                      // 'Public Key: 0x${Uint8List.fromList(publicKey).toSet()}');
                      // print('Public Key: ${publicKey}');
                      // print('Public Key: ${publicKey.length}');

                      String message = "hassan";
                      Uint8List messageBytes =
                          Uint8List.fromList(message.codeUnits);
                      print('Message: 0x${hex.encode(messageBytes)}');
                      // print('Message: $messageBytes');
                      // print('Message: ${messageBytes.length}');

                      Uint8List signature =
                          signMessage(privateKey, messageBytes);
                      print('Signature: 0x${hex.encode(signature)}');
                      // print('Signature: ${signature}');
                      // print('Signature: ${signature.length}');
                      bool isSignatureValid =
                          verifySignature(publicKey, messageBytes, signature);
                      print(
                          'Signature Verification in DART: $isSignatureValid');

                      makeApiRequest(publicKey, signature, messageBytes);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.all(20)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Signup',
                    style: TextStyle(
                      color: Color.fromARGB(255, 85, 209, 89),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

//  function to generate private key using eliptical curve cryptography (ECC)

  Uint8List generatePrivateKey(String input1, String input2) {
    // Concatenate the inputs to create the seed
    String seed = input1 + input2;

    // Create a SHA-256 digest of the seed
    Digest sha256Digest = SHA256Digest();
    Uint8List seedBytes = Uint8List.fromList(seed.codeUnits);
    Uint8List digest = sha256Digest.process(seedBytes);

    // Create an ECC private key using the secp256k1 curve
    ECCurve_secp256k1 curve = ECCurve_secp256k1();
    ECPrivateKey privateKey =
        ECPrivateKey(BigInt.parse(hex.encode(digest), radix: 16), curve);

    // Make sure the private key is within the valid range for the curve
    BigInt n = curve.n;
    BigInt privateKeyInt = privateKey.d!;
    privateKeyInt = privateKeyInt % n;

    String privateKeyHex = privateKeyInt.toRadixString(16).padLeft(64, '0');
    Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));

    return privateKeyBytes;
  }

  ECPublicKey generatePublicKey(Uint8List privateKeyBytes) {
    ECCurve_secp256k1 curve = ECCurve_secp256k1();
    ECPrivateKey privateKey = ECPrivateKey(
        BigInt.parse(hex.encode(privateKeyBytes), radix: 16), curve);

    ECPoint? publicKeyPoint = curve.G * privateKey.d!;
    return ECPublicKey(publicKeyPoint, curve);
  }

// Function to sign a message using the private key
  // Function to sign a message using the private key
  Uint8List signMessage(Uint8List privateKeyBytes, Uint8List message) {
    ECCurve_secp256k1 curve = ECCurve_secp256k1();
    ECPrivateKey privateKey = ECPrivateKey(
        BigInt.parse(hex.encode(privateKeyBytes), radix: 16), curve);

    // Create a secure random number generator
    SecureRandom secureRandom = FortunaRandom();
    secureRandom.seed(KeyParameter(Uint8List.fromList(privateKeyBytes)));

    final sha256Digest = SHA256Digest();
    final hmac = HMac(sha256Digest, 64);
    final signer = ECDSASigner(sha256Digest, hmac); // Use the digests here
    signer.init(true, PrivateKeyParameter(privateKey));

    final signature = signer.generateSignature(Uint8List.fromList(message));

    // Extract r and s from the Signature object
    BigInt r = (signature as ECSignature).r;
    BigInt s = (signature).s;

    // Convert r and s to 32-byte Uint8Lists
    Uint8List rBytes = _encodeBigInt(r, 32);
    Uint8List sBytes = _encodeBigInt(s, 32);

    // Concatenate r and s to get the 64-byte signature
    Uint8List signatureBytes = Uint8List.fromList([...rBytes, ...sBytes]);

    return signatureBytes;
  }

  Uint8List _encodeBigInt(BigInt value, int size) {
    var result = Uint8List(size);
    for (var i = size - 1; i >= 0; i--) {
      result[i] = value.toUnsigned(8).toInt();
      value >>= 8;
    }
    return result;
  }

// Function to verify a signature using the public key
  bool verifySignature(
      Uint8List publicKeyBytes, Uint8List message, Uint8List signatureBytes) {
    ECCurve_secp256k1 curve = ECCurve_secp256k1();
    ECPublicKey publicKey =
        ECPublicKey(curve.curve.decodePoint(publicKeyBytes), curve);

    ECDSASigner signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64));
    signer.init(false, PublicKeyParameter(publicKey));

    // Split the signatureBytes into r and s components
    int halfLength = signatureBytes.length ~/ 2;
    Uint8List rBytes = signatureBytes.sublist(0, halfLength);
    Uint8List sBytes = signatureBytes.sublist(halfLength);

    // Convert r and s to BigInt
    BigInt r = decodeBigInt(rBytes);
    BigInt s = decodeBigInt(sBytes);

    // Create the ECSignature instance
    ECSignature signature = ECSignature(r, s);

    return signer.verifySignature(Uint8List.fromList(message), signature);
  }

  BigInt decodeBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) + BigInt.from(bytes[i]);
    }
    return result;
  }
}
