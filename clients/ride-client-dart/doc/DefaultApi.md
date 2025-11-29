# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthGet**](DefaultApi.md#healthget) | **GET** /health | Health check
[**ridesIdAcceptPost**](DefaultApi.md#ridesidacceptpost) | **POST** /rides/{id}/accept | Driver accepts ride
[**ridesIdCompletePost**](DefaultApi.md#ridesidcompletepost) | **POST** /rides/{id}/complete | Complete the ride
[**ridesIdGet**](DefaultApi.md#ridesidget) | **GET** /rides/{id} | Get ride by id
[**ridesIdStartPost**](DefaultApi.md#ridesidstartpost) | **POST** /rides/{id}/start | Start the ride
[**ridesPost**](DefaultApi.md#ridespost) | **POST** /rides | Create a new ride request


# **healthGet**
> HealthGet200Response healthGet()

Health check

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();

try {
    final response = api.healthGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->healthGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthGet200Response**](HealthGet200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ridesIdAcceptPost**
> Ride ridesIdAcceptPost(id)

Driver accepts ride

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.ridesIdAcceptPost(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->ridesIdAcceptPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Ride**](Ride.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ridesIdCompletePost**
> Ride ridesIdCompletePost(id)

Complete the ride

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.ridesIdCompletePost(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->ridesIdCompletePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Ride**](Ride.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ridesIdGet**
> Ride ridesIdGet(id)

Get ride by id

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.ridesIdGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->ridesIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Ride**](Ride.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ridesIdStartPost**
> Ride ridesIdStartPost(id)

Start the ride

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.ridesIdStartPost(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->ridesIdStartPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Ride**](Ride.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ridesPost**
> Ride ridesPost(rideCreate)

Create a new ride request

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final RideCreate rideCreate = ; // RideCreate | 

try {
    final response = api.ridesPost(rideCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->ridesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rideCreate** | [**RideCreate**](RideCreate.md)|  | 

### Return type

[**Ride**](Ride.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

