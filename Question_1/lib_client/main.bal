import ballerina/http;
import ballerina/io;

final http:Client apiClient = check new ("http://localhost:8080/api");

public function main() returns error? {
    boolean running = true;

    while running {
        io:println("\n===== Library & Resource Management Client =====");
        io:println("1. Global View (all assets)");
        io:println("2. Campus View (filter by institution/site)");
        io:println("3. Overdue Dashboard");
        io:println("4. Loan an asset");
        io:println("5. Return an asset");
        io:println("6. Add schedule to asset");
        io:println("7. Remove schedule from asset");
        io:println("8. Add new asset");
        io:println("9. Exit");
        string choice = io:readln("Select option: ");

        if choice == "1" {
            check viewAllAssets();
        } else if choice == "2" {
            check viewByCampus();
        } else if choice == "3" {
            check viewOverdue();
        } else if choice == "4" {
            check loanAsset();
        } else if choice == "5" {
            check returnAsset();
        } else if choice == "6" {
            check addSchedule();
        } else if choice == "7" {
            check removeSchedule();
        } else if choice == "8" {
            check addAsset();
        } else if choice == "9" {
            running = false;
        } else {
            io:println("Invalid option.");
        }
    }
    io:println("Goodbye.");
}

function viewAllAssets() returns error? {
    Asset[] assets = check apiClient->get("/assets");
    printAssets(assets);
}

function viewByCampus() returns error? {
    string inst = io:readln("Institution (blank to skip): ");
    string site = io:readln("Site (blank to skip): ");
    string query = "/assets";
    string sep = "?";
    if inst != "" {
        query = query + sep + "institution=" + inst;
        sep = "&";
    }
    if site != "" {
        query = query + sep + "site=" + site;
    }
    Asset[] assets = check apiClient->get(query);
    printAssets(assets);
}

function viewOverdue() returns error? {
    Asset[] assets = check apiClient->get("/assets/overdue");
    printAssets(assets);
}

function loanAsset() returns error? {
    string tag = io:readln("Asset tag to loan: ");
    Asset|http:ClientError result = apiClient->post("/assets/" + tag + "/loan", ());
    if result is Asset {
        io:println("Loaned: " + result.assetTag + " | status now: " + result.status);
    } else {
        io:println("Error: " + result.message());
    }
}

function returnAsset() returns error? {
    string tag = io:readln("Asset tag to return: ");
    Asset|http:ClientError result = apiClient->post("/assets/" + tag + "/return", ());
    if result is Asset {
        io:println("Returned: " + result.assetTag + " | status now: " + result.status);
    } else {
        io:println("Error: " + result.message());
    }
}

function addSchedule() returns error? {
    string tag = io:readln("Asset tag: ");
    string schedId = io:readln("Schedule ID: ");
    string sType = io:readln("Type (MAINTENANCE/BOOKING): ");
    string due = io:readln("Due date (YYYY-MM-DD): ");
    string desc = io:readln("Description: ");
    Schedule sched = {scheduleId: schedId, 'type: sType, dueDate: due, description: desc};

    Asset|http:ClientError result = apiClient->post("/assets/" + tag + "/schedules", sched);
    if result is Asset {
        io:println("Schedule added. Asset now has " + result.schedules.length().toString() + " schedule(s).");
    } else {
        io:println("Error: " + result.message());
    }
}

function removeSchedule() returns error? {
    string tag = io:readln("Asset tag: ");
    string schedId = io:readln("Schedule ID to remove: ");
    Asset|http:ClientError result = apiClient->delete("/assets/" + tag + "/schedules/" + schedId);
    if result is Asset {
        io:println("Schedule removed. Remaining: " + result.schedules.length().toString());
    } else {
        io:println("Error: " + result.message());
    }
}

function addAsset() returns error? {
    string tag = io:readln("Asset tag: ");
    string name = io:readln("Name: ");
    string desc = io:readln("Description: ");
    string inst = io:readln("Institution: ");
    string site = io:readln("Site: ");
    string dateAcq = io:readln("Date acquired (YYYY-MM-DD): ");

    Asset newAsset = {
        assetTag: tag,
        name: name,
        description: desc,
        institution: inst,
        site: site,
        status: AVAILABLE,
        dateAcquired: dateAcq
    };

    Asset|http:ClientError result = apiClient->post("/assets", newAsset);
    if result is Asset {
        io:println("Created: " + result.assetTag);
    } else {
        io:println("Error: " + result.message());
    }
}

function printAssets(Asset[] assets) {
    if assets.length() == 0 {
        io:println("(no assets found)");
        return;
    }
    foreach Asset a in assets {
        io:println(a.assetTag + " | " + a.name + " | " + a.institution + " - " + a.site + " | " + a.status);
    }
}