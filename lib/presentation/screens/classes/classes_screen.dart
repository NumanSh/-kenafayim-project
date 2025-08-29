import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/class.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/models/user.dart';
import '../../../config/service_locator.dart';

class ClassesScreen extends StatefulWidget {
  final User user;

  const ClassesScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClassRepository _classRepository = ClassRepository();

  @override
  void initState() {
    super.initState();
    // For artists, only show available classes and registered classes
    // For mentors and staff, show all classes, their classes, and add class option
    final tabCount = widget.user.role == UserRole.client ? 2 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('שיעורים'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            if (widget.user.role != UserRole.client)
              const Tab(text: 'כל השיעורים'),
            if (widget.user.role == UserRole.client)
              const Tab(text: 'שיעורים זמינים'),
            const Tab(text: 'השיעורים שלי'),
            if (widget.user.role != UserRole.client)
              const Tab(text: 'הוספת שיעור'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (widget.user.role != UserRole.client)
            _buildAllClassesTab(),
          if (widget.user.role == UserRole.client)
            _buildAvailableClassesTab(),
          _buildMyClassesTab(),
          if (widget.user.role != UserRole.client)
            _buildAddClassTab(),
        ],
      ),
    );
  }

  Widget _buildAllClassesTab() {
    return StreamBuilder<List<Class>>(
      stream: _classRepository.getClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('שגיאה: ${snapshot.error}'));
        }

        final classes = snapshot.data ?? [];
        if (classes.isEmpty) {
          return const Center(child: Text('אין שיעורים זמינים'));
        }

        return ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classItem = classes[index];
            return _buildClassCard(classItem, canRegister: false);
          },
        );
      },
    );
  }

  Widget _buildAvailableClassesTab() {
    return StreamBuilder<List<Class>>(
      stream: _classRepository.getClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('שגיאה: ${snapshot.error}'));
        }

        final classes = snapshot.data ?? [];
        final availableClasses = classes.where((c) => 
          !c.registeredUserIds.contains(widget.user.id) && !c.isFull).toList();
        
        if (availableClasses.isEmpty) {
          return const Center(child: Text('אין שיעורים זמינים להרשמה'));
        }

        return ListView.builder(
          itemCount: availableClasses.length,
          itemBuilder: (context, index) {
            final classItem = availableClasses[index];
            return _buildClassCard(classItem, canRegister: true);
          },
        );
      },
    );
  }

  Widget _buildMyClassesTab() {
    return StreamBuilder<List<Class>>(
      stream: widget.user.role == UserRole.client
          ? _classRepository.getRegisteredClasses(widget.user.id)
          : _classRepository.getClassesByMentor(widget.user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('שגיאה: ${snapshot.error}'));
        }

        final classes = snapshot.data ?? [];
        if (classes.isEmpty) {
          return Center(
            child: Text(
              widget.user.role == UserRole.client
                  ? 'לא נרשמת לשיעורים'
                  : 'אין לך שיעורים',
            ),
          );
        }

        return ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classItem = classes[index];
            return _buildClassCard(
              classItem,
              canRegister: false,
              canUnregister: widget.user.role == UserRole.client,
              canEdit: widget.user.role != UserRole.client,
            );
          },
        );
      },
    );
  }

  Widget _buildAddClassTab() {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _locationController = TextEditingController();
    final _capacityController = TextEditingController(text: '10');
    DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay _selectedTime = TimeOfDay.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'כותרת השיעור',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'נא להזין כותרת';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'תיאור השיעור',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'מיקום',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'תאריך',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'שעה',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            decoration: const InputDecoration(
              labelText: 'מספר מקומות',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('נא להזין כותרת')),
                );
                return;
              }

              // Combine date and time
              final dateTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );

              // Create class object
              final newClass = Class(
                id: '', // Will be set by Firestore
                title: _titleController.text,
                description: _descriptionController.text,
                dateTime: dateTime,
                location: _locationController.text,
                mentorId: widget.user.id,
                mentorName: widget.user.name,
                capacity: int.tryParse(_capacityController.text) ?? 10,
                registeredUserIds: [],
              );

              try {
                await _classRepository.addClass(newClass);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('השיעור נוסף בהצלחה')),
                );
                
                // Clear form
                _titleController.clear();
                _descriptionController.clear();
                _locationController.clear();
                _capacityController.text = '10';
                
                // Switch to all classes tab
                _tabController.animateTo(0);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('הוספת שיעור'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    Class classItem, {
    bool canRegister = false,
    bool canUnregister = false,
    bool canEdit = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    classItem.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Show edit dialog
                      _showEditClassDialog(classItem);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (classItem.description.isNotEmpty) ...[
              Text(classItem.description),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(DateFormat('dd/MM/yyyy').format(classItem.dateTime)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(DateFormat('HH:mm').format(classItem.dateTime)),
              ],
            ),
            const SizedBox(height: 4),
            if (classItem.location.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(classItem.location),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(classItem.mentorName),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('${classItem.registeredUserIds.length}/${classItem.capacity} משתתפים'),
              ],
            ),
            const SizedBox(height: 16),
            if (canRegister)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _classRepository.registerForClass(
                      classItem.id,
                      widget.user.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('נרשמת לשיעור בהצלחה')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('שגיאה: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('הרשמה לשיעור'),
              ),
            if (canUnregister)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _classRepository.unregisterFromClass(
                      classItem.id,
                      widget.user.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ביטלת את ההרשמה לשיעור')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('שגיאה: ${e.toString()}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('ביטול הרשמה'),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditClassDialog(Class classItem) {
    final _titleController = TextEditingController(text: classItem.title);
    final _descriptionController = TextEditingController(text: classItem.description);
    final _locationController = TextEditingController(text: classItem.location);
    final _capacityController = TextEditingController(text: classItem.capacity.toString());
    DateTime _selectedDate = classItem.dateTime;
    TimeOfDay _selectedTime = TimeOfDay.fromDateTime(classItem.dateTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('עריכת שיעור'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'כותרת השיעור',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'תיאור השיעור',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'מיקום',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'תאריך',
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'שעה',
                        ),
                        child: Text(
                          _selectedTime.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'מספר מקומות',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              if (_titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('נא להזין כותרת')),
                );
                return;
              }

              // Combine date and time
              final dateTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );

              // Create updated class object
              final updatedClass = classItem.copyWith(
                title: _titleController.text,
                description: _descriptionController.text,
                dateTime: dateTime,
                location: _locationController.text,
                capacity: int.tryParse(_capacityController.text) ?? classItem.capacity,
              );

              try {
                await _classRepository.updateClass(updatedClass);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('השיעור עודכן בהצלחה')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה: ${e.toString()}')),
                );
              }
            },
            child: const Text('שמירה'),
          ),
          TextButton(
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('מחיקת שיעור'),
                  content: const Text('האם אתה בטוח שברצונך למחוק את השיעור?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('ביטול'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('מחיקה'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await _classRepository.deleteClass(classItem.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('השיעור נמחק בהצלחה')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('שגיאה: ${e.toString()}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחיקה'),
          ),
        ],
      ),
    );
  }
}
