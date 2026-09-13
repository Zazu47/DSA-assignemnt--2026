import ballerina/grpc;
import ballerina/io;
import rental_client.rental;

public function main() returns error? {
    rental:RentalServiceClient rentalClient = check new ("https://localhost:9090", secureSocket = {
    cert: "./server-public.crt"
});
    string loggedInUserId = "";

    while true {
        string status = loggedInUserId == "" ? "Not logged in" : "Logged in as: " + loggedInUserId;
        io:println("\n=== Rental System Client (" + status + ") ===");
        io:println("1. Add property (Host)");
        io:println("2. Update property (Host)");
        io:println("3. Remove property (Host)");
        io:println("4. Search property (anyone)");
        io:println("5. List available properties (anyone)");
        io:println("6. Create users (anyone - sign up)");
        io:println("7. Book property (Guest)");
        io:println("8. Confirm booking (Host)");
        io:println("9. Log in as user");
        io:println("0. Exit");
        string choice = io:readln("Choose an option: ");

        match choice {
            "1" => {
                check addPropertyFlow(rentalClient, loggedInUserId);
            }
            "2" => {
                check updatePropertyFlow(rentalClient, loggedInUserId);
            }
            "3" => {
                check removePropertyFlow(rentalClient, loggedInUserId);
            }
            "4" => {
                check searchPropertyFlow(rentalClient);
            }
            "5" => {
                check listPropertiesFlow(rentalClient);
            }
            "6" => {
                check createUsersFlow(rentalClient);
            }
            "7" => {
                check bookPropertyFlow(rentalClient, loggedInUserId);
            }
            "8" => {
                check confirmBookingFlow(rentalClient, loggedInUserId);
            }
            "9" => {
                loggedInUserId = io:readln("Enter your user_id: ");
            }
            "0" => {
                io:println("Goodbye!");
                return;
            }
            _ => {
                io:println("Invalid option, try again.");
            }
        }

        if choice != "0" {
            _ = io:readln("\nPress Enter to return to menu...");
        }
    }
}

function addPropertyFlow(rental:RentalServiceClient rentalClient, string loggedInUserId) returns error? {
    if loggedInUserId == "" {
        io:println("You must log in first (option 9).");
        return;
    }

    string name = io:readln("Property name: ");
    string location = io:readln("Location: ");
    string propertyType = io:readln("Property type: ");
    string priceStr = io:readln("Price per night: ");
    float price = check float:fromString(priceStr);

    rental:NewPropertyRequest req = {
        host_id: loggedInUserId,
        name: name,
        location: location,
        property_type: propertyType,
        price_per_night: price,
        status: rental:AVAILABLE
    };

    rental:ContextNewPropertyRequest ctxReq = {
        content: req,
        headers: {"user_id": loggedInUserId}
    };

    rental:ContextProperty|grpc:Error result = rentalClient->add_propertyContext(ctxReq);
    if result is grpc:Error {
        io:println("Error: ", result.message());
        return;
    }
    io:println("Created property_id: ", result.content.property_id);
}

function updatePropertyFlow(rental:RentalServiceClient rentalClient, string loggedInUserId) returns error? {
    if loggedInUserId == "" {
        io:println("You must log in first (option 9).");
        return;
    }

    string propertyId = io:readln("Property id to update: ");
    string priceStr = io:readln("New price (leave blank to skip): ");

    rental:UpdatePropertyRequest req = {property_id: propertyId};
    if priceStr.trim() != "" {
        req.price_per_night = check float:fromString(priceStr);
    }

    rental:ContextUpdatePropertyRequest ctxReq = {
        content: req,
        headers: {"user_id": loggedInUserId}
    };

    rental:ContextProperty|grpc:Error result = rentalClient->update_propertyContext(ctxReq);
    if result is grpc:Error {
        io:println("Error: ", result.message());
        return;
    }
    io:println("Updated. New price: ", result.content.price_per_night);
}

function removePropertyFlow(rental:RentalServiceClient rentalClient, string loggedInUserId) returns error? {
    if loggedInUserId == "" {
        io:println("You must log in first (option 9).");
        return;
    }

    string propertyId = io:readln("Property id to remove: ");
    rental:RemovePropertyRequest req = {property_id: propertyId};

    rental:ContextRemovePropertyRequest ctxReq = {
        content: req,
        headers: {"user_id": loggedInUserId}
    };

    rental:ContextRemovePropertyResponse|grpc:Error result = rentalClient->remove_propertyContext(ctxReq);
    if result is grpc:Error {
        io:println("Error: ", result.message());
        return;
    }
    io:println("Removed. Host's remaining properties: ", result.content.properties.length());
}

