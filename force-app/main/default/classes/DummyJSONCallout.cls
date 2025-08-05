/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {
    private static final String HTTP_GET    = 'GET';
    private static final String HTTP_POST   = 'POST';
    private static final String HTTP_PUT    = 'PUT';
    private static final String HTTP_PATCH  = 'PATCH';
    private static final String HTTP_DELETE = 'DELETE';
    
    private static final Integer TIMEOUT_MS = 10000;

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */

	public static void getDummyJSONUserFromId(String dummyUserId) {
        HTTPResponse response = makeCallout(HTTP_GET, 'callout:DummyJsonUser/' + dummyUserId, null, null);
        Integer statusCode = response.getStatusCode();
        if (statusCode >= 200 && statusCode < 300) {
            Contact cont = createContactFromJson(response.getBody());
            upsert cont DummyJSON_Id__c; //insert/update from the JSON response using the external id (dummyUserId)
        }
	}

    // private static HttpResponse sendRequest(String endpoint, String method) {
    //     HttpRequest request = new HttpRequest();
    //     request.setEndpoint(endpoint);
    //     request.setMethod(method);
    //     Http http = new Http();
    //     return http.send(request);
    // }

    public static HttpResponse makeCallout(
        String method,
        String endpoint,
        String payload,
        Map<String, String> additionalHeaders
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setTimeout(TIMEOUT_MS);
        req.setHeader('Content-Type', 'application/json');

        if (payload != null) {
            req.setBody(payload);
        }

        if (additionalHeaders != null) {
            for (String key : additionalHeaders.keySet()) {
                req.setHeader(key, additionalHeaders.get(key));
            }
        }

        try {
            Http http = new Http();
            HttpResponse response = http.send(req);

            Integer statusCode = response.getStatusCode();
            if (statusCode >= 200 && statusCode < 300) {
                return response;
            } else {
                System.debug('Callout failed. Status Code: ' + statusCode);
                System.debug('Response Body: ' + response.getBody());
                return response;
            }

        } catch (CalloutException ex) {
            System.debug('Callout Exception: ' + ex.getMessage());
            throw ex;
        }
    }

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible
	private static Contact createContactFromJson(String jsonResponse) {
        DummyJsonUser dummyJsonUser = (DummyJsonUser) JSON.deserialize(jsonResponse, DummyJsonUser.class);
        Contact cont = new Contact(
            FirstName = dummyJsonUser.firstName,
            LastName = dummyJsonUser.lastName,
            Email = dummyJsonUser.email,
            Phone = dummyJsonUser.phone,
            Birthdate = dummyJsonUser.birthDate,
            MailingStreet = dummyJsonUser.address.address,
            MailingCity = dummyJsonUser.address.city,
            MailingPostalCode = dummyJsonUser.address.postalCode,
            MailingState = dummyJsonUser.address.state,
            MailingCountry = dummyJsonUser.address.country,
            DummyJSON_Id__c = dummyJsonUser.id
        );

		return cont;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	public static void postCreateDummyJSONUser(String contactId) {
        String jsonPayload = generateDummyJsonUserPayload(contactId);
        HttpResponse response = makeCallout(HTTP_POST, 'callout:DummyJsonUser/add', jsonPayload, null);
        Integer statusCode = response.getStatusCode();
        if (statusCode >= 200 && statusCode < 300) {
            Contact cont = [SELECT Id, DummyJSON_Last_Updated__c FROM Contact WHERE Id = :contactId];
            cont.DummyJSON_Last_Updated__c = System.now();
            Update cont;
        }
	}

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible
	private static String generateDummyJsonUserPayload(String contactId) {
        Contact cont = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId];
        Map<String, Object> jsonMap = new Map<String, Object>{
            'salesforceId' => cont.Id != null ? cont.Id : 'Unknown',
            'firstName'  => cont.FirstName != null ? cont.FirstName : 'Unknown',
            'lastName' => cont.LastName != null ? cont.LastName : 'Unknown',
            'email' => cont.Email != null ? cont.Email : 'Unknown',
            'phone' => cont.Phone != null ? cont.Phone : 'Unknown'
        };
		return JSON.serialize(jsonMap);
	}
}