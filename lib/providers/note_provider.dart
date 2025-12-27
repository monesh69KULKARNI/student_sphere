import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await _noteService.getNotes();
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Note>> searchNotes(String query) async {
    return await _noteService.searchNotes(query);
  }

  Future<void> addNote(Note note) async {
    await _noteService.addNote(note);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _noteService.updateNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String noteId) async {
    await _noteService.deleteNote(noteId);
    await loadNotes();
  }

  Future<void> likeNote(String noteId, String userId) async {
    await _noteService.likeNote(noteId, userId);
    await loadNotes();
  }
}

