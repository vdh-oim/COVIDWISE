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

package gov.vdh.exposurenotification.onboarding;

import static gov.vdh.exposurenotification.home.ExposureNotificationActivity.HOME_FRAGMENT_TAG;

import android.os.Bundle;
import android.text.method.LinkMovementMethod;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;
import gov.vdh.exposurenotification.R;

/**
 * Page 1 of the onboarding flow {@link Fragment}.
 */
public class OnboardingStartFragment extends Fragment {

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
    return inflater.inflate(R.layout.fragment_onboarding_start, parent, false);
  }

  @Override
  public void onViewCreated(View view, Bundle savedInstanceState) {
    Button startButton = view.findViewById(R.id.onboarding_next_button);

    TextView t2 = (TextView) view.findViewById(R.id.onboarding_privacy_link);
    t2.setMovementMethod(LinkMovementMethod.getInstance());
    startButton.setOnClickListener(
        v -> {
          FragmentTransaction fragmentTransaction = getParentFragmentManager().beginTransaction();
          fragmentTransaction.replace(
              R.id.home_fragment, new OnboardingPermissionFragment(), HOME_FRAGMENT_TAG);
          fragmentTransaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE);
          fragmentTransaction.addToBackStack(null);
          fragmentTransaction.commit();
        });
  }

}
