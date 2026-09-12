import ballerina/grpc;
import ballerina/time;
import ballerina/log;
import ministry_tourism/rental_server.rental;

// ============ DATA STORE ============

final map<rental:RentalProperty> propertyStore = {};
final map<BookingCart> bookingCart = {};
final map<string[]> guestBookings = {};
int nextPropertyId = 1;
int nextBookingRef = 1;

// ============ INTERNAL RECORD TYPES ============

public type BookingCart record {|
    string guestId;
    string propertyId;
    string checkInDate;
    string checkOutDate;
    float estimatedTotal;
    string bookingRef;
|};

// ============ HELPER FUNCTIONS ============

isolated function parseToUtc(string dateStr) returns time:Utc|error {
    if dateStr.length() != 10 {
        return error("Date must be in YYYY-MM-DD format");
    }
    string isoStr = dateStr + "T00:00:00.000Z";
    return time:utcFromString(isoStr);
}

isolated function nightsBetween(string checkIn, string checkOut) returns int|error {
    time:Utc inUtc = check parseToUtc(checkIn);
    time:Utc outUtc = check parseToUtc(checkOut);
    time:Seconds diff = time:utcDiffSeconds(outUtc, inUtc);
    decimal days = <decimal>diff / 86400.0d;
    return <int>days;
}

// ============ SERVICE ============

