import 'dart:math';
import '../models/movie_model.dart';
import '../models/price_comparison_model.dart';
import '../models/show_model.dart';
import '../models/theatre_model.dart';

class MovieRepository {
  static final Random _rand = Random(42);

  static const List<_TheatreSeed> _theatreSeeds = [
    _TheatreSeed('t1', 'PVR Ampa Skywalk', 'Aminjikarai, Chennai', [
      'M-Ticket',
      'Food & Beverage',
      'Parking',
      'Dolby Atmos',
    ]),
    _TheatreSeed('t2', 'INOX Citi Centre', 'Mount Road, Chennai', [
      'M-Ticket',
      'Food & Beverage',
      'Wheelchair Access',
    ]),
    _TheatreSeed(
      't3',
      'SPI Cinemas - Palazzo',
      'Forum Vijaya Mall, Vadapalani',
      ['M-Ticket', 'Recliner Seats', 'Food & Beverage', 'Parking'],
    ),
    _TheatreSeed('t4', 'Rohini Silver Screens', 'Vadapalani, Chennai', [
      'Parking',
      'Food & Beverage',
    ]),
    _TheatreSeed('t5', 'Sathyam Cinemas', 'Royapettah, Chennai', [
      'M-Ticket',
      'IMAX',
      'Food & Beverage',
      'Parking',
      'Dolby Atmos',
    ]),
  ];

  static const List<String> _showTimes = [
    '10:00 AM',
    '1:15 PM',
    '4:30 PM',
    '8:00 PM',
    '10:45 PM',
  ];

  static List<TheatreModel> _generateTheatres(String movieId) {
    final theatres = <TheatreModel>[];
    for (final seed in _theatreSeeds) {
      final shows = <ShowModel>[];
      for (int d = 0; d < 5; d++) {
        final date = DateTime.now().add(Duration(days: d));
        for (int t = 0; t < _showTimes.length; t++) {
          final availabilityRoll = _rand.nextInt(10);
          final availability = availabilityRoll < 5
              ? ShowAvailability.available
              : availabilityRoll < 8
              ? ShowAvailability.fastFilling
              : ShowAvailability.almostFull;
          shows.add(
            ShowModel(
              id: '${movieId}_${seed.id}_${d}_$t',
              movieId: movieId,
              theatreId: seed.id,
              date: DateTime(date.year, date.month, date.day),
              time: _showTimes[t],
              screen: 'Screen ${(t % 4) + 1}',
              availability: availability,
            ),
          );
        }
      }
      theatres.add(
        TheatreModel(
          id: seed.id,
          name: seed.name,
          location: seed.location,
          amenities: seed.amenities,
          shows: shows,
        ),
      );
    }
    return theatres;
  }

