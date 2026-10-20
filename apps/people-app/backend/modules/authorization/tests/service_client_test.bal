// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License. 

// JwtInterceptor with service clients: an allowed client reads GET /employees/basic-info and nothing else;
// unknown clients and user tokens behave exactly as before.

import ballerina/http;
import ballerina/test;

const int TEST_PORT = 19190;

service http:InterceptableService / on new http:Listener(TEST_PORT) {

    public function createInterceptors() returns http:Interceptor[] => [new JwtInterceptor()];

    resource function get employees/basic\-info(http:RequestContext ctx) returns json {
        string|error serviceClient = ctx.getWithType(HEADER_SERVICE_CLIENT);
        CustomJwtPayload|error userInfo = ctx.getWithType(HEADER_USER_INFO);
        return {
            serviceClient: serviceClient is string ? serviceClient : (),
            user: userInfo is CustomJwtPayload ? userInfo.email : ()
        };
    }

    resource function post employees/basic\-info() returns json => {wrote: true};

    resource function get employees/[string employeeId]() returns json => {employeeId};

    resource function get employees/[string employeeEmail]/vehicles() returns json => {employeeEmail};
}

final http:Client testClient = check new (string `http://localhost:${TEST_PORT}`);

# An unsigned JWT: the interceptor only decodes (the gateway verifies), so the signature is never read.
function token(map<json> claims) returns string {
    string header = {alg: "RS256", typ: "JWT"}.toJsonString().toBytes().toBase64();
    string payload = claims.toJsonString().toBytes().toBase64();
    return string `${base64Url(header)}.${base64Url(payload)}.c2ln`;
}

function base64Url(string b64) returns string =>
    re `=+$`.replace(re `/`.replaceAll(re `\+`.replaceAll(b64, "-"), "_"), "");

function call(string method, string path, map<json> claims) returns http:Response|error {
    map<string> headers = {[JWT_ASSERTION_HEADER]: token(claims)};
    if method == "POST" {
        return testClient->post(path, {}, headers);
    }
    return testClient->get(path, headers);
}

@test:Config
function allowedServiceClientReadsTheDirectory() returns error? {
    http:Response res = check call("GET", "/employees/basic-info", {azp: "amplify-api-client", aut: "APPLICATION", sub: "amplify"});
    test:assertEquals(res.statusCode, 200);
    json body = check res.getJsonPayload();
    test:assertEquals(check body.serviceClient, "amplify-api-client");
    test:assertEquals(check body.user, (), "a service caller is never treated as a user");
}

@test:Config
function allowedServiceClientIsLimitedToTheDirectory() returns error? {
    map<json> amplify = {azp: "amplify-api-client", aut: "APPLICATION"};
    test:assertEquals((check call("GET", "/employees/E1", amplify)).statusCode, 403, "no single employee record");
    test:assertEquals((check call("GET", "/employees/a@wso2.com/vehicles", amplify)).statusCode, 403);
    test:assertEquals((check call("POST", "/employees/basic-info", amplify)).statusCode, 403, "read only");
}

@test:Config
function unknownServiceClientIsRefusedAsBefore() returns error? {
    // Not listed: falls through to the user path, which can't read a user from it (unchanged behaviour).
    http:Response res = check call("GET", "/employees/basic-info", {azp: "someone-else", aut: "APPLICATION"});
    test:assertEquals(res.statusCode, 500);
    http:Response blank = check call("GET", "/employees/basic-info", {azp: "  ", aut: "APPLICATION"});
    test:assertEquals(blank.statusCode, 500);
}

@test:Config
function userTokensAreUnchanged() returns error? {
    http:Response employee = check call("GET", "/employees/basic-info",
            {email: "ada@wso2.com", groups: ["people-employee"]});
    test:assertEquals(employee.statusCode, 200);
    json body = check employee.getJsonPayload();
    test:assertEquals(check body.user, "ada@wso2.com");
    test:assertEquals(check body.serviceClient, ());

    http:Response noGroup = check call("GET", "/employees/basic-info", {email: "ada@wso2.com", groups: []});
    test:assertEquals(noGroup.statusCode, 403);
}

@test:Config
function userTokenWithAListedClientIdStaysAUser() returns error? {
    // A user signed in through an app whose id happens to be listed still goes through the role check.
    http:Response res = check call("GET", "/employees/E1",
            {email: "ada@wso2.com", groups: [], azp: "amplify-api-client"});
    test:assertEquals(res.statusCode, 403);
}

@test:Config
function emailLessUserThroughAListedAppIsNotAService() returns error? {
    // A person (or a service account) with no email, signed in through the listed app, carries its azp but
    // isn't an application token: it never reaches the directory as a service.
    http:Response appUser = check call("GET", "/employees/basic-info",
            {azp: "amplify-api-client", aut: "APPLICATION_USER", sub: "someone"});
    test:assertEquals(appUser.statusCode, 500, "falls through to the user path, which can't read a user");
    http:Response noMarker = check call("GET", "/employees/basic-info", {azp: "amplify-api-client"});
    test:assertEquals(noMarker.statusCode, 500);
    http:Response withGroups = check call("GET", "/employees/basic-info",
            {azp: "amplify-api-client", aut: "APPLICATION", groups: []});
    test:assertEquals(withGroups.statusCode, 500, "a token with groups is a user token, never a service");
}

@test:Config
function serviceRouteMatchesSegmentsExactly() returns error? {
    map<json> amplify = {azp: "amplify-api-client", aut: "APPLICATION"};
    test:assertEquals((check call("GET", "/employees%2Fbasic-info", amplify)).statusCode, 403,
            "an encoded slash is one segment, not the directory route");
    test:assertEquals((check call("GET", "/employees/basic-info/extra", amplify)).statusCode, 403);
}

