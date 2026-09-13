import ballerina/grpc;
import ballerina/protobuf;

public const string RENTAL_DESC = "0A1270726F746F2F72656E74616C2E70726F746F120672656E74616C22DA010A124E657750726F70657274795265717565737412170A07686F73745F69641801200128095206686F7374496412120A046E616D6518022001280952046E616D65121A0A086C6F636174696F6E18032001280952086C6F636174696F6E12230A0D70726F70657274795F74797065180420012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180520012801520D70726963655065724E69676874122E0A0673746174757318062001280E32162E72656E74616C2E50726F7065727479537461747573520673746174757322F1010A0850726F7065727479121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A07686F73745F69641802200128095206686F7374496412120A046E616D6518032001280952046E616D65121A0A086C6F636174696F6E18042001280952086C6F636174696F6E12230A0D70726F70657274795F74797065180520012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180620012801520D70726963655065724E69676874122E0A0673746174757318072001280E32162E72656E74616C2E50726F7065727479537461747573520673746174757322C5020A1555706461746550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A046E616D65180220012809480052046E616D65880101121F0A086C6F636174696F6E180320012809480152086C6F636174696F6E88010112280A0D70726F70657274795F747970651804200128094802520C70726F706572747954797065880101122B0A0F70726963655F7065725F6E696768741805200128014803520D70726963655065724E6967687488010112330A0673746174757318062001280E32162E72656E74616C2E50726F70657274795374617475734804520673746174757388010142070A055F6E616D65420B0A095F6C6F636174696F6E42100A0E5F70726F70657274795F7479706542120A105F70726963655F7065725F6E6967687442090A075F73746174757322380A1552656D6F766550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F70657274794964224A0A1652656D6F766550726F7065727479526573706F6E736512300A0A70726F7065727469657318012003280B32102E72656E74616C2E50726F7065727479520A70726F7065727469657322380A1553656172636850726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F706572747949642288010A1653656172636850726F7065727479526573706F6E736512140A05666F756E641801200128085205666F756E6412310A0870726F706572747918022001280B32102E72656E74616C2E50726F70657274794800520870726F706572747988010112180A076D65737361676518032001280952076D657373616765420B0A095F70726F706572747922A5010A154C69737450726F7065727469657352657175657374121F0A086C6F636174696F6E180120012809480052086C6F636174696F6E88010112200A096D696E5F7072696365180220012801480152086D696E507269636588010112200A096D61785F7072696365180320012801480252086D61785072696365880101420B0A095F6C6F636174696F6E420C0A0A5F6D696E5F7072696365420C0A0A5F6D61785F707269636522600A0E4E6577557365725265717565737412120A046E616D6518012001280952046E616D6512140A05656D61696C1802200128095205656D61696C12240A04726F6C6518032001280E32102E72656E74616C2E55736572526F6C655204726F6C65226F0A045573657212170A07757365725F6964180120012809520675736572496412120A046E616D6518022001280952046E616D6512140A05656D61696C1803200128095205656D61696C12240A04726F6C6518042001280E32102E72656E74616C2E55736572526F6C655204726F6C6522780A134372656174655573657273526573706F6E736512230A0D75736572735F63726561746564180120012805520C75736572734372656174656412220A05757365727318022003280B320C2E72656E74616C2E557365725205757365727312180A076D65737361676518032001280952076D657373616765229B010A13426F6F6B50726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412190A0867756573745F696418022001280952076775657374496412220A0D636865636B5F696E5F64617465180320012809520B636865636B496E4461746512240A0E636865636B5F6F75745F64617465180420012809520C636865636B4F75744461746522D4010A0E426F6F6B696E6752657175657374121D0A0A726571756573745F69641801200128095209726571756573744964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496412190A0867756573745F696418032001280952076775657374496412220A0D636865636B5F696E5F64617465180420012809520B636865636B496E4461746512240A0E636865636B5F6F75745F64617465180520012809520C636865636B4F757444617465121D0A0A637265617465645F61741806200128035209637265617465644174227F0A14426F6F6B50726F7065727479526573706F6E7365121A0A0861636365707465641801200128085208616363657074656412220A0A726571756573745F69641802200128094800520972657175657374496488010112180A076D65737361676518032001280952076D657373616765420D0A0B5F726571756573745F6964224F0A15436F6E6669726D426F6F6B696E6752657175657374121D0A0A726571756573745F6964180120012809520972657175657374496412170A07686F73745F69641802200128095206686F7374496422CD010A07426F6F6B696E67121D0A0A626F6F6B696E675F69641801200128095209626F6F6B696E674964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496412190A0867756573745F696418032001280952076775657374496412220A0D636865636B5F696E5F64617465180420012809520B636865636B496E4461746512240A0E636865636B5F6F75745F64617465180520012809520C636865636B4F757444617465121D0A0A746F74616C5F636F73741806200128015209746F74616C436F73742288010A16436F6E6669726D426F6F6B696E67526573706F6E736512180A0773756363657373180120012808520773756363657373122E0A07626F6F6B696E6718022001280B320F2E72656E74616C2E426F6F6B696E6748005207626F6F6B696E6788010112180A076D65737361676518032001280952076D657373616765420A0A085F626F6F6B696E672A410A0E50726F7065727479537461747573120F0A0B554E5350454349464945441000120D0A09415641494C41424C451001120F0A0B554E415641494C41424C4510022A350A0855736572526F6C6512140A10524F4C455F554E535045434946494544100012080A04484F5354100112090A054755455354100232EA040A0D52656E74616C53657276696365123C0A0C6164645F70726F7065727479121A2E72656E74616C2E4E657750726F7065727479526571756573741A102E72656E74616C2E50726F706572747912420A0F7570646174655F70726F7065727479121D2E72656E74616C2E55706461746550726F7065727479526571756573741A102E72656E74616C2E50726F706572747912500A0F72656D6F76655F70726F7065727479121D2E72656E74616C2E52656D6F766550726F7065727479526571756573741A1E2E72656E74616C2E52656D6F766550726F7065727479526573706F6E736512500A0F7365617263685F70726F7065727479121D2E72656E74616C2E53656172636850726F7065727479526571756573741A1E2E72656E74616C2E53656172636850726F7065727479526573706F6E7365124E0A196C6973745F617661696C61626C655F70726F70657274696573121D2E72656E74616C2E4C69737450726F70657274696573526571756573741A102E72656E74616C2E50726F7065727479300112450A0C6372656174655F757365727312162E72656E74616C2E4E657755736572526571756573741A1B2E72656E74616C2E4372656174655573657273526573706F6E73652801124A0A0D626F6F6B5F70726F7065727479121B2E72656E74616C2E426F6F6B50726F7065727479526571756573741A1C2E72656E74616C2E426F6F6B50726F7065727479526573706F6E736512500A0F636F6E6669726D5F626F6F6B696E67121D2E72656E74616C2E436F6E6669726D426F6F6B696E67526571756573741A1E2E72656E74616C2E436F6E6669726D426F6F6B696E67526573706F6E7365620670726F746F33";

