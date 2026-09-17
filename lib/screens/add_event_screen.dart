import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_widgets.dart';

class AddEventScreen extends StatefulWidget {
  final EventModel? editEvent;

  const AddEventScreen({super.key, this.editEvent});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  late TextEditingController _descriptionController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCategory = 'Music';
  File? _imageFile;
  String? _existingImageUrl;

  final List<String> _categories = ['Music', 'Art', 'Tech', 'Food', 'Sports', 'Wellness'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editEvent?.name);
    _locationController = TextEditingController(text: widget.editEvent?.location);
    _priceController = TextEditingController(text: widget.editEvent?.price.toString());
    _seatsController = TextEditingController(text: widget.editEvent?.availableSeats.toString());
    _descriptionController = TextEditingController(text: widget.editEvent?.description);
    
    if (widget.editEvent != null) {
      _selectedCategory = widget.editEvent!.category;
      _selectedDate = widget.editEvent!.date;
      _existingImageUrl = widget.editEvent!.imageUrl;
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
        _existingImageUrl = null;
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
        ErrorSnackbar.show(context, 'Please select an image');
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
          'imageUrl': _existingImageUrl,
        };

        if (widget.editEvent != null) {
          if (_imageFile != null) {
            String newUrl = await _firestoreService.uploadImageToImgBB(_imageFile!);
            eventData['imageUrl'] = newUrl;
          }
          await _firestoreService.updateEvent(widget.editEvent!.id, eventData);
        } else {
          await _firestoreService.uploadNewEvent(eventData, _imageFile);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.editEvent != null ? 'Event Updated!' : 'Event Created!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ErrorSnackbar.show(context, e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editEvent != null ? 'Edit Event' : 'New Event'),
        backgroundColor: Colors.transparent,
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
                  const SizedBox(height: 30),
                  CustomTextField(
                    label: 'Event Name',
                    icon: Icons.event_note_rounded,
                    controller: _nameController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerTile(
                          icon: Icons.calendar_today_rounded,
                          text: _selectedDate == null ? 'Date' : DateFormat('MMM dd').format(_selectedDate!),
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
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
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Price (LKR)',
                          icon: Icons.payments_rounded,
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Seats',
                          icon: Icons.event_seat_rounded,
                          controller: _seatsController,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Description',
                    icon: Icons.description_rounded,
                    controller: _descriptionController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 50),
                  PrimaryButton(
                    text: widget.editEvent != null ? 'SAVE CHANGES' : 'CREATE EVENT',
                    isLoading: _isLoading,
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
          image: (_imageFile != null || _existingImageUrl != null)
            ? DecorationImage(
                image: _imageFile != null ? FileImage(_imageFile!) : NetworkImage(_existingImageUrl!) as ImageProvider,
                fit: BoxFit.cover) 
            : null,
        ),
        child: (_imageFile == null && _existingImageUrl == null)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFFD73B22)),
                SizedBox(height: 12),
                Text('Add Event Image', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            )
          : null,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD73B22)),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildPickerTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFFD73B22)),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
