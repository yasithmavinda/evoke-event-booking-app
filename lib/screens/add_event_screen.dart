import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_widgets.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State for Pickers & Image
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCategory = 'Music';
  File? _imageFile;

  final List<String> _categories = ['Music', 'Art', 'Tech', 'Food', 'Sports', 'Wellness'];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Widget _buildPickerTheme(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.dark(
          primary: Theme.of(context).primaryColor,
          surface: const Color(0xFF1F2937),
        ),
      ),
      child: child,
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ErrorSnackbar.show(context, 'Please select both date and time');
        return;
      }
      if (_imageFile == null) {
        ErrorSnackbar.show(context, 'Please select an event image');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final eventData = {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'date': _selectedDate!.toIso8601String(),
          'time': _selectedTime!.format(context),
          'location': _locationController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'description': _descriptionController.text.trim(),
          'availableSeats': 100,
        };

        await _firestoreService.uploadNewEvent(eventData, _imageFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event Created Successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ErrorSnackbar.show(context, 'Failed to create event: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('Create New Event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Event Name',
                    icon: Icons.event_note_rounded,
                    controller: _nameController,
                    validator: (v) => v!.isEmpty ? 'Enter event name' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerTile(
                          icon: Icons.calendar_today_rounded,
                          text: _selectedDate == null ? 'Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPickerTile(
                          icon: Icons.access_time_rounded,
                          text: _selectedTime == null ? 'Time' : _selectedTime!.format(context),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Location',
                    icon: Icons.location_on_rounded,
                    controller: _locationController,
                    validator: (v) => v!.isEmpty ? 'Enter location' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Price (LKR)',
                    icon: Icons.payments_rounded,
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Description',
                    icon: Icons.description_rounded,
                    controller: _descriptionController,
                    validator: (v) => v!.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: 'Create Event',
                    isLoading: _isLoading,
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          image: _imageFile != null 
            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) 
            : null,
        ),
        child: _imageFile == null 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_rounded, size: 40, color: Theme.of(context).primaryColor),
                const SizedBox(height: 12),
                const Text('Select Event Image', style: TextStyle(color: Colors.white70)),
              ],
            )
          : null,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFF1F2937),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildPickerTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
