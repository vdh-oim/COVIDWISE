/*
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package gov.vdh.exposurenotification.notify;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import gov.vdh.exposurenotification.R;
import com.google.android.material.bottomsheet.BottomSheetDialogFragment;

/**
 * Page 1 of the adding a positive diagnosis flow
 */
public class ShareDiagnosisBeginFragmentBotom extends BottomSheetDialogFragment {

  private static final String TAG = "ShareExposureBeginFrag";

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
    return inflater.inflate(R.layout.fragment_share_diagnosis_begin, parent, false);
  }

  static ShareDiagnosisBeginFragmentBotom newInstance() {
    ShareDiagnosisBeginFragmentBotom fragment = new ShareDiagnosisBeginFragmentBotom();
    return fragment;
  }


  @Override
  public void onViewCreated(View view, Bundle savedInstanceState) {
    view.findViewById(R.id.share_next_button)
        .setOnClickListener(new OnClickListener() {
          @Override
          public void onClick(View view) {
            startActivity(ShareDiagnosisActivity.newIntentForAddFlow(requireContext()));
            dismiss();
          }
        });

   // view.findViewById(R.id.share_cancel_button).setOnClickListener((v) -> cancelAction());
    view.findViewById(android.R.id.home).setOnClickListener((v) -> cancelAction());
  }

  private void cancelAction() {
    dismiss();
  }
}
