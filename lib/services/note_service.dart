import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NoteService {
  static const String _notesKey = 'notes';

  Future<List<Note>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    return notesJson.map((json) => Note.fromJson(jsonDecode(json))).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    final notes = await getNotes();
    final lowerQuery = query.toLowerCase();
    return notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery) ||
          note.subject.toLowerCase().contains(lowerQuery) ||
          note.course.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<List<Note>> getNotesBySubject(String subject) async {
    final notes = await getNotes();
    return notes.where((note) => note.subject.toLowerCase() == subject.toLowerCase()).toList();
  }

  Future<List<Note>> getNotesByCourse(String course) async {
    final notes = await getNotes();
    return notes.where((note) => note.course.toLowerCase() == course.toLowerCase()).toList();
  }

  Future<void> addNote(Note note) async {
    final notes = await getNotes();
    notes.add(note);
    await _saveNotes(notes);
  }

  Future<void> updateNote(Note note) async {
    final notes = await getNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      notes[index] = note.copyWith(updatedAt: DateTime.now());
      await _saveNotes(notes);
    }
  }

  Future<void> deleteNote(String noteId) async {
    final notes = await getNotes();
    notes.removeWhere((n) => n.id == noteId);
    await _saveNotes(notes);
  }

  Future<void> likeNote(String noteId, String userId) async {
    final notes = await getNotes();
    final index = notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final note = notes[index];
      if (note.likedBy.contains(userId)) {
        // Unlike
        final updatedLikedBy = List<String>.from(note.likedBy)..remove(userId);
        notes[index] = note.copyWith(
          likes: note.likes - 1,
          likedBy: updatedLikedBy,
        );
      } else {
        // Like
        final updatedLikedBy = List<String>.from(note.likedBy)..add(userId);
        notes[index] = note.copyWith(
          likes: note.likes + 1,
          likedBy: updatedLikedBy,
        );
      }
      await _saveNotes(notes);
    }
  }

  Future<void> _saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }
}

