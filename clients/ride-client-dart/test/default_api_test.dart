import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for DefaultApi
void main() {
  final instance = Openapi().getDefaultApi();

  group(DefaultApi, () {
    // Health check
    //
    //Future<HealthGet200Response> healthGet() async
    test('test healthGet', () async {
      // TODO
    });

    // Driver accepts ride
    //
    //Future<Ride> ridesIdAcceptPost(String id) async
    test('test ridesIdAcceptPost', () async {
      // TODO
    });

    // Complete the ride
    //
    //Future<Ride> ridesIdCompletePost(String id) async
    test('test ridesIdCompletePost', () async {
      // TODO
    });

    // Get ride by id
    //
    //Future<Ride> ridesIdGet(String id) async
    test('test ridesIdGet', () async {
      // TODO
    });

    // Start the ride
    //
    //Future<Ride> ridesIdStartPost(String id) async
    test('test ridesIdStartPost', () async {
      // TODO
    });

    // Create a new ride request
    //
    //Future<Ride> ridesPost(RideCreate rideCreate) async
    test('test ridesPost', () async {
      // TODO
    });

  });
}
