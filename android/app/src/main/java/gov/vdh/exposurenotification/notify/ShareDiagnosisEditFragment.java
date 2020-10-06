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

//import static androidx.test.core.app.ApplicationProvider.getApplicationContext;
import static gov.vdh.exposurenotification.notify.ShareDiagnosisActivity.SHARE_EXPOSURE_FRAGMENT_TAG;

import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.graphics.Color;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.widget.AppCompatSpinner;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;
import androidx.lifecycle.ViewModelProvider;
import com.android.volley.RequestQueue;
import gov.vdh.exposurenotification.BuildConfig;
import gov.vdh.exposurenotification.R;
import gov.vdh.exposurenotification.otpview.OtpView;
import gov.vdh.exposurenotification.storage.ExposureNotificationSharedPreferences;
import gov.vdh.exposurenotification.utils.CustomUtility;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.StringReader;
import java.net.InetAddress;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManagerFactory;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.threeten.bp.ZonedDateTime;
import org.threeten.bp.format.DateTimeFormatter;
import org.threeten.bp.format.FormatStyle;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

/**
 * Page 2 of the adding a positive diagnosis flow
 */
public class ShareDiagnosisEditFragment extends Fragment {

  private static final String TAG = "ShareExposureEditFrag";
  private static int retries = 0;

