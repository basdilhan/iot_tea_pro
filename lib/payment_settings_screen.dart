import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'payment_provider.dart';
import 'main.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      _controller.text = provider.pricePerKg.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
        backgroundColor: AppTheme.primaryGreen(context),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, payment, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments,
                              size: 32,
                              color: AppTheme.accentOrange(context),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Price Configuration',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Current Price per Kilogram',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        if (!_isEditing)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'LKR ${payment.pricePerKg.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentOrange(context),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                color: AppTheme.primaryGreen(context),
                              ),
                            ],
                          ),
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    prefixText: 'LKR ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryGreen(context),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final value = double.tryParse(
                                    _controller.text,
                                  );
                                  if (value != null && value > 0) {
                                    await payment.setPrice(value);
                                    setState(() {
                                      _isEditing = false;
                                    });
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Price updated successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a valid price',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen(
                                    context,
                                  ),
                                ),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earnings Examples',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEarningRow(
                          '10 kg',
                          payment.calculateEarnings(10),
                        ),
                        _buildEarningRow(
                          '20 kg',
                          payment.calculateEarnings(20),
                        ),
                        _buildEarningRow(
                          '50 kg',
                          payment.calculateEarnings(50),
                        ),
                        _buildEarningRow(
                          '100 kg',
                          payment.calculateEarnings(100),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarningRow(String weight, double earnings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(weight, style: const TextStyle(fontSize: 16)),
          Text(
            'LKR ${earnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentOrange(context),
            ),
          ),
        ],
      ),
    );
  }
}
