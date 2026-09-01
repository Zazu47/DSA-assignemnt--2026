// dateutils.bal

import ballerina/time;

// Parses "YYYY-MM-DD" into a time:Civil record for comparison.
function parseDate(string isoDate) returns time:Civil|time:Error {
    string[] parts = re `-`.split(isoDate);
    if parts.length() != 3 {
        return error("Invalid date format: " + isoDate);
    }

    int|error yearResult = int:fromString(parts[0]);
    int|error monthResult = int:fromString(parts[1]);
    int|error dayResult = int:fromString(parts[2]);

    if yearResult is error || monthResult is error || dayResult is error {
        return error("Invalid date components: " + isoDate);
    }

    time:Civil civil = {
        year: <int>yearResult,
        month: <int>monthResult,
        day: <int>dayResult,
        hour: 0,
        minute: 0,
        second: 0
    };
    return civil;
}

// Returns true if civil date 'a' is strictly before civil date 'b' (date-only comparison).
function isDateBefore(time:Civil a, time:Civil b) returns boolean {
    if a.year != b.year {
        return a.year < b.year;
    }
    if a.month != b.month {
        return a.month < b.month;
    }
    return a.day < b.day;
}
