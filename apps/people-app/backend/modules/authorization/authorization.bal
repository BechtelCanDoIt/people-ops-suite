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
import ballerina/http;
import ballerina/jwt;
import ballerina/log;

public configurable AppRoles authorizedRoles = ?;
public configurable ServiceClientConfig serviceClients = {};

# To handle authorization for each resource function invocation.
public isolated service class JwtInterceptor {

    *http:RequestInterceptor;

    isolated resource function default [string... path](http:RequestContext ctx, http:Request req)
        returns http:NextService|http:Forbidden|http:InternalServerError|error? {

        string|error idToken = req.getHeader(JWT_ASSERTION_HEADER);
        if idToken is error {
            string errorMsg = "Missing invoker info header!";
            log:printError(errorMsg, idToken);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }

        [jwt:Header, jwt:Payload]|jwt:Error result = jwt:decode(idToken);
        if result is jwt:Error {
            string errorMsg = "Error while reading the Invoker info!";
            log:printError(errorMsg, result);
            return <http:InternalServerError>{body: {message: errorMsg}};
        }

        // Service callers (an application token with no user email or groups) are decided before the user
        // path below, which would otherwise reject the token as malformed.
        if isApplicationToken(result[1]) {
            string clientId = clientIdOf(result[1]);
            string route = string `${req.method} ${path.toBalString()}`;
            if !isServiceClientRoute(clientId, req.method, path) {
                log:printWarn(string `Service client ${clientId == "" ? "(no client id)" : clientId} was refused: ${route}`);
                return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
            }
            log:printInfo(string `Service client ${clientId} accessed: ${route}`);
            ctx.set(HEADER_SERVICE_CLIENT, clientId);
            return ctx.next();
        }

        CustomJwtPayload|error userInfo = result[1].cloneWithType(CustomJwtPayload);
        if userInfo is error {
            string errorMsg = "Malformed Invoker info object!";
            log:printError(errorMsg, userInfo);
            return <http:InternalServerError>{body: {message: errorMsg}};
        }

        // Internal roles are allowed on any resource (further scoped by per-resource checks in service.bal).
        string[] internalRoles = [authorizedRoles.EMPLOYEE_ROLE, authorizedRoles.ADMIN_ROLE,
            authorizedRoles.SERVICE_DESK_ROLE];
        boolean hasInternalRole = false;
        foreach string userGroup in userInfo.groups {
            if internalRoles.indexOf(userGroup) !is () {
                hasInternalRole = true;
                break;
            }
        }
        if hasInternalRole {
            ctx.set(HEADER_USER_INFO, userInfo);
            return ctx.next();
        }

        // External users are only allowed to access the vehicles resource of their own record.
        boolean hasExternalRole = false;
        foreach string userGroup in userInfo.groups {
            if authorizedRoles.EXTERNAL_USER_ROLES.indexOf(userGroup) !is () {
                hasExternalRole = true;
                break;
            }
        }
        if hasExternalRole {
            if path.length() == 3 && path[0] == "employees" && path[2] == "vehicles"
                    && (req.method == http:HTTP_GET || req.method == http:HTTP_POST) {
                ctx.set(HEADER_USER_INFO, userInfo);
                return ctx.next();
            }

            log:printWarn(string `${userInfo.email} (external user) attempted to access a restricted resource: `
                    + string `${req.method} ${path.toBalString()}`);
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        log:printError(
                string `${userInfo.email} is missing required permissions, only has ${userInfo.groups.toBalString()}`);

        return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
    }
}

# Whether the token was issued to an application rather than a person: no user `email` or `groups`, and
# `applicationClaim` equals `applicationValue`.
#
# + payload - Decoded gateway JWT payload
# + return - True for an application (client-credentials) token
isolated function isApplicationToken(jwt:Payload payload) returns boolean =>
    payload["email"] is () && payload["groups"] is () &&
    payload[serviceClients.applicationClaim] == serviceClients.applicationValue;

# The calling application's client id.
#
# + payload - Decoded gateway JWT payload
# + return - Client id, or an empty string when the token doesn't carry one
isolated function clientIdOf(jwt:Payload payload) returns string {
    anydata claim = payload[serviceClients.clientIdClaim];
    return claim is string ? claim.trim() : "";
}

# Whether a listed service client may make a request. Each entry of `clientRoutes` is `<METHOD> <path>`,
# compared segment by segment.
#
# + clientId - Calling application's client id
# + method - HTTP method
# + path - Path segments after the service base path
# + return - True when the client is listed with this route
isolated function isServiceClientRoute(string clientId, string method, string[] path) returns boolean {
    string[]? routes = serviceClients.clientRoutes[clientId];
    if routes is () {
        return false;
    }
    foreach string route in routes {
        // An encoded slash (`employees%2Fbasic-info`) arrives as one segment, so it never equals two.
        string[] parts = re ` `.split(route.trim());
        if parts.length() == 2 && parts[0] == method && isSamePath(re `/`.split(parts[1]), path) {
            return true;
        }
    }
    return false;
}

# Segment-by-segment path comparison.
#
# + expected - Segments of the allowed route
# + actual - Segments of the request path
# + return - True when both have the same segments in the same order
isolated function isSamePath(string[] expected, string[] actual) returns boolean {
    if expected.length() != actual.length() {
        return false;
    }
    foreach int i in 0 ..< expected.length() {
        if expected[i] != actual[i] {
            return false;
        }
    }
    return true;
}
