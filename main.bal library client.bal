import ballerina/http;
import ballerina/io;
type Component record {|
    string compId;
    string name;
    string description;
|};

type Schedule record {|
    string scheduleId;
    string scheduleType;
    string dueDate;
    string description;
|};

type Task record {|
    string taskId;
    string description;
    boolean completed = false;
|};

type WorkOrder record {|
    string orderId;
    string status;
    string description;
    Task[] tasks = [];
|};

type Asset record {|
    string assetTag;
    string name;
    string description;
    string university;
    string site;
    string status;
    string dateAcquired;
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};

type University record {|
    string name;
|};

type StatusUpdate record {|
    string status;
|};

type BookingRequest record {|
    string scheduleId;
    string date;
    string description;
|};

public function main() returns error? {

    http:Client httpclient = check new ("http://localhost:9090");

    while true {

        io:println("");
        io:println("==============================================");
        io:println(" DSA612S LIBRARY MANAGEMENT SYSTEM");
        io:println("==============================================");
        io:println("1. Global View - View All Assets");
        io:println("2. View One Asset");
        io:println("3. Add Asset");
        io:println("4. Update Asset Status");
        io:println("5. Delete Asset");
        io:println("6. Campus View - Filter Assets");
        io:println("7. Loan Asset");
        io:println("8. Book Meeting Room/Lab");
        io:println("9. Overdue Dashboard");
        io:println("10. Add Schedule");
        io:println("11. Remove Schedule");
        io:println("12. Add Component");
        io:println("13. Add Work Order");
        io:println("14. Add Work-Order Task");
        io:println("15. View Universities");
        io:println("16. Add University");
        io:println("17. Remove University");
        io:println("0. Exit");
        io:println("==============================================");

        string choice = io:readln("Choose an option: ");

        match choice {

            "1" => {
                check viewAllAssets(httpclient);
            }

            "2" => {
                check viewOneAsset(httpclient);
            }

            "3" => {
                check addAsset(httpclient);
            }

            "4" => {
                check updateStatus(httpclient);
            }

            "5" => {
                check deleteAsset(httpclient);
            }

            "6" => {
                check filterAssets(httpclient);
            }

            "7" => {
                check loanAsset(httpclient);
            }

            "8" => {
                check bookAsset(httpclient);
            }

            "9" => {
                check overdueDashboard(httpclient);
            }

            "10" => {
                check addSchedule(httpclient);
            }

            "11" => {
                check removeSchedule(httpclient);
            }

            "12" => {
                check addComponent(httpclient);
            }

            "13" => {
                check addWorkOrder(httpclient);
            }

            "14" => {
                check addTask(httpclient);
            }

            "15" => {
                check viewUniversities(httpclient);
            }

            "16" => {
                check addUniversity(httpclient);
            }

            "17" => {
                check removeUniversity(httpclient);
            }

            "0" => {
                io:println("Goodbye!");
                break;
            }

            _ => {
                io:println("Invalid option.");
            }
        }
    }
}

function viewAllAssets(http:Client httpclient) returns error? {

    Asset[] assets = check httpclient->/assets;

    io:println("");
    io:println("========== GLOBAL ASSET VIEW ==========");

    foreach Asset asset in assets {
        printAsset(asset);
    }
}

function viewOneAsset(http:Client httpclient) returns error? {

    string tag = io:readln("Enter asset tag: ");

    Asset asset = check httpclient->/assets/[tag];

    printAsset(asset);
}


function addAsset(http:Client httpclient) returns error? {

    string tag = io:readln("Asset tag: ");
    string name = io:readln("Name: ");
    string description = io:readln("Description: ");
    string university = io:readln("University: ");
    string site = io:readln("Site/Campus: ");
    string status = io:readln("Status: ");
    string dateAcquired = io:readln("Date acquired (YYYY-MM-DD): ");

    Asset asset = {
        assetTag: tag,
        name: name,
        description: description,
        university: university,
        site: site,
        status: status,
        dateAcquired: dateAcquired,
        components: [],
        schedules: [],
        workOrders: []
    };

    Asset response = check httpclient->/assets.post(asset);

    io:println("Asset successfully added.");
    printAsset(response);
}


function updateStatus(http:Client httpclient) returns error? {

    string tag = io:readln("Asset tag: ");

    string status = io:readln(
        "New status (AVAILABLE/LOANED_OUT/OCCUPIED/"
        + "UNDER_MAINTENANCE/DISPOSED): "
    );

    StatusUpdate update = {
        status: status
    };

    Asset response =
        check httpclient->/assets/[tag]/status.put(update);

    io:println("Status updated.");
    printAsset(response);
}

function deleteAsset(http:Client httpclient) returns error? {

    string tag = io:readln("Asset tag to delete: ");

    http:Response response =
        check httpclient->/assets/[tag].delete();

    io:println("Asset deleted successfully.");
}


function filterAssets(http:Client httpclient) returns error? {

    string university = io:readln("University: ");

    string site = io:readln(
        "Site/Campus (leave blank for all campuses): "
    );

    Asset[] response;

    if site == "" {

        response = check httpclient->/assets/filter(
            university = university
        );

    } else {

        response = check httpclient->/assets/filter(
            university = university,
            site = site
        );
    }

    io:println("");
    io:println("========== CAMPUS VIEW ==========");

    if response.length() == 0 {
        io:println("No assets found.");
        return;
    }

    foreach Asset asset in response {
        printAsset(asset);
    }
}


// ============================================================
// 7. LOAN ASSET
// ============================================================

function loanAsset(http:Client httpclient) returns error? {

    string tag = io:readln("Asset tag to loan: ");

    Asset response =

    check httpclient->/assets/[tag]/loan.post({});
    io:println("Asset successfully loaned.");
    printAsset(response);
}


