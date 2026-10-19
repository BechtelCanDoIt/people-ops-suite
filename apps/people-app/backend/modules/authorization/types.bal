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

# User info custom type for Asgardeo token.
public type CustomJwtPayload record {
    # User email 
    string email;
    # User groups
    string[] groups;
};

# Service-to-service callers allowed to read the employee directory.
#
# A service calls through the gateway with OAuth2 client credentials, so its gateway JWT names the calling
# application but carries no user `email` or `groups`. Such a token is admitted only when its client id is
# listed here, and only for `GET /employees/basic-info`.
public type ServiceClientConfig record {|
    # JWT claim holding the calling application's client id. Check a real gateway token for the claim name
    # before relying on the default.
    string clientIdClaim = "azp";
    # Client ids allowed to read the directory. Empty = no service callers (the behaviour before this change).
    string[] directoryClientIds = [];
|};

# Application specific role mapping.
public type AppRoles record {|
    # Role for the employee
    string EMPLOYEE_ROLE;
    # Role for the admin
    string ADMIN_ROLE;
    # Role for the service desk
    string SERVICE_DESK_ROLE;
    # Role granting read-only access to employee profiles and employee reports
    string EMPLOYEE_VIEW_ROLE;
    # Role granting employee-view access plus the ability to record a resignation
    string RESIGNATION_ROLE;
    # Role granting access to the QR code report only
    string QR_EXPORT_ROLE;
    # Roles for the external users(for vehicle saving purpose)
    string[] EXTERNAL_USER_ROLES = [];
|};
