//config.dart
final baseUrl = 'http://localhost:3000/api';
final fileBaseUrl = 'http://localhost:3000';
final String bearerToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI0N2E0YTE4Zi01ODlmLTRlZGYtYmRjYS1iYzA0NDg4Zjc4Y2UiLCJsb2dpbiI6Ijc3NzUzNTEzMTMyIiwidXNlckdyb3VwIjoiYWRtaW4iLCJuYmYiOjE3NjUyMDIzNDcsImV4cCI6MTc2NTIwNTk0NywiaWF0IjoxNzY1MjAyMzQ3LCJpc3MiOiJxeXp5bG9yZGFzYyIsImF1ZCI6IndlYiJ9.MWu_RfXmGGY5fQcymq1VsSLGshM6YqCwpjGreR0GvH0';

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
