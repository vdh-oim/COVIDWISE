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

package gov.vdh.exposurenotification.exposure;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.text.method.LinkMovementMethod;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.ViewAnimator;
import android.widget.ViewSwitcher;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import com.google.android.material.snackbar.Snackbar;
import gov.vdh.exposurenotification.R;
import gov.vdh.exposurenotification.home.ExposureNotificationViewModel;
import gov.vdh.exposurenotification.storage.ExposureEntity;
import gov.vdh.exposurenotification.storage.ExposureNotificationSharedPreferences;
import gov.vdh.exposurenotification.utils.CustomUtility;
import java.util.List;

//import android.os.Build.VERSION_CODES;

/** Fragment for Exposures tab on home screen. */
public class ExposureHomeFragment extends Fragment {

  private final String TAG = "ExposureHomeFragment";

  private ExposureNotificationViewModel exposureNotificationViewModel;
  private ExposureHomeViewModel exposureHomeViewModel;
  private ExposureEntityAdapter adapter;
  public static final String ACTION_LAUNCH_FROM_EXPOSURE_NOTIFICATION =
      "com.google.android.apps.exposurenotification.ACTION_LAUNCH_FROM_EXPOSURE_NOTIFICATION";
  private static final String EXPOSURE_NOTIFICATION_CHANNEL_ID =
      "ApolloExposureNotificationCallback.EXPOSURE_NOTIFICATION_CHANNEL_ID";

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
    return inflater.inflate(R.layout.fragment_exposure_home, parent, false);
  }

  @RequiresApi(api = VERSION_CODES.M)
  @Override
  public void onViewCreated(View view, Bundle savedInstanceState) {

    TextView t2 = (TextView) view.findViewById(R.id.exposure_privacy_link);
    t2.setMovementMethod(LinkMovementMethod.getInstance());


    exposureNotificationViewModel =
        new ViewModelProvider(requireActivity()).get(ExposureNotificationViewModel.class);
    exposureHomeViewModel =
        new ViewModelProvider(this, getDefaultViewModelProviderFactory())
            .get(ExposureHomeViewModel.class);

    exposureNotificationViewModel
        .getIsEnabledLiveData()
        .observe(getViewLifecycleOwner(), isEnabled -> refreshUiForEnabled(isEnabled));

    Button startButton = view.findViewById(R.id.start_api_button);
    startButton.setOnClickListener(v -> exposureNotificationViewModel.startExposureNotifications());
    exposureNotificationViewModel
        .getInFlightLiveData()
        .observe(getViewLifecycleOwner(), isInFlight -> startButton.setEnabled(!isInFlight));


    exposureNotificationViewModel
        .getApiErrorLiveEvent()
        .observe(getViewLifecycleOwner(), unused -> {
          View rootView = getView();
          if (rootView != null) {
            Snackbar.make(rootView, R.string.generic_error_message, Snackbar.LENGTH_LONG).show();
          }
        });

    view.findViewById(R.id.exposure_about_button).setOnClickListener(v -> launchAboutAction());
    view.findViewById(R.id.exposure_about_button1).setOnClickListener(v -> launchAboutAction());

    //RecyclerView exposuresList = view.findViewById(R.id.exposures_list);
    /*adapter =
        new ExposureEntityAdapter(
            exposureEntity -> {
              ExposureBottomSheetFragment sheet =
                  ExposureBottomSheetFragment.newInstance(exposureEntity);
              sheet.show(getChildFragmentManager(), ExposureBottomSheetFragment.TAG);
            });
    exposuresList.setItemAnimator(null);
    exposuresList.setLayoutManager(
        new LinearLayoutManager(requireContext(), LinearLayoutManager.VERTICAL, false));
    exposuresList.setAdapter(adapter);
*/
    exposureHomeViewModel
        .getAllExposureEntityLiveData()
        .observe(getViewLifecycleOwner(), this::refreshUiForExposureEntities);
  }

  @Override
  public void onResume() {
    super.onResume();
    refreshUi();
  }

  private void refreshUi() {
    exposureNotificationViewModel.refreshIsEnabledState();
    //exposureHomeViewModel.updateExposureEntities();
  }

  /**
   * Update UI to match Exposure Notifications client has become enabled/not-enabled.
   *
   * @param isEnabled True if Exposure Notifications is enabled
   */
  private void refreshUiForEnabled(Boolean isEnabled) {
    View rootView = getView();
    if (rootView == null) {
      return;
    }

    exposureNotificationViewModel.deleteWebViewDB();

    ViewSwitcher settingsBannerSwitcher = rootView.findViewById(R.id.settings_banner_switcher);
    ViewAnimator switcher = rootView.findViewById(R.id.exposures_list_empty_switcher);
    TextView exposureNotificationStatus = rootView.findViewById(R.id.exposure_notifications_status);
    exposureNotificationStatus.setVisibility(View.GONE);

    TextView infoStatus = rootView.findViewById(R.id.info_status);
    TextView infoVirusStatus = rootView.findViewById(R.id.info_virus_status);
    TextView infopoint1= rootView.findViewById(R.id.info_point1);
    TextView infopoint2= rootView.findViewById(R.id.info_point2);
    TextView infopoint3= rootView.findViewById(R.id.info_point3);
    LinearLayout visitBullet=rootView.findViewById(R.id.layout1);
    LinearLayout linkBullet=rootView.findViewById(R.id.layout2);
    LinearLayout contactBullet=rootView.findViewById(R.id.layout3);
    ImageView virusDetectedImage = rootView.findViewById(R.id.detected_image);
    settingsBannerSwitcher.setDisplayedChild(isEnabled ? 1 : 0);
    if (isEnabled) {
      exposureNotificationStatus.setVisibility(View.VISIBLE);
      exposureNotificationStatus.setText(R.string.turned_on);
      exposureNotificationStatus.setTextColor(getResources().getColor(R.color.otpview_color));
      if (new ExposureNotificationSharedPreferences(getContext().getApplicationContext())
          .getPossibleExposureFound(false)) {
        String textarray[]=getExposureMessage(getContext()).split("\n•");
        infoStatus.setText(textarray[0]);
        infopoint1.setText(textarray[1]);
        infopoint2.setText(textarray[2]);
        infopoint3.setText(textarray[3]);
        visitBullet.setVisibility(View.VISIBLE);
        linkBullet.setVisibility(View.VISIBLE);
        contactBullet.setVisibility(View.VISIBLE);
        infoStatus.setTextColor(Color.BLACK);
        switcher.setDisplayedChild(1);
        virusDetectedImage.setVisibility(View.VISIBLE);
        infoVirusStatus.setText(R.string.possible_exposure);
        int padding = getResources().getDimensionPixelOffset(R.dimen.dp6);
        infoVirusStatus.setPadding(padding, 0, 0, 0);
      } else {
        infoStatus.setText(R.string.notifications_enabled_info);
        switcher.setDisplayedChild(0);
        virusDetectedImage.setVisibility(View.GONE);
        infoVirusStatus.setText(R.string.no_exposures);
        visitBullet.setVisibility(View.GONE);
        linkBullet.setVisibility(View.GONE);
        contactBullet.setVisibility(View.GONE);
      }
    } else {

      switcher.setDisplayedChild(0);
      exposureNotificationStatus.setVisibility(View.GONE);
      exposureNotificationStatus.setText(R.string.off);
      exposureNotificationStatus.setTextColor(getResources().getColor(R.color.red_color));
      infoStatus.setText(R.string.notifications_disabled_info);
      virusDetectedImage.setVisibility(View.GONE);
      infoVirusStatus.setText(R.string.no_exposures);
      visitBullet.setVisibility(View.GONE);
      linkBullet.setVisibility(View.GONE);
      contactBullet.setVisibility(View.GONE);
    }
  }

  /**
   * Method created by SpringML to get notification message based on no. of days of last exposure.
   * @param context context from where the message is to be shown.
   * */
  private String getExposureMessage(Context context){
    String message;
    String finalMessage;
    int days = new ExposureNotificationSharedPreferences(context.getApplicationContext()).getDaysSinceLastExposure(0);
    if (days == 0){
      message = context.getString(R.string.notification_message_zero_days);
    }
    else if (days == 1){
      message = context.getString(R.string.notification_message_one_day, days);
    }
    else{
      message = context.getString(R.string.notification_message_two_days, days);
    }
    finalMessage = context.getString(R.string.notifications_enabled_possible_exposure_info1) +
        message + context.getString(R.string.notifications_enabled_possible_exposure_info2);

    return finalMessage;
  }

  /**
   * Display new exposure information
   *
   * @param exposureEntities List of potential exposures
   */
  private void refreshUiForExposureEntities(@Nullable List<ExposureEntity> exposureEntities) {
    View rootView = getView();
    if (rootView == null) {
      return;
    }

    /*if (adapter != null) {
      adapter.submitList(exposureEntities);
    }*/

    ViewAnimator switcher = rootView.findViewById(R.id.exposures_list_empty_switcher);
    switcher.setDisplayedChild(exposureEntities == null || exposureEntities.isEmpty() ? 0 : 1);
    if (new ExposureNotificationSharedPreferences(getContext().getApplicationContext()).getPossibleExposureFound(false)){
      switcher.setDisplayedChild(1);
    }
  }

  /** Open the Exposure Notifications about screen. */
  private void launchAboutAction() {
    startActivity(new Intent(requireContext(), ExposureAboutActivity.class));
  }


}