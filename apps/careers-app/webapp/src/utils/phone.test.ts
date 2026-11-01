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

import { describe, expect, it } from "vitest";

import { COUNTRY_OPTIONS, isValidE164, phoneFrom, toE164 } from "@utils/phone";

describe("toE164", () => {
  it("puts the dialing code in front of the digits", () => {
    expect(toE164("+94", "771234567")).toBe("+94771234567");
  });

  it("drops a leading trunk zero", () => {
    expect(toE164("+94", "0771234567")).toBe("+94771234567");
    expect(toE164("+94", "00771234567")).toBe("+94771234567");
  });

  it("removes spaces, dashes and brackets", () => {
    expect(toE164("+94", "(077) 123-4567")).toBe("+94771234567");
    expect(toE164("+1", "415 555 0100")).toBe("+14155550100");
  });

  it("matches the pattern the backend accepts", () => {
    expect(toE164("+94", "0771234567")).toMatch(/^\+[1-9]\d{1,14}$/);
  });
});

describe("phoneFrom", () => {
  it("joins the dialing code of the chosen country and the digits", () => {
    expect(phoneFrom("US", "2025550123")).toBe("+12025550123");
  });

  it("is empty while nothing was typed", () => {
    expect(phoneFrom("US", "")).toBe("");
    expect(phoneFrom("", "")).toBe("");
  });

  it("keeps digits typed before a country is chosen, so they fail the check instead of vanishing", () => {
    const typed = phoneFrom("", "2025550123");
    expect(typed).toBe("2025550123");
    expect(isValidE164(typed)).toBe(false);
  });
});

describe("COUNTRY_OPTIONS", () => {
  it("gives every country an ISO code, a name and a dialing code", () => {
    expect(COUNTRY_OPTIONS.length).toBeGreaterThan(200);
    for (const option of COUNTRY_OPTIONS) {
      expect(option.iso).toMatch(/^[A-Z]{2}$/);
      expect(option.name.length).toBeGreaterThan(0);
      expect(option.dialCode).toMatch(/^\+\d{1,4}$/);
    }
  });

  it("keeps countries that share a dialing code as separate entries", () => {
    const withPlusOne = COUNTRY_OPTIONS.filter((option) => option.dialCode === "+1");
    expect(withPlusOne.length).toBeGreaterThan(1);
  });

  it("includes Sri Lanka with +94", () => {
    const sriLanka = COUNTRY_OPTIONS.find((option) => option.iso === "LK");
    expect(sriLanka?.dialCode).toBe("+94");
  });

  it("is sorted by country name", () => {
    const names = COUNTRY_OPTIONS.map((option) => option.name);
    expect(names).toEqual([...names].sort((a, b) => a.localeCompare(b)));
  });
});
