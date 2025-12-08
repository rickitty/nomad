//config.dart
final baseUrl = 'http://localhost:3000/api';
final fileBaseUrl = 'http://localhost:3000';
final String bearerToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI3OTA3OGNjZC0yODlmLTQ4YTctOTU0My0yMDViNTllZGE5MTAiLCJsb2dpbiI6Ijc3NzUzNTEzMTMyIiwidXNlckdyb3VwIjoiYWRtaW4iLCJuYmYiOjE3NjUyMjM4NjYsImV4cCI6MTc2NTIyNzQ2NiwiaWF0IjoxNzY1MjIzODY2LCJpc3MiOiJxeXp5bG9yZGFzYyIsImF1ZCI6IndlYiJ9.6XIyRyHeHd2XcT9S0waMG7JA_ims0f1-2GU1OemEvHs';

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
