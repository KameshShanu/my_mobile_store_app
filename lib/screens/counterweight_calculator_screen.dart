import 'package:flutter/material.dart';

class CounterweightCalculatorScreen extends StatefulWidget {
  const CounterweightCalculatorScreen({super.key});

  @override
  State<CounterweightCalculatorScreen> createState() =>
      _CounterweightCalculatorScreenState();
}

class _CounterweightCalculatorScreenState
    extends State<CounterweightCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController _hoistCapacityController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _reachController = TextEditingController(
    text: '1.5',
  ); // feet (overhang)
  final TextEditingController _fulcrumLengthController = TextEditingController(
    text: '14.0',
  ); // feet to counterweight center
  final TextEditingController _weightPerBlockController = TextEditingController(
    text: '55.0',
  ); // lbs per standard block

  double _totalCounterweightNeeded = 0.0;
  int _numberOfBlocksNeeded = 0;

  @override
  void initState() {
    super.initState();
    _calculateCounterweight();
  }

  @override
  void dispose() {
    _hoistCapacityController.dispose();
    _reachController.dispose();
    _fulcrumLengthController.dispose();
    _weightPerBlockController.dispose();
    super.dispose();
  }

  void _calculateCounterweight() {
    if (_formKey.currentState?.validate() ?? true) {
      final double hoistCapacity =
          double.tryParse(_hoistCapacityController.text) ?? 1000.0;
      final double reach = double.tryParse(_reachController.text) ?? 1.5;
      final double fulcrumLength =
          double.tryParse(_fulcrumLengthController.text) ?? 14.0;
      final double weightPerBlock =
          double.tryParse(_weightPerBlockController.text) ?? 55.0;

      if (fulcrumLength > 0) {
        // Formula with 4:1 safety factor: P = (4 * Hoist Capacity * Reach) / Fulcrum Length
        double requiredWeight = (4 * hoistCapacity * reach) / fulcrumLength;
        int blocks = (requiredWeight / weightPerBlock).ceil();

        setState(() {
          _totalCounterweightNeeded = requiredWeight;
          _numberOfBlocksNeeded = blocks;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Rigging Counterweight Calculator",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            onChanged: _calculateCounterweight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.black87, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Calculates required outrigger counterweight per beam incorporating a mandatory 4:1 safety ratio.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Input Fields Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Rigging Parameters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _hoistCapacityController,
                        label: "Hoist Rated Capacity (lbs)",
                        icon: Icons.fitness_center_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _reachController,
                        label: "Outboard Reach / Overhang (ft)",
                        icon: Icons.straighten_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _fulcrumLengthController,
                        label: "Inboard Fulcrum Length to Weights (ft)",
                        icon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _weightPerBlockController,
                        label: "Weight Per Counterweight Block (lbs)",
                        icon: Icons.layers_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Results Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Required Rigging Requirements (Per Beam)",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Weight Needed:",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          Text(
                            "${_totalCounterweightNeeded.toStringAsFixed(1)} lbs",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Standard Blocks Required:",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$_numberOfBlocksNeeded Blocks",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }
}
