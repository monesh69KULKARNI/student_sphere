import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/volunteer.dart';

class VolunteerService {
  static const String _volunteersKey = 'volunteers';

  Future<List<Volunteer>> getVolunteers() async {
    final prefs = await SharedPreferences.getInstance();
    final volunteersJson = prefs.getStringList(_volunteersKey) ?? [];
    return volunteersJson.map((json) => Volunteer.fromJson(jsonDecode(json))).toList();
  }

  Future<List<Volunteer>> getVolunteersByEvent(String eventId) async {
    final volunteers = await getVolunteers();
    return volunteers.where((v) => v.eventId == eventId).toList();
  }

  Future<void> addVolunteer(Volunteer volunteer) async {
    final volunteers = await getVolunteers();
    volunteers.add(volunteer);
    await _saveVolunteers(volunteers);
  }

  Future<void> updateVolunteer(Volunteer volunteer) async {
    final volunteers = await getVolunteers();
    final index = volunteers.indexWhere((v) => v.id == volunteer.id);
    if (index != -1) {
      volunteers[index] = volunteer;
      await _saveVolunteers(volunteers);
    }
  }

  Future<void> deleteVolunteer(String volunteerId) async {
    final volunteers = await getVolunteers();
    volunteers.removeWhere((v) => v.id == volunteerId);
    await _saveVolunteers(volunteers);
  }

  Future<void> approveVolunteer(String volunteerId) async {
    final volunteers = await getVolunteers();
    final index = volunteers.indexWhere((v) => v.id == volunteerId);
    if (index != -1) {
      volunteers[index] = volunteers[index].copyWith(status: 'approved');
      await _saveVolunteers(volunteers);
    }
  }

  Future<void> rejectVolunteer(String volunteerId) async {
    final volunteers = await getVolunteers();
    final index = volunteers.indexWhere((v) => v.id == volunteerId);
    if (index != -1) {
      volunteers[index] = volunteers[index].copyWith(status: 'rejected');
      await _saveVolunteers(volunteers);
    }
  }

  Future<void> _saveVolunteers(List<Volunteer> volunteers) async {
    final prefs = await SharedPreferences.getInstance();
    final volunteersJson = volunteers.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_volunteersKey, volunteersJson);
  }
}

