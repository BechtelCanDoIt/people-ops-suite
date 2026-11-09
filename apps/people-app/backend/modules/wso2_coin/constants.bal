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

# Google Sheet retry configuration for max retry attempts.
const int GSHEET_CONFIG_RETRY_COUNT = 3;

# Google Sheet retry configuration for wait interval in seconds.
const decimal GSHEET_CONFIG_RETRY_INTERVAL = 3.0;

# First parking sheet row that holds a reservation; row 1 is the header restored by the daily reset script.
const int PARKING_SHEET_FIRST_RESERVATION_ROW = 2;

# Required scheme for the transaction endpoint so forwarded assertions stay encrypted in transit.
const HTTPS_SCHEME = "https://";

# Header used to forward the end-user assertion to the payment service.
const USER_ASSERTION_HEADER = "X-User-Assertion";

# Originating feature reported to the payment service for car park payments.
const PARKING_PAYMENT_SOURCE = "PARKING";

# Reference prefix for car park payments.
public const PARKING_PAYMENT_REFERENCE_PREFIX = "parking-";

# Generic message used when the payment service rejects a payment without a specific reason.
const PAYMENT_REJECTED_MESSAGE = "Payment could not be completed.";

# Master wallet address for car park O2C payments.
public configurable string masterWalletAddress = ?;

# Reservation start hour in Sri Lanka time.
public configurable int reservationWindowStartHour = 5;

# Reservation end hour in Sri Lanka time.
public configurable int reservationWindowEndHour = 7;

# Expiry time (in minutes) for stale PENDING parking reservations.
public configurable int pendingReservationExpiryMinutes = 15;
