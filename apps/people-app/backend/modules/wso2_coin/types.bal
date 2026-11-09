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

# [Configurable] Google sheet OAuth2 application configuration for parking reservations.
public type ParkingSheetConfig record {|
    # OAuth2 token endpoint.
    string tokenUrl;
    # OAuth 2 refresh token.
    string refreshToken;
    # OAuth2 client ID.
    string clientId;
    # OAuth2 client secret.
    string clientSecret;
    # Sheet ID.
    string sheetId;
    # Sheet name (tab) to write reservations to.
    string sheetName;
|};

# OAuth2 client auth configurations.
public type ClientAuthConfig record {|
    # Token URL
    string tokenUrl;
    # Client Id
    string clientId;
    # Client Secret
    string clientSecret;
    # OAuth2 scopes to request for the transaction-service token
    string[] scopes = [];
|};

# Wallet owned by the caller, as returned by the payment service.
public type WalletDetails record {
    # Wallet address.
    string walletAddress;
    # Current balance in coins (decimal serialized as a string, matching the transaction service).
    string balance;
    # Whether this is the caller's default wallet.
    boolean defaultWallet;
};

# Request body sent to the payment service to collect a payment.
public type CollectPaymentRequest record {|
    # Payer wallet address.
    string fromAddress;
    # Payee wallet address.
    string toAddress;
    # Amount to collect in coins (decimal serialized as a string, matching the transaction service).
    string amount;
    # Idempotency reference for the payment.
    string reference;
    # Originating feature of the payment.
    string 'source;
|};

# Response returned by the payment service on a successful collection.
public type CollectPaymentResponse record {
    # Idempotency reference for the payment.
    string reference;
    # Payer wallet address.
    string fromAddress;
    # Payee wallet address.
    string toAddress;
    # Amount collected in coins (decimal serialized as a string, matching the transaction service).
    string amount;
};

# Detail carried by a payment rejection from the payment service.
public type PaymentErrorDetail record {|
    # HTTP status code returned by the payment service.
    int statusCode;
    # Human-readable reason surfaced by the payment service.
    string reason;
|};

# Raised when the payment service rejects a payment (non-2xx response).
public type PaymentError distinct error<PaymentErrorDetail>;
