import '../models/society_place.dart';
import '../services/location_service.dart';

/// All 24 Governorates of Tunisia with real central coordinates.
class TunisiaDirectory {
  static const List<UserLocation> allGovernorates = [
    UserLocation(latitude: 36.8065, longitude: 10.1815, label: 'Tunis', isLiveGps: false),
    UserLocation(latitude: 36.8665, longitude: 10.1647, label: 'Ariana', isLiveGps: false),
    UserLocation(latitude: 36.7531, longitude: 10.2189, label: 'Ben Arous', isLiveGps: false),
    UserLocation(latitude: 36.8080, longitude: 10.0972, label: 'Manouba', isLiveGps: false),
    UserLocation(latitude: 36.4561, longitude: 10.7376, label: 'Nabeul', isLiveGps: false),
    UserLocation(latitude: 36.4029, longitude: 10.1429, label: 'Zaghouan', isLiveGps: false),
    UserLocation(latitude: 37.2744, longitude: 9.8739, label: 'Bizerte', isLiveGps: false),
    UserLocation(latitude: 36.7256, longitude: 9.1817, label: 'Béja', isLiveGps: false),
    UserLocation(latitude: 36.5011, longitude: 8.7802, label: 'Jendouba', isLiveGps: false),
    UserLocation(latitude: 36.1742, longitude: 8.7049, label: 'Kef', isLiveGps: false),
    UserLocation(latitude: 36.0850, longitude: 9.3708, label: 'Siliana', isLiveGps: false),
    UserLocation(latitude: 35.8256, longitude: 10.6369, label: 'Sousse', isLiveGps: false),
    UserLocation(latitude: 35.7643, longitude: 10.8113, label: 'Monastir', isLiveGps: false),
    UserLocation(latitude: 35.5047, longitude: 11.0622, label: 'Mahdia', isLiveGps: false),
    UserLocation(latitude: 34.7406, longitude: 10.7603, label: 'Sfax', isLiveGps: false),
    UserLocation(latitude: 35.6781, longitude: 10.0963, label: 'Kairouan', isLiveGps: false),
    UserLocation(latitude: 35.1676, longitude: 8.8365, label: 'Kasserine', isLiveGps: false),
    UserLocation(latitude: 35.0382, longitude: 9.4849, label: 'Sidi Bouzid', isLiveGps: false),
    UserLocation(latitude: 33.8815, longitude: 10.0982, label: 'Gabès', isLiveGps: false),
    UserLocation(latitude: 33.3549, longitude: 10.5055, label: 'Médenine', isLiveGps: false),
    UserLocation(latitude: 32.9297, longitude: 10.4518, label: 'Tataouine', isLiveGps: false),
    UserLocation(latitude: 34.4250, longitude: 8.7842, label: 'Gafsa', isLiveGps: false),
    UserLocation(latitude: 33.9197, longitude: 8.1335, label: 'Tozeur', isLiveGps: false),
    UserLocation(latitude: 33.7044, longitude: 8.9690, label: 'Kébili', isLiveGps: false),
  ];

