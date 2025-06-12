import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:skill_auction/payment/payment_intent.dart';
import 'package:skill_auction/payment/reusabletext_field.dart';

class firstpage extends StatefulWidget {
  @override
  State<firstpage> createState() => _firstpageState();
}

class _firstpageState extends State<firstpage> {
  final DatabaseReference _ordersRef =
      FirebaseDatabase.instance.ref("orderdetails");
  final DatabaseReference _feedbackRef =
      FirebaseDatabase.instance.ref("Feedback");

  TextEditingController amountController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  final formkey = GlobalKey<FormState>();
  final formkey1 = GlobalKey<FormState>();
  final formkey2 = GlobalKey<FormState>();
  final formkey3 = GlobalKey<FormState>();
  final formkey4 = GlobalKey<FormState>();
  final formkey5 = GlobalKey<FormState>();
  final formkey6 = GlobalKey<FormState>();
  List<String> currencyList = <String>[
    'PKR',
    'USD',
    'INR',
    'EUR',
    'JPY',
    'GBP',
    'AED',
  ];
  String selectedCurrency = 'PKR';
  bool hasDonated = false;
  late User currentUser;
  Map<String, dynamic>? cartItems;

  Future<void> initPaymentSheet() async {
    try {
      // 1. create payment intent on the server
      final data = await cretaePaymentIntent(
          // sellerId: 'sellerId',
          //   buyerId: 'buyerId',
          //   skillId: 'skillId',
          amount: (int.parse(amountController.text) * 100).toString(),
          currency: selectedCurrency,
          name: nameController.text,
          address: addressController.text,
          pin: pincodeController.text,
          city: cityController.text,
          state: stateController.text,
          country: countryController.text);
      // 2. initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          // Set to true for custom flow
          customFlow: false,
          // Main params
          merchantDisplayName: 'Umair',
          paymentIntentClientSecret: data['client_secret'],
          // Customer keys
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['id'],
          // Extra options

          style: ThemeMode.dark,
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      rethrow;
    }
  }
  Future<void> fetchOrderAmount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('User not authenticated');
        return;
      }

      final orderQuery = _ordersRef.orderByChild('buyerId').equalTo(currentUser.uid);
      final DatabaseEvent event = await orderQuery.once();
      final DataSnapshot snapshot = event.snapshot;

      if (!snapshot.exists) {
        debugPrint('No orders found for user');
        return;
      }

      dynamic ordersData = snapshot.value;
      if (ordersData is! Map) {
        debugPrint('Invalid orders data format');
        return;
      }

      Map<String, dynamic> orders = Map<String, dynamic>.from(ordersData);
      String? latestOrderKey;
      int? latestTimestamp;

      orders.forEach((key, value) {
        if (value is Map && value['createdAt'] != null) {
          int orderTimestamp = value['createdAt'] is int
              ? value['createdAt']
              : DateTime.parse(value['createdAt']).millisecondsSinceEpoch;

          if (latestTimestamp == null || orderTimestamp > latestTimestamp!) {
            latestTimestamp = orderTimestamp;
            latestOrderKey = key;
          }
        }
      });

      if (latestOrderKey != null) {
        Map<String, dynamic> latestOrder = Map<String, dynamic>.from(orders[latestOrderKey]!);
        if (latestOrder['amount'] != null) {
          debugPrint('Updating amount to: ${latestOrder['amount']}');
          setState(() {
            amountController.text = latestOrder['amount'].toString();
          });
        } else {
          debugPrint('No amount in latest order');
        }
      } else {
        debugPrint('No valid orders found');
      }
    } catch (e) {
      debugPrint('Error fetching order amount: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch order amount: $e')),
      );
    }
  }

  Future<void> _savePaymentDetails(String entryId) async {
    try {
      final orderRef = _ordersRef.child(entryId);
      final _paymentRef = orderRef.child('Orderdetails');
      await _paymentRef.update({
        'orderId': entryId,
        'amount': amountController.text,
        'currency': selectedCurrency,
        'name': nameController.text,
        'address': addressController.text,
        'city': cityController.text,
        'state': stateController.text,
        'country': countryController.text,
        'pincode': pincodeController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // final paymentDetails = {
      //   'orderId': orderId,
      //   'amount': amountController.text,
      //   'currency': selectedCurrency,
      //   'name': nameController.text,
      //   'address': addressController.text,
      //   'city': cityController.text,
      //   'state': stateController.text,
      //   'country': countryController.text,
      //   'pincode': pincodeController.text,
      //   'timestamp': DateTime.now().toIso8601String(),
      // };

      // Save payment details within the order node
      // await _paymentRef.child(orderId).set({'payment_details': paymentDetails});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment details saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save payment details: $e')),
      );
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchOrderAmount();
    amountController.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Make Your Payments Easily",
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       flex: 5,
                      //       child: ReusableTextField(
                      //         formkey: formkey,
                      //         controller: amountController,
                      //         isNumber: true,
                      //         title: "Total Order Amount",
                      //         hint: "Order Amount",
                      //         // readOnly: true,
                      //       ),
                      //     ),
                      //     SizedBox(
                      //       width: 10,
                      //     ),
                      //     DropdownMenu<String>(
                      //       inputDecorationTheme: InputDecorationTheme(
                      //         contentPadding: EdgeInsets.symmetric(
                      //             vertical: 20, horizontal: 0),
                      //         enabledBorder: UnderlineInputBorder(
                      //           borderSide: BorderSide(
                      //             color: Colors.grey.shade600,
                      //           ),
                      //         ),
                      //       ),
                      //       initialSelection: currencyList.first,
                      //       onSelected: (String? value) {
                      //         // This is called when the user selects an item.
                      //         setState(() {
                      //           selectedCurrency = value!;
                      //         });
                      //       },
                      //       dropdownMenuEntries: currencyList
                      //           .map<DropdownMenuEntry<String>>((String value) {
                      //         return DropdownMenuEntry<String>(
                      //             value: value, label: value);
                      //       }).toList(),
                      //     )
                      //   ],
                      // ),
                      Container(
                        width: double.infinity,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ReusableTextField(
                        formkey: formkey1,
                        title: "Name",
                        hint: "Ex. Ali",
                        controller: nameController,
                        // readOnly: false,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ReusableTextField(
                        formkey: formkey2,
                        title: "Address Line",
                        hint: "Ex. 123 Main St",
                        controller: addressController,
                        // readOnly: false,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey3,
                                title: "City",
                                hint: "Ex. Lahore",
                                controller: cityController,
                                // readOnly: false,
                              )),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey4,
                                title: "State (Short code)",
                                hint: "Ex. Lh for Lahore",
                                controller: stateController,
                                // readOnly: false,
                              )),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey5,
                                title: "Country (Short Code)",
                                hint: "Ex. PK for Pakistan",
                                controller: countryController,
                                // readOnly: false,
                              )),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                              flex: 5,
                              child: ReusableTextField(
                                formkey: formkey6,
                                title: "Pincode",
                                hint: "Ex. 123456",
                                controller: pincodeController,
                                // readOnly: false,
                                isNumber: true,
                              )),
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent.shade400),
                          child: Text(
                            "Proceed to Pay",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          onPressed: () async {
                            if (formkey.currentState!.validate() &&
                                formkey1.currentState!.validate() &&
                                formkey2.currentState!.validate() &&
                                formkey3.currentState!.validate() &&
                                formkey4.currentState!.validate() &&
                                formkey5.currentState!.validate() &&
                                formkey6.currentState!.validate()) {
                              try {
                                // Initialize the payment sheet
                                await initPaymentSheet();

                                // Present the payment sheet to the user
                                await Stripe.instance.presentPaymentSheet();

                                // Payment successful, show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Done",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                return; // Stop processing if no orderId is found
                              } catch (e) {
                                print("payment sheet failed: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Failed",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      )
                    ])),
          ],
        ),
      ),
    );
  }
}
