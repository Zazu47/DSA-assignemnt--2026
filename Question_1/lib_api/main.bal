import ballerina/http;
import ballerina/log;
import ballerina/time;

listener http:Listener libListener = new (8080);

service /api on libListener {

    // ==================== ASSET CRUD ====================

    // POST /api/assets
    resource function post assets(@http:Payload Asset newAsset) returns Asset|http:Conflict|http:BadRequest {
        if assetStore.hasKey(newAsset.assetTag) {
            return <http:Conflict>{
                body: {message: "Asset with tag " + newAsset.assetTag + " already exists."}
            };
        }
        assetStore[newAsset.assetTag] = newAsset;
        log:printInfo("Created asset: " + newAsset.assetTag);
        return newAsset;
    }

    // GET /api/assets?institution=X&site=Y
    resource function get assets(string? institution, string? site) returns Asset[] {
        Asset[] result = assetStore.toArray();

        if institution is string {
            result = from Asset a in result
                where a.institution == institution
                select a;
        }
        if site is string {
            result = from Asset a in result
                where a.site == site
                select a;
        }
        return result;
    }

    // GET /api/assets/overdue
    resource function get assets/overdue() returns Asset[] {
        time:Civil nowCivil = time:utcToCivil(time:utcNow());
        Asset[] overdueAssets = [];

        foreach Asset a in assetStore {
            boolean isOverdue = false;
            foreach Schedule s in a.schedules {
                time:Civil|time:Error dueCivil = parseDate(s.dueDate);
                if dueCivil is time:Civil && isDateBefore(dueCivil, nowCivil) {
                    isOverdue = true;
                }
            }
            if isOverdue {
                overdueAssets.push(a);
            }
        }
        return overdueAssets;
    }

    // GET /api/assets/{assetTag}
    resource function get assets/[string assetTag]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is Asset {
            return found;
        }
        return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
    }

    // PUT /api/assets/{assetTag}
    resource function put assets/[string assetTag](@http:Payload Asset updatedAsset) returns Asset|http:NotFound|http:BadRequest {
        if !assetStore.hasKey(assetTag) {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        if updatedAsset.assetTag != assetTag {
            return <http:BadRequest>{body: {message: "assetTag in body must match assetTag in URL."}};
        }
        assetStore[assetTag] = updatedAsset;
        log:printInfo("Updated asset: " + assetTag);
        return updatedAsset;
    }

    // DELETE /api/assets/{assetTag}
    resource function delete assets/[string assetTag]() returns http:Ok|http:NotFound {
        if !assetStore.hasKey(assetTag) {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        _ = assetStore.remove(assetTag);
        log:printInfo("Deleted asset: " + assetTag);
        return <http:Ok>{body: {message: "Asset " + assetTag + " deleted."}};
    }

    // ==================== LOANING / BOOKING ====================

    // POST /api/assets/{assetTag}/loan
    resource function post assets/[string assetTag]/loan() returns Asset|http:NotFound|http:Conflict {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        if found.status != AVAILABLE {
            return <http:Conflict>{body: {message: "Asset " + assetTag + " is not AVAILABLE (current: " + found.status + ")."}};
        }
        found.status = LOANED_OUT;
        log:printInfo("Loaned out: " + assetTag);
        return found;
    }

    // POST /api/assets/{assetTag}/return
    resource function post assets/[string assetTag]/'return() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        found.status = AVAILABLE;
        log:printInfo("Returned: " + assetTag);
        return found;
    }

    // ==================== COMPONENTS ====================

    // POST /api/assets/{assetTag}/components
    resource function post assets/[string assetTag]/components(@http:Payload Component newComp) returns Asset|http:NotFound|http:Conflict {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        foreach Component c in found.components {
            if c.compId == newComp.compId {
                return <http:Conflict>{body: {message: "Component " + newComp.compId + " already exists."}};
            }
        }
        found.components.push(newComp);
        return found;
    }

    // DELETE /api/assets/{assetTag}/components/{compId}
    resource function delete assets/[string assetTag]/components/[string compId]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        found.components = from Component c in found.components
            where c.compId != compId
            select c;
        return found;
    }

    // ==================== SCHEDULES ====================

    // POST /api/assets/{assetTag}/schedules
    resource function post assets/[string assetTag]/schedules(@http:Payload Schedule newSched) returns Asset|http:NotFound|http:Conflict {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        foreach Schedule s in found.schedules {
            if s.scheduleId == newSched.scheduleId {
                return <http:Conflict>{body: {message: "Schedule " + newSched.scheduleId + " already exists."}};
            }
        }
        found.schedules.push(newSched);
        return found;
    }

    // DELETE /api/assets/{assetTag}/schedules/{scheduleId}
    resource function delete assets/[string assetTag]/schedules/[string scheduleId]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        found.schedules = from Schedule s in found.schedules
            where s.scheduleId != scheduleId
            select s;
        return found;
    }

    // ==================== WORK ORDERS ====================

    // POST /api/assets/{assetTag}/workorders
    resource function post assets/[string assetTag]/workorders(@http:Payload WorkOrder newWO) returns Asset|http:NotFound|http:Conflict {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        foreach WorkOrder wo in found.workOrders {
            if wo.orderId == newWO.orderId {
                return <http:Conflict>{body: {message: "Work order " + newWO.orderId + " already exists."}};
            }
        }
        found.workOrders.push(newWO);
        return found;
    }

    // PUT /api/assets/{assetTag}/workorders/{orderId}  (update status: OPEN/IN_PROGRESS/CLOSED)
    resource function put assets/[string assetTag]/workorders/[string orderId](@http:Payload StatusUpdate upd) returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        boolean woFound = false;
        foreach WorkOrder wo in found.workOrders {
            if wo.orderId == orderId {
                wo.status = upd.status;
                woFound = true;
            }
        }
        if !woFound {
            return <http:NotFound>{body: {message: "Work order " + orderId + " not found."}};
        }
        return found;
    }

    // DELETE /api/assets/{assetTag}/workorders/{orderId}
    resource function delete assets/[string assetTag]/workorders/[string orderId]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        found.workOrders = from WorkOrder wo in found.workOrders
            where wo.orderId != orderId
            select wo;
        return found;
    }

    // POST /api/assets/{assetTag}/workorders/{orderId}/tasks
    resource function post assets/[string assetTag]/workorders/[string orderId]/tasks(@http:Payload WorkOrderTask newTask) returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        boolean woFound = false;
        foreach WorkOrder wo in found.workOrders {
            if wo.orderId == orderId {
                wo.tasks.push(newTask);
                woFound = true;
            }
        }
        if !woFound {
            return <http:NotFound>{body: {message: "Work order " + orderId + " not found."}};
        }
        return found;
    }

    // PUT /api/assets/{assetTag}/workorders/{orderId}/tasks/{taskId}  (mark complete/incomplete)
    resource function put assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId](@http:Payload TaskUpdate upd) returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return <http:NotFound>{body: {message: "Asset " + assetTag + " not found."}};
        }
        boolean taskFound = false;
        foreach WorkOrder wo in found.workOrders {
            if wo.orderId == orderId {
                foreach WorkOrderTask t in wo.tasks {
                    if t.taskId == taskId {
                        t.completed = upd.completed;
                        taskFound = true;
                    }
                }
            }
        }
        if !taskFound {
            return <http:NotFound>{body: {message: "Task " + taskId + " not found."}};
        }
        return found;
    }

    // ==================== INSTITUTIONS ====================

    // POST /api/institutions
    resource function post institutions(@http:Payload Institution newInst) returns Institution|http:Conflict {
        if institutionStore.hasKey(newInst.institutionId) {
            return <http:Conflict>{body: {message: "Institution " + newInst.institutionId + " already exists."}};
        }
        institutionStore[newInst.institutionId] = newInst;
        return newInst;
    }

    // GET /api/institutions
    resource function get institutions() returns Institution[] {
        return institutionStore.toArray();
    }

    // GET /api/institutions/{institutionId}
    resource function get institutions/[string institutionId]() returns Institution|http:NotFound {
        Institution? found = institutionStore[institutionId];
        if found is Institution {
            return found;
        }
        return <http:NotFound>{body: {message: "Institution " + institutionId + " not found."}};
    }

    // DELETE /api/institutions/{institutionId}
    resource function delete institutions/[string institutionId]() returns http:Ok|http:NotFound {
        if !institutionStore.hasKey(institutionId) {
            return <http:NotFound>{body: {message: "Institution " + institutionId + " not found."}};
        }
        _ = institutionStore.remove(institutionId);
        return <http:Ok>{body: {message: "Institution " + institutionId + " deleted."}};
    }
}