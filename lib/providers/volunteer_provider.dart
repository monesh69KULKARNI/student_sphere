import 'package:flutter/foundation.dart';
import '../models/volunteer.dart';
import '../services/volunteer_service.dart';

class VolunteerProvider with ChangeNotifier {
  final VolunteerService _volunteerService = VolunteerService();
  List<Volunteer> _volunteers = [];
  bool _isLoading = false;

  List<Volunteer> get volunteers => _volunteers;
  bool get isLoading => _isLoading;

  Future<void> loadVolunteers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _volunteers = await _volunteerService.getVolunteers();
    } catch (e) {
      debugPrint('Error loading volunteers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Volunteer>> getVolunteersByEvent(String eventId) async {
    return await _volunteerService.getVolunteersByEvent(eventId);
  }

  Future<void> addVolunteer(Volunteer volunteer) async {
    await _volunteerService.addVolunteer(volunteer);
    await loadVolunteers();
  }

  Future<void> updateVolunteer(Volunteer volunteer) async {
    await _volunteerService.updateVolunteer(volunteer);
    await loadVolunteers();
  }

  Future<void> deleteVolunteer(String volunteerId) async {
    await _volunteerService.deleteVolunteer(volunteerId);
    await loadVolunteers();
  }

  Future<void> approveVolunteer(String volunteerId) async {
    await _volunteerService.approveVolunteer(volunteerId);
    await loadVolunteers();
  }

  Future<void> rejectVolunteer(String volunteerId) async {
    await _volunteerService.rejectVolunteer(volunteerId);
    await loadVolunteers();
  }
}