  private static final DateTimeFormatter formatter =
      DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM);

  private ShareDiagnosisViewModel shareDiagnosisViewModel;

  AppCompatSpinner month_spinner;
  String selectedMonth = "";
  RequestQueue queue;

  Button nextButton;

  OtpView pincodeEdittext;
  String pincode;

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
    return inflater.inflate(R.layout.fragment_share_diagnosis_edit, parent, false);
  }

  @Override
  public void onViewCreated(@NonNull View view, Bundle savedInstanceState) {
    shareDiagnosisViewModel =
        new ViewModelProvider(getActivity()).get(ShareDiagnosisViewModel.class);

    pincodeEdittext = view.findViewById(R.id.otp_view);
    pincodeEdittext.requestFocus();
    pincodeEdittext.addTextChangedListener(mPinEntryWatcher);
    String incorrectPinText = getString(R.string.pin_less_than_6_digits);

    pincodeEdittext.setOnEditorActionListener(new OnEditorActionListener() {
      @Override
      public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
        if ((event != null && (event.getKeyCode() == KeyEvent.KEYCODE_ENTER)) || (actionId
            == EditorInfo.IME_ACTION_DONE)) {
          if (pincodeEdittext.getText().toString() != null && !pincodeEdittext.getText().toString()
              .isEmpty() && (pincodeEdittext.getText().toString().length() == 6)) {
            //verificationMethod();
            pincode = pincodeEdittext.getText().toString().trim();
            new newVerificationMethod().execute();

          } else {
            Toast.makeText(getActivity(), incorrectPinText, Toast.LENGTH_SHORT).show();
          }
        }
        return false;
      }
    });

    nextButton = view.findViewById(R.id.share_next_button);

    nextButton.setEnabled(false);

    nextButton.setOnClickListener(new OnClickListener() {
      @Override
      public void onClick(View view) {
        pincode = pincodeEdittext.getText().toString().trim();
        new newVerificationMethod().execute();
      }
    });

    //view.findViewById(R.id.share_cancel_button).setOnClickListener((v) -> cancelAction());

    View upButton = view.findViewById(android.R.id.home);
    upButton.setContentDescription(getString(R.string.navigate_up));
    upButton.setOnClickListener((v) -> navigateUp());

    ExposureNotificationSharedPreferences sharedPreferences = new ExposureNotificationSharedPreferences(getContext().getApplicationContext());
    long lastRetryTime = sharedPreferences.getLastRetryTimeInMillis(0L);
    long waitTime = 600000 - (System.currentTimeMillis() - lastRetryTime);

    if ((waitTime > 1000) && (waitTime < 600000)) {
      TextView timerTextField = view.findViewById(R.id.wait_if_retry_exhausted);
      timerTextField.setVisibility(View.VISIBLE);

      CountDownTimer ct = new CountDownTimer(waitTime, 1000) {

        public void onTick(long millisUntilFinished) {
          int timeLeftInMIn = (int) (millisUntilFinished / 60000);
          int secondsInMIn = (int) ((millisUntilFinished/1000)%60);
          String separator = ":";
          if (secondsInMIn < 10)
            separator = ":0";
          pincodeEdittext.setEnabled(false);
          if (Locale.getDefault().getLanguage() == "es")
            timerTextField.setText("Espera " + timeLeftInMIn + separator + secondsInMIn + " minuto(s) antes de volver a intentar.");
          else
            timerTextField.setText("Please wait for " + timeLeftInMIn + separator + secondsInMIn + " before retry.");
          timerTextField.setTextColor(Color.RED);

        }

        @Override
        public void onFinish() {
          timerTextField.setVisibility(View.GONE);
          pincodeEdittext.setEnabled(true);
          retries = 0;
        }

      }.start();
    }
  }


  private TextWatcher mPinEntryWatcher = new TextWatcher() {

    @Override
    public void onTextChanged(CharSequence s, int start, int before, int count) {
    }

    @Override
    public void afterTextChanged(Editable s) {
        nextButton.setEnabled((s.length() == 6 ));
    }

    @Override
    public void beforeTextChanged(CharSequence s, int start, int count, int after) {
    }

  };

  private final class newVerificationMethod extends AsyncTask<Void, Void, String> {

    ProgressDialog prog = new ProgressDialog(getActivity());

    @Override
    protected void onPreExecute() {
      super.onPreExecute();

      prog.setMessage(getString(R.string.verifying));
      prog.setCancelable(false);
      prog.setIndeterminate(true);
      prog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
      prog.show();


    }

    @Override
    protected String doInBackground(Void... params) {
      retries = retries + 1;
      String result = "";
      if (retries <=3) {
        int attempt = 0;

        while (attempt < 3 && ("".equalsIgnoreCase(result) || result == null)) {
          try {
            result = vdhConnector(attempt);
          } catch (SocketTimeoutException ste) {
            CustomUtility.customLogger("A_CW_ERROR Timeout while VDH pin verification : " + ste.getStackTrace());
            ste.printStackTrace();
            result = "NO";
          } catch (Exception e) {
            e.printStackTrace();
            CustomUtility.customLogger("A_CW_ERROR Error during VDH pin verification : " + e.getStackTrace());
            attempt = 3;
            result = "NO";
          } finally {
            attempt = attempt + 1;
          }
        }
        prog.dismiss();
        return result;
      }
     return "RETRIES_EXHAUSTED";
    }

    String vdhConnector(int attempt) throws Exception {
      String token = "";

      String httpsURL = getString(R.string.vdh_pin_uri);

//    To get the code
      String xmlString =
            "<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:con=\"ContactTracingTestVerificationWS\">\n"
                + "   <soap:Header/>\n"
                + "   <soap:Body>\n"
                + "      <con:VerificationRequest>\n"
                + "         \n"
                + "         <con:Pin>" + pincode + "</con:Pin>\n"
                + "         \n"
                + "\n"
                + "<con:VerificationType>I</con:VerificationType>\n"
                + "      </con:VerificationRequest>\n"
                + "   </soap:Body>\n"
                + "</soap:Envelope>";

        byte[] out = xmlString.getBytes();
        int length = out.length;
//      SSL Pinning Enabled
        String vdhCert = "";  //To get the cert in base-64 encoding


        byte[] certBytes = vdhCert.getBytes();
        java.io.ByteArrayInputStream in = new java.io.ByteArrayInputStream(certBytes);

        java.security.cert.CertificateFactory cf = java.security.cert.CertificateFactory
            .getInstance("X.509");
        java.security.cert.X509Certificate certificate = (java.security.cert.X509Certificate) cf
            .generateCertificate(in);

        KeyStore keyStore = KeyStore.getInstance(KeyStore.getDefaultType());
        keyStore.load(null, null);
        keyStore.setCertificateEntry("server", certificate);

        TrustManagerFactory trustManagerFactory = TrustManagerFactory
            .getInstance(TrustManagerFactory.getDefaultAlgorithm());
        trustManagerFactory.init(keyStore);

        URL myurl = new URL(httpsURL);


        HttpsURLConnection con = (HttpsURLConnection) myurl.openConnection();
        con.setConnectTimeout(20000);
        con.setReadTimeout(15000);

        SSLContext sc = SSLContext.getInstance("TLS");
        sc.init(null, trustManagerFactory.getTrustManagers(), null);
        con.setSSLSocketFactory(sc.getSocketFactory());
        con.setRequestMethod("POST");
        con.setRequestProperty("Content-length", String.valueOf(length));
        con.setRequestProperty("Content-Type",
            "application/soap+xml;charset=UTF-8;action='urn:VerificationRequest'");
        con.setDoOutput(true);
        con.setDoInput(true);
        OutputStream outputStream = con.getOutputStream();
        DataOutputStream output = new DataOutputStream(outputStream);

        output.writeBytes(new String(out));
        output.close();
        DataInputStream input = new DataInputStream(con.getInputStream());
        byte[] buffer = new byte[1024];
        StringBuffer sb = new StringBuffer();
        InputStreamReader isReader = new InputStreamReader(input);

        BufferedReader reader = new BufferedReader(isReader);
        String str;
        while ((str = reader.readLine()) != null) {
          sb.append(str);
        }
        if (con.getResponseCode() == 200){
        token = sb.toString();
        input.close();
        DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
        DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
        Document doc = dBuilder.parse(new InputSource(new StringReader(token)));
        doc.getDocumentElement().normalize();

        NodeList nList = doc.getElementsByTagName("con:VerificationRequestResponse");

        String response = "";
        String jwtToken = "";
        for (int i = 0; i < nList.getLength(); i++) {
          Node nNode = nList.item(i);

          if (nNode.getNodeType() == Node.ELEMENT_NODE) {

            Element elem = (Element) nNode;

            Node node1 = elem.getElementsByTagName("con:response").item(0);
            response = node1.getTextContent();
            if ("YES".equalsIgnoreCase(response)) {
              Node node2 = elem.getElementsByTagName("con:token").item(0);
              jwtToken = node2.getTextContent();
              token = jwtToken;
            } else {
              token = "NO";
            }
          }

        }
      }
        else {
          //TODO for future implementation we can create more specific messages based on server
          // error response
          token = "NO";
        }
      return token;
    }

    @Override
    protected void onPostExecute(String result) {

      if("RETRIES_EXHAUSTED".equalsIgnoreCase(result) || (retries >=3 && "NO".equalsIgnoreCase(result))){

        prog.dismiss();
        new ExposureNotificationSharedPreferences(getContext().getApplicationContext()).setLastRetryTimeInMillis(System.currentTimeMillis());

        AlertDialog alertDialog = new AlertDialog.Builder(getActivity()).create();
        alertDialog.setTitle(getString(R.string.max_retries_exhausted_title_text));
        alertDialog.setMessage(getString(R.string.max_retries_exhausted_message_text));
        alertDialog.setCancelable(false);

        alertDialog.setButton(AlertDialog.BUTTON_NEGATIVE, "OK",
            new DialogInterface.OnClickListener() {
              public void onClick(DialogInterface dialog, int which) {
                pincodeEdittext.setText("");
                alertDialog.dismiss();
                requireActivity().finish();
              }
            });

        alertDialog.show();

      }
      else if("NO".equalsIgnoreCase(result)){
        CustomUtility.customLogger("A_CW_ERROR: PIN verification error, PIN not verified");
        AlertDialog alertDialog = new AlertDialog.Builder(getActivity()).create();
        alertDialog.setTitle(getString(R.string.incorrect_pin_title_text));
        alertDialog.setMessage(getString(R.string.incorrect_pin_message_text));
        alertDialog.setCancelable(false);

        alertDialog.setButton(AlertDialog.BUTTON_NEGATIVE, "OK",
            new DialogInterface.OnClickListener() {
              public void onClick(DialogInterface dialog, int which) {
                pincodeEdittext.setText("");
                alertDialog.dismiss();
              }
            });

        alertDialog.show();
      }
      else if("Error".equalsIgnoreCase(result)) {
        //TODO for future error response codes
      }
      else {

        CustomUtility.customLogger("A_CW_91002 - A PIN was successfully verified.");
        retries = 0;

        shareDiagnosisViewModel.setTestIdentifier(pincodeEdittext.getText().toString());

        new ExposureNotificationSharedPreferences(getContext().getApplicationContext()).setPinToken(result);

//        Instant instant = Instant.now();
        String currentDate = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale
            .getDefault()).format(new Date());
        shareDiagnosisViewModel
            .onTestTimestampChanged(ZonedDateTime.parse(currentDate));

        getParentFragmentManager()
            .beginTransaction()
            .replace(
                R.id.share_exposure_fragment,
                new ShareDiagnosisReviewFragment(),
                SHARE_EXPOSURE_FRAGMENT_TAG)
            .addToBackStack(null)
            .setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN)
            .commit();
      }
    }
  }


  class MyFactory extends SSLSocketFactory {

    private javax.net.ssl.SSLSocketFactory internalSSLSocketFactory;

    public MyFactory() throws KeyManagementException, NoSuchAlgorithmException {
      SSLContext context = SSLContext.getInstance("TLS");
      context.init(null, null, null);
      internalSSLSocketFactory = context.getSocketFactory();
    }

    @Override
    public String[] getDefaultCipherSuites() {
      return internalSSLSocketFactory.getDefaultCipherSuites();
    }

    @Override
    public String[] getSupportedCipherSuites() {
      return internalSSLSocketFactory.getSupportedCipherSuites();
    }

    @Override
    public Socket createSocket() throws IOException {
      return enableTLSOnSocket(internalSSLSocketFactory.createSocket());
    }

    @Override
    public Socket createSocket(Socket s, String host, int port, boolean autoClose)
        throws IOException {
      return enableTLSOnSocket(internalSSLSocketFactory.createSocket(s, host, port, autoClose));
    }

    @Override
    public Socket createSocket(String host, int port) throws IOException {
      return enableTLSOnSocket(internalSSLSocketFactory.createSocket(host, port));
    }

    @Override
    public Socket createSocket(String host, int port, InetAddress localHost, int localPort)
        throws IOException {
      return enableTLSOnSocket(
          internalSSLSocketFactory.createSocket(host, port, localHost, localPort));
    }

    @Override
    public Socket createSocket(InetAddress host, int port) throws IOException {
      return enableTLSOnSocket(internalSSLSocketFactory.createSocket(host, port));
    }

    @Override
    public Socket createSocket(InetAddress address, int port, InetAddress localAddress,
        int localPort) throws IOException {
      return enableTLSOnSocket(
          internalSSLSocketFactory.createSocket(address, port, localAddress, localPort));
    }

    private Socket enableTLSOnSocket(Socket socket) {
      if (socket != null && (socket instanceof SSLSocket)) {
        ((SSLSocket) socket).setEnabledProtocols(new String[]{"TLSv1.1", "TLSv1.2"});
      }
      return socket;
    }
  }


  private void cancelAction() {
    requireActivity().finish();
  }

  private void navigateUp() {
    getParentFragmentManager().popBackStack();
  }

}
