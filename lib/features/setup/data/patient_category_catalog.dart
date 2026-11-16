import '../../../core/theme/app_assets.dart';
import '../domain/models/patient_category.dart';

const patientCategories = <PatientCategory>[
  PatientCategory('needs', 'احتياجاتي', 'ماء، طعام، راحة', AppAssets.needs),
  PatientCategory(
    'health',
    'صحتي وألمي',
    'ألم، دواء، مساعدة',
    AppAssets.health,
  ),
  PatientCategory('feelings', 'مشاعري', 'فرح، حزن، قلق', AppAssets.emotions),
  PatientCategory(
    'composer',
    'تكوين جملة',
    'اكتب ما تريد قوله',
    AppAssets.sentence,
  ),
];
