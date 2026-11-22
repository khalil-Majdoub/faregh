import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:queue_time_app/data/tunisia_places.dart';
import 'package:queue_time_app/models/society_place.dart';
import 'package:queue_time_app/models/user_account.dart';
import 'package:queue_time_app/services/auth_provider.dart';
import 'package:queue_time_app/services/location_service.dart';
import 'package:queue_time_app/services/osm_discovery_service.dart';
import 'package:queue_time_app/services/queue_provider.dart';
import 'package:queue_time_app/widgets/service_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Tests fonctionnels', () {
    test('Inscription, connexion, validation mot de passe et déconnexion', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(auth.isInitialized, isTrue);
      expect(auth.isAuthenticated, isFalse);

      // Inscription d'un nouveau citoyen
      final regError = await auth.register(
        fullName: 'Amine Trabelsi',
        email: 'amine@feregh.tn',
        password: 'secret123',
        role: UserRole.user,
        city: 'Sousse',
      );
      expect(regError, isNull);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.firstName, 'Amine');
      expect(auth.currentUser?.role, UserRole.user);

      // Refus d'un email déjà existant
      final dupError = await auth.register(
        fullName: 'Autre',
        email: 'amine@feregh.tn',
        password: 'secret123',
        role: UserRole.user,
        city: 'Sousse',
      );
      expect(dupError, isNotNull);

      // Déconnexion puis reconnexion avec mauvais puis bon mot de passe
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);

      final wrongPwd = await auth.login(
        email: 'amine@feregh.tn',
        password: 'wrong',
      );
      expect(wrongPwd, isNotNull);
      expect(auth.isAuthenticated, isFalse);

      final okLogin = await auth.login(
        email: 'amine@feregh.tn',
        password: 'secret123',
      );
      expect(okLogin, isNull);
      expect(auth.isAuthenticated, isTrue);
    });

    test('Gestion des comptes citoyens et établissements (sociétés)', () async {
      final auth = AuthProvider();
      final queue = QueueProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Connexion compte citoyen pré-configuré (Khalil)
      final citizenErr = await auth.login(
        email: 'khalil@user.tn',
        password: '123456',
      );
      expect(citizenErr, isNull);
      expect(auth.currentUser?.role, UserRole.user);
      expect(auth.currentUser?.societyPlaceId, isNull);

      await auth.logout();

      // Inscription d'un nouvel établissement lié à sa branche
      final createdBranch = await queue.addSocietyPlace(
        name: 'LA POSTE - Monastir',
        city: 'Monastir',
        address: 'Avenue de la Liberté',
        category: PlaceCategory.post,
        guichetCount: 4,
      );

      final socErr = await auth.register(
        fullName: 'LA POSTE - Monastir',
        email: 'poste.monastir@feregh.tn',
        password: 'post2026',
        role: UserRole.society,
        city: 'Monastir',
        societyPlaceId: createdBranch.id,
      );
      expect(socErr, isNull);
      expect(auth.currentUser?.role, UserRole.society);
      expect(auth.currentUser?.societyPlaceId, createdBranch.id);

      queue.dispose();
    });

    test('Mise à jour en direct des files d’attente (guichets et tickets)', () async {
      final queue = QueueProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // LA POSTE - Sousse Centre démarre à 150 / 100 / 5 guichets -> 50 min (Rouge)
      final initial = queue.getPlaceById('post_sousse_centre')!;
      expect(initial.calculatedWaitMinutes, 50);
      expect(initial.crowdStatus, CrowdStatus.crowded);

      // Mise à jour côté société : 120 / 100 / 4 guichets -> 25 min (Jaune)
      await queue.updateSocietyQueue(
        placeId: 'post_sousse_centre',
        guichetCount: 4,
        lastTicketNumber: 120,
        currentTicketNumber: 100,
      );
      final moderate = queue.getPlaceById('post_sousse_centre')!;
      expect(moderate.waitingPeople, 20);
      expect(moderate.calculatedWaitMinutes, 25);
      expect(moderate.crowdStatus, CrowdStatus.moderate);

      // Sécurité : currentTicket > lastTicket est borné à lastTicket -> 0 min (Vert)
      await queue.updateSocietyQueue(
        placeId: 'post_sousse_centre',
        lastTicketNumber: 120,
        currentTicketNumber: 150,
      );
      final empty = queue.getPlaceById('post_sousse_centre')!;
      expect(empty.currentTicketNumber, 120);
      expect(empty.calculatedWaitMinutes, 0);
      expect(empty.crowdStatus, CrowdStatus.notCrowded);

      queue.dispose();
    });

    test('Filtrage des établissements pour la carte et la recherche (catégorie & affluence)', () async {
      final queue = QueueProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Tous les établissements possèdent des coordonnées GPS valides pour la carte
      expect(queue.places.length, greaterThanOrEqualTo(10));
      for (final p in queue.places) {
        expect(p.latitude, inInclusiveRange(30.0, 38.0));
        expect(p.longitude, inInclusiveRange(7.0, 12.0));
      }

      // Filtre "Post" uniquement (exclut hôpitaux et banques)
      final postsOnly = queue.getFilteredPlaces(category: PlaceCategory.post);
      expect(postsOnly, isNotEmpty);
      expect(postsOnly.every((p) => p.category == PlaceCategory.post), isTrue);

      // Filtre "Post" + Vert (Non encombré)
      final greenPosts = queue.getFilteredPlaces(
        category: PlaceCategory.post,
        crowdStatus: CrowdStatus.notCrowded,
      );
      expect(greenPosts, isNotEmpty);
      expect(greenPosts.every((p) => p.crowdStatus == CrowdStatus.notCrowded), isTrue);

      // Recherche textuelle par mot-clé ("hospital", "bank")
      final hospitals = queue.getFilteredPlaces(searchQuery: 'hospital');
      expect(hospitals, isNotEmpty);
      expect(hospitals.every((p) => p.category == PlaceCategory.hospital), isTrue);

      final banks = queue.getFilteredPlaces(searchQuery: 'bank');
      expect(banks, isNotEmpty);
      expect(banks.every((p) => p.category == PlaceCategory.bank), isTrue);

      queue.dispose();
    });

    test('Géolocalisation, calcul des distances (Haversine) et recommandation optimale', () async {
      final queue = QueueProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Position utilisateur à Khzema, Sousse
      queue.setCustomUserLocation(LocationService.presetLocations[1]);

      final distKhzema = queue.distanceTo(queue.getPlaceById('post_khzema')!);
      final distCentre = queue.distanceTo(queue.getPlaceById('post_sousse_centre')!);

      expect(distKhzema, lessThan(1.0));
      expect(distCentre, greaterThan(distKhzema));

      // La meilleure poste recommandée doit être LA POSTE - Khzema (plus proche + 15 min vert)
      final bestPost = queue.getBestPlace(category: PlaceCategory.post);
      expect(bestPost?.id, 'post_khzema');

      queue.dispose();
    });
  });

  group('2. Tests du moteur de calcul', () {
    test('Différentes combinaisons de tickets et de guichets actifs', () {
      // Exemple principal : 150 - 100 = 50 / 5 = 10 * 5 = 50 min (Rouge)
      expect(
        SocietyPlace.calculateWaitMinutes(lastTicket: 150, currentTicket: 100, guichets: 5),
        50,
      );
      // 1 seul guichet actif : 6 personnes * 5 min = 30 min (Jaune)
      expect(
        SocietyPlace.calculateWaitMinutes(lastTicket: 46, currentTicket: 40, guichets: 1),
        30,
      );
      // 3 guichets actifs : 9 personnes / 3 = 3 * 5 = 15 min (Vert)
      expect(
        SocietyPlace.calculateWaitMinutes(lastTicket: 69, currentTicket: 60, guichets: 3),
        15,
      );
      // 6 guichets actifs : 54 personnes / 6 = 9 * 5 = 45 min (Rouge)
      expect(
        SocietyPlace.calculateWaitMinutes(lastTicket: 214, currentTicket: 160, guichets: 6),
        45,
      );
      // Protection contre guichets = 0 (division sécurisée à 1)
      expect(
        SocietyPlace.calculateWaitMinutes(lastTicket: 12, currentTicket: 10, guichets: 0),
        10,
      );
    });

    test('Classification complète des seuils d’affluence (Vert / Jaune / Rouge)', () {
      expect(SocietyPlace.statusForWaitMinutes(0), CrowdStatus.notCrowded);
      expect(SocietyPlace.statusForWaitMinutes(19), CrowdStatus.notCrowded);
      expect(SocietyPlace.statusForWaitMinutes(20), CrowdStatus.moderate);
      expect(SocietyPlace.statusForWaitMinutes(39), CrowdStatus.moderate);
      expect(SocietyPlace.statusForWaitMinutes(40), CrowdStatus.crowded);
      expect(SocietyPlace.statusForWaitMinutes(90), CrowdStatus.crowded);
    });
  });

  group('3. Tests d’actualisation (2 min / 5 min et mise à jour UI)', () {
    testWidgets('Recalcul automatique toutes les 2 min et 5 min + mise à jour widget', (tester) async {
      final queue = QueueProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<QueueProvider>.value(
          value: queue,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<QueueProvider>(
                builder: (context, q, _) {
                  final poste = q.getPlaceById('post_sousse_centre')!;
                  return ServiceCard(
                    place: poste,
                    distanceKm: q.distanceTo(poste),
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Laisser l'initialisation asynchrone démarrer les timers
      await tester.pump(const Duration(milliseconds: 50));

      // Affichage initial : 50 min / CROWDED
      expect(find.text('LA POSTE - Sousse Centre'), findsOneWidget);
      expect(find.text('CROWDED'), findsOneWidget);

      final logsBefore2m = queue.logs.length;
      expect(queue.refreshIntervalMinutes, 2);

      // Avance de l'horloge de 2 minutes -> déclenche le Timer.periodic automatique
      await tester.pump(const Duration(minutes: 2));
      expect(queue.logs.length, greaterThan(logsBefore2m));
      expect(queue.logs.first.wasAutomatic, isTrue);

      // Passage à l'intervalle de 5 minutes
      await queue.setRefreshIntervalMinutes(5);
      await tester.pump();
      expect(queue.refreshIntervalMinutes, 5);
      final logsBefore5m = queue.logs.length;

      // Après 2 minutes, ne doit PAS encore recalculer (intervalle = 5 min)
      await tester.pump(const Duration(minutes: 2));
      expect(queue.logs.length, logsBefore5m);

      // Après 3 minutes supplémentaires (total 5 min) -> recalcul automatique déclenché
      await tester.pump(const Duration(minutes: 3));
      expect(queue.logs.length, logsBefore5m + 1);
      expect(queue.logs.first.wasAutomatic, isTrue);

      // Vérifie que l'interface affichée se met à jour en direct lors d'un changement de file
      await queue.updateSocietyQueue(
        placeId: 'post_sousse_centre',
        lastTicketNumber: 115,
        currentTicketNumber: 100,
        guichetCount: 5,
      );
      await tester.pump();
      expect(find.text('NOT CROWDED'), findsOneWidget);

      queue.dispose();
    });
  });

  group('4. Couverture nationale (24 gouvernorats + OpenStreetMap)', () {
    test('Tous les 24 gouvernorats tunisiens sont couverts avec établissements réels', () async {
      final queue = QueueProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(TunisiaDirectory.allGovernorates.length, 24);
      expect(queue.places.length, greaterThanOrEqualTo(115));

      for (final gov in TunisiaDirectory.governorateNames) {
        final inGov = queue.getFilteredPlaces(governorate: gov);
        expect(
          inGov,
          isNotEmpty,
          reason: 'Le gouvernorat $gov doit contenir des établissements',
        );
      }

      // Vérifie le filtrage par gouvernorat (ex. Sfax, Tunis, Tataouine)
      final sfaxPlaces = queue.getFilteredPlaces(governorate: 'Sfax');
      expect(sfaxPlaces.every((p) => p.city == 'Sfax'), isTrue);

      final tataouinePlaces = queue.getFilteredPlaces(governorate: 'Tataouine');
      expect(tataouinePlaces.every((p) => p.city == 'Tataouine'), isTrue);

      queue.dispose();
    });

    test('OsmDiscoveryService parse correctement les données Overpass en Tunisie', () {
      const sampleJson = '''
      {
        "elements": [
          {
            "type": "node",
            "id": 123456,
            "lat": 36.8065,
            "lon": 10.1815,
            "tags": {
              "amenity": "post_office",
              "name": "Bureau de Poste Habib Thameur",
              "addr:city": "Tunis",
              "addr:street": "Avenue Habib Thameur"
            }
          },
          {
            "type": "way",
            "id": 654321,
            "center": {"lat": 34.7406, "lon": 10.7603},
            "tags": {
              "amenity": "hospital",
              "name": "Polyclinique Sfax"
            }
          },
          {
            "type": "node",
            "id": 999999,
            "lat": 48.8566,
            "lon": 2.3522,
            "tags": {
              "amenity": "bank",
              "name": "Outside Tunisia Bank"
            }
          }
        ]
      }
      ''';

      final parsed = OsmDiscoveryService.parseOverpassJson(
        sampleJson,
        fallbackCity: 'Sfax',
      );

      // Seuls les 2 lieux situés en Tunisie sont conservés (Paris exclu)
      expect(parsed.length, 2);
      expect(parsed[0].category, PlaceCategory.post);
      expect(parsed[0].city, 'Tunis');
      expect(parsed[1].category, PlaceCategory.hospital);
      expect(parsed[1].city, 'Sfax');
    });
  });
}
