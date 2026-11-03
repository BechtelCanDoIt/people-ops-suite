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

import { Button, Dialog, DialogActions, DialogContent, DialogTitle, MenuItem, TextField, Typography } from "@wso2/oxygen-ui";
import { useState } from "react";

import type { OfferAnswer } from "@/types/types";
import { pillButtonSx } from "@utils/styles";

const MAX_COMMENT_LENGTH = 1000;

const DECLINE_REASONS = [
  "I accepted another offer",
  "The salary or benefits",
  "The location or working arrangement",
  "The role is not what I expected",
  "Personal reasons",
  "Other",
];

interface DeclineOfferDialogProps {
  jobTitle: string;
  sending: boolean;
  onDecline: (answer: OfferAnswer) => void;
  onClose: () => void;
}

// Asks the candidate why they are declining an offer.
const DeclineOfferDialog = ({ jobTitle, sending, onDecline, onClose }: DeclineOfferDialogProps) => {
  const [reason, setReason] = useState("");
  const [comment, setComment] = useState("");

  return (
    <Dialog open onClose={sending ? undefined : onClose} fullWidth maxWidth="sm" aria-labelledby="decline-title">
      <DialogTitle id="decline-title">Decline this offer?</DialogTitle>
      <DialogContent>
        <Typography color="text.secondary" mb={2}>
          We are sorry you are not joining us as {jobTitle}. Please tell us why, so we can do better.
        </Typography>
        <TextField
          select
          label="Reason"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          fullWidth
          sx={{ mb: 2 }}
        >
          {DECLINE_REASONS.map((option) => (
            <MenuItem key={option} value={option}>
              {option}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          label="Anything else you would like to tell us? (optional)"
          value={comment}
          onChange={(e) => setComment(e.target.value.slice(0, MAX_COMMENT_LENGTH))}
          helperText={`${comment.length}/${MAX_COMMENT_LENGTH}`}
          multiline
          minRows={3}
          fullWidth
        />
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} disabled={sending} sx={{ fontWeight: 600 }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          disabled={reason === "" || sending}
          onClick={() => onDecline({ response: "declined", reason, comment: comment.trim() })}
          sx={{ ...pillButtonSx, px: 3 }}
        >
          {sending ? "Declining..." : "Decline offer"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default DeclineOfferDialog;
