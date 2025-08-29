import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/data/models/lesson.dart';
import 'package:knafayim_app/presentation/providers/lesson_providers.dart';

class ParticipantManagementModal extends ConsumerStatefulWidget {
  final Lesson lesson;

  const ParticipantManagementModal({
    super.key,
    required this.lesson,
  });

  @override
  ConsumerState<ParticipantManagementModal> createState() =>
      _ParticipantManagementModalState();
}

class _ParticipantManagementModalState
    extends ConsumerState<ParticipantManagementModal> {
  @override
  void initState() {
    super.initState();
    // Initialize the participant management when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedLessonProvider.notifier).select(widget.lesson);
      ref
          .read(participantManagementProvider.notifier)
          .initialize(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(participantManagementProvider);
    final notifier = ref.read(participantManagementProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchField(notifier),
          _buildArtistsList(state, notifier),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10b981),
            const Color(0xFF10b981).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'ניהול משתתפים',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'שיעור: ${widget.lesson.title}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ParticipantManagement notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: notifier.updateSearch,
        decoration: InputDecoration(
          hintText: 'חפש אמנים...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsList(
    ParticipantManagementState state,
    ParticipantManagement notifier,
  ) {
    return Expanded(
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.filteredArtists.isEmpty
              ? const Center(
                  child: Text(
                    'לא נמצאו אמנים',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.filteredArtists.length,
                  itemBuilder: (context, index) {
                    final artist = state.filteredArtists[index];
                    final isSelected =
                        state.selectedArtistIds.contains(artist.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10b981).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10b981)
                              : const Color(0xFFe2e8f0),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? const Color(0xFF10b981)
                              : const Color(0xFF10b981).withOpacity(0.1),
                          child: Text(
                            artist.name.isNotEmpty
                                ? artist.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF10b981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          artist.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF10b981)
                                : const Color(0xFF1f2937),
                          ),
                        ),
                        subtitle: Text(
                          artist.email,
                          style: const TextStyle(
                            color: Color(0xFF6b7280),
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => notifier.toggleArtist(artist.id),
                          activeColor: const Color(0xFF10b981),
                        ),
                        onTap: () => notifier.toggleArtist(artist.id),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildActionButtons() {
    final state = ref.watch(participantManagementProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFe2e8f0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false), // Return false
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFe2e8f0)),
              ),
              child: const Text('ביטול',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6b7280))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(participantManagementProvider.notifier)
                            .save(widget.lesson.id);

                        if (mounted) {
                          Navigator.of(context)
                              .pop(true); // Return true to indicate success
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('השינויים נשמרו בהצלחה'),
                                ],
                              ),
                              backgroundColor: Color(0xFF10b981),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          'שגיאה בשמירה: ${e.toString()}')),
                                ],
                              ),
                              backgroundColor: const Color(0xFFef4444),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'שמור שינויים (${state.selectedArtistIds.length})',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
