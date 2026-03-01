import '../models/event.dart';

class HolidayService {
  List<Event> getHolidays({String countryCode = 'IN', bool public = true, bool religious = false, bool school = false}) {
    final List<Event> holidays = [];
    final year = 2026; // Specifically targeting 2026 as per app identity

    if (public) {
      if (countryCode == 'IN') {
        holidays.addAll([
          _buildHoliday('in_ny', "New Year's Day", year, 1, 1, "Public Holiday"),
          _buildHoliday('in_pongal', "Pongal/Makar Sankranti", year, 1, 14, "Public Holiday"),
          _buildHoliday('in_rd', "Republic Day", year, 1, 26, "National Holiday"),
          _buildHoliday('in_ms', "Maha Shivaratri", year, 2, 15, "Public Holiday"),
          _buildHoliday('in_holi', "Holi", year, 3, 4, "Public Holiday"),
          _buildHoliday('in_gf', "Good Friday", year, 4, 3, "Public Holiday"),
          _buildHoliday('in_id', "Independence Day", year, 8, 15, "National Holiday"),
          _buildHoliday('in_gj', "Gandhi Jayanti", year, 10, 2, "National Holiday"),
          _buildHoliday('in_dus', "Dussehra", year, 10, 21, "Public Holiday"),
          _buildHoliday('in_diwali', "Diwali", year, 11, 8, "Public Holiday"),
          _buildHoliday('in_guru', "Guru Nanak Jayanti", year, 11, 24, "Public Holiday"),
          _buildHoliday('in_xmas', "Christmas Day", year, 12, 25, "Public Holiday"),
        ]);
      } else if (countryCode == 'US') {
        holidays.addAll([
          _buildHoliday('us_ny', "New Year's Day", year, 1, 1, "Public Holiday"),
          _buildHoliday('us_mlk', "Martin Luther King Jr. Day", year, 1, 19, "Federal Holiday"),
          _buildHoliday('us_pres', "Presidents' Day", year, 2, 16, "Federal Holiday"),
          _buildHoliday('us_mem', "Memorial Day", year, 5, 25, "Federal Holiday"),
          _buildHoliday('us_june', "Juneteenth", year, 6, 19, "Federal Holiday"),
          _buildHoliday('us_ind', "Independence Day", year, 7, 4, "National Holiday"),
          _buildHoliday('us_lab', "Labor Day", year, 9, 7, "Federal Holiday"),
          _buildHoliday('us_col', "Columbus Day", year, 10, 12, "Federal Holiday"),
          _buildHoliday('us_vet', "Veterans Day", year, 11, 11, "Federal Holiday"),
          _buildHoliday('us_thanks', "Thanksgiving Day", year, 11, 26, "Federal Holiday"),
          _buildHoliday('us_xmas', "Christmas Day", year, 12, 25, "Federal Holiday"),
        ]);
      } else if (countryCode == 'GB') {
        holidays.addAll([
          _buildHoliday('gb_ny', "New Year's Day", year, 1, 1, "Bank Holiday"),
          _buildHoliday('gb_gf', "Good Friday", year, 4, 3, "Bank Holiday"),
          _buildHoliday('gb_em', "Easter Monday", year, 4, 6, "Bank Holiday"),
          _buildHoliday('gb_may', "Early May Bank Holiday", year, 5, 4, "Bank Holiday"),
          _buildHoliday('gb_spring', "Spring Bank Holiday", year, 5, 25, "Bank Holiday"),
          _buildHoliday('gb_summer', "Summer Bank Holiday", year, 8, 31, "Bank Holiday"),
          _buildHoliday('gb_xmas', "Christmas Day", year, 12, 25, "Bank Holiday"),
          _buildHoliday('gb_boxing', "Boxing Day", year, 12, 26, "Bank Holiday"),
        ]);
      }
    }

    if (religious) {
      if (countryCode == 'IN') {
        holidays.addAll([
          _buildHoliday('rel_mahavir', "Mahavir Jayanti", year, 3, 31, "Religious Holiday"),
          _buildHoliday('rel_eid', "Eid-ul-Fitr", year, 3, 20, "Religious Holiday"),
          _buildHoliday('rel_buddha', "Buddha Purnima", year, 5, 1, "Religious Holiday"),
          _buildHoliday('rel_muharram', "Muharram", year, 6, 17, "Religious Holiday"),
          _buildHoliday('rel_jan', "Janmashtami", year, 9, 4, "Religious Holiday"),
          _buildHoliday('rel_milad', "Milad-un-Nabi", year, 8, 26, "Religious Holiday"),
        ]);
      } else {
         holidays.add(_buildHoliday('rel_easter', "Easter Sunday", year, 4, 5, "Religious Holiday"));
      }
    }

    if (school) {
       holidays.addAll([
         _buildHoliday('sch_summer', "Summer Holidays", year, 5, 15, "School Term Break", color: EventColor.work),
         _buildHoliday('sch_winter', "Winter Break", year, 12, 20, "School Term Break", color: EventColor.work),
       ]);
    }

    return holidays;
  }

  Event _buildHoliday(String id, String title, int year, int month, int day, String notes, {EventColor color = EventColor.social}) {
    return Event(
      id: id,
      title: title,
      startTime: DateTime(year, month, day),
      endTime: DateTime(year, month, day, 23, 59),
      isAllDay: true,
      color: color,
      notes: notes,
    );
  }
}
