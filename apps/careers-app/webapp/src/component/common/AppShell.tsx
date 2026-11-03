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

import { Box, Button, Stack, Tooltip, Typography, useColorScheme } from "@wso2/oxygen-ui";
import { ClipboardList, LogOut, Moon, Sun, User } from "@wso2/oxygen-ui-icons-react";
import { Outlet, useLocation, useMatches, useNavigate } from "react-router-dom";

import { useEffect, useRef } from "react";

import SnackbarListener from "@component/common/SnackbarListener";
import { useAppAuthContext } from "@context/AuthContext";

import wso2LogoBlack from "@assets/images/wso2-logo-black.svg";
import wso2LogoWhite from "@assets/images/wso2-logo-white.svg";

import { State } from "@/types/types";
import { useIsDark } from "@config/brand";
import { CareersSiteUrl } from "@config/config";
import {
  applicationsFailed,
  clearUserData,
  loadApplications,
  loadProfile,
  profileFailed,
} from "@slices/careersSlice/careers";
import { RootState, useAppDispatch, useAppSelector } from "@slices/store";
import { noteForcedSignOut } from "@utils/profileService";
import { dataNeededBy } from "@utils/routeData";

// The height of the logo and the size of the word next to it, in pixels, so the two match.
const BRAND_SIZE = 22;

// The pages of this app. Jobs are found on the wso2.com careers page, so there is no link for them here.
const NAV_ITEMS: { label: string; icon: typeof ClipboardList; path: string }[] = [
  { path: "/applications", label: "Applications", icon: ClipboardList },
  { path: "/profile", label: "Profile", icon: User },
];