function bookAsset(http:Client httpclient) returns error? {

    string tag = io:readln("Room/Lab asset tag: ");
    string scheduleId = io:readln("Booking ID: ");
    string date = io:readln("Booking date (YYYY-MM-DD): ");
    string description = io:readln("Booking description: ");

    BookingRequest booking = {
        scheduleId: scheduleId,
        date: date,
        description: description
    };

    Asset response =
        check httpclient->/assets/[tag]/book.post(booking);

    io:println("Booking successful.");
    printAsset(response);
}


function overdueDashboard(http:Client httpclient) returns error? {

    Asset[] response =
        check httpclient->/assets/overdue;

    io:println("");
    io:println("========== OVERDUE DASHBOARD ==========");

    if response.length() == 0 {
        io:println("No overdue maintenance schedules.");
        return;
    }

    foreach Asset asset in response {
        printAsset(asset);
    }
}

function addSchedule(http:Client httpclient) returns error? {

    string tag = io:readln("Asset tag: ");

    string scheduleId =
        io:readln("Schedule ID: ");

    string scheduleType =
        io:readln(
            "Type (MAINTENANCE/BOOKING): "
        );

    string dueDate =
        io:readln("Due date (YYYY-MM-DD): ");

    string description =
        io:readln("Description: ");

    Schedule schedule = {
        scheduleId: scheduleId,
        scheduleType: scheduleType,
        dueDate: dueDate,
        description: description
    };

    Asset response =
        check httpclient->/assets/[tag]/schedules.post(schedule);

    io:println("Schedule added.");
    printAsset(response);
}


function removeSchedule(http:Client httpclient) returns error? {

    string tag =
        io:readln("Asset tag: ");

    string scheduleId =
        io:readln("Schedule ID: ");

    Asset response =
        check httpclient->
        /assets/[tag]/schedules/[scheduleId].delete();

    io:println("Schedule removed.");
    printAsset(response);
}

function addComponent(http:Client httpclient) returns error? {

    string tag =
        io:readln("Asset tag: ");

    string compId =
        io:readln("Component ID: ");

    string name =
        io:readln("Component name: ");

    string description =
        io:readln("Component description: ");

    Component component = {
        compId: compId,
        name: name,
        description: description
    };

    Asset response =
        check httpclient->/assets/[tag]/components.post(component);

    io:println("Component added.");
    printAsset(response);
}

function addWorkOrder(http:Client httpclient) returns error? {

    string tag =
        io:readln("Asset tag: ");

    string orderId =
        io:readln("Work order ID: ");

    string status =
        io:readln(
            "Status (OPEN/IN_PROGRESS/CLOSED): "
        );

    string description =
        io:readln("Description: ");

    WorkOrder workOrders = {
        orderId: orderId,
        status: status,
        description: description,
        tasks: []
    };

    Asset response =
        check httpclient->/assets/[tag]/workorders.post(workOrders);

    io:println("Work order created.");
    printAsset(response);
}

function addTask(http:Client httpclient) returns error? {

    string tag =
        io:readln("Asset tag: ");

    string orderId =
        io:readln("Work order ID: ");

    string taskId =
        io:readln("Task ID: ");

    string description =
        io:readln("Task description: ");

    Task task = {
        taskId: taskId,
        description: description,
        completed: false
    };

    Asset response =
        check httpclient->
        /assets/[tag]/workorders/[orderId]/tasks.post(task);

    io:println("Task added.");
    printAsset(response);
}


function viewUniversities(http:Client httpclient) returns error? {

    University[] response =
        check httpclient->/universities;

    io:println("");
    io:println("========== UNIVERSITIES ==========");

    if response.length() == 0 {
        io:println("No universities found.");
        return;
    }

    foreach University university in response {
        io:println("- ", university.name);
    }
}

function addUniversity(http:Client httpclient) returns error? {

    string name =
        io:readln("University name: ");

    University university = {
        name: name
    };

    University response =
        check httpclient->/universities.post(university);

    io:println(
        "University added: ",
        response.name
    );
}

function removeUniversity(http:Client httpclient) returns error? {

    string name =
        io:readln("University to remove: ");

http:Response response =
    check httpclient->/universities/[name].delete();
    io:println("University removed.");
}


function printAsset(Asset asset) {

    io:println("");
    io:println("----------------------------------------");
    io:println("Asset Tag:       ", asset.assetTag);
    io:println("Name:            ", asset.name);
    io:println("Description:     ", asset.description);
    io:println("University:      ", asset.university);
    io:println("Site:             ", asset.site);
    io:println("Status:           ", asset.status);
    io:println("Date Acquired:    ", asset.dateAcquired);

    io:println("Components:       ", asset.components.length());
    io:println("Schedules:        ", asset.schedules.length());
    io:println("Work Orders:      ", asset.workOrders.length());

    if asset.schedules.length() > 0 {

        io:println("");
        io:println("Schedules:");

        foreach Schedule schedule in asset.schedules {

            io:println(
                "  ",
                schedule.scheduleId,
                " | ",
                schedule.scheduleType,
                " | ",
                schedule.dueDate,
                " | ",
                schedule.description
            );
        }
    }

    if asset.workOrders.length() > 0 {

        io:println("");
        io:println("Work Orders:");

        foreach WorkOrder workOrders in asset.workOrders {

            io:println(
                "  ",
                workOrders.orderId,
                " | ",
                workOrders.status,
                " | ",
                workOrders.description
            );

            foreach Task task in workOrders.tasks {

                string completed =
                    task.completed ? "DONE" : "PENDING";

                io:println(
                    "       - ",
                    task.taskId,
                    " | ",
                    completed,
                    " | ",
                    task.description
                );
            }
        }
    }

    io:println("----------------------------------------");
}