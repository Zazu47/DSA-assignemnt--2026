import ballerina/http;
import ballerina/time;

const string AVAILABLE = "AVAILABLE";
const string LOANED_OUT = "LOANED_OUT";
const string OCCUPIED = "OCCUPIED";
const string UNDER_MAINTENANCE = "UNDER_MAINTENANCE";
const string DISPOSED = "DISPOSED";
const string MAINTENANCE = "MAINTENANCE";
const string BOOKING = "BOOKING";
const string OPEN = "OPEN";
const string IN_PROGRESS = "IN_PROGRESS";
const string CLOSED = "CLOSED";

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
    readonly string assetTag;
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
    readonly string name;
|};

type StatusUpdate record {|
    string status;
|};

type BookingRequest record {|
    string scheduleId;
    string date;
    string description;
|};

table<Asset> key(assetTag) assets = table [
    {
        assetTag: "NUST-LIB-3DP-001",
        name: "3D Printer",
        description: "Laboratory printer",
        university: "NUST",
        site: "Main Campus Lab 1",
        status: AVAILABLE,
        dateAcquired: "2026-05-20",

        components: [
            {
                compId: "C001",
                name: "Printer Motor",
                description: "Main printer motor"
            }
        ],

        schedules: [
            {
                scheduleId: "SCH-001",
                scheduleType: "MAINTENANVE",
                dueDate: "2026-05-01",
                description: "Printer maintenance"
            }
        ],

        workOrders: [
            {
                orderId: "WO-001",
                status: OPEN,
                description: "Check printer",
                tasks: [
                    {
                        taskId: "T001",
                        description: "Check motor"
                    }
                ]
            }
        ]
    },

    {
        assetTag: "NUST LIB",
        name: "Library Laptop",
        description: "Laptop for students",
        university: "NUST",
        site: "Main Campus Library",
        status: AVAILABLE,
        dateAcquired: "2026-05-22"
    },

    {
        assetTag: "UNAM LAB",
        name: "Laboratory Computer",
        description: "Computer for laboratory use",
        university: "UNAM",
        site: "Main Campus Lab",
        status: AVAILABLE,
        dateAcquired: "2026-05-25"
    },

    {
        assetTag: "NUST MR",
        name: "Meeting Room",
        description: "Student meeting room",
        university: "NUST",
        site: "Lower Campus",
        status: AVAILABLE,
        dateAcquired: "2026-05-23"
    }
];

table<University> key(name) universities = table [
    {name: "NUST"},
    {name: "UNAM"}
];

function findAsset(string assetTag) returns Asset? {
    return assets[assetTag];
}

function universityExists(string name) returns boolean {
    University? university = universities[name];

    return university is University;
}

function today() returns string {
    time:Utc now = time:utcNow();
    time:Civil date = time:utcToCivil(now);

    string month = date.month < 10
        ? string `0${date.month}`
        : string `${date.month}`;

    string day = date.day < 10
        ? string `0${date.day}`
        : string `${date.day}`;

    return string `${date.year}-${month}-${day}`;
}

function isOverdue(Asset asset) returns boolean {

    string currentDate = today();

    foreach Schedule schedule in asset.schedules {
        if schedule.scheduleType == MAINTENANCE && schedule.dueDate < currentDate {
            return true;
        }
    }

    return false;
}

