package app.numforlife.com;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.RenderMode;
import io.flutter.embedding.android.TransparencyMode;

public class MainActivity extends FlutterFragmentActivity {

    @NonNull
    @Override
    protected FlutterFragment createFlutterFragment() {
        return FlutterFragment.withNewEngine()
                .renderMode(RenderMode.surface)
                .transparencyMode(TransparencyMode.opaque) // 改为不透明
                .build();
    }
}
