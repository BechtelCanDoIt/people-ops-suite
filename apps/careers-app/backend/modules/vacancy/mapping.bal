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

import wso2/careers_app.types;

// The status the web app shows for an ATS interview status.
isolated function interviewStatusOf(string atsStatus) returns string {
    match atsStatus {
        "COMPLETED" => {
            return "Completed";
        }
        "WITHDRAWN" => {
            return "Cancelled";
        }
    }
    return "Upcoming";
}

// The place of a physical interview: the custom location when there is one, otherwise the room and the floor.
isolated function physicalPlaceOf(AtsInterview interview) returns string {
    string? custom = interview.customLocation;
    if custom is string && custom.trim() != "" {
        return custom.trim();
    }
    string[] parts = [];
    string? room = interview.roomName;
    if room is string && room.trim() != "" {
        parts.push(room.trim());
    }
    string? floor = interview.floorNumber;
    if floor is string && floor.trim() != "" {
        parts.push(string `floor ${floor.trim()}`);
    }
    return string:'join(", ", ...parts);
}

// An interview in the shape the web app reads. Nothing but the fields it shows is passed on.
isolated function interviewOf(AtsInterview interview) returns ApplicationInterview {
    boolean isVirtual = interview.interviewModality == "Virtual";
    string? link = interview.meetingUrl;
    string? stage = interview.interviewStage;
    string? title = interview.title;
    string round = stage is string && stage.trim() != "" ? stage.trim()
        : title is string && title.trim() != "" ? title.trim() : "Interview";
    return {
        id: interview.id.toString(),
        round,
        dateTime: interview.startTime ?: "",
        mode: isVirtual ? "Video" : "Onsite",
        location: isVirtual ? (link is string ? link.trim() : "") : physicalPlaceOf(interview),
        status: interviewStatusOf(interview.status)
    };
}

// The interviews of an application in the order they take place.
isolated function interviewsOf(AtsInterview[] interviews) returns ApplicationInterview[] =>
    from AtsInterview interview in interviews
    let ApplicationInterview shown = interviewOf(interview)
    order by shown.dateTime ascending
    select shown;

// The status the web app shows for an ATS candidate status.
isolated function applicationStatusOf(string atsStatus) returns string {
    match atsStatus {
        "SHORTLISTED" => {
            return "Screening";
        }
        "INTERVIEW_IN_PROGRESS"|"INTERVIEW_COMPLETED" => {
            return "Interview";
        }
        "HIRED" => {
            return "Offer Accepted";
        }
        "REJECTED"|"NOT_SHORTLISTED" => {
            return "Rejected";
        }
    }
    return "Applied";
}

// The candidate's applications, newest first, without the ones that were deleted.
isolated function applicationsOf(AtsHistoryEntry[] history) returns ApplicationSummary[] =>
    from AtsHistoryEntry entry in history
    where entry.status != CANDIDATE_STATUS_DELETED
    order by entry.id descending
    select {
        id: entry.id.toString(),
        jobId: entry.vacancyId.toString(),
        jobTitle: entry.vacancyTitle ?: "",
        appliedDate: entry.createdOn ?: "",
        updatedDate: entry.updatedOn ?: entry.createdOn ?: "",
        status: applicationStatusOf(entry.status)
    };

// The candidate's most recent application that was not deleted.
isolated function latestEntry(AtsHistoryEntry[] history) returns AtsHistoryEntry? {
    AtsHistoryEntry[] latest = from AtsHistoryEntry entry in history
        where entry.status != CANDIDATE_STATUS_DELETED
        order by entry.id descending
        limit 1
        select entry;
    return latest.length() == 0 ? () : latest[0];
}

// The candidate's details from their most recent application.
isolated function profileOf(AtsHistoryEntry[] history, string email) returns CandidateProfile? {
    AtsHistoryEntry? entry = latestEntry(history);
    if entry is () {
        return ();
    }
    string? address = entry.address;
    return {
        firstName: entry.firstName ?: "",
        lastName: entry.lastName ?: "",
        gender: entry.gender ?: "",
        personalEmail: email,
        contactNo: entry.contactNo ?: "",
        address: address is string && address.trim() != "" && address != ADDRESS_NOT_APPLICABLE ? address : (),
        university: entry.university
    };
}

// The changes in the form the ATS takes, or the reason they cannot be accepted.
isolated function atsUpdateOf(ProfileChanges changes) returns AtsCandidateUpdate|string {
    AtsCandidateUpdate update = {};
    string? firstName = changes?.firstName;
    if firstName is string {
        if firstName.trim() == "" {
            return "Enter your first name.";
        }
        if firstName.trim().length() > MAX_NAME_LENGTH {
            return DETAIL_TOO_LONG_MESSAGE;
        }
        update.firstName = firstName.trim();
    }
    string? lastName = changes?.lastName;
    if lastName is string {
        if lastName.trim() == "" {
            return "Enter your last name.";
        }
        if lastName.trim().length() > MAX_NAME_LENGTH {
            return DETAIL_TOO_LONG_MESSAGE;
        }
        update.lastName = lastName.trim();
    }
    string? gender = changes?.gender;
    if gender is string {
        if gender !is "Male"|"Female"|"Prefer not to say" {
            return "Choose Male, Female or Prefer not to say as the gender.";
        }
        update.gender = gender;
    }
    string? contactNo = changes?.contactNo;
    if contactNo is string {
        if !types:isValidPhone(contactNo.trim()) {
            return "Enter the phone number in international format, for example +94771234567.";
        }
        update.contactNo = contactNo.trim();
    }
    if changes.hasKey("address") {
        string address = (changes?.address ?: "").trim();
        if address.length() > MAX_ADDRESS_LENGTH {
            return DETAIL_TOO_LONG_MESSAGE;
        }
        update.address = address;
    }
    if changes.hasKey("university") {
        string university = (changes?.university ?: "").trim();
        if university.length() > MAX_UNIVERSITY_LENGTH {
            return DETAIL_TOO_LONG_MESSAGE;
        }
        update.university = university;
    }
    return update;
}
