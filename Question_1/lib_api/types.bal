// types.bal

public enum Status {
    AVAILABLE,
    LOANED_OUT,
    OCCUPIED,
    UNDER_MAINTENANCE,
    DISPOSED
}

// Distinguishes books/equipment (LOANED_OUT when checked out) from
// physical spaces like labs/meeting rooms (OCCUPIED when booked).
public enum AssetCategory {
    BOOK,
    EQUIPMENT,
    SPACE
}

public type Component record {|
    string compId;
    string name;
    string description;
|};

public type Schedule record {|
    string scheduleId;
    string 'type; // "MAINTENANCE", "BOOKING", etc.
    string dueDate; // ISO date string YYYY-MM-DD
    string description;
|};

public type WorkOrderTask record {|
    string taskId;
    string description;
    boolean completed = false;
|};

public type WorkOrder record {|
    string orderId;
    string status; // "OPEN", "IN_PROGRESS", "CLOSED"
    string description;
    WorkOrderTask[] tasks = [];
|};

public type Asset record {|
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    Status status;
    AssetCategory category = EQUIPMENT;
    string dateAcquired;
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};

public type Institution record {|
    string institutionId;
    string name;
    string[] sites = [];
|};

public type StatusUpdate record {|
    string status;
|};

public type MessageResponse record {
    string message;
};

public type TaskUpdate record {|
    boolean completed;
|};