  static final List<MovieModel> _movies = [
    _movie(
      id: 'm001',
      title: 'Kalki 2898 AD',
      seed: 'kalki',
      rating: 8.4,
      votes: 142000,
      duration: 181,
      genre: ['Action', 'Sci-Fi', 'Drama'],
      language: ['Telugu', 'Tamil', 'Hindi', 'Malayalam'],
      certification: 'U/A',
      synopsis:
          'Set in a dystopian future, a warrior fights to protect the last hope of humanity in a world ravaged by war and myth colliding in an epic tale of destruction and rebirth.',
      director: 'Nag Ashwin',
      daysAgo: -3,
      isNowShowing: true,
      isUpcoming: false,
      myPrice: 180,
      bmsPrice: 210,
      paytmPrice: 200,
      cast: ['Prabhas', 'Deepika Padukone', 'Amitabh Bachchan', 'Kamal Haasan'],
    ),
    _movie(
      id: 'm002',
      title: 'Leo',
      seed: 'leo',
      rating: 7.9,
      votes: 98000,
      duration: 164,
      genre: ['Action', 'Thriller'],
      language: ['Tamil', 'Telugu', 'Hindi'],
      certification: 'U/A',
      synopsis:
          'A mild-mannered café owner in Kashmir finds his past catching up with him when his family is threatened by a vicious drug cartel.',
      director: 'Lokesh Kanagaraj',
      daysAgo: -20,
      isNowShowing: true,
      isUpcoming: false,
      myPrice: 160,
      bmsPrice: 190,
      paytmPrice: 185,
      cast: ['Vijay', 'Trisha', 'Sanjay Dutt', 'Arjun Sarja'],
    ),
    _movie(
      id: 'm003',
      title: 'Jawan',
      seed: 'jawan',
      rating: 8.1,
      votes: 210000,
      duration: 169,
      genre: ['Action', 'Drama'],
      language: ['Hindi', 'Tamil', 'Telugu'],
      certification: 'U/A',
      synopsis:
          'A man is driven by a personal vendetta to rectify the wrongs in society, all while keeping a promise made years ago.',
      director: 'Atlee',
      daysAgo: -60,
      isNowShowing: true,
      isUpcoming: false,
      myPrice: 170,
      bmsPrice: 200,
      paytmPrice: 195,
      cast: [
        'Shah Rukh Khan',
        'Nayanthara',
        'Vijay Sethupathi',
        'Deepika Padukone',
      ],
    ),
    _movie(
      id: 'm004',
      title: 'Animal',
      seed: 'animal',
      rating: 7.2,
      votes: 175000,
      duration: 201,
      genre: ['Action', 'Crime', 'Drama'],
      language: ['Hindi', 'Tamil', 'Telugu'],
      certification: 'A',
      synopsis:
          'A son\'s desperate quest to win his father\'s love and approval spirals into a violent obsession that consumes everyone around him.',
      director: 'Sandeep Reddy Vanga',
      daysAgo: -90,
      isNowShowing: true,
      isUpcoming: false,
      myPrice: 150,
      bmsPrice: 180,
      paytmPrice: 175,
      cast: ['Ranbir Kapoor', 'Rashmika Mandanna', 'Anil Kapoor', 'Bobby Deol'],
    ),
    _movie(
      id: 'm005',
      title: 'Pushpa 2: The Rule',
      seed: 'pushpa2',
      rating: 8.6,
      votes: 260000,
      duration: 199,
      genre: ['Action', 'Drama'],
      language: ['Telugu', 'Tamil', 'Hindi', 'Malayalam', 'Kannada'],
      certification: 'U/A',
      synopsis:
          'Pushpa Raj continues his rise in the red sandalwood smuggling syndicate, facing new rivals and an unrelenting police force.',
      director: 'Sukumar',
      daysAgo: -5,
      isNowShowing: true,
      isUpcoming: false,
      myPrice: 200,
      bmsPrice: 240,
      paytmPrice: 230,
      cast: ['Allu Arjun', 'Rashmika Mandanna', 'Fahadh Faasil'],
    ),
    _movie(
      id: 'm006',
      title: 'KGF Chapter 3',
      seed: 'kgf3',
      rating: 8.8,
      votes: 5200,
      duration: 175,
      genre: ['Action', 'Drama'],
      language: ['Kannada', 'Tamil', 'Telugu', 'Hindi'],
      certification: 'U/A',
      synopsis:
          'Rocky\'s reign over the Kolar Gold Fields faces its greatest challenge yet as new global forces close in.',
      director: 'Prashanth Neel',
      daysAgo: 45,
      isNowShowing: false,
      isUpcoming: true,
      myPrice: 220,
      bmsPrice: 260,
      paytmPrice: 250,
      cast: ['Yash', 'Srinidhi Shetty', 'Raveena Tandon'],
    ),
    _movie(
      id: 'm007',
      title: 'RRR 2',
      seed: 'rrr2',
      rating: 9.0,
      votes: 3100,
      duration: 185,
      genre: ['Action', 'Drama', 'Fantasy'],
      language: ['Telugu', 'Tamil', 'Hindi'],
      certification: 'U/A',
      synopsis:
          'The legendary duo returns in a new saga of friendship, sacrifice, and rebellion set against the backdrop of colonial India.',
      director: 'S.S. Rajamouli',
      daysAgo: 120,
      isNowShowing: false,
      isUpcoming: true,
      myPrice: 210,
      bmsPrice: 250,
      paytmPrice: 240,
      cast: ['N.T. Rama Rao Jr.', 'Ram Charan', 'Alia Bhatt'],
    ),
    _movie(
      id: 'm008',
      title: 'Salaar: Part 2 - Shouryanga Parvam',
      seed: 'salaar2',
      rating: 8.2,
      votes: 4300,
      duration: 172,
      genre: ['Action', 'Thriller'],
      language: ['Telugu', 'Tamil', 'Hindi', 'Kannada'],
      certification: 'A',
      synopsis:
          'Deva\'s war against the empire of Khansaar intensifies as old alliances shatter and new enemies emerge.',
      director: 'Prashanth Neel',
      daysAgo: 30,
      isNowShowing: false,
      isUpcoming: true,
      myPrice: 200,
      bmsPrice: 230,
      paytmPrice: 225,
      cast: ['Prabhas', 'Prithviraj Sukumaran', 'Shruti Haasan'],
    ),
    _movie(
      id: 'm009',
      title: 'Fighter',
      seed: 'fighter',
      rating: 7.6,
      votes: 88000,
      duration: 166,
      genre: ['Action', 'Drama'],
      language: ['Hindi', 'Tamil', 'Telugu'],
      certification: 'U/A',
      synopsis:
          'An elite Air Force squadron takes on a high-stakes mission that tests their courage, unity, and resolve.',
      director: 'Siddharth Anand',
      daysAgo: -100,
      isNowShowing: true,
      isUpcoming: false,
      myPrice: 165,
      bmsPrice: 195,
      paytmPrice: 190,
      cast: ['Hrithik Roshan', 'Deepika Padukone', 'Anil Kapoor'],
    ),
    _movie(
      id: 'm010',
      title: 'Devara: Part 1',
      seed: 'devara',
      rating: 7.8,
      votes: 121000,
      duration: 175,
      genre: ['Action', 'Drama'],
      language: ['Telugu', 'Tamil', 'Hindi', 'Malayalam'],
      certification: 'U/A',
      synopsis:
          'A fearsome protector of a coastal village rises against a smuggling syndicate threatening his people.',
      director: 'Koratala Siva',
      daysAgo: -70,
      isNowShowing: true,
      isUpcoming: false,
      myPrice: 175,
      bmsPrice: 205,
      paytmPrice: 198,
      cast: ['N.T. Rama Rao Jr.', 'Janhvi Kapoor', 'Saif Ali Khan'],
    ),
  ];

