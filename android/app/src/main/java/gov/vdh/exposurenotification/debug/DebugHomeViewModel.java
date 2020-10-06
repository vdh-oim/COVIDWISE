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

package gov.vdh.exposurenotification.debug;

import android.app.Application;
import android.content.Intent;
import android.os.Build.VERSION_CODES;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.lifecycle.AndroidViewModel;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;
import gov.vdh.exposurenotification.common.AppExecutors;
import gov.vdh.exposurenotification.common.SingleLiveEvent;
import gov.vdh.exposurenotification.nearby.ExposureNotificationBroadcastReceiver;
import gov.vdh.exposurenotification.nearby.ExposureNotificationClientWrapper;
import gov.vdh.exposurenotification.nearby.ProvideDiagnosisKeysWorker;
import gov.vdh.exposurenotification.storage.ExposureNotificationSharedPreferences;
import gov.vdh.exposurenotification.storage.ExposureNotificationSharedPreferences.NetworkMode;
import gov.vdh.exposurenotification.storage.ExposureRepository;
import gov.vdh.exposurenotification.storage.TokenEntity;
import gov.vdh.exposurenotification.storage.TokenRepository;
import gov.vdh.exposurenotification.utils.CustomUtility;
import com.google.android.gms.nearby.exposurenotification.ExposureNotificationClient;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import javax.net.ssl.HttpsURLConnection;
import org.checkerframework.checker.nullness.compatqual.NullableDecl;
import org.json.JSONArray;
import org.json.JSONObject;

/** View model for the {@link DebugHomeFragment}. */
public class DebugHomeViewModel extends AndroidViewModel {

  private static final String TAG = "DebugViewModel";

  private static SingleLiveEvent<String> snackbarLiveEvent = new SingleLiveEvent<>();

  private final TokenRepository tokenRepository;
  private final ExposureRepository exposureRepository;
  private final ExposureNotificationSharedPreferences exposureNotificationSharedPreferences;

  public DebugHomeViewModel(@NonNull Application application) {
    super(application);
    tokenRepository = new TokenRepository(application);
    exposureRepository = new ExposureRepository(application);
    exposureNotificationSharedPreferences = new ExposureNotificationSharedPreferences(application);
  }

  public SingleLiveEvent<String> getSnackbarSingleLiveEvent() {
    return snackbarLiveEvent;
  }

  public NetworkMode getNetworkMode(NetworkMode defaultMode) {
    return exposureNotificationSharedPreferences.getNetworkMode(defaultMode);
  }

  public void setNetworkMode(NetworkMode networkMode) {
    exposureNotificationSharedPreferences.setNetworkMode(networkMode);
  }

  /** Generate test exposure events */
  public void addTestExposures(String errorSnackbarMessage) {
    // First inserts/updates the hard coded tokens.
    Futures.addCallback(
        Futures.allAsList(
            tokenRepository.upsertAsync(
                TokenEntity.create(ExposureNotificationClientWrapper.FAKE_TOKEN_1, false)),
            tokenRepository.upsertAsync(
                TokenEntity.create(ExposureNotificationClientWrapper.FAKE_TOKEN_2, false)),
            tokenRepository.upsertAsync(
                TokenEntity.create(ExposureNotificationClientWrapper.FAKE_TOKEN_3, false))),
        new FutureCallback<List<Void>>() {
          @Override
          public void onSuccess(@NullableDecl List<Void> result) {
            // Now broadcasts them to the worker.
            Intent intent1 =
                new Intent(getApplication(), ExposureNotificationBroadcastReceiver.class);
            intent1.setAction(ExposureNotificationClient.ACTION_EXPOSURE_STATE_UPDATED);
            intent1.putExtra(
                ExposureNotificationClient.EXTRA_TOKEN,
                ExposureNotificationClientWrapper.FAKE_TOKEN_1);
            getApplication().sendBroadcast(intent1);

            Intent intent2 =
                new Intent(getApplication(), ExposureNotificationBroadcastReceiver.class);
            intent2.setAction(ExposureNotificationClient.ACTION_EXPOSURE_STATE_UPDATED);
            intent2.putExtra(
                ExposureNotificationClient.EXTRA_TOKEN,
                ExposureNotificationClientWrapper.FAKE_TOKEN_2);
            getApplication().sendBroadcast(intent2);

            Intent intent3 =
                new Intent(getApplication(), ExposureNotificationBroadcastReceiver.class);
            intent3.setAction(ExposureNotificationClient.ACTION_EXPOSURE_STATE_UPDATED);
            intent3.putExtra(
                ExposureNotificationClient.EXTRA_TOKEN,
                ExposureNotificationClientWrapper.FAKE_TOKEN_3);
            getApplication().sendBroadcast(intent3);
          }

          @Override
          public void onFailure(Throwable t) {
            snackbarLiveEvent.postValue(errorSnackbarMessage);
          }
        },
        AppExecutors.getBackgroundExecutor());
  }

  /** Reset exposure events for testing purposes */
  public void resetExposures(String successSnackbarMessage, String failureSnackbarMessage) {
    Futures.addCallback(
        Futures.allAsList(
            tokenRepository.deleteByTokensAsync(
                ExposureNotificationClientWrapper.FAKE_TOKEN_1,
                ExposureNotificationClientWrapper.FAKE_TOKEN_2,
                ExposureNotificationClientWrapper.FAKE_TOKEN_3),
            exposureRepository.deleteAllAsync()),
        new FutureCallback<List<Void>>() {
          @Override
          public void onSuccess(@NullableDecl List<Void> result) {
            new ExposureNotificationSharedPreferences(getApplication().getApplicationContext()).setPossibleExposureFound(false);
            snackbarLiveEvent.postValue(successSnackbarMessage);
          }

          @Override
          public void onFailure(Throwable t) {
            snackbarLiveEvent.postValue(failureSnackbarMessage);
          }
        },
        AppExecutors.getBackgroundExecutor());
  }

  /** Triggers a one off provide keys job. */
  public void provideKeys() {
    WorkManager workManager = WorkManager.getInstance(getApplication());
    workManager.enqueue(new OneTimeWorkRequest.Builder(ProvideDiagnosisKeysWorker.class).build());
  }

  /** Triggers the scheduler to run every 15 mins.
   * Added by springml
   * */
  @RequiresApi(api = VERSION_CODES.M)
  public void scheduleSync() {
    //WorkManager workManager = WorkManager.getInstance(getApplication());
    ProvideDiagnosisKeysWorker.scheduleDailyProvideDiagnosisKeys(getApplication());
  }
}