public isolated client class RentalServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, RENTAL_DESC);
    }

    isolated remote function add_property(NewPropertyRequest|ContextNewPropertyRequest req) returns Property|grpc:Error {
        map<string|string[]> headers = {};
        NewPropertyRequest message;
        if req is ContextNewPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/add_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <Property>result;
    }

    isolated remote function add_propertyContext(NewPropertyRequest|ContextNewPropertyRequest req) returns ContextProperty|grpc:Error {
        map<string|string[]> headers = {};
        NewPropertyRequest message;
        if req is ContextNewPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/add_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <Property>result, headers: respHeaders};
    }

    isolated remote function update_property(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns Property|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/update_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <Property>result;
    }

    isolated remote function update_propertyContext(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns ContextProperty|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/update_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <Property>result, headers: respHeaders};
    }

    isolated remote function remove_property(RemovePropertyRequest|ContextRemovePropertyRequest req) returns RemovePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/remove_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <RemovePropertyResponse>result;
    }

    isolated remote function remove_propertyContext(RemovePropertyRequest|ContextRemovePropertyRequest req) returns ContextRemovePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/remove_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <RemovePropertyResponse>result, headers: respHeaders};
    }

    isolated remote function search_property(SearchPropertyRequest|ContextSearchPropertyRequest req) returns SearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/search_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SearchPropertyResponse>result;
    }

    isolated remote function search_propertyContext(SearchPropertyRequest|ContextSearchPropertyRequest req) returns ContextSearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/search_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SearchPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function book_property(BookPropertyRequest|ContextBookPropertyRequest req) returns BookPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/book_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookPropertyResponse>result;
    }

    isolated remote function book_propertyContext(BookPropertyRequest|ContextBookPropertyRequest req) returns ContextBookPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/book_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function confirm_booking(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ConfirmBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirm_booking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <ConfirmBookingResponse>result;
    }

    isolated remote function confirm_bookingContext(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ContextConfirmBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirm_booking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <ConfirmBookingResponse>result, headers: respHeaders};
    }

    isolated remote function create_users() returns Create_usersStreamingClient|grpc:Error {
        grpc:StreamingClient sClient = check self.grpcClient->executeClientStreaming("rental.RentalService/create_users");
        return new Create_usersStreamingClient(sClient);
    }

    isolated remote function list_available_properties(ListPropertiesRequest|ContextListPropertiesRequest req) returns stream<Property, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListPropertiesRequest message;
        if req is ContextListPropertiesRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/list_available_properties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return new stream<Property, grpc:Error?>(outputStream);
    }

    isolated remote function list_available_propertiesContext(ListPropertiesRequest|ContextListPropertiesRequest req) returns ContextPropertyStream|grpc:Error {
        map<string|string[]> headers = {};
        ListPropertiesRequest message;
        if req is ContextListPropertiesRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/list_available_properties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return {content: new stream<Property, grpc:Error?>(outputStream), headers: respHeaders};
    }
}

