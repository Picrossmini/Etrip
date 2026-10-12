import 'package:etrip/features/auth/data/models/egyptopia_user.dart';
import 'package:etrip/features/places/data/models/place_model.dart';

const _places = 'assets/images/places';

// ============ Mock Places ============

final List<PlaceModel> mockPlaces = [
  PlaceModel(
    id: '1',
    name: 'Great Wall',
    profileImage: '$_places/great_wall.jpg',
    carouselImages: [
      '$_places/great_wall.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Beijing',
    rate: 4.9,
    totalRates: 23500,
    description:
        'The Great Wall of China is one of the most iconic wonders of the world, stretching over 13,000 miles. '
        'Built across multiple dynasties, it offers breathtaking views and a glimpse into China\'s ancient history.',
    googleMapsLink: 'https://maps.google.com/?q=Great+Wall+of+China',
    lat: 40.4319,
    lng: 116.5704,
  ),
  PlaceModel(
    id: '2',
    name: 'Forbidden City',
    profileImage: '$_places/forbidden_city.jpg',
    carouselImages: [
      '$_places/forbidden_city.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'palace',
    cityName: 'Beijing',
    rate: 4.8,
    totalRates: 18200,
    description:
        'The Forbidden City was the Chinese imperial palace from the Ming to the Qing dynasty. '
        'It houses over 1 million artifacts and is the world\'s largest palace complex.',
    googleMapsLink: 'https://maps.google.com/?q=Forbidden+City+Beijing',
    lat: 39.9163,
    lng: 116.3972,
  ),
  PlaceModel(
    id: '3',
    name: 'The Bund',
    profileImage: '$_places/the_bund.jpg',
    carouselImages: [
      '$_places/the_bund.jpg',
    ],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'shopping',
    cityName: 'Shanghai',
    rate: 4.5,
    totalRates: 15400,
    description:
        'The Bund is Shanghai\'s iconic waterfront promenade, lined with colonial-era buildings '
        'and modern skyscrapers. It offers spectacular views of the Huangpu River and Pudong skyline.',
    googleMapsLink: 'https://maps.google.com/?q=The+Bund+Shanghai',
    lat: 31.2400,
    lng: 121.4900,
  ),
  PlaceModel(
    id: '4',
    name: 'Leshan Giant Buddha',
    profileImage: '$_places/leshan_buddha.jpg',
    carouselImages: [
      '$_places/leshan_buddha.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Leshan',
    rate: 4.7,
    totalRates: 8600,
    description:
        'The Leshan Giant Buddha is a 71-meter tall stone statue carved into a cliff face. '
        'Built during the Tang dynasty, it is the largest stone Buddha in the world.',
    googleMapsLink: 'https://maps.google.com/?q=Leshan+Giant+Buddha',
    lat: 29.5472,
    lng: 103.7695,
  ),
  PlaceModel(
    id: '5',
    name: 'Zhangjiajie National Forest',
    profileImage: '$_places/zhangjiajie.jpg',
    carouselImages: [
      '$_places/zhangjiajie.jpg',
    ],
    tourismType: 'Natural Attractions',
    category: 'historical site',
    cityName: 'Zhangjiajie',
    rate: 4.8,
    totalRates: 12600,
    description:
        'Zhangjiajie National Forest Park is famous for its towering sandstone pillars, '
        'which inspired the floating mountains in Avatar. It offers stunning hiking trails and glass bridges.',
    googleMapsLink: 'https://maps.google.com/?q=Zhangjiajie+National+Forest',
    lat: 29.3992,
    lng: 110.4666,
  ),
  PlaceModel(
    id: '6',
    name: 'Terracotta Warriors',
    profileImage: '$_places/terracotta.jpg',
    carouselImages: [
      '$_places/terracotta.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'museum',
    cityName: "Xi'an",
    rate: 4.8,
    totalRates: 16800,
    description:
        'The Terracotta Army is a collection of thousands of life-sized clay soldiers buried with Emperor Qin. '
        'Discovered in 1974, it is considered the eighth wonder of the world.',
    googleMapsLink: 'https://maps.google.com/?q=Terracotta+Warriors+Xian',
    lat: 34.3841,
    lng: 109.2739,
  ),
  PlaceModel(
    id: '7',
    name: 'West Lake',
    profileImage: '$_places/west_lake.jpg',
    carouselImages: [
      '$_places/west_lake.jpg',
    ],
    tourismType: 'Natural Attractions',
    category: 'garden',
    cityName: 'Hangzhou',
    rate: 4.7,
    totalRates: 14500,
    description:
        'West Lake is a UNESCO World Heritage site in Hangzhou, known for its natural beauty '
        'and historic pagodas. It has inspired poets and artists for centuries.',
    googleMapsLink: 'https://maps.google.com/?q=West+Lake+Hangzhou',
    lat: 30.2590,
    lng: 120.1485,
  ),
  PlaceModel(
    id: '8',
    name: 'Potala Palace',
    profileImage: '$_places/potala_palace.jpg',
    carouselImages: [
      '$_places/potala_palace.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'palace',
    cityName: 'Lhasa',
    rate: 4.8,
    totalRates: 9200,
    description:
        'The Potala Palace in Lhasa was the winter residence of the Dalai Lama. '
        'This stunning 13-story palace features over 1,000 rooms with beautiful Tibetan Buddhist art.',
    googleMapsLink: 'https://maps.google.com/?q=Potala+Palace+Lhasa',
    lat: 29.6579,
    lng: 91.1172,
  ),
  PlaceModel(
    id: '9',
    name: 'Li River',
    profileImage: '$_places/li_river.jpg',
    carouselImages: [
      '$_places/li_river.jpg',
    ],
    tourismType: 'Natural Attractions',
    category: 'historical site',
    cityName: 'Guilin',
    rate: 4.7,
    totalRates: 11300,
    description:
        'The Li River cruise from Guilin to Yangshuo offers some of China\'s most spectacular scenery, '
        'with dramatic karst mountains reflected in the emerald water.',
    googleMapsLink: 'https://maps.google.com/?q=Li+River+Guilin',
    lat: 24.8840,
    lng: 110.4420,
  ),
  PlaceModel(
    id: '10',
    name: 'Summer Palace',
    profileImage: '$_places/summer_palace.jpg',
    carouselImages: [
      '$_places/summer_palace.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'palace',
    cityName: 'Beijing',
    rate: 4.6,
    totalRates: 13100,
    description:
        'The Summer Palace is a magnificent ensemble of lakes, gardens and palaces in Beijing. '
        'It served as a royal retreat and is a masterpiece of Chinese landscape design.',
    googleMapsLink: 'https://maps.google.com/?q=Summer+Palace+Beijing',
    lat: 39.9998,
    lng: 116.2755,
  ),
  PlaceModel(
    id: '11',
    name: 'Shanghai Disneyland',
    profileImage: '$_places/disneyland.jpg',
    carouselImages: [
      '$_places/disneyland.jpg',
    ],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'shopping',
    cityName: 'Shanghai',
    rate: 4.6,
    totalRates: 17800,
    description:
        'Shanghai Disneyland is a world-class theme park with unique attractions blending '
        'Disney magic with Chinese culture, including the Enchanted Storybook Castle.',
    googleMapsLink: 'https://maps.google.com/?q=Shanghai+Disneyland',
    lat: 31.1439,
    lng: 121.6575,
  ),
  PlaceModel(
    id: '12',
    name: 'Chengdu Panda Base',
    profileImage: '$_places/panda_base.jpg',
    carouselImages: [
      '$_places/panda_base.jpg',
    ],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'garden',
    cityName: 'Chengdu',
    rate: 4.8,
    totalRates: 14100,
    description:
        'The Chengdu Research Base of Giant Panda Breeding lets visitors see giant pandas up close '
        'in a natural setting. It\'s one of the most popular wildlife attractions in China.',
    googleMapsLink: 'https://maps.google.com/?q=Chengdu+Panda+Base',
    lat: 30.7310,
    lng: 104.1450,
  ),
  PlaceModel(
    id: '13',
    name: 'Shaolin Temple',
    profileImage: '$_places/shaolin.jpg',
    carouselImages: [
      '$_places/shaolin.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'temple',
    cityName: 'Zhengzhou',
    rate: 4.5,
    totalRates: 7800,
    description:
        'Shaolin Temple is the birthplace of Chan (Zen) Buddhism and Shaolin Kung Fu. '
        'Located at Songshan Mountain, it attracts martial arts enthusiasts from around the world.',
    googleMapsLink: 'https://maps.google.com/?q=Shaolin+Temple',
    lat: 34.5050,
    lng: 112.9350,
  ),
  PlaceModel(
    id: '14',
    name: 'Yellow Mountain',
    profileImage: '$_places/huangshan.jpg',
    carouselImages: [
      '$_places/huangshan.jpg',
    ],
    tourismType: 'Natural Attractions',
    category: 'historical site',
    cityName: 'Huangshan',
    rate: 4.8,
    totalRates: 10500,
    description:
        'Huangshan, the Yellow Mountain, is renowned for its magnificent granite peaks, '
        'hot springs, and seas of clouds. It\'s one of China\'s most famous scenic areas.',
    googleMapsLink: 'https://maps.google.com/?q=Yellow+Mountain+Huangshan',
    lat: 30.1320,
    lng: 118.1690,
  ),
  PlaceModel(
    id: '15',
    name: 'Mogao Caves',
    profileImage: '$_places/mogao_caves.jpg',
    carouselImages: [
      '$_places/mogao_caves.jpg',
    ],
    tourismType: 'Cultural and Historical Attractions',
    category: 'museum',
    cityName: 'Dunhuang',
    rate: 4.6,
    totalRates: 6400,
    description:
        'The Mogao Caves are a UNESCO World Heritage site featuring hundreds of Buddhist cave temples '
        'filled with exquisite murals and sculptures spanning over 1,000 years.',
    googleMapsLink: 'https://maps.google.com/?q=Mogao+Caves+Dunhuang',
    lat: 40.0400,
    lng: 94.8000,
  ),
  PlaceModel(
    id: '16',
    name: 'Victoria Harbour',
    profileImage: '$_places/victoria_harbour.jpg',
    carouselImages: [
      '$_places/victoria_harbour.jpg',
    ],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'shopping',
    cityName: 'Hong Kong',
    rate: 4.7,
    totalRates: 19200,
    description:
        'Victoria Harbour is a major attraction in Hong Kong, famous for its stunning skyline '
        'and the Symphony of Lights show. The Star Ferry offers a classic harbour crossing.',
    googleMapsLink: 'https://maps.google.com/?q=Victoria+Harbour+Hong+Kong',
    lat: 22.2854,
    lng: 114.1628,
  ),

  // ====== Chengdu / Sichuan Attractions (added for Step 2) ======

  PlaceModel(
    id: '17',
    name: 'Jinli Ancient Street',
    profileImage: '$_places/jinli.jpg',
    carouselImages: ['$_places/jinli.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.5,
    totalRates: 5200,
    description:
        'Jinli Ancient Street is a bustling pedestrian street in Chengdu that recreates '
        'the architectural style of the Qing Dynasty. It offers traditional snacks, crafts, '
        'and folk performances in a lively atmosphere.',
    googleMapsLink: 'https://maps.google.com/?q=Jinli+Ancient+Street+Chengdu',
    lat: 30.6440,
    lng: 104.0470,
  ),
  PlaceModel(
    id: '18',
    name: 'Wuhou Shrine',
    profileImage: '$_places/wuhou.jpg',
    carouselImages: ['$_places/wuhou.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.6,
    totalRates: 7200,
    description:
        'Wuhou Shrine is a memorial dedicated to Zhuge Liang, the famous strategist '
        'of the Three Kingdoms period. The serene temple grounds feature beautiful '
        'architecture, ancient inscriptions, and statues.',
    googleMapsLink: 'https://maps.google.com/?q=Wuhou+Shrine+Chengdu',
    lat: 30.6490,
    lng: 104.0478,
  ),
  PlaceModel(
    id: '19',
    name: 'Mount Qingcheng',
    profileImage: '$_places/qingcheng.jpg',
    carouselImages: ['$_places/qingcheng.jpg'],
    tourismType: 'Natural Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.7,
    totalRates: 8900,
    description:
        'Mount Qingcheng is one of the birthplaces of Taoism, known for its lush green forests, '
        'ancient Taoist temples, and peaceful mountain paths. It offers a perfect escape from '
        'the busy city into nature.',
    googleMapsLink: 'https://maps.google.com/?q=Mount+Qingcheng+Chengdu',
    lat: 30.8978,
    lng: 103.5720,
  ),
  PlaceModel(
    id: '20',
    name: 'Dujiangyan Irrigation System',
    profileImage: '$_places/dujiangyan.jpg',
    carouselImages: ['$_places/dujiangyan.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.7,
    totalRates: 6500,
    description:
        'Built over 2,200 years ago, the Dujiangyan Irrigation System is a marvel of ancient '
        'Chinese engineering that still irrigates the Chengdu Plain today. A UNESCO World Heritage site.',
    googleMapsLink: 'https://maps.google.com/?q=Dujiangyan+Irrigation+System',
    lat: 31.0017,
    lng: 103.6146,
  ),
  PlaceModel(
    id: '21',
    name: 'Mount Emei',
    profileImage: '$_places/emei.jpg',
    carouselImages: ['$_places/emei.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'temple',
    cityName: 'Emeishan',
    rate: 4.8,
    totalRates: 11200,
    description:
        'Mount Emei is one of China\'s four sacred Buddhist mountains, with breathtaking '
        'scenery, ancient temples, and the famous Golden Summit. It offers spectacular sunrise views '
        'and a chance to see wild monkeys.',
    googleMapsLink: 'https://maps.google.com/?q=Mount+Emei+Sichuan',
    lat: 29.5200,
    lng: 103.3400,
  ),
  PlaceModel(
    id: '22',
    name: 'Kuanzhai Ancient Alley',
    profileImage: '$_places/kuanzhai.jpg',
    carouselImages: ['$_places/kuanzhai.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.5,
    totalRates: 7800,
    description:
        'Kuanzhai Ancient Alley consists of three parallel alleys — Wide, Narrow, and Well — '
        'representing Chengdu\'s ancient urban layout. It\'s a perfect blend of traditional '
        'architecture, trendy cafes, and local food.',
    googleMapsLink: 'https://maps.google.com/?q=Kuanzhai+Alley+Chengdu',
    lat: 30.6670,
    lng: 104.0520,
  ),
  PlaceModel(
    id: '23',
    name: 'Chunxi Road',
    profileImage: '$_places/chunxi.jpg',
    carouselImages: ['$_places/chunxi.jpg'],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'shopping',
    cityName: 'Chengdu',
    rate: 4.4,
    totalRates: 15200,
    description:
        'Chunxi Road is Chengdu\'s premier shopping district, a vibrant pedestrian street '
        'lined with modern malls, luxury boutiques, and countless local restaurants serving '
        'authentic Sichuan cuisine.',
    googleMapsLink: 'https://maps.google.com/?q=Chunxi+Road+Chengdu',
    lat: 30.6550,
    lng: 104.0830,
  ),
  PlaceModel(
    id: '24',
    name: 'Sichuan Opera Theater',
    profileImage: '$_places/sichuan_opera.jpg',
    carouselImages: ['$_places/sichuan_opera.jpg'],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'theater',
    cityName: 'Chengdu',
    rate: 4.6,
    totalRates: 4300,
    description:
        'Sichuan Opera is famous for its unique face-changing performance (Bian Lian), '
        'where performers instantly change colorful masks. The theater in Chengdu offers '
        'an unforgettable cultural show with music and puppetry.',
    googleMapsLink: 'https://maps.google.com/?q=Sichuan+Opera+Chengdu',
    lat: 30.6550,
    lng: 104.0820,
  ),
  PlaceModel(
    id: '25',
    name: 'Jiuzhaigou Valley',
    profileImage: '$_places/jiuzhaigou.jpg',
    carouselImages: ['$_places/jiuzhaigou.jpg'],
    tourismType: 'Natural Attractions',
    category: 'historical site',
    cityName: 'Jiuzhaigou',
    rate: 4.9,
    totalRates: 13500,
    description:
        'Jiuzhaigou Valley is a UNESCO World Heritage site famous for its turquoise lakes, '
        'tiered waterfalls, and snow-capped peaks. Its colorful alpine lakes look like '
        'scattered jewels in a forest paradise.',
    googleMapsLink: 'https://maps.google.com/?q=Jiuzhaigou+Valley+Sichuan',
    lat: 33.2667,
    lng: 104.2333,
  ),
  PlaceModel(
    id: '26',
    name: 'Mount Siguniang',
    profileImage: '$_places/siguniang.jpg',
    carouselImages: ['$_places/siguniang.jpg'],
    tourismType: 'Natural Attractions',
    category: 'historical site',
    cityName: 'Xiaojin',
    rate: 4.8,
    totalRates: 5600,
    description:
        'Mount Siguniang (Four Girls Mountain) is renowned for its four majestic peaks, '
        'alpine meadows, and pristine glacial lakes. It\'s a paradise for hikers and '
        'photographers, often called "Eastern Alps".',
    googleMapsLink: 'https://maps.google.com/?q=Mount+Siguniang+Sichuan',
    lat: 30.9972,
    lng: 102.8361,
  ),

  // ====== Additional Chengdu / Sichuan Attractions (Step 4) ======

  PlaceModel(
    id: '27',
    name: 'Du Fu Thatched Cottage',
    profileImage: '$_places/dufu_cottage.jpg',
    carouselImages: ['$_places/dufu_cottage.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.5,
    totalRates: 6100,
    description:
        'Du Fu Thatched Cottage is a memorial to Du Fu, one of China\'s greatest poets. '
        'Set in a peaceful garden with traditional architecture, it recreates the poet\'s '
        'former residence and showcases his literary legacy.',
    googleMapsLink: 'https://maps.google.com/?q=Du+Fu+Thatched+Cottage+Chengdu',
    lat: 30.6630,
    lng: 104.0310,
  ),
  PlaceModel(
    id: '28',
    name: 'People\'s Park',
    profileImage: '$_places/peoples_park.jpg',
    carouselImages: ['$_places/peoples_park.jpg'],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'garden',
    cityName: 'Chengdu',
    rate: 4.3,
    totalRates: 8900,
    description:
        'People\'s Park is Chengdu\'s most famous public park, where locals gather for tea, '
        'dancing, and leisure. It offers a genuine glimpse into Chengdu\'s relaxed lifestyle '
        'with its traditional tea houses and lively atmosphere.',
    googleMapsLink: 'https://maps.google.com/?q=Peoples+Park+Chengdu',
    lat: 30.6590,
    lng: 104.0550,
  ),
  PlaceModel(
    id: '29',
    name: 'Huanglongxi Ancient Town',
    profileImage: '$_places/huanglongxi.jpg',
    carouselImages: ['$_places/huanglongxi.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.4,
    totalRates: 4800,
    description:
        'Huanglongxi Ancient Town is a well-preserved water town near Chengdu, featuring '
        'Ming and Qing dynasty architecture, winding stone streets, and ancient banyan trees '
        'along scenic canals.',
    googleMapsLink: 'https://maps.google.com/?q=Huanglongxi+Ancient+Town',
    lat: 30.3200,
    lng: 103.9700,
  ),
  PlaceModel(
    id: '30',
    name: 'Sanxingdui Museum',
    profileImage: '$_places/sanxingdui.jpg',
    carouselImages: ['$_places/sanxingdui.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'museum',
    cityName: 'Guanghan',
    rate: 4.7,
    totalRates: 7400,
    description:
        'Sanxingdui Museum displays the mysterious Bronze Age artifacts from the Shu kingdom, '
        'including huge bronze masks and a golden sun tree. These 3,000-year-old treasures '
        'are one of China\'s greatest archaeological discoveries.',
    googleMapsLink: 'https://maps.google.com/?q=Sanxingdui+Museum+Guanghan',
    lat: 30.9930,
    lng: 104.2000,
  ),
  PlaceModel(
    id: '31',
    name: 'Xiling Snow Mountain',
    profileImage: '$_places/xiling.jpg',
    carouselImages: ['$_places/xiling.jpg'],
    tourismType: 'Natural Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.6,
    totalRates: 5100,
    description:
        'Xiling Snow Mountain is a scenic ski resort and nature park located 95km from Chengdu. '
        'In winter it offers skiing, and in summer it provides cool mountain escapes with '
        'stunning alpine meadows and forests.',
    googleMapsLink: 'https://maps.google.com/?q=Xiling+Snow+Mountain+Chengdu',
    lat: 30.6200,
    lng: 103.2300,
  ),
  PlaceModel(
    id: '32',
    name: 'Luodai Ancient Town',
    profileImage: '$_places/luodai.jpg',
    carouselImages: ['$_places/luodai.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.3,
    totalRates: 3600,
    description:
        'Luodai Ancient Town is famous for its unique Hakka culture and architecture. '
        'The town features well-preserved Hakka buildings, ancient temples, and a lively '
        'street market selling local snacks.',
    googleMapsLink: 'https://maps.google.com/?q=Luodai+Ancient+Town+Chengdu',
    lat: 30.6300,
    lng: 104.2900,
  ),
  PlaceModel(
    id: '33',
    name: 'Anren Ancient Town',
    profileImage: '$_places/anren.jpg',
    carouselImages: ['$_places/anren.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.4,
    totalRates: 3200,
    description:
        'Anren Ancient Town is known for its cluster of historic mansions from the late Qing '
        'and Republican periods. It also houses the Jianchuan Museum Cluster, China\'s largest '
        'private museum group.',
    googleMapsLink: 'https://maps.google.com/?q=Anren+Ancient+Town+Chengdu',
    lat: 30.5100,
    lng: 103.6200,
  ),
  PlaceModel(
    id: '34',
    name: 'Bifengxia Panda Base',
    profileImage: '$_places/bifengxia.jpg',
    carouselImages: ['$_places/bifengxia.jpg'],
    tourismType: 'Entertainment and Modern Attractions',
    category: 'zoo',
    cityName: 'Ya\'an',
    rate: 4.6,
    totalRates: 5800,
    description:
        'Bifengxia Panda Base is a giant panda research center set in a lush valley. '
        'It offers a more natural environment than Chengdu\'s base, with opportunities '
        'to see pandas of all ages in spacious enclosures.',
    googleMapsLink: 'https://maps.google.com/?q=Bifengxia+Panda+Base+Yaan',
    lat: 30.0800,
    lng: 103.0000,
  ),
  PlaceModel(
    id: '35',
    name: 'Chengdu Museum',
    profileImage: '$_places/chengdu_museum.jpg',
    carouselImages: ['$_places/chengdu_museum.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'museum',
    cityName: 'Chengdu',
    rate: 4.5,
    totalRates: 4200,
    description:
        'Chengdu Museum showcases the rich history of Chengdu from prehistoric times '
        'to the modern era. Its extensive collection includes ancient artifacts, '
        'cultural relics, and interactive exhibits about Shu civilization.',
    googleMapsLink: 'https://maps.google.com/?q=Chengdu+Museum',
    lat: 30.6590,
    lng: 104.0600,
  ),
  PlaceModel(
    id: '36',
    name: 'Wangjiang Tower Park',
    profileImage: '$_places/wangjiang.jpg',
    carouselImages: ['$_places/wangjiang.jpg'],
    tourismType: 'Cultural and Historical Attractions',
    category: 'historical site',
    cityName: 'Chengdu',
    rate: 4.3,
    totalRates: 3100,
    description:
        'Wangjiang Tower Park is a scenic riverside park named after its iconic tower '
        'dedicated to the Tang dynasty poetess Xue Tao. The park features bamboo groves, '
        'traditional pavilions, and a tranquil atmosphere.',
    googleMapsLink: 'https://maps.google.com/?q=Wangjiang+Tower+Park+Chengdu',
    lat: 30.6430,
    lng: 104.0880,
  ),
];


// ============ Mock User ============

final EgyptopiaUser mockUser = EgyptopiaUser(
  id: 'mock-user-001',
  name: 'Zhang Wei',
  email: 'zhangwei@example.com',
  country: 'China',
  dateOfBirth: '1998-05-15',
  gender: 'male',
  profileImg: null,
  preferredCategories: ['museum', 'historical site', 'palace'],
  preferredTourismTypes: [
    'Cultural and Historical Attractions',
    'Natural Attractions',
  ],
  preferredCities: ['Beijing', 'Shanghai', "Xi'an"],
);

// ============ Mock Itinerary Helpers ============

/// Returns a subset of places for the itinerary plan, filtered by city and tourism type.
Map<int, List<PlaceModel>> getMockItineraryPlan(
  int noOfDays, {
  String? city,
  List<String>? tourismTypes,
}) {
  // Build prioritized tiers
  var tier1 = List<PlaceModel>.from(mockPlaces); // city + type match
  var tier2 = List<PlaceModel>.from(mockPlaces); // city match only
  var tier3 = List<PlaceModel>.from(mockPlaces); // all places (fallback)

  if (city != null && city.isNotEmpty) {
    tier1 = tier1.where((p) => p.cityName == city).toList();
    tier2 = tier2.where((p) => p.cityName == city).toList();
    tier3 = List<PlaceModel>.from(mockPlaces);
  }

  if (tourismTypes != null && tourismTypes.isNotEmpty) {
    final lowerTypes = tourismTypes.map((t) => t.toLowerCase()).toSet();
    tier1 = tier1
        .where((p) => lowerTypes.contains(p.tourismType.toLowerCase()))
        .toList();
  }

  // If tier1 empty, fall back to tier2 for the preferred list
  // If tier2 empty too, use tier3
  var preferred = tier1.isNotEmpty ? tier1 : (tier2.isNotEmpty ? tier2 : tier3);
  final fallback = tier2.isNotEmpty ? tier2 : tier3;

  final usedIds = <String>{};
  final plan = <int, List<PlaceModel>>{};

  PlaceModel _pickNext() {
    // Try preferred tier first
    for (final list in [preferred, fallback, mockPlaces]) {
      final available = list.where((p) => !usedIds.contains(p.id)).toList();
      if (available.isNotEmpty) {
        usedIds.add(available.first.id);
        return available.first;
      }
    }
    // All places used — reset and reuse (shouldn't normally happen)
    usedIds.clear();
    final first = preferred.isNotEmpty ? preferred.first : mockPlaces.first;
    usedIds.add(first.id);
    return first;
  }

  for (int day = 1; day <= noOfDays; day++) {
    plan[day] = [_pickNext(), _pickNext()];
  }

  return plan;
}

/// Chinese descriptions for mock places, keyed by place ID.
final Map<String, String> placeDescriptionsZh = {
  '1': '中国长城是世界最著名的奇迹之一，全长超过13,000英里。'
      '历经多个朝代修建，它提供了令人叹为观止的景色，让人一窥中国古代历史。',
  '2': '故宫是中国明清两代的皇家宫殿。'
      '它收藏了超过100万件文物，是世界上最大的宫殿建筑群。',
  '3': '外滩是上海标志性的滨江长廊，两旁排列着殖民时期的建筑'
      '和现代摩天大楼。可以欣赏到黄浦江和浦东天际线的壮观景色。',
  '4': '乐山大佛是一尊高达71米的石雕佛像，雕刻在悬崖峭壁上。'
      '建于唐代，是世界上最大的石刻佛像。',
  '5': '张家界国家森林公园以其高耸的砂岩柱而闻名，'
      '这些石柱曾是电影《阿凡达》中悬浮山的灵感来源。这里有绝佳的徒步路线和玻璃桥。',
  '6': '兵马俑是成千上万等身大小的陶俑，与秦始皇一同埋葬。'
      '于1974年被发现，被誉为世界第八大奇迹。',
  '7': '西湖是杭州的一处联合国教科文组织世界遗产，以其自然美景'
      '和历史悠久的宝塔而闻名。数百年来一直激发着诗人和艺术家的灵感。',
  '8': '拉萨的布达拉宫曾是达赖喇嘛的冬季宫殿。'
      '这座令人惊叹的13层宫殿拥有超过1,000个房间，装饰着精美的藏传佛教艺术品。',
  '9': '从桂林到阳朔的漓江游船展现了中国最壮观的景色，'
      '翠绿的江面倒映着奇特的喀斯特山峰。',
  '10': '颐和园是北京一处集湖泊、园林和宫殿于一体的宏伟建筑群。'
      '它曾是皇家避暑胜地，是中国园林设计的杰作。',
  '11': '上海迪士尼乐园是世界级主题公园，拥有融合迪士尼魔法'
      '与中国文化的独特景点，包括奇幻童话城堡。',
  '12': '成都大熊猫繁育研究基地让游客在自然环境中近距离观赏大熊猫。'
      '它是中国最受欢迎的野生动物景点之一。',
  '13': '少林寺是禅宗佛教和少林功夫的发源地。'
      '位于嵩山，吸引着来自世界各地的武术爱好者。',
  '14': '黄山以其壮丽的花岗岩山峰、温泉和云海而闻名。'
      '它是中国最著名的风景区之一。',
  '15': '莫高窟是联合国教科文组织世界遗产，拥有数百个佛教石窟寺，'
      '内有精美的壁画和雕塑，跨越一千多年。',
  '16': '维多利亚港是香港的主要景点，以其壮丽的天际线'
      '和幻彩咏香江灯光秀而闻名。天星小轮提供经典的海港渡轮体验。',
  '17': '锦里古街是成都一条热闹的步行街，再现了清代的建筑风格。'
      '这里提供传统小吃、手工艺品和民间表演，氛围热闹非凡。',
  '18': '武侯祠是为纪念三国时期著名战略家诸葛亮而建的祠堂。'
      '宁静的庭院内有精美的建筑、古代碑刻和雕像。',
  '19': '青城山是道教的发源地之一，以苍翠的森林、'
      '古老的道观和幽静的山间小道而闻名。是远离城市喧嚣、亲近自然的绝佳去处。',
  '20': '都江堰水利工程建于2200多年前，是中国古代工程的奇迹，'
      '至今仍在灌溉成都平原。被联合国教科文组织列为世界遗产。',
  '21': '峨眉山是中国四大佛教名山之一，拥有令人叹为观止的风景、'
      '古刹和著名的金顶。可欣赏壮观的日出，还能见到野生猴子。',
  '22': '宽窄巷子由三条平行巷道组成——宽巷子、窄巷子和井巷子——'
      '代表了成都的古代城市布局。完美融合了传统建筑、时尚咖啡馆和当地美食。',
  '23': '春熙路是成都首屈一指的商业区，是一条充满活力的步行街，'
      '两旁林立着现代购物中心、奢侈品牌店和无数品尝正宗川菜的餐厅。',
  '24': '川剧以其独特的变脸表演而闻名，表演者瞬间变换彩色面具。'
      '成都的川剧剧场提供融合音乐和木偶戏的难忘文化表演。',
  '25': '九寨沟是联合国教科文组织世界遗产，以碧蓝的湖泊、'
      '层叠的瀑布和雪峰而闻名。五彩斑斓的高山湖泊犹如散落在森林中的宝石。',
  '26': '四姑娘山以四座雄伟的山峰、高山草甸和原始的冰川湖泊而闻名。'
      '这里是徒步旅行者和摄影爱好者的天堂，被誉为"东方阿尔卑斯"。',
  '27': '杜甫草堂是为纪念中国伟大诗人杜甫而建的祠宇。'
      '园内清幽雅致，传统建筑再现了诗人的故居风貌，展示了他的文学成就。',
  '28': '人民公园是成都最著名的公共园林，当地人来此喝茶、跳舞、休闲。'
      '传统的茶馆和热闹的氛围让人真实感受到成都的悠闲生活方式。',
  '29': '黄龙溪古镇是成都附近保存完好的水乡古镇，'
      '拥有明清建筑、蜿蜒的石板路和河岸旁的古榕树。',
  '30': '三星堆博物馆展示了古蜀王国神秘的青铜器文物，'
      '包括巨大的青铜面具和青铜神树。这些3000年前的宝藏是中国最伟大的考古发现之一。',
  '31': '西岭雪山是距离成都95公里的滑雪胜地和自然风景区。'
      '冬季可滑雪，夏季可避暑，拥有令人惊叹的高山草甸和森林。',
  '32': '洛带古镇以独特的客家文化和建筑而闻名。'
      '镇内保存完好的客家建筑、古庙和热闹的集市是感受客家文化的好去处。',
  '33': '安仁古镇以清末民初的公馆群落而闻名，'
      '还拥有建川博物馆聚落，是中国最大的私立博物馆群。',
  '34': '碧峰峡大熊猫基地是一个坐落于翠绿山谷中的大熊猫研究中心。'
      '这里环境更接近自然，可以在宽敞的园区内看到各个年龄段的大熊猫。',
  '35': '成都博物馆展示了成都从史前到现代的历史。'
      '丰富的馆藏包括古代文物、文化遗迹和关于古蜀文明的互动展览。',
  '36': '望江楼公园是为纪念唐代女诗人薛涛而建的河滨公园。'
      '园内翠竹成林，亭台楼阁古色古香，环境清幽宜人。',
};

// ============ Chinese Translations for Mock Data ============

/// Chinese place names keyed by place ID.
final Map<String, String> placeNamesZh = {
  '1': '长城',
  '2': '故宫',
  '3': '外滩',
  '4': '乐山大佛',
  '5': '张家界国家森林公园',
  '6': '兵马俑',
  '7': '西湖',
  '8': '布达拉宫',
  '9': '漓江',
  '10': '颐和园',
  '11': '上海迪士尼乐园',
  '12': '成都大熊猫基地',
  '13': '少林寺',
  '14': '黄山',
  '15': '莫高窟',
  '16': '维多利亚港',
  '17': '锦里古街',
  '18': '武侯祠',
  '19': '青城山',
  '20': '都江堰',
  '21': '峨眉山',
  '22': '宽窄巷子',
  '23': '春熙路',
  '24': '川剧剧场',
  '25': '九寨沟',
  '26': '四姑娘山',
  '27': '杜甫草堂',
  '28': '人民公园',
  '29': '黄龙溪古镇',
  '30': '三星堆博物馆',
  '31': '西岭雪山',
  '32': '洛带古镇',
  '33': '安仁古镇',
  '34': '碧峰峡大熊猫基地',
  '35': '成都博物馆',
  '36': '望江楼公园',
};

/// Chinese city names keyed by English name.
final Map<String, String> cityNamesZh = {
  'Beijing': '北京',
  'Shanghai': '上海',
  'Leshan': '乐山',
  'Zhangjiajie': '张家界',
  "Xi'an": '西安',
  'Hangzhou': '杭州',
  'Lhasa': '拉萨',
  'Guilin': '桂林',
  'Huangshan': '黄山',
  'Dunhuang': '敦煌',
  'Hong Kong': '香港',
  'Chengdu': '成都',
  'Zhengzhou': '郑州',
  'Yangshuo': '阳朔',
  'Emeishan': '峨眉山',
  'Jiuzhaigou': '九寨沟',
  'Xiaojin': '小金',
  'Guanghan': '广汉',
  "Ya'an": '雅安',
};

/// Chinese tourism types keyed by English value.
final Map<String, String> tourismTypesZh = {
  'Cultural and Historical Attractions': '文化与历史景点',
  'Natural Attractions': '自然景观',
  'Entertainment and Modern Attractions': '娱乐与现代景点',
  'Religious and Spiritual Attractions': '宗教与精神景点',
  'Medical Attractions': '医疗旅游',
};

/// Chinese category names keyed by English category value.
final Map<String, String> categoriesZh = {
  'library': '图书馆',
  'museum': '博物馆',
  'theater': '剧院',
  'garden': '园林',
  'fortress': '堡垒',
  'mosque': '清真寺',
  'tower': '塔',
  'palace': '宫殿',
  'tomb': '陵墓',
  'shopping': '购物',
  'zoo': '动物园',
  'synagogue': '犹太教堂',
  'historical site': '历史遗址',
  'temple': '寺庙',
  'aquarium': '水族馆',
  'church': '教堂',
};

// ============ Helper Functions ============

String localizedPlaceName(PlaceModel place, String lang) {
  if (lang == 'zh') return placeNamesZh[place.id] ?? place.name;
  return place.name;
}

String localizedCityName(String cityName, String lang) {
  if (lang == 'zh') return cityNamesZh[cityName] ?? cityName;
  return cityName;
}

String localizedTourismType(String tourismType, String lang) {
  if (lang == 'zh') return tourismTypesZh[tourismType] ?? tourismType;
  return tourismType;
}

String localizedCategory(String category, String lang) {
  if (lang == 'zh') return categoriesZh[category] ?? category;
  return category;
}