const AppShell = () => {
  const { setMode } = useColorScheme();
  const isDark = useIsDark();
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useAppDispatch();
  const { getToken: getAccessToken, isSignedIn, appSignIn, appSignOut } = useAppAuthContext();
  const applicationsState = useAppSelector((state: RootState) => state.careers.applicationsState);
  const profileState = useAppSelector((state: RootState) => state.careers.profileState);
  const sessionExpired = useAppSelector((state: RootState) => state.careers.sessionExpired);

  // The data the open route needs.
  const { applications: needsApplications, profile: needsProfile } = dataNeededBy(useMatches());

  // Loads the candidate's applications and profile for the open route.
  useEffect(() => {
    const loadApps = needsApplications && applicationsState === State.idle;
    const loadOwnProfile = needsProfile && profileState === State.idle;
    if (!isSignedIn || (!loadApps && !loadOwnProfile)) return;
    // Set when the effect is replaced before the token arrives.
    let cancelled = false;
    getAccessToken()
      .then((token) => {
        if (cancelled) return;
        if (loadApps) dispatch(loadApplications(token));
        if (loadOwnProfile) dispatch(loadProfile(token));
      })
      .catch(() => {
        if (cancelled) return;
        if (loadApps) dispatch(applicationsFailed());
        if (loadOwnProfile) dispatch(profileFailed());
      });
    return () => {
      cancelled = true;
    };
  }, [isSignedIn, applicationsState, profileState, needsApplications, needsProfile, dispatch, getAccessToken]);

  // Clears the candidate's data when nobody is signed in.
  useEffect(() => {
    if (!isSignedIn) dispatch(clearUserData());
  }, [isSignedIn, dispatch]);

  // Signs the candidate out when the backend refuses the access token and a new one could not be had. The sign-out is
  // noted, so the entry page does not start the same sign-in again if the backend keeps refusing the session.
  useEffect(() => {
    if (!sessionExpired) return;
    dispatch(clearUserData());
    noteForcedSignOut();
    appSignOut();
  }, [sessionExpired, dispatch, appSignOut]);

  // The links are for signed-in candidates; a guest has none.
  const navItems = isSignedIn ? NAV_ITEMS : [];

  const isActive = (path?: string) => !!path && location.pathname.startsWith(path);

  // Resets the scroll of the page container on a route change.
  const contentRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    contentRef.current?.scrollTo({ top: 0 });
  }, [location.pathname]);

  return (
    <Box sx={{ height: "100vh", display: "flex", flexDirection: "column" }}>
      <SnackbarListener />

      {/* Top bar */}
      <Box
        sx={{
          height: "60px",
          flexShrink: 0,
          zIndex: 20,
          backgroundColor: isDark ? "transparent" : "#FFFFFF",
          borderBottom: "1px solid",
          borderColor: "divider",
          boxShadow: isDark ? "none" : "0 4px 18px -10px rgba(7,20,46,0.18)",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          px: { xs: 2, md: 3 },
        }}
      >
        {/* The logo and the word next to it are one link, to the vacancies on the wso2.com careers page. */}
        <Box
          component="a"
          href={CareersSiteUrl}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="WSO2 Careers: see the open positions"
          sx={{ display: "flex", alignItems: "center", gap: "3px", textDecoration: "none", color: "text.primary" }}
        >
          <Box
            component="img"
            src={isDark ? wso2LogoWhite : wso2LogoBlack}
            alt=""
            sx={{ height: BRAND_SIZE, width: "auto" }}
          />
          <Typography
            component="span"
            fontSize={BRAND_SIZE}
            lineHeight={1}
            fontWeight={600}
            color="text.primary"
          >
            Careers
          </Typography>
        </Box>

        <Stack direction="row" alignItems="center" gap={0.5}>
          {/* Icon-only links; the name shows as a tooltip on hover or keyboard focus */}
          <Stack component="nav" direction="row" alignItems="center" gap={0.5}>
            {navItems.map((item) => {
              const active = isActive(item.path);
              return (
                <Tooltip key={item.label} title={item.label} arrow disableInteractive>
                  <Box
                    component="button"
                    onClick={() => navigate(item.path)}
                    aria-label={item.label}
                    aria-current={active ? "page" : undefined}
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      px: 1.25,
                      py: 0.9,
                      border: "none",
                      borderRadius: "10px",
                      cursor: "pointer",
                      backgroundColor: active ? "#ff670018" : "transparent",
                      color: active ? "#ff6700" : "text.secondary",
                      transition: "background-color 0.15s, color 0.15s",
                      "&:hover, &:focus-visible": {
                        backgroundColor: active ? "#ff670018" : "action.hover",
                        color: active ? "#ff6700" : "text.primary",
                      },
                    }}
                  >
                    <item.icon size={19} />
                  </Box>
                </Tooltip>
              );
            })}
          </Stack>

          <Box sx={{ width: "1px", height: 24, backgroundColor: "divider", mx: 1 }} />

          <Tooltip title={isDark ? "Switch to light mode" : "Switch to dark mode"} arrow disableInteractive>
            <Box
              component="button"
              onClick={() => setMode(isDark ? "light" : "dark")}
              aria-label="Toggle light and dark mode"
              sx={{
                width: 34,
                height: 34,
                borderRadius: "50%",
                border: "1px solid",
                borderColor: "divider",
                background: "none",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "text.secondary",
                transition: "color 0.15s, border-color 0.15s",
                "&:hover": { color: "primary.main", borderColor: "primary.main" },
              }}
            >
              {isDark ? <Sun size={17} /> : <Moon size={17} />}
            </Box>
          </Tooltip>

          {isSignedIn ? (
            <Tooltip title="Sign out" arrow disableInteractive>
              <Box
                component="button"
                onClick={appSignOut}
                aria-label="Sign out"
                sx={{
                  width: 34,
                  height: 34,
                  ml: 0.5,
                  borderRadius: "50%",
                  border: "1px solid",
                  borderColor: "divider",
                  background: "none",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "text.secondary",
                  transition: "color 0.15s, border-color 0.15s",
                  "&:hover": { color: "primary.main", borderColor: "primary.main" },
                }}
              >
                <LogOut size={16} />
              </Box>
            </Tooltip>
          ) : (
            <Button
              size="small"
              variant="contained"
              onClick={() => appSignIn()}
              sx={{ ml: 1, fontWeight: 700, borderRadius: "999px", px: 2.5 }}
            >
              Sign in
            </Button>
          )}
        </Stack>
      </Box>

      {/* Page content */}
      <Box ref={contentRef} sx={{ flex: 1, overflowY: "auto" }}>
        <Outlet />
      </Box>
    </Box>
  );
};

export default AppShell;