public isolated client class Create_usersStreamingClient {
    private final grpc:StreamingClient sClient;

    isolated function init(grpc:StreamingClient sClient) {
        self.sClient = sClient;
    }

    isolated remote function sendNewUserRequest(NewUserRequest message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function sendContextNewUserRequest(ContextNewUserRequest message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function receiveCreateUsersResponse() returns CreateUsersResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, _] = response;
            return <CreateUsersResponse>payload;
        }
    }

    isolated remote function receiveContextCreateUsersResponse() returns ContextCreateUsersResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, headers] = response;
            return {content: <CreateUsersResponse>payload, headers: headers};
        }
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.sClient->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.sClient->complete();
    }
}

public class PropertyStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|Property value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|Property value;|} nextRecord = {value: <Property>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public isolated client class RentalServiceSearchPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSearchPropertyResponse(SearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSearchPropertyResponse(ContextSearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceCreateUsersResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendCreateUsersResponse(CreateUsersResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextCreateUsersResponse(ContextCreateUsersResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceRemovePropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendRemovePropertyResponse(RemovePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextRemovePropertyResponse(ContextRemovePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceConfirmBookingResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendConfirmBookingResponse(ConfirmBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextConfirmBookingResponse(ContextConfirmBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServicePropertyCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendProperty(Property response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextProperty(ContextProperty response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceBookPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBookPropertyResponse(BookPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBookPropertyResponse(ContextBookPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public type ContextNewUserRequestStream record {|
    stream<NewUserRequest, error?> content;
    map<string|string[]> headers;
|};

public type ContextPropertyStream record {|
    stream<Property, error?> content;
    map<string|string[]> headers;
|};

public type ContextBookPropertyRequest record {|
    BookPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextListPropertiesRequest record {|
    ListPropertiesRequest content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyRequest record {|
    UpdatePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyResponse record {|
    SearchPropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingRequest record {|
    ConfirmBookingRequest content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingResponse record {|
    ConfirmBookingResponse content;
    map<string|string[]> headers;
|};

public type ContextNewPropertyRequest record {|
    NewPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyRequest record {|
    RemovePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextNewUserRequest record {|
    NewUserRequest content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyResponse record {|
    RemovePropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyRequest record {|
    SearchPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextCreateUsersResponse record {|
    CreateUsersResponse content;
    map<string|string[]> headers;
|};

public type ContextProperty record {|
    Property content;
    map<string|string[]> headers;
|};

public type ContextBookPropertyResponse record {|
    BookPropertyResponse content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookPropertyRequest record {|
    string property_id = "";
    string guest_id = "";
    string check_in_date = "";
    string check_out_date = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ListPropertiesRequest record {|
    string location?;
    float max_price?;
    float min_price?;
|};

isolated function isValidListpropertiesrequest(ListPropertiesRequest r) returns boolean {
    int _locationCount = 0;
    if r?.location !is () {
        _locationCount += 1;
    }
    int _max_priceCount = 0;
    if r?.max_price !is () {
        _max_priceCount += 1;
    }
    int _min_priceCount = 0;
    if r?.min_price !is () {
        _min_priceCount += 1;
    }
    if _locationCount > 1 || _max_priceCount > 1 || _min_priceCount > 1 {
        return false;
    }
    return true;
}

isolated function setListPropertiesRequest_Location(ListPropertiesRequest r, string location) {
    r.location = location;
}

isolated function setListPropertiesRequest_MaxPrice(ListPropertiesRequest r, float max_price) {
    r.max_price = max_price;
}

isolated function setListPropertiesRequest_MinPrice(ListPropertiesRequest r, float min_price) {
    r.min_price = min_price;
}

@protobuf:Descriptor {value: RENTAL_DESC}
public type User record {|
    string user_id = "";
    string name = "";
    string email = "";
    UserRole role = ROLE_UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UpdatePropertyRequest record {|
    string property_id = "";
    string location?;
    string name?;
    float price_per_night?;
    PropertyStatus status?;
    string property_type?;
|};

isolated function isValidUpdatepropertyrequest(UpdatePropertyRequest r) returns boolean {
    int _locationCount = 0;
    if r?.location !is () {
        _locationCount += 1;
    }
    int _nameCount = 0;
    if r?.name !is () {
        _nameCount += 1;
    }
    int _price_per_nightCount = 0;
    if r?.price_per_night !is () {
        _price_per_nightCount += 1;
    }
    int _statusCount = 0;
    if r?.status !is () {
        _statusCount += 1;
    }
    int _property_typeCount = 0;
    if r?.property_type !is () {
        _property_typeCount += 1;
    }
    if _locationCount > 1 || _nameCount > 1 || _price_per_nightCount > 1 || _statusCount > 1 || _property_typeCount > 1 {
        return false;
    }
    return true;
}

isolated function setUpdatePropertyRequest_Location(UpdatePropertyRequest r, string location) {
    r.location = location;
}

isolated function setUpdatePropertyRequest_Name(UpdatePropertyRequest r, string name) {
    r.name = name;
}

isolated function setUpdatePropertyRequest_PricePerNight(UpdatePropertyRequest r, float price_per_night) {
    r.price_per_night = price_per_night;
}

isolated function setUpdatePropertyRequest_Status(UpdatePropertyRequest r, PropertyStatus status) {
    r.status = status;
}

isolated function setUpdatePropertyRequest_PropertyType(UpdatePropertyRequest r, string property_type) {
    r.property_type = property_type;
}

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchPropertyResponse record {|
    boolean found = false;
    string message = "";
    Property property?;
|};

isolated function isValidSearchpropertyresponse(SearchPropertyResponse r) returns boolean {
    int _propertyCount = 0;
    if r?.property !is () {
        _propertyCount += 1;
    }
    if _propertyCount > 1 {
        return false;
    }
    return true;
}

isolated function setSearchPropertyResponse_Property(SearchPropertyResponse r, Property property) {
    r.property = property;
}

@protobuf:Descriptor {value: RENTAL_DESC}
public type Booking record {|
    string booking_id = "";
    string property_id = "";
    string guest_id = "";
    string check_in_date = "";
    string check_out_date = "";
    float total_cost = 0.0;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ConfirmBookingRequest record {|
    string request_id = "";
    string host_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ConfirmBookingResponse record {|
    boolean success = false;
    string message = "";
    Booking booking?;
|};

isolated function isValidConfirmbookingresponse(ConfirmBookingResponse r) returns boolean {
    int _bookingCount = 0;
    if r?.booking !is () {
        _bookingCount += 1;
    }
    if _bookingCount > 1 {
        return false;
    }
    return true;
}

isolated function setConfirmBookingResponse_Booking(ConfirmBookingResponse r, Booking booking) {
    r.booking = booking;
}

@protobuf:Descriptor {value: RENTAL_DESC}
public type NewPropertyRequest record {|
    string host_id = "";
    string name = "";
    string location = "";
    string property_type = "";
    float price_per_night = 0.0;
    PropertyStatus status = UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookingRequest record {|
    string request_id = "";
    string property_id = "";
    string guest_id = "";
    string check_in_date = "";
    string check_out_date = "";
    int created_at = 0;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemovePropertyRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type NewUserRequest record {|
    string name = "";
    string email = "";
    UserRole role = ROLE_UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemovePropertyResponse record {|
    Property[] properties = [];
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchPropertyRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type CreateUsersResponse record {|
    int users_created = 0;
    User[] users = [];
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type Property record {|
    string property_id = "";
    string host_id = "";
    string name = "";
    string location = "";
    string property_type = "";
    float price_per_night = 0.0;
    PropertyStatus status = UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookPropertyResponse record {|
    boolean accepted = false;
    string message = "";
    string request_id?;
|};

isolated function isValidBookpropertyresponse(BookPropertyResponse r) returns boolean {
    int _request_idCount = 0;
    if r?.request_id !is () {
        _request_idCount += 1;
    }
    if _request_idCount > 1 {
        return false;
    }
    return true;
}

isolated function setBookPropertyResponse_RequestId(BookPropertyResponse r, string request_id) {
    r.request_id = request_id;
}

public enum PropertyStatus {
    UNSPECIFIED, AVAILABLE, UNAVAILABLE
}

public enum UserRole {
    ROLE_UNSPECIFIED, HOST, GUEST
}
