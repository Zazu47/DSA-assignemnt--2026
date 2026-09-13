import ballerina/grpc;
import ballerina/time;
import ballerina/uuid;
import rental_system.rental;

// Shared, persistent state — declared outside the service block so every
// incoming call reads/writes the SAME data, rather than starting fresh each time.
map<rental:Property> properties = {};
map<rental:User> users = {};
map<rental:BookingRequest> pendingBookings = {};
map<rental:Booking> confirmedBookings = {};

const int BOOKING_EXPIRY_SECONDS = 900; // 15 minutes

// Removes any pending booking request older than BOOKING_EXPIRY_SECONDS.
// Called lazily whenever booking-related activity happens — no background
// task needed, since the cart is checked whenever it actually matters.
function cleanupExpiredBookings() {
    time:Utc now = time:utcNow();
    int nowSeconds = now[0];

    string[] expiredIds = [];
    foreach rental:BookingRequest br in pendingBookings {
        if (nowSeconds - br.created_at) > BOOKING_EXPIRY_SECONDS {
            expiredIds.push(br.request_id);
        }
    }
    foreach string id in expiredIds {
        _ = pendingBookings.remove(id);
    }
}

// Reads the "user_id" header (the caller's credential, issued by create_users),
// looks up who that ACTUALLY is in the users map (never trusts the request body),
// and rejects if that person doesn't hold the required role.
function authenticate(map<string|string[]> headers, rental:UserRole requiredRole) returns rental:User|error {
    string callerId = check grpc:getHeader(headers, "user_id");

    if !users.hasKey(callerId) {
        return error("Not authenticated: unknown user_id");
    }

    rental:User caller = users.get(callerId);
    if caller.role != requiredRole {
        return error("Access denied: this operation requires role " + requiredRole.toString());
    }

    return caller;
}

listener grpc:Listener rentalListener = new (9090, secureSocket = {
    key: {
        path: "./server.p12",
        password: "ballerina"
    }
});