@grpc:Descriptor {
    value: rental:RENTAL_DESC
}
service "RentalService" on new grpc:Listener(9090) {

    // ----- 1. ADD PROPERTY -----
    remote function addProperty(rental:AddPropertyRequest req) returns rental:AddPropertyResponse|grpc:Error {
        lock {
            string propertyId = "PROP-" + nextPropertyId.toString();
            nextPropertyId += 1;

            rental:RentalProperty newProperty = {
                property_id: propertyId,
                property_name: req.property_name,
                location: req.location,
                property_type: req.property_type,
                price_per_night: req.price_per_night,
                status: req.status,
                host_id: req.host_id
            };

            propertyStore[propertyId] = newProperty;

            return {
                property_id: propertyId,
                message: "Property added successfully"
            };
        }
    }

    // ----- 2. CREATE USERS (Client Streaming) -----
    remote function createUsers(stream<rental:UserProfile, grpc:Error?> clientStream)
        returns rental:CreateUsersResponse|grpc:Error {

        int userCount = 0;

        while true {
            record {| rental:UserProfile value; |}|grpc:Error? next = clientStream.next();

            if next is record {| rental:UserProfile value; |} {
                userCount += 1;
                log:printInfo("Created user: " + next.value.username);
            } else if next is grpc:Error {
                return next;
            } else {
                break;
            }
        }

        return {
            total_created: userCount,
            message: "Successfully created " + userCount.toString() + " users"
        };
    }

    // ----- 3. UPDATE PROPERTY -----
    remote function updateProperty(rental:UpdatePropertyRequest req)
        returns rental:RentalProperty|grpc:Error {

        lock {
            rental:RentalProperty? existing = propertyStore[req.property_id];
            if existing is () {
                return error("Property not found");
            }

            if existing.host_id != req.host_id {
                return error("Host does not own this property");
            }

            if req.property_name is string {
                existing.property_name = <string>req.property_name;
            }
            if req.location is string {
                existing.location = <string>req.location;
            }
            if req.property_type is string {
                existing.property_type = <string>req.property_type;
            }
            if req.price_per_night is float {
                existing.price_per_night = <float>req.price_per_night;
            }
            if req.status is string {
                existing.status = <string>req.status;
            }

            propertyStore[req.property_id] = existing;
            return existing;
        }
    }

    // ----- 4. REMOVE PROPERTY -----
    remote function removeProperty(rental:RemovePropertyRequest req)
        returns rental:RemovePropertyResponse|grpc:Error {

        lock {
            rental:RentalProperty? existing = propertyStore[req.property_id];
            if existing is () {
                return error("Property not found");
            }

            if existing.host_id != req.host_id {
                return error("Host does not own this property");
            }

            _ = propertyStore.remove(req.property_id);

            rental:RentalProperty[] remaining = [];
            foreach var [_, prop] in propertyStore.entries() {
                if prop.location == existing.location {
                    remaining.push(prop);
                }
            }

            return {
                available_properties: remaining,
                message: "Property removed. " + remaining.length().toString() + " properties remain."
            };
        }
    }

    // ----- 5. LIST AVAILABLE PROPERTIES (Server Streaming) -----
    remote function listAvailableProperties(rental:ListPropertiesRequest req)
        returns stream<rental:RentalProperty, grpc:Error?> {

        rental:RentalProperty[] matching = [];

        lock {
            foreach var [_, prop] in propertyStore.entries() {
                if prop.status != "Available" {
                    continue;
                }

                if req.location is string {
                    string locationFilter = <string>req.location;
                    if !prop.location.includes(locationFilter) {
                        continue;
                    }
                }

                if req.min_price is float {
                    float minPrice = <float>req.min_price;
                    if prop.price_per_night < minPrice {
                        continue;
                    }
                }

                if req.max_price is float {
                    float maxPrice = <float>req.max_price;
                    if prop.price_per_night > maxPrice {
                        continue;
                    }
                }

                matching.push(prop);
            }
        }

        return matching.toStream();
    }

    // ----- 6. SEARCH PROPERTY -----
    remote function searchProperty(rental:SearchPropertyRequest req)
        returns rental:SearchPropertyResponse|grpc:Error {

        lock {
            rental:RentalProperty? found = propertyStore[req.property_id];

            if found is rental:RentalProperty {
                return {
                    found: true,
                    message: "Property found",
                    property: found
                };
            } else {
                return {
                    found: false,
                    message: "Not Available",
                    property: ()
                };
            }
        }
    }

    // ----- 7. BOOK PROPERTY -----
    remote function bookProperty(rental:BookPropertyRequest req)
        returns rental:BookPropertyResponse|grpc:Error {

        lock {
            rental:RentalProperty? prop = propertyStore[req.property_id];
            if prop is () {
                return error("Property not found");
            }

            int|error nightsResult = nightsBetween(req.check_in_date, req.check_out_date);
            if nightsResult is error {
                return error("Invalid date format. Use YYYY-MM-DD");
            }
            int nights = nightsResult;

            if nights <= 0 {
                return error("Check-out date must be after check-in date");
            }

            float totalCost = prop.price_per_night * <float>nights;

            string bookingRef = "BK-" + nextBookingRef.toString();
            nextBookingRef += 1;

            BookingCart cart = {
                guestId: req.guest_id,
                propertyId: req.property_id,
                checkInDate: req.check_in_date,
                checkOutDate: req.check_out_date,
                estimatedTotal: totalCost,
                bookingRef: bookingRef
            };

            bookingCart[bookingRef] = cart;

            return {
                booking_ref: bookingRef,
                estimated_total: totalCost,
                message: "Booking added to cart. Use confirmBooking to finalize."
            };
        }
    }

    // ----- 8. CONFIRM BOOKING -----
    remote function confirmBooking(rental:ConfirmBookingRequest req)
        returns rental:ConfirmBookingResponse|grpc:Error {

        lock {
            BookingCart? cart = bookingCart[req.booking_ref];
            if cart is () {
                return error("Booking reference not found");
            }

            if cart.guestId != req.guest_id {
                return error("Guest ID does not match booking");
            }

            rental:RentalProperty? prop = propertyStore[cart.propertyId];
            if prop is () {
                return error("Property no longer exists");
            }

            int|error nightsResult = nightsBetween(cart.checkInDate, cart.checkOutDate);
            if nightsResult is error {
                return error("Invalid date format");
            }
            int nights = nightsResult;

            string[]? existingBookings = guestBookings[cart.propertyId];
            if existingBookings is string[] {
                foreach string booking in existingBookings {
                    BookingCart? existingCart = bookingCart[booking];
                    if existingCart is BookingCart {
                        int|error ov1 = nightsBetween(
                            cart.checkInDate, existingCart.checkOutDate);
                        int|error ov2 = nightsBetween(
                            existingCart.checkInDate, cart.checkOutDate);

                        if ov1 is int && ov2 is int {
                            if ov1 > 0 && ov2 > 0 {
                                return error("Property not available. Dates overlap with an existing booking.");
                            }
                        }
                    }
                }
            }

            float totalCost = prop.price_per_night * <float>nights;
            string bookingId = "CONF-" + cart.bookingRef;

            string[] bookings;
            string[]? existingList = guestBookings[cart.propertyId];
            if existingList is string[] {
                bookings = existingList;
            } else {
                bookings = [];
            }
            bookings.push(cart.bookingRef);
            guestBookings[cart.propertyId] = bookings;

            _ = bookingCart.remove(req.booking_ref);

            return {
                confirmed: true,
                booking_id: bookingId,
                total_cost: totalCost,
                number_of_nights: nights,
                message: "Booking confirmed! Total cost: " + totalCost.toString()
            };
        }
    }
}
