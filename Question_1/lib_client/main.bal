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
        io:println("4. View asset details (status, schedules, work orders)");
        io:println("5. Loan / Book an asset");
        io:println("6. Return an asset");
        io:println("7. Add schedule to asset");
        io:println("8. Remove schedule from asset");
        io:println("9. Add new asset");
        io:println("10. List institutions");
        io:println("11. Add institution");
        io:println("12. Remove institution");
        io:println("13. Exit");
        string choice = io:readln("Select option: ");

        if choice == "1" {
            check viewAllAssets();
        } else if choice == "2" {
            check viewByCampus();
        } else if choice == "3" {
            check viewOverdue();
        } else if choice == "4" {
            check viewAssetDetail();
        } else if choice == "5" {
            check loanAsset();
        } else if choice == "6" {
            check returnAsset();
        } else if choice == "7" {
            check addSchedule();
        } else if choice == "8" {
            check removeSchedule();
        } else if choice == "9" {
            check addAsset();
        } else if choice == "10" {
            check listInstitutions();
        } else if choice == "11" {
            check addInstitution();
        } else if choice == "12" {
            check removeInstitution();
        } else if choice == "13" {
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

function viewAssetDetail() returns error? {
    string tag = io:readln("Asset tag: ");
    Asset|http:ClientError result = apiClient->get("/assets/" + tag);
    if result is Asset {
        io:println("--- " + result.assetTag + " ---");
        io:println("Name: " + result.name);
        io:println("Category: " + result.category);
        io:println("Institution: " + result.institution + " | Site: " + result.site);
        io:println("Status: " + result.status);
        io:println("Date acquired: " + result.dateAcquired);

        io:println("Schedules:");
        if result.schedules.length() == 0 {
            io:println("  (none)");
        }
        foreach Schedule s in result.schedules {
            io:println("  " + s.scheduleId + " | " + s.'type + " | due " + s.dueDate + " | " + s.description);
        }

        io:println("Work orders:");
        if result.workOrders.length() == 0 {
            io:println("  (none)");
        }
        foreach WorkOrder wo in result.workOrders {
            io:println("  " + wo.orderId + " | " + wo.status + " | " + wo.description);
            foreach WorkOrderTask t in wo.tasks {
                string mark = t.completed ? "x" : " ";
                io:println("     [" + mark + "] " + t.taskId + ": " + t.description);
            }
        }
    } else {
        io:println("Error: " + result.message());
    }
}

function loanAsset() returns error? {
    string tag = io:readln("Asset tag to loan/book: ");
    Asset|http:ClientError result = apiClient->post("/assets/" + tag + "/loan", ());
    if result is Asset {
        io:println("Checked out: " + result.assetTag + " | status now: " + result.status);
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
    string catInput = io:readln("Category (BOOK/EQUIPMENT/SPACE, blank = EQUIPMENT): ");

    AssetCategory category = EQUIPMENT;
    if catInput == "BOOK" {
        category = BOOK;
    } else if catInput == "SPACE" {
        category = SPACE;
    }

    Asset newAsset = {
        assetTag: tag,
        name: name,
        description: desc,
        institution: inst,
        site: site,
        status: AVAILABLE,
        category: category,
        dateAcquired: dateAcq
    };

    Asset|http:ClientError result = apiClient->post("/assets", newAsset);
    if result is Asset {
        io:println("Created: " + result.assetTag);
    } else {
        io:println("Error: " + result.message());
    }
}

function listInstitutions() returns error? {
    Institution[] insts = check apiClient->get("/institutions");
    if insts.length() == 0 {
        io:println("(no institutions found)");
        return;
    }
    foreach Institution i in insts {
        io:println(i.institutionId + " | " + i.name + " | sites: " + i.sites.toString());
    }
}

function addInstitution() returns error? {
    string id = io:readln("Institution ID: ");
    string name = io:readln("Name: ");
    string sitesInput = io:readln("Sites (comma-separated, blank for none): ");

    string[] sites = [];
    if sitesInput != "" {
        sites = re `,`.split(sitesInput);
    }

    Institution newInst = {institutionId: id, name: name, sites: sites};
    Institution|http:ClientError result = apiClient->post("/institutions", newInst);
    if result is Institution {
        io:println("Created institution: " + result.institutionId);
    } else {
        io:println("Error: " + result.message());
    }
}

function removeInstitution() returns error? {
    string id = io:readln("Institution ID to remove: ");
    MessageResponse|http:ClientError result = apiClient->delete("/institutions/" + id);
    if result is MessageResponse {
        io:println(result.message);
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
