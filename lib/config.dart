//config.dart
final baseUrl = 'http://localhost:3000/api';
final fileBaseUrl = 'http://localhost:3000';
final String bearerToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJmOGU3YTg2ZC0zZTczLTRiYjgtOWM4OC03Zjc4ZDhlODcxMTYiLCJsb2dpbiI6Ijc3NzUzNTEzMTMyIiwidXNlckdyb3VwIjoiYWRtaW4iLCJuYmYiOjE3NjUyMzc3MjUsImV4cCI6MTc2NTI0MTMyNSwiaWF0IjoxNzY1MjM3NzI1LCJpc3MiOiJxeXp5bG9yZGFzYyIsImF1ZCI6IndlYiJ9.K-eWiz_WbVKYgSdi5KFfM0t2gT7e4NDifhE8CLI83Bw';

final createmarket = '$baseUrl/market/create-market';
final getMarkets = '$baseUrl/market/markets';
final alltasks = '$baseUrl/tasks/all';
final createTaskUrl = '$baseUrl/tasks/create-task';
final sendCode = '$baseUrl/proxy/sendcode';
final login = '$baseUrl/proxy/login';
final refreshToken = '$baseUrl/proxy/refresh';
final profileUrl = '$baseUrl/proxy/profile';
final profilePhoto = '$baseUrl/proxy';

final workersUrl = '$baseUrl/user/workers';
final objectsUrl = '$baseUrl/object/objects';
final assignObjectsUrl = '$baseUrl/user/assignObjects';
final ensureUser = '$baseUrl/auth/ensureUser';
final productsUrl = '$baseUrl/products';
final tasksByPhoneUrl = '$baseUrl/tasks/by-phone';
final workerObjectsUrl = '$baseUrl/object/objects-of';