@grpc:ServiceDescriptor {descriptor: rental:RENTAL_DESC}
service "RentalService" on rentalListener {

    remote function add_property(rental:ContextNewPropertyRequest ctxReq) returns rental:Property|error {
        rental:User caller = check authenticate(ctxReq.headers, rental:HOST);
        rental:NewPropertyRequest req = ctxReq.content;

        if req.host_id != caller.user_id {
            return error("host_id in request must match your authenticated identity");
        }

        if req.name.trim() == "" {
            return error("Property name cannot be empty");
        }
        if req.location.trim() == "" {
            return error("Location cannot be empty");
        }
        if req.price_per_night <= 0.0 {
            return error("Price per night must be greater than zero");
        }

        string newId = uuid:createType4AsString();

        rental:Property newProperty = {
            property_id: newId,
            host_id: req.host_id,
            name: req.name,
            location: req.location,
            property_type: req.property_type,
            price_per_night: req.price_per_night,
            status: req.status
        };

        properties[newId] = newProperty;
        return newProperty;
    }

    remote function update_property(rental:ContextUpdatePropertyRequest ctxReq) returns rental:Property|error {
        rental:User caller = check authenticate(ctxReq.headers, rental:HOST);
        rental:UpdatePropertyRequest req = ctxReq.content;

        if !properties.hasKey(req.property_id) {
            return error("Property not found: " + req.property_id);
        }

        rental:Property existing = properties.get(req.property_id);

        if existing.host_id != caller.user_id {
            return error("You do not own this property");
        }

        float? priceCheck = req?.price_per_night;
        if priceCheck is float && priceCheck <= 0.0 {
            return error("Price per night must be greater than zero");
        }
        string? nameCheck = req?.name;
        if nameCheck is string && nameCheck.trim() == "" {
            return error("Property name cannot be empty");
        }

        string? name = req?.name;
        if name is string {
            existing.name = name;
        }
        string? location = req?.location;
        if location is string {
            existing.location = location;
        }
        string? propertyType = req?.property_type;
        if propertyType is string {
            existing.property_type = propertyType;
        }
        float? price = req?.price_per_night;
        if price is float {
            existing.price_per_night = price;
        }
        rental:PropertyStatus? status = req?.status;
        if status is rental:PropertyStatus {
            existing.status = status;
        }

        properties[req.property_id] = existing;
        return existing;
    }

    remote function remove_property(rental:ContextRemovePropertyRequest ctxReq) returns rental:RemovePropertyResponse|error {
        rental:User caller = check authenticate(ctxReq.headers, rental:HOST);
        rental:RemovePropertyRequest req = ctxReq.content;

        if !properties.hasKey(req.property_id) {
            return error("Property not found: " + req.property_id);
        }

        rental:Property removed = properties.get(req.property_id);

        if removed.host_id != caller.user_id {
            return error("You do not own this property");
        }

        string hostId = removed.host_id;

        _ = properties.remove(req.property_id);

        rental:Property[] hostProperties = [];
        foreach rental:Property p in properties {
            if p.host_id == hostId {
                hostProperties.push(p);
            }
        }

        rental:RemovePropertyResponse response = {
            properties: hostProperties
        };
        return response;
    }

    remote function search_property(rental:SearchPropertyRequest req) returns rental:SearchPropertyResponse|error {
        if !properties.hasKey(req.property_id) {
            rental:SearchPropertyResponse notFound = {
                found: false,
                message: "Not Available"
            };
            return notFound;
        }

        rental:Property found = properties.get(req.property_id);
        rental:SearchPropertyResponse response = {
            found: true,
            property: found,
            message: "Property found"
        };
        return response;
    }

    remote function list_available_properties(rental:ListPropertiesRequest req)
            returns stream<rental:Property, error?>|error {

        string? location = req?.location;
        float? minPrice = req?.min_price;
        float? maxPrice = req?.max_price;

        rental:Property[] matches = [];
        foreach rental:Property p in properties {
            boolean matchesLocation = location is () || p.location == location;
            boolean matchesMin = minPrice is () || p.price_per_night >= minPrice;
            boolean matchesMax = maxPrice is () || p.price_per_night <= maxPrice;

            if p.status == rental:AVAILABLE && matchesLocation && matchesMin && matchesMax {
                matches.push(p);
            }
        }

        return matches.toStream();
    }

    remote function create_users(stream<rental:NewUserRequest, grpc:Error?> clientStream)
            returns rental:CreateUsersResponse|error {

        rental:User[] createdUsers = [];

        check from rental:NewUserRequest req in clientStream
            do {
                string newId = uuid:createType4AsString();
                rental:User newUser = {
                    user_id: newId,
                    name: req.name,
                    email: req.email,
                    role: req.role
                };
                users[newId] = newUser;
                createdUsers.push(newUser);
            };

        rental:CreateUsersResponse response = {
            users_created: createdUsers.length(),
            users: createdUsers,
            message: createdUsers.length().toString() + " users created successfully"
        };
        return response;
    }

    remote function book_property(rental:ContextBookPropertyRequest ctxReq) returns rental:BookPropertyResponse|error {
        rental:User caller = check authenticate(ctxReq.headers, rental:GUEST);
        rental:BookPropertyRequest req = ctxReq.content;

        cleanupExpiredBookings();

        if req.guest_id != caller.user_id {
            return error("guest_id in request must match your authenticated identity");
        }

        // 1. Does the property exist?
        if !properties.hasKey(req.property_id) {
            return error("Property not found: " + req.property_id);
        }

        // 2. Basic validation: valid date format, and end date after start date
        if !isValidDateFormat(req.check_in_date) || !isValidDateFormat(req.check_out_date) {
            rental:BookPropertyResponse badFormat = {
                accepted: false,
                message: "Dates must be in YYYY-MM-DD format"
            };
            return badFormat;
        }

        if req.check_out_date <= req.check_in_date {
            rental:BookPropertyResponse rejected = {
                accepted: false,
                message: "Check-out date must be after check-in date"
            };
            return rejected;
        }

        // 3. Early clash check against CONFIRMED bookings only
        foreach rental:Booking b in confirmedBookings {
            if b.property_id == req.property_id
                    && datesOverlap(req.check_in_date, req.check_out_date, b.check_in_date, b.check_out_date) {
                rental:BookPropertyResponse clash = {
                    accepted: false,
                    message: "Dates clash with an existing booking"
                };
                return clash;
            }
        }

        // 4. No conflicts found — add to the cart
        string newRequestId = uuid:createType4AsString();
        time:Utc bookedAt = time:utcNow();
        rental:BookingRequest pending = {
            request_id: newRequestId,
            property_id: req.property_id,
            guest_id: req.guest_id,
            check_in_date: req.check_in_date,
            check_out_date: req.check_out_date,
            created_at: bookedAt[0]
        };
        pendingBookings[newRequestId] = pending;

        rental:BookPropertyResponse accepted = {
            accepted: true,
            request_id: newRequestId,
            message: "Request added to cart"
        };
        return accepted;
    }

    remote function confirm_booking(rental:ContextConfirmBookingRequest ctxReq) returns rental:ConfirmBookingResponse|error {
        rental:User caller = check authenticate(ctxReq.headers, rental:HOST);
        rental:ConfirmBookingRequest req = ctxReq.content;

        cleanupExpiredBookings();

        if req.host_id != caller.user_id {
            return error("host_id in request must match your authenticated identity");
        }

        // 1. Does the pending request exist?
        if !pendingBookings.hasKey(req.request_id) {
            rental:ConfirmBookingResponse notFound = {
                success: false,
                message: "Booking request not found"
            };
            return notFound;
        }

        rental:BookingRequest pending = pendingBookings.get(req.request_id);
        rental:Property prop = properties.get(pending.property_id);

        // 2. Ownership check — is this actually the property's host?
        if prop.host_id != req.host_id {
            rental:ConfirmBookingResponse notOwner = {
                success: false,
                message: "Host does not own this property"
            };
            return notOwner;
        }

        // 3. Authoritative overlap re-check against CONFIRMED bookings
        foreach rental:Booking b in confirmedBookings {
            if b.property_id == pending.property_id
                    && datesOverlap(pending.check_in_date, pending.check_out_date, b.check_in_date, b.check_out_date) {
                rental:ConfirmBookingResponse clash = {
                    success: false,
                    message: "Dates no longer available"
                };
                return clash;
            }
        }

        // 4. Calculate cost, create the confirmed booking
        int nights = check calculateNights(pending.check_in_date, pending.check_out_date);
        float cost = prop.price_per_night * nights;

        string newBookingId = uuid:createType4AsString();
        rental:Booking confirmed = {
            booking_id: newBookingId,
            property_id: pending.property_id,
            guest_id: pending.guest_id,
            check_in_date: pending.check_in_date,
            check_out_date: pending.check_out_date,
            total_cost: cost
        };
        confirmedBookings[newBookingId] = confirmed;

        // 5. Remove from the cart — it's no longer pending
        _ = pendingBookings.remove(req.request_id);

        rental:ConfirmBookingResponse response = {
            success: true,
            booking: confirmed,
            message: "Booking confirmed"
        };
        return response;
    }
}

