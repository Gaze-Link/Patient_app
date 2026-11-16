import '../domain/models/communication_option.dart';

abstract final class CommunicationCatalog {
  static const defaultOptions = <CommunicationOption>[
    CommunicationOption(label: 'أحتاج مساعدة'),
    CommunicationOption(label: 'نعم'),
    CommunicationOption(label: 'لا'),
    CommunicationOption(label: 'أشعر بألم'),
    CommunicationOption(label: 'أنا مرتاح'),
    CommunicationOption(label: 'أريد أن أرتاح'),
  ];

  static const optionsByCategory = <String, List<CommunicationOption>>{
    'needs': [
      CommunicationOption(label: 'عايز أشرب'),
      CommunicationOption(label: 'عايز آكل'),
      CommunicationOption(label: 'عايز أغير وضعي'),
      CommunicationOption(label: 'عايز أرتاح'),
      CommunicationOption(label: 'عايز أغير المكان'),
      CommunicationOption(label: 'محتاج الحمّام'),
    ],
    'health': [
      CommunicationOption(label: 'عندي ألم'),
      CommunicationOption(label: 'الألم شديد'),
      CommunicationOption(label: 'محتاج دواء'),
      CommunicationOption(label: 'محتاج مساعدة طبية'),
      CommunicationOption(label: 'الألم هنا'),
      CommunicationOption(label: 'مش مرتاح'),
    ],
    'feelings': [
      CommunicationOption(label: 'أنا مبسوط'),
      CommunicationOption(label: 'أنا زعلان'),
      CommunicationOption(label: 'أنا قلقان'),
      CommunicationOption(label: 'أنا خايف'),
      CommunicationOption(label: 'أنا محتاج حد جنبي'),
      CommunicationOption(label: 'عايز أكون لوحدي'),
    ],
    'communication': [
      CommunicationOption(label: 'نعم'),
      CommunicationOption(label: 'لا'),
      CommunicationOption(label: 'أحتاج مساعدة'),
      CommunicationOption(label: 'أنا بتألم'),
      CommunicationOption(label: 'نادِ المرافق'),
      CommunicationOption(label: 'أحتاج راحة'),
    ],
  };
}
