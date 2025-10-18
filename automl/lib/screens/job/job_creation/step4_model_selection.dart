import 'package:flutter/material.dart';

class ModelSelectionStep extends StatefulWidget {
  final Function(Set<String>) onSelectionChanged;

  const ModelSelectionStep({super.key, required this.onSelectionChanged});

  @override
  State<ModelSelectionStep> createState() => _ModelSelectionStepState();
}

class _ModelSelectionStepState extends State<ModelSelectionStep> {
  final Set<String> _selectedModels = {};

  final Map<String, IconData> _availableModels = {
    'Logistic Regression': Icons.linear_scale,
    'Random Forest': Icons.park_outlined,
    'XGBoost': Icons.flash_on,
    'LightGBM': Icons.speed,
    'CatBoost': Icons.pets,
  };

  void _toggleModel(String modelKey) {
    setState(() {
      if (_selectedModels.contains(modelKey)) {
        _selectedModels.remove(modelKey);
      } else {
        _selectedModels.add(modelKey);
      }
    });
    widget.onSelectionChanged(_selectedModels);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.model_training, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Select Models',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Choose one or more algorithms to train on your dataset. More complex models may take longer to train.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _availableModels.length,
            itemBuilder: (context, index) {
              final modelName = _availableModels.keys.elementAt(index);
              final modelIcon = _availableModels.values.elementAt(index);
              final isSelected = _selectedModels.contains(modelName.toLowerCase().replaceAll(' ', '_'));

              return InkWell(
                onTap: () => _toggleModel(modelName.toLowerCase().replaceAll(' ', '_')),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(modelIcon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Expanded(child: Text(modelName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}