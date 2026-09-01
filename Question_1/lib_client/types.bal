// types.bal

public enum Status {
    AVAILABLE,
    LOANED_OUT,
    OCCUPIED,
    UNDER_MAINTENANCE,
    DISPOSED
}

public type Component record {|
    string compId;
    string name;
    string description;
|};

public type Schedule record {|
    string scheduleId;
    string 'type;
    string dueDate;
    string description;
|};

public type WorkOrderTask record {|
    string taskId;
    string description;
    boolean completed = false;
|};

public type WorkOrder record {|
    string orderId;
    string status;
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
    string dateAcquired;
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};