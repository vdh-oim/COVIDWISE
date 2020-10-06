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

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.gms.nearby.exposurenotification.TemporaryExposureKey;
import com.google.common.io.BaseEncoding;
import gov.vdh.exposurenotification.R;
import gov.vdh.exposurenotification.debug.TemporaryExposureKeyAdapter.TemporaryExposureKeyViewHolder;
import java.util.List;

/** Adapter for displaying keys in {@link KeysMatchingFragment}. */
class TemporaryExposureKeyAdapter extends RecyclerView.Adapter<TemporaryExposureKeyViewHolder> {

  private static final String TAG = "ViewKeysAdapter";

  private static final BaseEncoding BASE16 = BaseEncoding.base16().lowerCase();

  private List<TemporaryExposureKey> temporaryExposureKeys = null;

  void setTemporaryExposureKeys(List<TemporaryExposureKey> temporaryExposureKeys) {
    this.temporaryExposureKeys = temporaryExposureKeys;
    notifyDataSetChanged();
  }

  List<TemporaryExposureKey> getTemporaryExposureKeys() {
    return temporaryExposureKeys;
  }

  @NonNull
  @Override
  public TemporaryExposureKeyViewHolder onCreateViewHolder(@NonNull ViewGroup viewGroup, int i) {
    return new TemporaryExposureKeyViewHolder(
        LayoutInflater.from(viewGroup.getContext())
            .inflate(R.layout.item_temporary_exposure_key_entity, viewGroup, false));
  }

  @Override
  public void onBindViewHolder(
      @NonNull TemporaryExposureKeyViewHolder temporaryExposureKeyViewHolder, int i) {
  }

  @Override
  public int getItemCount() {
    if (temporaryExposureKeys == null) {
      return 0;
    }
    return temporaryExposureKeys.size();
  }

  class TemporaryExposureKeyViewHolder extends RecyclerView.ViewHolder {

    private static final long INTERVAL_TIME_MILLIS = 10 * 60 * 1000L;

    private final View view;
    private final TextView date;
    private final TextView key;
    private final TextView rollingPeriod;
    private final TextView intervalNumber;
    private final TextView transmissionRiskLevel;
    private final ImageView qrCode;

    TemporaryExposureKeyViewHolder(@NonNull View view) {
      super(view);
      this.view = view;
      date = view.findViewById(R.id.temporary_exposure_key_date);
      key = view.findViewById(R.id.temporary_exposure_key_key);
      intervalNumber = view.findViewById(R.id.temporary_exposure_key_interval_number);
      rollingPeriod = view.findViewById(R.id.temporary_exposure_key_rolling_period);
      transmissionRiskLevel = view.findViewById(R.id.temporary_exposure_key_risk_level);
      qrCode = view.findViewById(R.id.qr_code);
    }

  }
  }
