import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/drawing_provider.dart';

class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, provider, child) {
        final layers = provider.layers;
        final activeLayerId = provider.activeLayerId;

        return Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              AppBar(
                title: const Text('Layers', style: TextStyle(fontSize: 16)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddLayerDialog(context, provider),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: layers.length,
                  itemBuilder: (context, index) {
                    final layer = layers[index];
                    final isSelected = layer['id'] == activeLayerId;

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      leading: IconButton(
                        icon: Icon(
                          layer['isVisible'] != false ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                        ),
                        onPressed: () => provider.toggleLayerVisibility(layer['id']),
                      ),
                      title: Text(
                        layer['name'],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          decoration: layer['isVisible'] == false ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: layer['id'] == 'default'
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _showDeleteConfirm(context, provider, layer),
                            ),
                      onTap: () => provider.setActiveLayer(layer['id']),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddLayerDialog(BuildContext context, DrawingProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Layer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Layer Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // In a real app, this would call the API
                // For now, we'll just update local state
                final newLayers = List<Map<String, dynamic>>.from(provider.layers);
                newLayers.add({
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': controller.text,
                  'isVisible': true,
                  'isLocked': false,
                });
                provider.setLayers(newLayers);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, DrawingProvider provider, Map<String, dynamic> layer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layer'),
        content: Text('Are you sure you want to delete "${layer['name']}"? Strokes will be moved to the default layer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final newLayers = List<Map<String, dynamic>>.from(provider.layers);
              newLayers.removeWhere((l) => l['id'] == layer['id']);
              provider.setLayers(newLayers);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