function searchPropertyFlow(rental:RentalServiceClient rentalClient) returns error? {
    string propertyId = io:readln("Property id to search: ");
    rental:SearchPropertyRequest req = {property_id: propertyId};
    rental:SearchPropertyResponse resp = check rentalClient->search_property(req);
    io:println("Found: ", resp.found, " - ", resp.message);
}

function listPropertiesFlow(rental:RentalServiceClient rentalClient) returns error? {
    string location = io:readln("Filter by location (leave blank for none): ");

    rental:ListPropertiesRequest req = {};
    if location.trim() != "" {
        req.location = location;
    }

    stream<rental:Property, error?> propStream = check rentalClient->list_available_properties(req);
    io:println("Available properties:");
    check propStream.forEach(function(rental:Property p) {
        io:println(" - ", p.property_id, " | ", p.name, " | ", p.location, " | $", p.price_per_night);
    });
}

function createUsersFlow(rental:RentalServiceClient rentalClient) returns error? {
    string countStr = io:readln("How many users to create? ");
    int count = check int:fromString(countStr);

    rental:Create_usersStreamingClient userStream = check rentalClient->create_users();

    int i = 0;
    while i < count {
        string name = io:readln("  User " + (i + 1).toString() + " name: ");
        string email = io:readln("  Email: ");
        string roleStr = io:readln("  Role (HOST/GUEST): ");
        rental:UserRole role = roleStr.toUpperAscii() == "HOST" ? rental:HOST : rental:GUEST;

        check userStream->sendNewUserRequest({name: name, email: email, role: role});
        i += 1;
    }

    check userStream->complete();
    rental:CreateUsersResponse? resp = check userStream->receiveCreateUsersResponse();
    if resp is rental:CreateUsersResponse {
        io:println(resp.message);
        foreach rental:User u in resp.users {
            io:println(" - ", u.role, " ", u.name, " -> user_id: ", u.user_id, " (save this to log in)");
        }
    }
}

function bookPropertyFlow(rental:RentalServiceClient rentalClient, string loggedInUserId) returns error? {
    if loggedInUserId == "" {
        io:println("You must log in first (option 9).");
        return;
    }

    string propertyId = io:readln("Property id to book: ");
    string checkIn = io:readln("Check-in date (YYYY-MM-DD): ");
    string checkOut = io:readln("Check-out date (YYYY-MM-DD): ");

    rental:BookPropertyRequest req = {
        property_id: propertyId,
        guest_id: loggedInUserId,
        check_in_date: checkIn,
        check_out_date: checkOut
    };

    rental:ContextBookPropertyRequest ctxReq = {
        content: req,
        headers: {"user_id": loggedInUserId}
    };

    rental:ContextBookPropertyResponse|grpc:Error result = rentalClient->book_propertyContext(ctxReq);
    if result is grpc:Error {
        io:println("Error: ", result.message());
        return;
    }
    io:println("Accepted: ", result.content.accepted, " - ", result.content.message);
    if result.content?.request_id is string {
        io:println("request_id: ", <string>result.content?.request_id);
    }
}

function confirmBookingFlow(rental:RentalServiceClient rentalClient, string loggedInUserId) returns error? {
    if loggedInUserId == "" {
        io:println("You must log in first (option 9).");
        return;
    }

    string requestId = io:readln("Request id to confirm: ");

    rental:ConfirmBookingRequest req = {request_id: requestId, host_id: loggedInUserId};

    rental:ContextConfirmBookingRequest ctxReq = {
        content: req,
        headers: {"user_id": loggedInUserId}
    };

    rental:ContextConfirmBookingResponse|grpc:Error result = rentalClient->confirm_bookingContext(ctxReq);
    if result is grpc:Error {
        io:println("Error: ", result.message());
        return;
    }
    io:println("Success: ", result.content.success, " - ", result.content.message);
    if result.content?.booking is rental:Booking {
        rental:Booking b = <rental:Booking>result.content?.booking;
        io:println("Total cost: ", b.total_cost);
    }
}