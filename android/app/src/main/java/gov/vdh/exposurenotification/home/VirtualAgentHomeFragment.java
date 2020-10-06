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

package gov.vdh.exposurenotification.home;

import android.icu.util.ULocale;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebSettings;
import android.webkit.WebView;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import gov.vdh.exposurenotification.R;
import java.util.Locale;

public class VirtualAgentHomeFragment extends Fragment {

  private static final String TAG = "VirtualFragment";

  @Override
  public View onCreateView(@NonNull final LayoutInflater inflater,
      final ViewGroup container, Bundle savedInstanceState) {

    final View root = inflater.inflate(R.layout.fragment_virtual_agent_home, container, false);
    final WebView webview = (WebView) root.findViewById(R.id.webview_home);
    WebSettings webSettings = webview.getSettings();
    webSettings.setJavaScriptEnabled(true);
    Locale locale = Locale.getDefault();
    String url = getString(R.string.virtual_agent_uri) + "?locale=" + locale.getLanguage();
    webview.loadUrl(url);
    return root;
  }

}
