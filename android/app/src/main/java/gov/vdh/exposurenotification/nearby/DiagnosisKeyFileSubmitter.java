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
import android.util.Log;
import gov.vdh.exposurenotification.common.AppExecutors;
import gov.vdh.exposurenotification.common.TaskToFutureAdapter;
import gov.vdh.exposurenotification.network.KeyFileConstants;
import gov.vdh.exposurenotification.debug.KeyFileWriter;
import gov.vdh.exposurenotification.debug.proto.TEKSignatureList;
import gov.vdh.exposurenotification.debug.proto.TemporaryExposureKey;
import gov.vdh.exposurenotification.debug.proto.TemporaryExposureKeyExport;
import gov.vdh.exposurenotification.network.KeyFileBatch;
import gov.vdh.exposurenotification.utils.CustomUtility;
import com.google.common.io.BaseEncoding;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import org.apache.commons.io.IOUtils;
import org.threeten.bp.Duration;

/**
 * A thin class to take responsibility for submitting downloaded Diagnosis Key files to the Google
 * Play Services Exposure Notifications API.
 */
public class DiagnosisKeyFileSubmitter {
  private static final String TAG = "KeyFileSubmitter";
  // Use a very very long timeout, in case of a stress-test that supplies a very large number of
  // diagnosis key files.
  private static final Duration PROVIDE_KEYS_TIMEOUT = Duration.ofMinutes(60);
  private static final BaseEncoding BASE16 = BaseEncoding.base16().lowerCase();
  private static final BaseEncoding BASE64 = BaseEncoding.base64();

  private final ExposureNotificationClientWrapper client;

  public DiagnosisKeyFileSubmitter(Context context) {
    client = ExposureNotificationClientWrapper.get(context);
  }

  /**
   * Accepts batches of key files, and submits them to provideDiagnosisKeys(), and returns a future
   * representing the completion of that task.
   *
   * <p>This naive implementation is not robust to individual failures. In fact, a single failure
   * will fail the entire operation. A more robust implementation would support retries, partial
   * completion, and other robustness measures.
   *
   * <p>Returns early if given an empty list of batches.
   */
  public ListenableFuture<?> submitFiles(List<KeyFileBatch> batches, String token) {
    if (batches.isEmpty()) {

      return Futures.immediateFuture(null);
    }

    ListenableFuture<?> allDone = submitBatches(batches, token);

    // Add a listener to delete all the files.
    allDone.addListener(
        () -> {
          for (KeyFileBatch b : batches) {
            for (File f : b.files()) {
              f.delete();
            }
          }
        },
        AppExecutors.getBackgroundExecutor());

    return allDone;
  }

  private ListenableFuture<?> submitBatches(List<KeyFileBatch> batches, String token) {

    List<File> files = new ArrayList<>();
    for (KeyFileBatch b : batches) {
      files.addAll(b.files());
    }

    return TaskToFutureAdapter.getFutureWithTimeout(
        client.provideDiagnosisKeys(files, token),
        PROVIDE_KEYS_TIMEOUT.toMillis(),
        TimeUnit.MILLISECONDS,
        AppExecutors.getScheduledExecutor());
  }



  private FileContent readFile(File file) throws IOException {
    try(ZipFile zip = new ZipFile(file)) {
      ZipEntry signatureEntry = zip.getEntry(KeyFileConstants.SIG_FILENAME);
      ZipEntry exportEntry = zip.getEntry(KeyFileConstants.EXPORT_FILENAME);

    byte[] sigData = IOUtils.toByteArray(zip.getInputStream(signatureEntry));
    byte[] bodyData = IOUtils.toByteArray(zip.getInputStream(exportEntry));

    byte[] header = Arrays.copyOf(bodyData, 16);
    byte[] exportData = Arrays.copyOfRange(bodyData, 16, bodyData.length);

    String headerString = new String(header);
    TEKSignatureList signature = TEKSignatureList.parseFrom(sigData);
    TemporaryExposureKeyExport export = TemporaryExposureKeyExport.parseFrom(exportData);

    return new FileContent(headerString, export, signature);
  }
  }

  private static class FileContent {
    private final String header;
    private final TemporaryExposureKeyExport export;
    private final TEKSignatureList signature;

    FileContent(String header, TemporaryExposureKeyExport export, TEKSignatureList signature) {
      this.export = export;
      this.header = header;
      this.signature = signature;
    }
  }
}
