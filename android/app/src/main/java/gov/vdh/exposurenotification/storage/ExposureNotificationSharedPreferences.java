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

package gov.vdh.exposurenotification.storage;

import android.content.Context;
import android.content.SharedPreferences;
import java.util.ArrayList;

/**
 * Key value storage for ExposureNotification.
 *
 * <p>Partners should implement a daily TTL/expiry, for on-device storage of this data, and must
 * ensure compliance with all applicable laws and requirements with respect to encryption, storage,
 * and retention polices for end user data.
 */
public class ExposureNotificationSharedPreferences {

  private static final String SHARED_PREFERENCES_FILE =
      "ExposureNotificationSharedPreferences.SHARED_PREFERENCES_FILE";

  private static final String ONBOARDING_STATE_KEY = "ExposureNotificationSharedPreferences.ONBOARDING_STATE_KEY";
  private static final String NETWORK_MODE_KEY = "ExposureNotificationSharedPreferences.NETWORK_MODE_KEY";
  private static final String ATTENUATION_THRESHOLD_1_KEY = "ExposureNotificationSharedPreferences.ATTENUATION_THRESHOLD_1_KEY";
  private static final String ATTENUATION_THRESHOLD_2_KEY = "ExposureNotificationSharedPreferences.ATTENUATION_THRESHOLD_2_KEY";

  private static final String CUSTOM_LOGGING_ENABLED = "ExposureNotificationSharedPreferences.CUSTOM_LOGGING_ENABLED";
  private static final String RETRIES_EXHAUSTED = "ExposureNotificationSharedPreferences.RETRIES_EXHAUSTED";
  private static final String PIN_TOKEN = "ExposureNotificationSharedPreferences.PIN_TOKEN";
  private static final String LAST_RETRY_TIME_IN_MILLIS = "ExposureNotificationSharedPreferences.LAST_RETRY_TIME_IN_MILLIS";
  private static final String POSSIBLE_EXPOSURE_FOUND = "ExposureNotificationSharedPreferences.POSSIBLE_EXPOSURE_FOUND";
  private static final String DAYS_SINCE_LAST_EXPOSURE = "ExposureNotificationSharedPreferences.DAYS_SINCE_LAST_EXPOSURE";
  private static final String FIRST_ONBOARDING_DONE = "ExposureNotificationSharedPreferences.FIRST_ONBOARDING_DONE";

  private static final String LAST_NOTIFICATION_TIME_IN_MILLIS="ExposureNotificationSharedPreferences.LAST_NOTIFICATION_TIME_IN_MILLIS";

  private final SharedPreferences sharedPreferences;

  public enum OnboardingStatus {
    UNKNOWN(0),
    ONBOARDED(1),
    SKIPPED(2);

    private final int value;

    OnboardingStatus(int value) {
      this.value = value;
    }

    public int value() {
      return value;
    }

    public static OnboardingStatus fromValue(int value) {
      switch (value) {
        case 1:
          return ONBOARDED;
        case 2:
          return SKIPPED;
        default:
          return UNKNOWN;
      }
    }
  }

  public enum NetworkMode {
    // Uses live but test instances of the diagnosis key upload and download servers.
    TEST,
    // Uses local faked implementations of the diagnosis key uploads and downloads; no actual network calls.
    FAKE
  }

  public ExposureNotificationSharedPreferences(Context context) {
    // These shared preferences are stored in {@value Context#MODE_PRIVATE} to be made only
    // accessible by the app.
    sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCES_FILE, Context.MODE_PRIVATE);
  }

  public void setOnboardedState(boolean onboardedState) {
    sharedPreferences.edit().putInt(ONBOARDING_STATE_KEY,
        onboardedState ? OnboardingStatus.ONBOARDED.value() : OnboardingStatus.UNKNOWN.value())
        .apply();
  }

  public OnboardingStatus getOnboardedState() {
    return OnboardingStatus.fromValue(sharedPreferences.getInt(ONBOARDING_STATE_KEY, 0));
  }

  public NetworkMode getNetworkMode(NetworkMode defaultMode) {
    return NetworkMode.valueOf(
        sharedPreferences.getString(NETWORK_MODE_KEY, defaultMode.toString()));
  }

  public void setNetworkMode(NetworkMode key) {
    sharedPreferences.edit().putString(NETWORK_MODE_KEY, key.toString()).commit();
  }

  public int getAttenuationThreshold1(int defaultThreshold) {
    return sharedPreferences.getInt(ATTENUATION_THRESHOLD_1_KEY, defaultThreshold);
  }

  public void setAttenuationThreshold1(int threshold) {
    sharedPreferences.edit().putInt(ATTENUATION_THRESHOLD_1_KEY, threshold).commit();
  }

  public int getAttenuationThreshold2(int defaultThreshold) {
    return sharedPreferences.getInt(ATTENUATION_THRESHOLD_2_KEY, defaultThreshold);
  }

  public void setAttenuationThreshold2(int threshold) {
    sharedPreferences.edit().putInt(ATTENUATION_THRESHOLD_2_KEY, threshold).commit();
  }

  public boolean getRetriesExhausted(boolean defaultExhaustion){
    return sharedPreferences.getBoolean(RETRIES_EXHAUSTED, defaultExhaustion);
  }

  public void setRetriesExhausted(boolean retriesExhausted) {
    sharedPreferences.edit().putBoolean(RETRIES_EXHAUSTED, retriesExhausted).commit();
  }

  public boolean getPossibleExposureFound(boolean defaultExposure){
    return sharedPreferences.getBoolean(POSSIBLE_EXPOSURE_FOUND, defaultExposure);
  }

  public void setPossibleExposureFound(boolean exposureFound) {
    sharedPreferences.edit().putBoolean(POSSIBLE_EXPOSURE_FOUND, exposureFound).commit();
  }

  public String getPinToken(String pinToken){
    return sharedPreferences.getString(PIN_TOKEN, pinToken);
  }

  public void setPinToken(String pinToken){
    sharedPreferences.edit().putString(PIN_TOKEN, pinToken).commit();
  }

  public Long getLastRetryTimeInMillis(Long lastRetryTimeInMillis){
    return sharedPreferences.getLong(LAST_RETRY_TIME_IN_MILLIS, lastRetryTimeInMillis);
  }

  public void setLastRetryTimeInMillis(Long lastRetryTimeInMillis){
    sharedPreferences.edit().putLong(LAST_RETRY_TIME_IN_MILLIS, lastRetryTimeInMillis).commit();
  }


  public int getDaysSinceLastExposure(int days){
    return sharedPreferences.getInt(DAYS_SINCE_LAST_EXPOSURE, days);
  }

  public void setDaysSinceLastExposure(int days){
    sharedPreferences.edit().putInt(DAYS_SINCE_LAST_EXPOSURE, days).commit();
  }

  public boolean getFirstOnboardingStatus(boolean status){
    return sharedPreferences.getBoolean(FIRST_ONBOARDING_DONE, status);
  }

  public void setFirstOnboardingStatus(boolean status){
    sharedPreferences.edit().putBoolean(FIRST_ONBOARDING_DONE, status).commit();
  }

  //notification change
  public void setLastNotificationTimeInMillis(Long time){
    sharedPreferences.edit().putLong(LAST_NOTIFICATION_TIME_IN_MILLIS, time).commit();
  }

  public long getLastNotificationTimeInMillis(Long time){
    return sharedPreferences.getLong(LAST_NOTIFICATION_TIME_IN_MILLIS, time);
  }
}
