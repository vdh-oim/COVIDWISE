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

package gov.vdh.exposurenotification.nearby;

import android.content.Context;
import android.os.Build.VERSION_CODES;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.work.Constraints;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.ListenableWorker;
import androidx.work.NetworkType;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;
import androidx.work.WorkerParameters;
import com.google.android.gms.common.api.ApiException;
import com.google.common.io.BaseEncoding;
import com.google.common.util.concurrent.FluentFuture;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import gov.vdh.exposurenotification.BuildConfig;
import gov.vdh.exposurenotification.common.AppExecutors;
import gov.vdh.exposurenotification.common.TaskToFutureAdapter;
import gov.vdh.exposurenotification.network.DiagnosisKeys;
import gov.vdh.exposurenotification.storage.TokenEntity;
import gov.vdh.exposurenotification.storage.TokenRepository;
import gov.vdh.exposurenotification.utils.CustomUtility;
import java.security.SecureRandom;
import java.util.concurrent.TimeUnit;
import org.threeten.bp.Duration;

//import com.google.firebase.analytics.FirebaseAnalytics;
//import com.google.firebase.database.DatabaseReference;
//import com.google.firebase.database.FirebaseDatabase;   //TODO Ani

/**
 * Performs work to provide diagnosis keys to the exposure notifications API.
 */
public class ProvideDiagnosisKeysWorker extends ListenableWorker {

  private static final String TAG = "ProvideDiagnosisKeysWkr";



  public static final Duration DEFAULT_API_TIMEOUT = Duration.ofSeconds(15);

  public static final String WORKER_NAME = "ProvideDiagnosisKeysWorker";
  private static final BaseEncoding BASE64_LOWER = BaseEncoding.base64();
  private static final int RANDOM_TOKEN_BYTE_LENGTH = 32;

  private final DiagnosisKeys diagnosisKeys;
  private final DiagnosisKeyFileSubmitter submitter;
  private final SecureRandom secureRandom;
  private final TokenRepository tokenRepository;

  public ProvideDiagnosisKeysWorker(@NonNull Context context,
      @NonNull WorkerParameters workerParams) {
    super(context, workerParams);
    diagnosisKeys = new DiagnosisKeys(context);
    submitter = new DiagnosisKeyFileSubmitter(context);
    secureRandom = new SecureRandom();
    tokenRepository = new TokenRepository(context);
  }

  private String generateRandomToken() {
    byte bytes[] = new byte[RANDOM_TOKEN_BYTE_LENGTH];
    secureRandom.nextBytes(bytes);
    return BASE64_LOWER.encode(bytes);
  }

  @NonNull
  @Override
  public ListenableFuture<Result> startWork() {




    final String token = generateRandomToken(); //hidden for scheduler testing by springml
    return FluentFuture.from(TaskToFutureAdapter
        .getFutureWithTimeout(
            ExposureNotificationClientWrapper.get(getApplicationContext()).isEnabled(),
            DEFAULT_API_TIMEOUT.toMillis(),
            TimeUnit.MILLISECONDS,
            AppExecutors.getScheduledExecutor()))
        .transformAsync((isEnabled) -> {
          // Only continue if it is enabled.

          if (isEnabled) {
            return diagnosisKeys.download();
          } else {
            // Stop here because things aren't enabled. Will still return successful though.
            return Futures.immediateFailedFuture(new NotEnabledException());
          }
        }, AppExecutors.getBackgroundExecutor())
        .transformAsync((batches) -> submitter.submitFiles(batches, token),
            AppExecutors.getBackgroundExecutor())
        .transformAsync(
            done -> tokenRepository.upsertAsync(TokenEntity.create(token, false)),
            AppExecutors.getBackgroundExecutor())
        .transform(done -> Result.success(), AppExecutors.getLightweightExecutor())
        .catching(NotEnabledException.class, x -> {
          // Not enabled. Return as success.
          return Result.success();
        }, AppExecutors.getBackgroundExecutor())
        .catching(Exception.class, x -> {
          if (!(x instanceof ApiException)){
            CustomUtility.customLogger("A_CW_ERROR while downloading");
          }
          return Result.failure();
        }, AppExecutors.getBackgroundExecutor());
    // TODO: consider a retry strategy
  }

  /**
   * Schedules a job that runs once a day to fetch diagnosis keys from a server and to provide them
   * to the exposure notifications API.
   *
   * <p>This job will only be run when idle, not low battery and with network connection.
   *
   * <p>TODO: schedule the daily job
   */
  @RequiresApi(api = VERSION_CODES.M)
  public static void scheduleDailyProvideDiagnosisKeys(Context context) {
    WorkManager workManager = WorkManager.getInstance(context);
    int interval;
    TimeUnit timeUnit;
    if ("debug".equalsIgnoreCase(BuildConfig.BUILD_TYPE)){
      interval = 16;
      timeUnit = TimeUnit.MINUTES;
    } else
      {
        interval = BuildConfig.DOWNLOAD_SCHEDULE;
        timeUnit = TimeUnit.HOURS;
    }

    PeriodicWorkRequest workRequest = new PeriodicWorkRequest.Builder(
       ProvideDiagnosisKeysWorker.class,   interval, timeUnit)
        .setConstraints(
            new Constraints.Builder()
                .setRequiresBatteryNotLow(true)
//                .setRequiresDeviceIdle(true)
                .setRequiresDeviceIdle(false) //springml
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build())
        .build();
    workManager
        .enqueueUniquePeriodicWork(WORKER_NAME, ExistingPeriodicWorkPolicy.REPLACE, workRequest);
  }

  private static class NotEnabledException extends Exception {

  }

}