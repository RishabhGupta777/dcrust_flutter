class Program {
  final String code;
  final String name;

  const Program({required this.code, required this.name});
}

const Map<String, List<Program>> programsData = {
  "B.Tech.": [
    Program(code: '001', name: 'Computer Science and Engineering'),
    Program(code: '002', name: 'Electrical Engineering'),
    Program(code: '003', name: 'Electronics & Communication Engineering'),
    Program(code: '004', name: 'Mechanical Engineering'),
    Program(code: '005', name: 'Chemical Engineering'),
    Program(code: '007', name: 'Bio Medical Engineering'),
    Program(code: '008', name: 'Bio Technology'),
    Program(code: '009', name: 'Civil Engineering'),
    Program(code: '010', name: 'Information Technology'),
    Program(code: '011', name: 'Instrumentation & Control'),
    Program(code: '013', name: 'Electronics & Electrical Engineering (EEE)'),
    Program(code: '014', name: 'Aircraft Maintenance Engineering'),
    Program(code: '015', name: 'Automobile Engineering'),
    Program(code: '016', name: 'Aeronautical Engineering'),
    Program(code: '018', name: 'PLASTICS Engineering'),
    Program(code: '019', name: 'Agriculture Engineering'),
    Program(code: '020', name: 'Computer Science and Engineering (Data Science)'),
    Program(code: '021', name: 'Computer Science and Engineering (Artificial Intelligence and Machine Learning)'),
    Program(code: '022', name: 'Computer Science and Engineering (Internet of Thing and Cyber Security with Block Chain Technology)'),
    Program(code: '024', name: 'Aerospace Engineering (BBA)'),
  ],
  "Other UG Programs": [
    Program(code: '006', name: 'Bachelor of Architecture'),
    Program(code: '012', name: 'Bachelor of Architecture (Interior Designing)'),
    Program(code: '017', name: 'BID- Bachelor of Interior Designing'),
    Program(code: '031', name: 'Bachelor of Business Administration (BBA)'),
    Program(code: '032', name: 'Bachelor of Hotel Management (BHM)'),
    Program(code: '033', name: 'Bachelor of Hotel Management (BHM 4yrs)'),
    Program(code: '041', name: 'Bachelor of Computer Application (BCA)'),
    Program(code: '042', name: 'BCA/BCA (Hons./Hons. with Research)'),
    Program(code: '101', name: 'Bachelor of Education'),
    Program(code: '102', name: 'Bachelor of Physical Education'),
    Program(code: '104', name: 'Bachelor of Physical Education & Sports'),
    Program(code: '105', name: 'Bachelor of Education(Special Education - Mental Retardation)'),
    Program(code: '106', name: 'BACHELOR OF EDUCATION (Special Education - Hearing Impairment)'),
    Program(code: '107', name: 'B.Ed. Special Education (Intellectual Disability)'),
  ]
};
