import ballerina/io;
import ballerina/grpc;

public function main() returns error? {
    io:println("=== Rental Accommodation gRPC Client Demo ===");

    RentalServiceClient rentalClient = check new ("http://localhost:9090");

    // ---- 1. ADD PROPERTIES ----
    io:println("\n--- 1. ADD PROPERTY ---");

    AddPropertyResponse addResp1 = check rentalClient->addProperty({
        property_name: "Luxury Beach House",
        location: "Cape Town",
        property_type: "House",
        price_per_night: 2500.00,
        status: "Available",
        host_id: "host-001"
    });
    io:println("Added: " + addResp1.property_id + " - " + addResp1.message);

    AddPropertyResponse addResp2 = check rentalClient->addProperty({
        property_name: "Mountain View Cabin",
        location: "Stellenbosch",
        property_type: "Cabin",
        price_per_night: 1800.00,
        status: "Available",
        host_id: "host-001"
    });
    io:println("Added: " + addResp2.property_id);

    AddPropertyResponse addResp3 = check rentalClient->addProperty({
        property_name: "City Center Apartment",
        location: "Johannesburg",
        property_type: "Apartment",
        price_per_night: 1200.00,
        status: "Available",
        host_id: "host-002"
    });
    io:println("Added: " + addResp3.property_id);

    // ---- 2. CREATE USERS (Client Streaming) ----
    io:println("\n--- 2. CREATE USERS (Client Streaming) ---");

    CreateUsersStreamingClient streamingClient = check rentalClient->createUsers();

    UserProfile[] users = [
        { user_id: "user-001", username: "JohnHost", email: "john@example.com", role: "Host" },
        { user_id: "user-002", username: "SarahGuest", email: "sarah@example.com", role: "Guest" },
        { user_id: "user-003", username: "MikeGuest", email: "mike@example.com", role: "Guest" }
    ];

    foreach var u in users {
        check streamingClient->sendUserProfile(u);
        io:println("Streamed: " + u.username);
    }

    CreateUsersResponse|grpc:Error? createUsersResp = streamingClient->receiveCreateUsersResponse();
    if createUsersResp is CreateUsersResponse {
        io:println("Server: " + createUsersResp.message);
    } else if createUsersResp is grpc:Error {
        io:println("Error receiving response: " + createUsersResp.message());
    } else {
        io:println("No response received from server.");
    }

    // ---- 3. UPDATE PROPERTY ----
    io:println("\n--- 3. UPDATE PROPERTY ---");

    UpdatePropertyResponse updatedProp = check rentalClient->updateProperty({
        property_id: addResp1.property_id,
        host_id: "host-001",
        property_name: (),
        location: (),
        property_type: (),
        price_per_night: 2800.00,
        status: ()
    });
    io:println("Updated: " + updatedProp.property.property_name + " - R" + updatedProp.property.price_per_night.toString());

    // ---- 4. LIST PROPERTIES (Server Streaming) ----
    io:println("\n--- 4. LIST AVAILABLE PROPERTIES (Server Streaming) ---");

    stream<RentalProperty, grpc:Error?> listStream = check rentalClient->listAvailableProperties({
        location: "Cape Town",
        min_price: 0.00,
        max_price: 3000.00
    });

    int count = 0;
    error? listErr = from RentalProperty prop in listStream
        do {
            count += 1;
            io:println("  " + count.toString() + ". " + prop.property_name +
                       " - R" + prop.price_per_night.toString());
        };

    io:println("Total streamed: " + count.toString());

    // ---- 5. SEARCH PROPERTY ----
    io:println("\n--- 5. SEARCH PROPERTY ---");

    SearchPropertyResponse searchResp = check rentalClient->searchProperty({
        property_id: addResp1.property_id
    });

    if searchResp.found {
        RentalProperty? foundProp = searchResp.property;
        if foundProp is RentalProperty {
            io:println("Found: " + foundProp.property_name);
        }
    }

    SearchPropertyResponse notFound = check rentalClient->searchProperty({
        property_id: "PROP-999"
    });
    io:println("PROP-999: " + notFound.message);

    // ---- 6. BOOK PROPERTY ----
    io:println("\n--- 6. BOOK PROPERTY ---");

    BookPropertyResponse bookResp = check rentalClient->bookProperty({
        guest_id: "user-002",
        property_id: addResp1.property_id,
        check_in_date: "2026-09-10",
        check_out_date: "2026-09-15"
    });
    io:println("Booking ref: " + bookResp.booking_ref);
    io:println("Estimated: R" + bookResp.estimated_total.toString());

    // ---- 7. CONFIRM BOOKING ----
    io:println("\n--- 7. CONFIRM BOOKING ---");

    ConfirmBookingResponse confirmResp = check rentalClient->confirmBooking({
        guest_id: "user-002",
        booking_ref: bookResp.booking_ref
    });
    io:println("Confirmed: " + confirmResp.booking_id);
    io:println("Total: R" + confirmResp.total_cost.toString());
    io:println("Nights: " + confirmResp.number_of_nights.toString());

    // ---- 8. OVERLAP TEST ----
    io:println("\n--- 8. OVERLAP TEST (Should Fail) ---");

    BookPropertyResponse overlapBook = check rentalClient->bookProperty({
        guest_id: "user-003",
        property_id: addResp1.property_id,
        check_in_date: "2026-09-12",
        check_out_date: "2026-09-18"
    });

    ConfirmBookingResponse|grpc:Error overlapResult =
        rentalClient->confirmBooking({
            guest_id: "user-003",
            booking_ref: overlapBook.booking_ref
        });

    if overlapResult is grpc:Error {
        io:println("Correctly rejected: " + overlapResult.message());
    } else {
        io:println("Should have been rejected!");
    }

    // ---- 9. REMOVE PROPERTY ----
    io:println("\n--- 9. REMOVE PROPERTY ---");

    RemovePropertyResponse removeResp = check rentalClient->removeProperty({
        property_id: addResp2.property_id,
        host_id: "host-001"
    });
    io:println(removeResp.message);

    io:println("\n=== Demo Complete ===");
}