// =====================================================
// HELPER FUNCTIONS
// =====================================================

// Two date ranges overlap if one starts before the other ends,
// AND the other starts before the first ends.
// Works with plain string comparison because dates are stored in ISO
// format ("YYYY-MM-DD"), where alphabetical order matches chronological order.
function datesOverlap(string checkInA, string checkOutA, string checkInB, string checkOutB) returns boolean {
    return checkInA < checkOutB && checkInB < checkOutA;
}

// Checks a date string genuinely looks like "YYYY-MM-DD" before we ever try
// to parse or compare it — catches typos/garbage input with a clear message
// instead of letting calculateNights fail with a cryptic parse error later.
function isValidDateFormat(string date) returns boolean {
    if date.length() != 10 {
        return false;
    }
    if date.substring(4, 5) != "-" || date.substring(7, 8) != "-" {
        return false;
    }
    string year = date.substring(0, 4);
    string month = date.substring(5, 7);
    string day = date.substring(8, 10);
    int|error yearNum = int:fromString(year);
    int|error monthNum = int:fromString(month);
    int|error dayNum = int:fromString(day);
    if yearNum is error || monthNum is error || dayNum is error {
        return false;
    }
    if monthNum < 1 || monthNum > 12 {
        return false;
    }
    if dayNum < 1 || dayNum > 31 {
        return false;
    }
    return true;
}

// Converts two ISO date strings into a whole number of nights.
// NOTE: exact ballerina/time function names (civilFromString, utcFromCivil,
// utcDiffSeconds) can vary slightly by Ballerina version — verify against
// your installed version's docs/autocomplete if this doesn't compile as-is.
function calculateNights(string checkIn, string checkOut) returns int|error {
    time:Civil inDate = check time:civilFromString(checkIn + "T00:00:00.00Z");
    time:Civil outDate = check time:civilFromString(checkOut + "T00:00:00.00Z");

    time:Utc inUtc = check time:utcFromCivil(inDate);
    time:Utc outUtc = check time:utcFromCivil(outDate);

    decimal diffSeconds = time:utcDiffSeconds(outUtc, inUtc);
    int nights = <int>(diffSeconds / 86400);

    return nights;
}