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

import { Button, Dialog, DialogActions, DialogContent, DialogTitle, Rating, TextField, Typography } from "@wso2/oxygen-ui";
import { useState } from "react";

import type { ApplicationFeedback } from "@/types/types";
import { pillButtonSx } from "@utils/styles";

const MAX_COMMENT_LENGTH = 1000;

interface RejectionFeedbackDialogProps {
  jobTitle: string;
  sending: boolean;
  onSend: (feedback: ApplicationFeedback) => void;
  onClose: () => void;
}

// Asks a candidate whose application was not successful to rate their experience and say what could be better.
const RejectionFeedbackDialog = ({ jobTitle, sending, onSend, onClose }: RejectionFeedbackDialogProps) => {
  const [rating, setRating] = useState<number | null>(null);
  const [comment, setComment] = useState("");

  const canSend = (rating !== null || comment.trim() !== "") && !sending;

  return (
    <Dialog open onClose={sending ? undefined : onClose} fullWidth maxWidth="sm" aria-labelledby="feedback-title">
      <DialogTitle id="feedback-title">Help us improve</DialogTitle>
      <DialogContent>
        <Typography color="text.secondary" mb={2}>
          Thank you for applying for {jobTitle}. How was your experience with us?
        </Typography>
        <Rating
          name="experience"
          value={rating}
          onChange={(_, value) => setRating(value)}
          size="large"
          sx={{ mb: 2, "& .MuiRating-iconFilled": { color: "primary.main" } }}
        />
        <TextField
          label="What could we have done better? (optional)"
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
          Not now
        </Button>
        <Button
          variant="contained"
          disabled={!canSend}
          onClick={() => onSend({ rating, comment: comment.trim() })}
          sx={{ ...pillButtonSx, px: 3 }}
        >
          {sending ? "Sending..." : "Send feedback"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default RejectionFeedbackDialog;