  static UserLocation governorateByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final g in allGovernorates) {
      if (g.label.toLowerCase() == lower) return g;
    }
    return LocationService.defaultSousseLocation;
  }

  static List<String> get governorateNames =>
      allGovernorates.map((g) => g.label).toList(growable: false);

  /// Real Tunisian public services & establishments across ALL 24 governorates.
  static List<SocietyPlace> buildAllTunisiaPlaces() {
    final now = DateTime.now();

    SocietyPlace make(
      String id,
      String name,
      String city,
      String address,
      PlaceCategory category,
      double lat,
      double lng,
      int guichets,
      int lastTicket,
      int currentTicket, [
      int minutesAgo = 2,
    ]) {
      return SocietyPlace(
        id: id,
        name: name,
        city: city,
        address: address,
        category: category,
        latitude: lat,
        longitude: lng,
        guichetCount: guichets,
        lastTicketNumber: lastTicket,
        currentTicketNumber: currentTicket,
        calculatedWaitMinutes: SocietyPlace.calculateWaitMinutes(
          lastTicket: lastTicket,
          currentTicket: currentTicket,
          guichets: guichets,
        ),
        lastCalculatedAt: now.subtract(Duration(minutes: minutesAgo)),
      );
    }

    return [
      // ==================== 1. SOUSSE ====================
      make('post_sousse_centre', 'LA POSTE - Sousse Centre', 'Sousse', 'Avenue Habib Bourguiba, Sousse', PlaceCategory.post, 35.8286, 10.6408, 5, 150, 100, 2),
      make('post_khzema', 'LA POSTE - Khzema', 'Sousse', 'Boulevard 14 Janvier, Khzema', PlaceCategory.post, 35.8458, 10.6145, 4, 82, 70, 1),
      make('post_sahloul', 'LA POSTE - Sahloul', 'Sousse', 'Cité Sahloul 1, Sousse', PlaceCategory.post, 35.8194, 10.6152, 3, 108, 90, 3),
      make('steg_sousse', 'STEG - Sousse', 'Sousse', 'Avenue Léopold Sédar Senghor, Sousse', PlaceCategory.utilities, 35.8342, 10.6295, 4, 120, 100, 2),
      make('cnam_sousse', 'CNAM - Sousse', 'Sousse', 'Avenue Mohamed Karoui, Sousse', PlaceCategory.utilities, 35.8305, 10.6218, 3, 69, 60, 1),
      make('hospital_farhat_hached', 'Hôpital Farhat Hached', 'Sousse', 'Avenue Ibn El Jazzar, Sousse', PlaceCategory.hospital, 35.8211, 10.6291, 6, 214, 160, 2),
      make('hospital_sahloul', 'CHU Sahloul Hospital', 'Sousse', 'Route de Ceinture, Sahloul', PlaceCategory.hospital, 35.8148, 10.6088, 6, 118, 100, 1),
      make('bank_biat', 'BIAT Bank - Boujaafar', 'Sousse', 'Avenue de la Corniche, Sousse', PlaceCategory.bank, 35.8355, 10.6352, 4, 94, 70, 3),
      make('bank_stb', 'STB Bank - Bab Bhar', 'Sousse', 'Place Farhat Hached, Sousse', PlaceCategory.bank, 35.8268, 10.6415, 4, 58, 50, 1),
      make('municipality_sousse', 'Municipalité de Sousse', 'Sousse', 'Avenue Mohamed V, Sousse', PlaceCategory.municipality, 35.8276, 10.6378, 4, 136, 100, 2),

      // ==================== 2. TUNIS ====================
      make('post_tunis_rp', 'LA POSTE - Tunis RP', 'Tunis', 'Rue Charles de Gaulle, Tunis', PlaceCategory.post, 36.7988, 10.1782, 6, 210, 156, 2),
      make('post_tunis_marsa', 'LA POSTE - La Marsa', 'Tunis', 'Avenue Habib Bourguiba, La Marsa', PlaceCategory.post, 36.8784, 10.3247, 4, 72, 60, 1),
      make('post_tunis_bardo', 'LA POSTE - Le Bardo', 'Tunis', 'Avenue Habib Bourguiba, Le Bardo', PlaceCategory.post, 36.8092, 10.1355, 4, 104, 80, 2),
      make('hospital_charles_nicolle', 'CHU Charles Nicolle', 'Tunis', 'Boulevard du 9 Avril 1938, Tunis', PlaceCategory.hospital, 36.8022, 10.1613, 8, 280, 208, 3),
      make('hospital_rabta', 'Hôpital La Rabta', 'Tunis', 'Jebari, Bab Saadoun, Tunis', PlaceCategory.hospital, 36.8058, 10.1566, 6, 166, 130, 2),
      make('bank_biat_tunis', 'BIAT - Avenue Bourguiba', 'Tunis', '70 Avenue Habib Bourguiba, Tunis', PlaceCategory.bank, 36.8002, 10.1834, 5, 115, 90, 2),
      make('bank_stb_tunis', 'STB - Siège Tunis', 'Tunis', 'Rue Hédi Nouira, Tunis', PlaceCategory.bank, 36.8068, 10.1846, 5, 85, 75, 1),
      make('steg_tunis', 'STEG - Tunis Centre', 'Tunis', '38 Rue Kamel Ataturk, Tunis', PlaceCategory.utilities, 36.8031, 10.1820, 5, 145, 115, 2),
      make('cnam_tunis', 'CNAM - Centre Urbain Nord', 'Tunis', 'Centre Urbain Nord, Tunis', PlaceCategory.utilities, 36.8468, 10.1972, 6, 192, 144, 3),
      make('municipality_tunis', 'Municipalité de Tunis (Kasbah)', 'Tunis', 'Place de la Kasbah, Tunis', PlaceCategory.municipality, 36.7979, 10.1674, 5, 120, 95, 2),

      // ==================== 3. ARIANA ====================
      make('post_ariana', 'LA POSTE - Ariana Centre', 'Ariana', 'Avenue Habib Bourguiba, Ariana', PlaceCategory.post, 36.8625, 10.1956, 4, 116, 84, 2),
      make('post_menzah', 'LA POSTE - El Menzah 6', 'Ariana', 'Avenue Othman Ibn Affen, Ariana', PlaceCategory.post, 36.8490, 10.1670, 4, 66, 58, 1),
      make('hospital_mami_ariana', 'Hôpital Abderrahmen Mami', 'Ariana', 'Rue de l’Hôpital, Ariana', PlaceCategory.hospital, 36.8669, 10.1932, 5, 150, 125, 2),
      make('bank_biat_ariana', 'BIAT - Ariana', 'Ariana', 'Avenue Mustapha Mohsen, Ariana', PlaceCategory.bank, 36.8602, 10.1920, 4, 76, 68, 1),
      make('steg_ariana', 'STEG - Ariana', 'Ariana', 'Route de Raoued, Ariana', PlaceCategory.utilities, 36.8695, 10.1890, 4, 132, 100, 3),
      make('municipality_ariana', 'Municipalité de l’Ariana', 'Ariana', 'Avenue Habib Bourguiba, Ariana', PlaceCategory.municipality, 36.8632, 10.1945, 4, 96, 76, 2),

      // ==================== 4. BEN AROUS ====================
      make('post_ben_arous', 'LA POSTE - Ben Arous', 'Ben Arous', 'Avenue de France, Ben Arous', PlaceCategory.post, 36.7536, 10.2215, 4, 110, 86, 2),
      make('post_rades', 'LA POSTE - Radès', 'Ben Arous', 'Avenue Habib Bourguiba, Radès', PlaceCategory.post, 36.7681, 10.2753, 3, 57, 48, 1),
      make('hospital_ben_arous', 'Centre de Traumatologie Ben Arous', 'Ben Arous', 'Nouvelle Médina, Ben Arous', PlaceCategory.hospital, 36.7438, 10.2286, 5, 185, 140, 2),
      make('bank_stb_ben_arous', 'STB - Ben Arous', 'Ben Arous', 'Avenue de l’Indépendance, Ben Arous', PlaceCategory.bank, 36.7519, 10.2202, 4, 62, 54, 1),
      make('municipality_ben_arous', 'Municipalité de Ben Arous', 'Ben Arous', 'Avenue de France, Ben Arous', PlaceCategory.municipality, 36.7544, 10.2192, 4, 92, 72, 2),

      // ==================== 5. MANOUBA ====================
      make('post_manouba', 'LA POSTE - Manouba', 'Manouba', 'Avenue de la Liberté, Manouba', PlaceCategory.post, 36.8089, 10.0985, 4, 88, 72, 2),
      make('hospital_kassab_manouba', 'Institut Mohamed Kassab', 'Manouba', 'Ksar Saïd, Manouba', PlaceCategory.hospital, 36.8152, 10.1112, 5, 155, 125, 2),
      make('bank_bna_manouba', 'BNA - Manouba', 'Manouba', 'Avenue Habib Bourguiba, Manouba', PlaceCategory.bank, 36.8075, 10.0958, 3, 51, 45, 1),
      make('municipality_manouba', 'Municipalité de La Manouba', 'Manouba', 'Rue de la Municipalité, Manouba', PlaceCategory.municipality, 36.8098, 10.0968, 3, 84, 60, 3),

      // ==================== 6. NABEUL ====================
      make('post_nabeul', 'LA POSTE - Nabeul Centre', 'Nabeul', 'Avenue Habib Bourguiba, Nabeul', PlaceCategory.post, 36.4513, 10.7357, 4, 124, 92, 2),
      make('post_hammamet', 'LA POSTE - Hammamet', 'Nabeul', 'Avenue de la République, Hammamet', PlaceCategory.post, 36.4000, 10.6167, 4, 64, 56, 1),
      make('hospital_maamouri_nabeul', 'Hôpital Mohamed Tahar Maamouri', 'Nabeul', 'Mrezga, Nabeul', PlaceCategory.hospital, 36.4375, 10.6928, 6, 204, 156, 2),
      make('bank_biat_nabeul', 'BIAT - Nabeul', 'Nabeul', 'Avenue Habib Thameur, Nabeul', PlaceCategory.bank, 36.4535, 10.7369, 4, 80, 64, 2),
      make('steg_nabeul', 'STEG - Nabeul', 'Nabeul', 'Avenue Farhat Hached, Nabeul', PlaceCategory.utilities, 36.4578, 10.7341, 4, 112, 88, 2),
      make('municipality_nabeul', 'Municipalité de Nabeul', 'Nabeul', 'Place des Martyrs, Nabeul', PlaceCategory.municipality, 36.4521, 10.7364, 3, 66, 57, 1),

      // ==================== 7. ZAGHOUAN ====================
      make('post_zaghouan', 'LA POSTE - Zaghouan', 'Zaghouan', 'Avenue de l’Indépendance, Zaghouan', PlaceCategory.post, 36.4038, 10.1435, 3, 54, 45, 1),
      make('hospital_zaghouan', 'Hôpital Régional de Zaghouan', 'Zaghouan', 'Route de Moghrane, Zaghouan', PlaceCategory.hospital, 36.4071, 10.1462, 4, 108, 84, 2),
      make('bank_bna_zaghouan', 'BNA - Zaghouan', 'Zaghouan', 'Centre-Ville, Zaghouan', PlaceCategory.bank, 36.4021, 10.1422, 3, 42, 36, 1),
      make('municipality_zaghouan', 'Municipalité de Zaghouan', 'Zaghouan', 'Avenue Habib Bourguiba, Zaghouan', PlaceCategory.municipality, 36.4033, 10.1419, 3, 63, 45, 2),

      // ==================== 8. BIZERTE ====================
      make('post_bizerte', 'LA POSTE - Bizerte Centre', 'Bizerte', 'Avenue Habib Bourguiba, Bizerte', PlaceCategory.post, 37.2749, 9.8731, 5, 145, 105, 2),
      make('post_menzel_bourguiba', 'LA POSTE - Menzel Bourguiba', 'Bizerte', 'Avenue de l’Indépendance, Menzel Bourguiba', PlaceCategory.post, 37.1537, 9.7859, 4, 68, 60, 1),
      make('hospital_bougatfa_bizerte', 'Hôpital Habib Bougatfa', 'Bizerte', 'Route de la Corniche, Bizerte', PlaceCategory.hospital, 37.2812, 9.8768, 6, 198, 150, 2),
      make('bank_stb_bizerte', 'STB - Bizerte', 'Bizerte', 'Rue de Russie, Bizerte', PlaceCategory.bank, 37.2731, 9.8745, 4, 78, 62, 2),
      make('steg_bizerte', 'STEG - Bizerte', 'Bizerte', 'Avenue d’Algérie, Bizerte', PlaceCategory.utilities, 37.2704, 9.8692, 4, 96, 84, 1),
      make('municipality_bizerte', 'Municipalité de Bizerte', 'Bizerte', 'Avenue Habib Bourguiba, Bizerte', PlaceCategory.municipality, 37.2742, 9.8752, 4, 108, 84, 2),

      // ==================== 9. BÉJA ====================
      make('post_beja', 'LA POSTE - Béja', 'Béja', 'Avenue Habib Bourguiba, Béja', PlaceCategory.post, 36.7262, 9.1825, 4, 92, 72, 2),
      make('hospital_beja', 'Hôpital Régional de Béja', 'Béja', 'Route de Tunis, Béja', PlaceCategory.hospital, 36.7295, 9.1904, 4, 128, 96, 2),
      make('bank_bna_beja', 'BNA - Béja', 'Béja', 'Place de l’Indépendance, Béja', PlaceCategory.bank, 36.7248, 9.1812, 3, 48, 42, 1),
      make('municipality_beja', 'Municipalité de Béja', 'Béja', 'Avenue de France, Béja', PlaceCategory.municipality, 36.7259, 9.1838, 3, 60, 48, 2),

      // ==================== 10. JENDOUBA ====================
      make('post_jendouba', 'LA POSTE - Jendouba', 'Jendouba', 'Avenue Habib Bourguiba, Jendouba', PlaceCategory.post, 36.5015, 8.7808, 4, 84, 72, 1),
      make('hospital_jendouba', 'Hôpital Régional de Jendouba', 'Jendouba', 'Route de Tabarka, Jendouba', PlaceCategory.hospital, 36.5055, 8.7764, 5, 160, 120, 2),
      make('bank_stb_jendouba', 'STB - Jendouba', 'Jendouba', 'Rue Kheireddine Pacha, Jendouba', PlaceCategory.bank, 36.5003, 8.7819, 3, 57, 45, 2),
      make('municipality_jendouba', 'Municipalité de Jendouba', 'Jendouba', 'Avenue de la Liberté, Jendouba', PlaceCategory.municipality, 36.5019, 8.7795, 3, 54, 48, 1),

      // ==================== 11. KEF ====================
      make('post_kef', 'LA POSTE - Le Kef', 'Kef', 'Avenue Habib Bourguiba, Le Kef', PlaceCategory.post, 36.1748, 8.7056, 3, 72, 54, 2),
      make('hospital_kef', 'Hôpital Régional du Kef', 'Kef', 'Route de Tunis, Le Kef', PlaceCategory.hospital, 36.1684, 8.7124, 4, 120, 96, 2),
      make('bank_bna_kef', 'BNA - Le Kef', 'Kef', 'Place de l’Indépendance, Le Kef', PlaceCategory.bank, 36.1755, 8.7041, 3, 39, 33, 1),
      make('municipality_kef', 'Municipalité du Kef', 'Kef', 'Place de la Kasbah, Le Kef', PlaceCategory.municipality, 36.1782, 8.7048, 3, 45, 39, 1),

      // ==================== 12. SILIANA ====================
      make('post_siliana', 'LA POSTE - Siliana', 'Siliana', 'Avenue des Martyrs, Siliana', PlaceCategory.post, 36.0856, 9.3712, 3, 51, 42, 1),
      make('hospital_siliana', 'Hôpital Régional de Siliana', 'Siliana', 'Route du Kef, Siliana', PlaceCategory.hospital, 36.0891, 9.3665, 4, 112, 84, 2),
      make('bank_bna_siliana', 'BNA - Siliana', 'Siliana', 'Avenue Habib Bourguiba, Siliana', PlaceCategory.bank, 36.0842, 9.3701, 3, 44, 38, 1),
      make('municipality_siliana', 'Municipalité de Siliana', 'Siliana', 'Centre-Ville, Siliana', PlaceCategory.municipality, 36.0851, 9.3720, 3, 66, 48, 2),

      // ==================== 13. MONASTIR ====================
      make('post_monastir', 'LA POSTE - Monastir Centre', 'Monastir', 'Avenue de l’Indépendance, Monastir', PlaceCategory.post, 35.7745, 10.8262, 4, 112, 80, 2),
      make('post_moknine', 'LA POSTE - Moknine', 'Monastir', 'Avenue Habib Bourguiba, Moknine', PlaceCategory.post, 35.6297, 10.9008, 3, 57, 48, 1),
      make('hospital_fattouma_monastir', 'CHU Fattouma Bourguiba', 'Monastir', 'Avenue 1er Juin, Monastir', PlaceCategory.hospital, 35.7702, 10.8318, 6, 210, 156, 2),
      make('bank_biat_monastir', 'BIAT - Monastir', 'Monastir', 'Avenue Habib Bourguiba, Monastir', PlaceCategory.bank, 35.7758, 10.8285, 4, 76, 64, 1),
      make('steg_monastir', 'STEG - Monastir', 'Monastir', 'Route de Khniss, Monastir', PlaceCategory.utilities, 35.7621, 10.8185, 4, 100, 80, 2),
      make('municipality_monastir', 'Municipalité de Monastir', 'Monastir', 'Place du 3 Août, Monastir', PlaceCategory.municipality, 35.7765, 10.8271, 4, 88, 76, 1),

      // ==================== 14. MAHDIA ====================
      make('post_mahdia', 'LA POSTE - Mahdia', 'Mahdia', 'Avenue 2 Mars 1934, Mahdia', PlaceCategory.post, 35.5042, 11.0638, 4, 84, 72, 1),
      make('hospital_tahar_sfar_mahdia', 'CHU Tahar Sfar', 'Mahdia', 'Route de Réjiche, Mahdia', PlaceCategory.hospital, 35.4981, 11.0452, 5, 165, 125, 2),
      make('bank_stb_mahdia', 'STB - Mahdia', 'Mahdia', 'Avenue Habib Bourguiba, Mahdia', PlaceCategory.bank, 35.5051, 11.0655, 3, 57, 45, 2),
      make('municipality_mahdia', 'Municipalité de Mahdia', 'Mahdia', 'Place du Caire, Mahdia', PlaceCategory.municipality, 35.5048, 11.0682, 3, 54, 48, 1),

      // ==================== 15. SFAX ====================
      make('post_sfax_bab_bhar', 'LA POSTE - Sfax Bab Bhar', 'Sfax', 'Avenue Habib Bourguiba, Sfax', PlaceCategory.post, 34.7364, 10.7615, 6, 204, 150, 2),
      make('post_sfax_sakiet', 'LA POSTE - Sakiet Ezzit', 'Sfax', 'Route de Tunis km 9, Sfax', PlaceCategory.post, 34.7985, 10.7720, 4, 72, 60, 1),
      make('hospital_habib_bourguiba_sfax', 'CHU Habib Bourguiba', 'Sfax', 'Route El Aïn km 0.5, Sfax', PlaceCategory.hospital, 34.7396, 10.7512, 7, 252, 189, 2),
      make('hospital_hedi_chaker_sfax', 'CHU Hédi Chaker', 'Sfax', 'Route El Aïn, Sfax', PlaceCategory.hospital, 34.7412, 10.7485, 6, 168, 132, 2),
      make('bank_biat_sfax', 'BIAT - Sfax Centre', 'Sfax', 'Avenue Hédi Chaker, Sfax', PlaceCategory.bank, 34.7379, 10.7634, 5, 110, 85, 2),
      make('steg_sfax', 'STEG - Sfax', 'Sfax', 'Avenue des Martyrs, Sfax', PlaceCategory.utilities, 34.7422, 10.7662, 5, 140, 115, 2),
      make('cnam_sfax', 'CNAM - Sfax', 'Sfax', 'Route de Gabès, Sfax', PlaceCategory.utilities, 34.7315, 10.7568, 4, 68, 60, 1),
      make('municipality_sfax', 'Municipalité de Sfax', 'Sfax', 'Avenue Habib Bourguiba, Sfax', PlaceCategory.municipality, 34.7358, 10.7604, 5, 130, 105, 2),

      // ==================== 16. KAIROUAN ====================
      make('post_kairouan', 'LA POSTE - Kairouan Centre', 'Kairouan', 'Avenue de la République, Kairouan', PlaceCategory.post, 35.6768, 10.0975, 4, 120, 88, 2),
      make('hospital_kairouan', 'Hôpital Ibn El Jazzar', 'Kairouan', 'Avenue Ibn El Jazzar, Kairouan', PlaceCategory.hospital, 35.6712, 10.1045, 5, 180, 135, 3),
      make('bank_bna_kairouan', 'BNA - Kairouan', 'Kairouan', 'Avenue Habib Bourguiba, Kairouan', PlaceCategory.bank, 35.6778, 10.0988, 4, 64, 56, 1),
      make('steg_kairouan', 'STEG - Kairouan', 'Kairouan', 'Route de Sousse, Kairouan', PlaceCategory.utilities, 35.6804, 10.1012, 4, 96, 76, 2),
      make('municipality_kairouan', 'Municipalité de Kairouan', 'Kairouan', 'Place des Martyrs, Kairouan', PlaceCategory.municipality, 35.6754, 10.0992, 4, 72, 64, 1),

      // ==================== 17. KASSERINE ====================
      make('post_kasserine', 'LA POSTE - Kasserine', 'Kasserine', 'Avenue Habib Bourguiba, Kasserine', PlaceCategory.post, 35.1682, 8.8371, 4, 104, 80, 2),
      make('hospital_kasserine', 'Hôpital Régional de Kasserine', 'Kasserine', 'Route de Thala, Kasserine', PlaceCategory.hospital, 35.1725, 8.8321, 5, 175, 135, 2),
      make('bank_bna_kasserine', 'BNA - Kasserine', 'Kasserine', 'Avenue des Martyrs, Kasserine', PlaceCategory.bank, 35.1669, 8.8382, 3, 48, 42, 1),
      make('municipality_kasserine', 'Municipalité de Kasserine', 'Kasserine', 'Centre-Ville, Kasserine', PlaceCategory.municipality, 35.1678, 8.8358, 3, 63, 45, 2),

      // ==================== 18. SIDI BOUZID ====================
      make('post_sidi_bouzid', 'LA POSTE - Sidi Bouzid', 'Sidi Bouzid', 'Avenue Mohamed Bouazizi, Sidi Bouzid', PlaceCategory.post, 35.0389, 9.4856, 4, 88, 76, 1),
      make('hospital_sidi_bouzid', 'Hôpital Régional de Sidi Bouzid', 'Sidi Bouzid', 'Route de Sfax, Sidi Bouzid', PlaceCategory.hospital, 35.0352, 9.4912, 4, 136, 100, 2),
      make('bank_bna_sidi_bouzid', 'BNA - Sidi Bouzid', 'Sidi Bouzid', 'Avenue Habib Bourguiba, Sidi Bouzid', PlaceCategory.bank, 35.0378, 9.4842, 3, 51, 45, 1),
      make('municipality_sidi_bouzid', 'Municipalité de Sidi Bouzid', 'Sidi Bouzid', 'Place du 17 Décembre, Sidi Bouzid', PlaceCategory.municipality, 35.0385, 9.4849, 3, 69, 51, 2),

      // ==================== 19. GABÈS ====================
      make('post_gabes', 'LA POSTE - Gabès Centre', 'Gabès', 'Avenue Habib Bourguiba, Gabès', PlaceCategory.post, 33.8832, 10.0991, 4, 116, 84, 2),
      make('hospital_gabes', 'Hôpital Régional de Gabès', 'Gabès', 'Mtorrech, Gabès', PlaceCategory.hospital, 33.8654, 10.0912, 5, 175, 130, 2),
      make('bank_stb_gabes', 'STB - Gabès', 'Gabès', 'Avenue Farhat Hached, Gabès', PlaceCategory.bank, 33.8821, 10.0975, 4, 64, 56, 1),
      make('steg_gabes', 'STEG - Gabès', 'Gabès', 'Avenue Mohamed Ali, Gabès', PlaceCategory.utilities, 33.8848, 10.1008, 4, 100, 80, 2),
      make('municipality_gabes', 'Municipalité de Gabès', 'Gabès', 'Avenue Habib Bourguiba, Gabès', PlaceCategory.municipality, 33.8819, 10.0988, 4, 80, 68, 1),

      // ==================== 20. MÉDENINE & DJERBA ====================
      make('post_medenine', 'LA POSTE - Médenine', 'Médenine', 'Avenue Habib Bourguiba, Médenine', PlaceCategory.post, 33.3554, 10.5061, 4, 100, 80, 2),
      make('post_djerba', 'LA POSTE - Djerba Houmt Souk', 'Médenine', 'Avenue Abdelhamid El Kadhi, Djerba', PlaceCategory.post, 33.8758, 10.8575, 4, 68, 60, 1),
      make('hospital_medenine', 'Hôpital Habib Bourguiba Médenine', 'Médenine', 'Route de Tataouine, Médenine', PlaceCategory.hospital, 33.3472, 10.5015, 5, 165, 120, 2),
      make('bank_biat_djerba', 'BIAT - Djerba Houmt Souk', 'Médenine', 'Place de l’Indépendance, Djerba', PlaceCategory.bank, 33.8764, 10.8588, 4, 84, 64, 2),
      make('municipality_medenine', 'Municipalité de Médenine', 'Médenine', 'Avenue du 2 Mai, Médenine', PlaceCategory.municipality, 33.3541, 10.5048, 3, 54, 48, 1),

      // ==================== 21. TATAOUINE ====================
      make('post_tataouine', 'LA POSTE - Tataouine', 'Tataouine', 'Avenue Habib Bourguiba, Tataouine', PlaceCategory.post, 32.9302, 10.4522, 3, 60, 48, 1),
      make('hospital_tataouine', 'Hôpital Régional de Tataouine', 'Tataouine', 'Route de Médenine, Tataouine', PlaceCategory.hospital, 32.9368, 10.4551, 4, 112, 88, 2),
      make('bank_bna_tataouine', 'BNA - Tataouine', 'Tataouine', 'Avenue de la Liberté, Tataouine', PlaceCategory.bank, 32.9291, 10.4511, 3, 39, 33, 1),
      make('municipality_tataouine', 'Municipalité de Tataouine', 'Tataouine', 'Place du Peuple, Tataouine', PlaceCategory.municipality, 32.9298, 10.4508, 3, 69, 45, 2),

      // ==================== 22. GAFSA ====================
      make('post_gafsa', 'LA POSTE - Gafsa Centre', 'Gafsa', 'Avenue Habib Bourguiba, Gafsa', PlaceCategory.post, 34.4256, 8.7848, 4, 124, 92, 2),
      make('hospital_gafsa', 'Hôpital Houcine Bouzaiene', 'Gafsa', 'Avenue Houcine Bouzaiene, Gafsa', PlaceCategory.hospital, 34.4215, 8.7892, 5, 175, 130, 2),
      make('bank_stb_gafsa', 'STB - Gafsa', 'Gafsa', 'Place de l’Indépendance, Gafsa', PlaceCategory.bank, 34.4245, 8.7835, 3, 51, 45, 1),
      make('steg_gafsa', 'STEG - Gafsa', 'Gafsa', 'Avenue de la République, Gafsa', PlaceCategory.utilities, 34.4278, 8.7822, 4, 96, 76, 2),
      make('municipality_gafsa', 'Municipalité de Gafsa', 'Gafsa', 'Avenue Habib Bourguiba, Gafsa', PlaceCategory.municipality, 34.4251, 8.7841, 4, 72, 64, 1),

      // ==================== 23. TOZEUR ====================
      make('post_tozeur', 'LA POSTE - Tozeur', 'Tozeur', 'Avenue Habib Bourguiba, Tozeur', PlaceCategory.post, 33.9204, 8.1342, 3, 54, 45, 1),
      make('hospital_tozeur', 'Hôpital Régional Hédi Jaballah', 'Tozeur', 'Route de Nefta, Tozeur', PlaceCategory.hospital, 33.9165, 8.1288, 4, 104, 80, 2),
      make('bank_bna_tozeur', 'BNA - Tozeur', 'Tozeur', 'Avenue Abou El Kacem Chebbi, Tozeur', PlaceCategory.bank, 33.9191, 8.1331, 3, 42, 36, 1),
      make('municipality_tozeur', 'Municipalité de Tozeur', 'Tozeur', 'Place Ibn Chabbat, Tozeur', PlaceCategory.municipality, 33.9199, 8.1349, 3, 57, 45, 2),

      // ==================== 24. KÉBILI ====================
      make('post_kebili', 'LA POSTE - Kébili', 'Kébili', 'Avenue des Martyrs, Kébili', PlaceCategory.post, 33.7049, 8.9695, 3, 48, 42, 1),
      make('hospital_kebili', 'Hôpital Régional de Kébili', 'Kébili', 'Route de Gabès, Kébili', PlaceCategory.hospital, 33.7082, 8.9742, 4, 116, 84, 2),
      make('bank_bna_kebili', 'BNA - Kébili', 'Kébili', 'Avenue Habib Bourguiba, Kébili', PlaceCategory.bank, 33.7038, 8.9682, 3, 45, 39, 1),
      make('municipality_kebili', 'Municipalité de Kébili', 'Kébili', 'Centre-Ville, Kébili', PlaceCategory.municipality, 33.7042, 8.9698, 3, 57, 45, 2),
    ];
  }
}
