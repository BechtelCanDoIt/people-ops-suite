// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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

const CTX_CORS_ORIGIN = "careers-app-cors-origin";

# Whether the origin is one of the allowed development origins.
isolated function isDevOrigin(string[] allowedOrigins, string origin) returns boolean {
    foreach string allowed in allowedOrigins {
        if allowed == origin {
            return true;
        }
    }
    return false;
}

# Allows the web app running on a development origin to call the service from the browser, answering its preflight
# requests. It is installed only when development origins are configured; deployed services rely on the gateway.
public isolated service class DevCorsRequestInterceptor {
    *http:RequestInterceptor;

    private final readonly & string[] allowedOrigins;

    public isolated function init(string[] allowedOrigins) {
        self.allowedOrigins = allowedOrigins.cloneReadOnly();
    }

    isolated resource function 'default [string... path](http:RequestContext ctx, http:Request req)
            returns http:NextService|http:Response|error? {
        string|http:HeaderNotFoundError origin = req.getHeader("Origin");
        if origin is http:HeaderNotFoundError || !isDevOrigin(self.allowedOrigins, origin) {
            return ctx.next();
        }
        if req.method == http:OPTIONS {
            http:Response preflight = new;
            preflight.statusCode = http:STATUS_NO_CONTENT;
            preflight.setHeader("Access-Control-Allow-Origin", origin);
            preflight.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, OPTIONS");
            preflight.setHeader("Access-Control-Allow-Headers", string `Content-Type, Authorization, ${REQUEST_ID_HEADER}`);
            preflight.setHeader("Access-Control-Max-Age", "84900");
            preflight.setHeader("Vary", "Origin");
            return preflight;
        }
        ctx.set(CTX_CORS_ORIGIN, origin);
        return ctx.next();
    }
}

# Adds the allowed origin to the responses of a request that came from a development origin.
public isolated service class DevCorsResponseInterceptor {
    *http:ResponseInterceptor;

    isolated remote function interceptResponse(http:RequestContext ctx, http:Response res)
            returns http:NextService|error? {
        if ctx.hasKey(CTX_CORS_ORIGIN) {
            string|error origin = ctx.getWithType(CTX_CORS_ORIGIN);
            if origin is string {
                res.setHeader("Access-Control-Allow-Origin", origin);
                res.setHeader("Vary", "Origin");
            }
        }
        return ctx.next();
    }
}
