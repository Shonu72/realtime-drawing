import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/drawing_provider.dart';
import '../models/stroke_model.dart';
import '../../../core/theme/app_theme.dart';

class ToolPalette extends StatelessWidget {
  final bool isCompact;
  
  const ToolPalette({
    super.key,
    this.isCompact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final drawingProvider = context.watch<DrawingProvider>();
    
    if (isCompact) {
      return _buildCompactPalette(context, drawingProvider);
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolSelector(context, drawingProvider),
            const SizedBox(height: 16),
            _buildColorPicker(context, drawingProvider),
            const SizedBox(height: 16),
            _buildWidthSlider(context, drawingProvider),
            const SizedBox(height: 16),
            _buildActionButtons(context, drawingProvider),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactPalette(BuildContext context, DrawingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolSelector(context, provider, isHorizontal: true),
          const SizedBox(width: 8),
          _buildColorIndicator(context, provider),
          const SizedBox(width: 8),
          _buildActionButtons(context, provider, isCompact: true),
        ],
      ),
    );
  }
  
  Widget _buildToolSelector(
    BuildContext context,
    DrawingProvider provider, {
    bool isHorizontal = false,
  }) {
    final tools = [
      (StrokeTool.pencil, Icons.edit, 'Pencil'),
      (StrokeTool.brush, Icons.brush, 'Brush'),
      (StrokeTool.highlighter, Icons.highlight, 'Highlighter'),
      (StrokeTool.eraser, Icons.clear_all, 'Eraser'),
    ];
    
    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: tools.map((tool) {
          final (toolType, icon, label) = tool;
          final isSelected = provider.currentTool == toolType;
          return Tooltip(
            message: label,
            child: IconButton(
              icon: Icon(icon),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              onPressed: () => provider.setTool(toolType),
            ),
          );
        }).toList(),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tools.map((tool) {
        final (toolType, icon, label) = tool;
        final isSelected = provider.currentTool == toolType;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => provider.setTool(toolType),
        );
      }).toList(),
    );
  }
  
  Widget _buildColorPicker(BuildContext context, DrawingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Color indicator
            GestureDetector(
              onTap: () => _showColorPicker(context, provider),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: provider.currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Preset colors
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppTheme.defaultColors.map((color) {
                  final isSelected = provider.currentColor.value == color.value;
                  return GestureDetector(
                    onTap: () => provider.setColor(color),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildColorIndicator(BuildContext context, DrawingProvider provider) {
    return GestureDetector(
      onTap: () => _showColorPicker(context, provider),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: provider.currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 2),
        ),
      ),
    );
  }
  
  void _showColorPicker(BuildContext context, DrawingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: provider.currentColor,
            onColorChanged: (color) {
              provider.setColor(color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWidthSlider(BuildContext context, DrawingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Width: ${provider.currentWidth.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: provider.currentWidth,
          min: 1,
          max: 50,
          divisions: 49,
          label: provider.currentWidth.toStringAsFixed(1),
          onChanged: (value) => provider.setWidth(value),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(
    BuildContext context,
    DrawingProvider provider, {
    bool isCompact = false,
  }) {
    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: provider.canUndo() ? () => provider.undo() : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: provider.canRedo() ? () => provider.redo() : null,
            tooltip: 'Redo',
          ),
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: provider.canUndo() ? () => provider.undo() : null,
          icon: const Icon(Icons.undo),
          label: const Text('Undo'),
        ),
        ElevatedButton.icon(
          onPressed: provider.canRedo() ? () => provider.redo() : null,
          icon: const Icon(Icons.redo),
          label: const Text('Redo'),
        ),
      ],
    );
  }
}

