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
import ballerinax/googleapis.sheets as sheets;

import people.database;

# Rewrite all confirmed parking reservations of a booking date into the Google Sheet, read fresh from the database.
#
# Each call writes the whole day's list, in confirmation order, from the first reservation row down. This replaces
# appending to the next empty row, which let two concurrent confirmations land on the same row and overwrite one.
# Concurrent calls, including from other replicas, need no lock: the confirmed list only grows and its order never
# changes, so a write based on an older read only repeats rows that are already correct and leaves the newer rows
# below it untouched. For the same reason, rows below the list are deliberately never cleared.
#
# + bookingDate - Booking date (YYYY-MM-DD) whose reservations to write
# + return - () on success, error if reading the reservations or writing the sheet failed
public isolated function syncParkingReservations(string bookingDate) returns error? {
    database:ParkingReservationDetails[] reservations =
        check database:getConfirmedParkingReservationsByDate(bookingDate);
    if reservations.length() == 0 {
        return;
    }

    // Columns: Booking Date | Employee Email | Vehicle Number | Slot Id | Floor
    string[][] rows = from database:ParkingReservationDetails reservation in reservations
        select [
            reservation.bookingDate,
            reservation.employeeEmail,
            reservation.vehicleRegistrationNumber,
            reservation.slotId,
            reservation.floorName
        ];

    int lastRow = PARKING_SHEET_FIRST_RESERVATION_ROW + rows.length() - 1;
    sheets:Range range = {a1Notation: string `A${PARKING_SHEET_FIRST_RESERVATION_ROW}:E${lastRow}`, values: rows};
    return parkingSpreadsheetClient->setRange(parkingSheetConfig.sheetId, parkingSheetConfig.sheetName, range);
}

