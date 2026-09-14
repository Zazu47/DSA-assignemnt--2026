// types.bal - same shapes as the API side, just what the client needs to
// print things out and build requests.

public type AssetComponent record {|
    string compId;
    string name;
    string description;
|};

public type AssetSchedule record {|
    string scheduleId;
    string 'type;
    string dueDate;
    string description;
    boolean completed = false;
|};

public type WorkOrderTask record {|
    string taskId;
    string description;
    boolean done = false;
|};

public type WorkOrder record {|
    string orderId;
    string status;
    string description;
    WorkOrderTask[] tasks = [];
|};

public type LoanInfo record {|
    string borrower;
    string borrowedOn;
    string dueBack;
|};

public type Asset record {|
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    string status;
    string dateAcquired;
    AssetComponent[] components = [];
    AssetSchedule[] schedules = [];
    WorkOrder[] workOrders = [];
    LoanInfo? loan = ();
|};
