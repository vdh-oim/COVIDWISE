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

import static gov.vdh.exposurenotification.nearby.ProvideDiagnosisKeysWorker.DEFAULT_API_TIMEOUT;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationCompat.Builder;
import androidx.core.app.NotificationManagerCompat;
import androidx.work.ListenableWorker;
import androidx.work.WorkerParameters;
import com.google.android.gms.nearby.exposurenotification.ExposureNotificationClient;
import com.google.android.gms.nearby.exposurenotification.ExposureSummary;
import com.google.common.util.concurrent.FluentFuture;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import gov.vdh.exposurenotification.BuildConfig;
import gov.vdh.exposurenotification.R;
import gov.vdh.exposurenotification.common.AppExecutors;
import gov.vdh.exposurenotification.common.TaskToFutureAdapter;
import gov.vdh.exposurenotification.home.ExposureNotificationActivity;
import gov.vdh.exposurenotification.storage.ExposureNotificationSharedPreferences;
import gov.vdh.exposurenotification.storage.TokenEntity;
import gov.vdh.exposurenotification.storage.TokenRepository;
import gov.vdh.exposurenotification.utils.CustomUtility;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

/**
 * Performs work for {@value com.google.android.gms.nearby.exposurenotification.ExposureNotificationClient#ACTION_EXPOSURE_STATE_UPDATED}
 * broadcast from exposure notification API.
 */
public class StateUpdatedWorker extends ListenableWorker {

  private static final String TAG = "StateUpdatedWorker";

  private static final String EXPOSURE_NOTIFICATION_CHANNEL_ID =
      "ApolloExposureNotificationCallback.EXPOSURE_NOTIFICATION_CHANNEL_ID";
  public static final String ACTION_LAUNCH_FROM_EXPOSURE_NOTIFICATION =
      "gov.vdh.exposurenotification.ACTION_LAUNCH_FROM_EXPOSURE_NOTIFICATION";

  private final Context context;
  private final TokenRepository tokenRepository;

  public StateUpdatedWorker(
      @NonNull Context context, @NonNull WorkerParameters workerParams) {
    super(context, workerParams);
    this.context = context;
    this.tokenRepository = new TokenRepository(context);
  }

  @NonNull
  @Override
  public ListenableFuture<Result> startWork() {

    final String token = getInputData().getString(ExposureNotificationClient.EXTRA_TOKEN);
    if (token == null) {
      return Futures.immediateFuture(Result.failure());
    } else {

      return FluentFuture.from(TaskToFutureAdapter.getFutureWithTimeout(
          ExposureNotificationClientWrapper.get(context).getExposureSummary(token),
          DEFAULT_API_TIMEOUT.toMillis(),
          TimeUnit.MILLISECONDS,
          AppExecutors.getScheduledExecutor()))
          .transformAsync((exposureSummary) -> {

            if (riskComputation(exposureSummary) && (exposureSummary.getMatchedKeyCount() > 0)) {
              // Positive so show a notification and update the token.
              int days = exposureSummary.getDaysSinceLastExposure();
              setDaysSinceLastExposure(days);
              Long last =  new ExposureNotificationSharedPreferences(context).getLastNotificationTimeInMillis(0L);//
              if(Math.abs((System.currentTimeMillis())-last) > 82800000){
                CustomUtility.customLogger("A_CW_91001 - The app has shown a notification to a user." );
                showNotification();
                setLastNotificationTimeInMillis(System.currentTimeMillis());
              }


              // Update the TokenEntity by upserting with the same token.
              return tokenRepository.upsertAsync(TokenEntity.create(token, true));
            } else {
              // No matches so we show no notification and just delete the token.
              return tokenRepository.deleteByTokensAsync(token);
            }
          }, AppExecutors.getBackgroundExecutor())
          .transform((v) -> Result.success(), AppExecutors.getLightweightExecutor())
          .catching(Exception.class, x -> Result.failure(), AppExecutors.getLightweightExecutor());
    }
  }

  private void createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      NotificationChannel channel =
          new NotificationChannel(EXPOSURE_NOTIFICATION_CHANNEL_ID,
              context.getString(R.string.notification_channel_name),
              NotificationManager.IMPORTANCE_HIGH);
      channel.setDescription(context.getString(R.string.notification_channel_description));
      NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
      Objects.requireNonNull(notificationManager).createNotificationChannel(channel);
    }
  }

  public void showNotification() {
    Intent intent;
    PendingIntent pendingIntent = null;
    try {
      createNotificationChannel();
      intent = new Intent(getApplicationContext(), ExposureNotificationActivity.class);
      intent.setAction(ACTION_LAUNCH_FROM_EXPOSURE_NOTIFICATION);
      intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
      pendingIntent = PendingIntent.getActivity(context, 0, intent, 0);
      }
    catch (Exception e){
    }
    NotificationCompat.Builder builder =
        new Builder(context, EXPOSURE_NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(getApplicationContext().getResources().getColor(R.color.notification_color))
            .setContentTitle(context.getString(R.string.notification_title))
            .setContentText(context.getString(R.string.notification_message))
            .setStyle(new NotificationCompat.BigTextStyle()
                .bigText(context.getString(R.string.notification_message)))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setContentIntent(pendingIntent)
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            // Do not reveal this notification on a secure lockscreen.
            .setVisibility(NotificationCompat.VISIBILITY_SECRET);
    NotificationManagerCompat notificationManager = NotificationManagerCompat
        .from(context);
    notificationManager.notify(0, builder.build());
  }

  /**
   * Method created by SpringML to perform additional check for Exposure risk.
   * @param exposureSummary A class that stores the summary of Exposures.
   * @return <>true</> If the duration of contact was enough to be infected/exposed, <>false</> if
   * the duration was not enough to raise doubts.
   * */
  private boolean riskComputation(ExposureSummary exposureSummary){

    double duration_close = exposureSummary.getAttenuationDurationsInMinutes()[0];
    double duration_medium = exposureSummary.getAttenuationDurationsInMinutes()[1];

    double risk_duration = duration_close + (duration_medium * 0.5);

    if (risk_duration * 60 >= BuildConfig.ATTENUATION_THRESHOLD){
      new ExposureNotificationSharedPreferences(getApplicationContext()).setPossibleExposureFound(true);
      return true;
    }
    new ExposureNotificationSharedPreferences(getApplicationContext()).setPossibleExposureFound(false);
    if ((risk_duration > 0) && (risk_duration < BuildConfig.ATTENUATION_THRESHOLD)) {
      CustomUtility.customLogger("A_CW_91009_" + (int)risk_duration);
    }
    return false;
  }

  /**
   * Method created by SpringML to update the no. of days since last exposure.
   * @param days no. of days since last exposure.
   * */
  private void setDaysSinceLastExposure(int days){
    new ExposureNotificationSharedPreferences(getApplicationContext()).setDaysSinceLastExposure(days);
  }

  private void setLastNotificationTimeInMillis(Long notifyTime){
    new ExposureNotificationSharedPreferences(getApplicationContext()).setLastNotificationTimeInMillis(notifyTime);
  }

  /**
   * Method created by SpringML to get notification message based on no. of days of last exposure.
   * @param days no. of days since last exposure.
   * */
  private String getNotificationMsg(int days){
    String message;
    if (days == 0){
      message = context.getString(R.string.notification_message_zero_days);
    }
    else if (days == 1){
      message = context.getString(R.string.notification_message_one_day, days);
    }
    else{
      message = context.getString(R.string.notification_message_two_days, days);
    }
    message = message + context.getString(R.string.notification_message_tap_to_learn);
    return message;
  }
}