  static MovieModel _movie({
    required String id,
    required String title,
    required String seed,
    required double rating,
    required int votes,
    required int duration,
    required List<String> genre,
    required List<String> language,
    required String certification,
    required String synopsis,
    required String director,
    required int daysAgo,
    required bool isNowShowing,
    required bool isUpcoming,
    required double myPrice,
    required double bmsPrice,
    required double paytmPrice,
    required List<String> cast,
  }) {
    final localAssetMap = <String, String>{
      'kalki': 'assets/images/kalki.jpg',
      'leo': 'assets/images/leo.jpg',
      'jawan': 'assets/images/jawan.jpg',
      'animal': 'assets/images/animal.jpg',
      'pushpa2': 'assets/images/pushpa.jpg',
      'fighter': 'assets/images/flighter.jpg',
      'devara': 'assets/images/devra.jpg',
    };

    final poster = localAssetMap[seed] ?? 'https://picsum.photos/seed/$seed/300/450';
    final banner = localAssetMap[seed] ?? 'https://picsum.photos/seed/${seed}banner/800/450';

    return MovieModel(
      id: id,
      title: title,
      posterUrl: poster,
      bannerUrl: banner,
      rating: rating,
      votes: votes,
      duration: duration,
      genre: genre,
      language: language,
      certification: certification,
      synopsis: synopsis,
      cast: cast
          .map(
            (n) => CastMember(
              name: n,
              imageUrl:
                  'https://picsum.photos/seed/${n.replaceAll(' ', '')}/200/200',
              role: 'Actor',
            ),
          )
          .toList(),
      director: director,
      releaseDate: DateTime.now().subtract(Duration(days: daysAgo)),
      isNowShowing: isNowShowing,
      isUpcoming: isUpcoming,
      trailerUrl: 'https://example.com/trailer/$seed',
      theatres: isNowShowing ? _generateTheatres(id) : [],
      priceComparison: PriceComparisonModel(
        myTicketsPrice: myPrice,
        bookMyShowPrice: bmsPrice,
        paytmPrice: paytmPrice,
      ),
      reviews: [
        ReviewModel(
          id: '${id}_r1',
          userName: 'Arjun R.',
          userAvatarUrl: 'https://picsum.photos/seed/${seed}u1/100/100',
          rating: (rating - 0.3).clamp(0, 10) / 2,
          comment:
              'Absolutely loved the visuals and the pacing. Worth every rupee!',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ReviewModel(
          id: '${id}_r2',
          userName: 'Priya S.',
          userAvatarUrl: 'https://picsum.photos/seed/${seed}u2/100/100',
          rating: (rating - 1.0).clamp(0, 10) / 2,
          comment: 'Great performances, though the second half dragged a bit.',
          date: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ReviewModel(
          id: '${id}_r3',
          userName: 'Karthik M.',
          userAvatarUrl: 'https://picsum.photos/seed/${seed}u3/100/100',
          rating: (rating - 0.1).clamp(0, 10) / 2,
          comment:
              'One of the best theatre experiences this year. Highly recommend watching it on the big screen.',
          date: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ],
    );
  }

  Future<List<MovieModel>> getNowShowing() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _movies.where((m) => m.isNowShowing).toList();
  }

  Future<List<MovieModel>> getUpcoming() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _movies.where((m) => m.isUpcoming).toList();
  }

  Future<List<MovieModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _movies;
  }

  Future<MovieModel> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _movies.firstWhere((m) => m.id == id, orElse: () => _movies.first);
  }

  List<MovieModel> searchSync(String query) {
    final q = query.toLowerCase();
    return _movies.where((m) => m.title.toLowerCase().contains(q)).toList();
  }
}

class _TheatreSeed {
  final String id;
  final String name;
  final String location;
  final List<String> amenities;
  const _TheatreSeed(this.id, this.name, this.location, this.amenities);
}
