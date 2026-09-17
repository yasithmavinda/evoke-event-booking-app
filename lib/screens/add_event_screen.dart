import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_widgets.dart';

class AddEventScreen extends StatefulWidget {
  final EventModel? editEvent; // Optional: If provided, the screen acts as an 'Edit' screen

  const AddEventScreen({super.key, this.editEvent});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  late TextEditingController _descriptionController;

  // State for Pickers & Image
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCategory = 'Music';
  File? _imageFile;
  String? _existingImageUrl;

  final List<String> _categories = ['Music', 'Art', 'Tech', 'Food', 'Sports', 'Wellness'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.editEvent?.name);
    _locationController = TextEditingController(text: widget.editEvent?.location);
    _priceController = TextEditingController(text: widget.editEvent?.price.toString());
    _seatsController = TextEditingController(text: widget.editEvent?.availableSeats.toString());
    _descriptionController = TextEditingController(text: widget.editEvent?.description);
    
    if (widget.editEvent != null) {
      _selectedCategory = widget.editEvent!.category;
      _selectedDate = widget.editEvent!.date;
      _existingImageUrl = widget.editEvent!.imageUrl;
      // Note: Parsing TimeOfDay from string is omitted for brevity, usually stored separately
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _existingImageUrl = null; // Clear existing if new one picked
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ErrorSnackbar.show(context, 'Please select a date');
        return;
      }
      if (_imageFile == null && _existingImageUrl == null) {
        ErrorSnackbar.show(context, 'Please select an event image');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final eventData = {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'date': _selectedDate!.toIso8601String(),
          'time': _selectedTime?.format(context) ?? '09:00 AM',
          'location': _locationController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'description': _descriptionController.text.trim(),
          'availableSeats': int.tryParse(_seatsController.text) ?? 0,
          'imageUrl': _existingImageUrl, // Might be updated by service if _imageFile is provided
        };

        if (widget.editEvent != null) {
          // Update existing
          if (_imageFile != null) {
            String newUrl = await _firestoreService.uploadImageToImgBB(_imageFile!);
            eventData['imageUrl'] = newUrl;
          }
          await _firestoreService.updateEvent(widget.editEvent!.id, eventData);
        } else {
          // Upload new
          await _firestoreService.uploadNewEvent(eventData, _imageFile);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.editEvent != null ? 'Event Updated!' : 'Event Created!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ErrorSnackbar.show(context, 'Operation failed: $e');
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
        title: Text(widget.editEvent != null ? 'Edit Event' : 'Create New Event'),
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
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPickerTile(
                          icon: Icons.access_time_rounded,
                          text: _selectedTime == null ? 'Time' : _selectedTime!.format(context),
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (picked != null) setState(() => _selectedTime = picked);
                          },
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
                    label: 'Available Seats',
                    icon: Icons.event_seat_rounded,
                    controller: _seatsController,
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
                    text: widget.editEvent != null ? 'Update Event' : 'Create Event',
                    isLoading: _isLoading,
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
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
          image: (_imageFile != null || _existingImageUrl != null)
            ? DecorationImage(
                image: _imageFile != null ? FileImage(_imageFile!) : NetworkImage(_existingImageUrl!) as ImageProvider,
                fit: BoxFit.cover) 
            : null,
        ),
        child: (_imageFile == null && _existingImageUrl == null)
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
