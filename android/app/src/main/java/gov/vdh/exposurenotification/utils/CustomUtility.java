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

package gov.vdh.exposurenotification.utils;

//import androidx.test.core.app.ApplicationProvider;
//FirebaseApp.initializeApp(this);
//import com.google.firebase.database.DatabaseReference;   //TODO Ani
//import com.google.firebase.database.FirebaseDatabase;
import android.util.Log;
import gov.vdh.exposurenotification.BuildConfig;
import java.io.OutputStream;
import java.net.URL;
import java.util.Date;
import java.util.UUID;
import javax.net.ssl.HttpsURLConnection;


/**
 * Generated class for utility functions which are accessible globally.
 **/

public class CustomUtility {

  private static final String TAG = "CustomUtility" ;
  private static UUID uuid = UUID.randomUUID();
  private static Boolean LOG_TO_SERVER = true;

  public static void customLogger(String msg) {

    if ("YES".equalsIgnoreCase(BuildConfig.LOGGING_ENABLED)) {
      if(LOG_TO_SERVER) {
        String httpsURL = BuildConfig.LOGGING_URL;
        String finalMsg = msg;
        if(("NO".equalsIgnoreCase(BuildConfig.VERBOSE_LOGGING) && containsWords(finalMsg))
            || ("YES".equalsIgnoreCase(BuildConfig.VERBOSE_LOGGING))) {
          Thread t = new Thread(){
            public void run()
            {
              try {
                Logger(httpsURL, finalMsg);
              } catch (Exception e) {
              }
            }
          };
          //Starting anonymous thread
          t.start();
        }
      }
    }
  }

  public static boolean containsWords(String message) {
    boolean found = false;
    String[] words = {"A_CW_91001", "A_CW_91009", "A_CW_91002", "A_CW_ERROR", "ERROR", "error", "Error", };
    for (String eachWord : words) {
      if (message.contains(eachWord)) {
        found = true;
        break;
      }
    }
    return found;
  }

  public static void Logger(String urlToRead, String msg) throws Exception{
    URL url = new URL(urlToRead);
    Date refDate = new Date();
    msg = refDate.toString() + " : " + msg;
    String payload ="{\"type\" : \"Android\",\"user\" : \"" + uuid.toString() + "\",\"timestamp\": \"" + refDate.getTime() + "\",\"message\" :\"" + msg +"\"}";
    HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
    conn.setRequestMethod("POST");
    conn.setDoOutput(true);
    conn.setConnectTimeout(300000);
    conn.setReadTimeout(15000);
    conn.setRequestProperty("Content-Type", "application/json; utf-8");
    conn.setRequestProperty("Accept", "application/json");
    OutputStream os = conn.getOutputStream();
    byte[] input = payload.getBytes("utf-8");
    os.write(input, 0, input.length);
    if(conn.getResponseCode() != 200 ){
      LOG_TO_SERVER = false;
    }
    else{
      LOG_TO_SERVER = true;
    }
    return;
  }

}