service / on new http:Listener(9090) {

    resource function get .() returns string {
        return "Library and Resource Management API is running";
    }

    resource function get assets() returns Asset[] {
        return assets.toArray();
    }

    resource function get assets/[string assetTag]()
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        return asset;
    }

    resource function post assets(Asset asset)
            returns Asset|http:Conflict {

        if !universityExists(asset.university) {
            return http:CONFLICT;
        }

        if findAsset(asset.assetTag) is Asset {
            return http:CONFLICT;
        }

        assets.add(asset);

        return asset;
    }

    resource function put assets/[string assetTag](Asset asset)
            returns Asset|http:NotFound {

        if findAsset(assetTag) is () {
            return http:NOT_FOUND;
        }

        Asset updated = {
            assetTag: assetTag,
            name: asset.name,
            description: asset.description,
            university: asset.university,
            site: asset.site,
            status: asset.status,
            dateAcquired: asset.dateAcquired,
            components: asset.components,
            schedules: asset.schedules,
            workOrders: asset.workOrders
        };

        assets.put(updated);

        return updated;
    }

    resource function delete assets/[string assetTag]()
            returns http:NoContent|http:NotFound {

        if findAsset(assetTag) is () {
            return http:NOT_FOUND;
        }

        _ = assets.remove(assetTag);

        return http:NO_CONTENT;
    }

    resource function get assets/filter(string university, string? site)
            returns Asset[] {

        if site is () {
            return from Asset asset in assets
                where asset.university == university
                select asset;
        }

        return from Asset asset in assets
            where asset.university == university
                && asset.site == site
            select asset;
    }

    resource function put assets/[string assetTag]/status(StatusUpdate update)
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        Asset updated = {
            assetTag: asset.assetTag,
            name: asset.name,
            description: asset.description,
            university: asset.university,
            site: asset.site,
            status: update.status,
            dateAcquired: asset.dateAcquired,
            components: asset.components,
            schedules: asset.schedules,
            workOrders: asset.workOrders
        };

        assets.put(updated);

        return updated;
    }

    resource function post assets/[string assetTag]/loan()
            returns Asset|http:NotFound|http:Conflict {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        if asset.status != AVAILABLE {
            return http:CONFLICT;
        }

        asset.status = LOANED_OUT;
        assets.put(asset);

        return asset;
    }

    resource function post assets/[string assetTag]/book(BookingRequest booking)
            returns Asset|http:NotFound|http:Conflict {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        if asset.status != AVAILABLE {
            return http:CONFLICT;
        }

        Schedule schedule = {
            scheduleId: booking.scheduleId,
            scheduleType: BOOKING,
            dueDate: booking.date,
            description: booking.description
        };

        asset.schedules.push(schedule);
        asset.status = OCCUPIED;

        assets.put(asset);

        return asset;
    }

    resource function get assets/overdue() returns Asset[] {

        return from Asset asset in assets
            where isOverdue(asset)
            select asset;
    }

    resource function post assets/[string assetTag]/components(Component component)
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        asset.components.push(component);
        assets.put(asset);

        return asset;
    }

    resource function delete assets/[string assetTag]/components/[string compId]()
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        Component[] newComponents = [];

        foreach Component component in asset.components {
            if component.compId != compId {
                newComponents.push(component);
            }
        }

        asset.components = newComponents;
        assets.put(asset);

        return asset;
    }

    resource function post assets/[string assetTag]/schedules(Schedule schedule)
            returns Asset|http:NotFound|http:Conflict {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        foreach Schedule oldSchedule in asset.schedules {
            if oldSchedule.scheduleId == schedule.scheduleId {
                return http:CONFLICT;
            }
        }

        asset.schedules.push(schedule);
        assets.put(asset);

        return asset;
    }
    resource function put assets/[string assetTag]/schedules/[string scheduleId](
            Schedule schedule)
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        foreach int i in 0 ..< asset.schedules.length() {
            if asset.schedules[i].scheduleId == scheduleId {
                asset.schedules[i] = schedule;
                assets.put(asset);
                return asset;
            }
        }

        return http:NOT_FOUND;
    }

    resource function delete assets/[string assetTag]/schedules/[string scheduleId]()
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        Schedule[] newSchedules = [];

        foreach Schedule schedule in asset.schedules {
            if schedule.scheduleId != scheduleId {
                newSchedules.push(schedule);
            }
        }

        asset.schedules = newSchedules;
        assets.put(asset);

        return asset;
    }

    resource function post assets/[string assetTag]/workorders(WorkOrder workOrder)
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        asset.workOrders.push(workOrder);
        asset.status = UNDER_MAINTENANCE;

        assets.put(asset);

        return asset;
    }

    resource function put assets/[string assetTag]/workorders/[string orderId](
            WorkOrder updatedOrder)
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        foreach int i in 0 ..< asset.workOrders.length() {
            if asset.workOrders[i].orderId == orderId {

                asset.workOrders[i] = updatedOrder;

                if updatedOrder.status == CLOSED {
                    asset.status = AVAILABLE;
                }

                assets.put(asset);

                return asset;
            }
        }

        return http:NOT_FOUND;
    }

    resource function post assets/[string assetTag]/workorders/[string orderId]/tasks(
            Task task)
            returns Asset|http:NotFound {

        Asset? asset = findAsset(assetTag);

        if asset is () {
            return http:NOT_FOUND;
        }

        foreach int i in 0 ..< asset.workOrders.length() {

            if asset.workOrders[i].orderId == orderId {
                asset.workOrders[i].tasks.push(task);
                assets.put(asset);

                return asset;
            }
        }

        return http:NOT_FOUND;
    }

    resource function get universities() returns University[] {
        return universities.toArray();
    }

    resource function post universities(University university)
            returns University|http:Conflict {

        if universityExists(university.name) {
            return http:CONFLICT;
        }

        universities.add(university);

        return university;
    }

    resource function delete universities/[string name]()
            returns http:NoContent|http:NotFound {

        if universities[name] is () {
            return http:NOT_FOUND;
        }

        _ = universities.remove(name);

        return http:NO_CONTENT;
    }
}