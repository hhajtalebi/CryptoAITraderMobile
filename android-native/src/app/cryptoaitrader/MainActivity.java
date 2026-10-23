package app.cryptoaitrader;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.graphics.Color;
import android.view.Window;
import android.net.Uri;
import android.content.res.AssetManager;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URI;

/** Offline-first Android shell. Public market GETs are bounded and host allow-listed. */
public final class MainActivity extends Activity {
    private WebView webView;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        Window w = getWindow();
        w.setStatusBarColor(Color.rgb(5, 10, 20));
        w.setNavigationBarColor(Color.rgb(5, 10, 20));
        w.getDecorView().setSystemUiVisibility(0);
        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(5, 10, 20));
        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(false);
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        s.setLoadsImagesAutomatically(true);
        s.setDefaultTextEncodingName("UTF-8");
        webView.setWebChromeClient(new WebChromeClient());
        webView.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
                Uri u = req.getUrl();
                return !"https".equals(u.getScheme()) || !"appassets.androidplatform.net".equals(u.getHost()) || u.getPath() == null || !u.getPath().startsWith("/assets/");
            }
            @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest req) {
                Uri u = req.getUrl();
                if (!"https".equals(u.getScheme()) || !"appassets.androidplatform.net".equals(u.getHost()) || u.getPath() == null || !u.getPath().startsWith("/assets/")) return super.shouldInterceptRequest(view, req);
                String name = u.getPath().substring("/assets/".length());
                if (name.contains("..") || name.startsWith("/") || name.isEmpty()) return new WebResourceResponse("text/plain", "UTF-8", 403, "Forbidden", null, new ByteArrayInputStream(new byte[0]));
                try {
                    AssetManager assets = getAssets();
                    String mime = name.endsWith(".png") ? "image/png" : name.endsWith(".ttf") ? "font/ttf" : name.endsWith(".css") ? "text/css" : name.endsWith(".js") ? "text/javascript" : "text/html";
                    return new WebResourceResponse(mime, "UTF-8", assets.open(name));
                } catch (Exception ex) {
                    return new WebResourceResponse("text/plain", "UTF-8", 404, "Not Found", null, new ByteArrayInputStream(new byte[0]));
                }
            }
        });
        webView.addJavascriptInterface(new PublicApiBridge(), "NativeBridge");
        setContentView(webView);
        try {
            InputStream page = getAssets().open("web/index.html");
            ByteArrayOutputStream html = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192]; int read;
            while ((read = page.read(buffer)) != -1) html.write(buffer, 0, read);
            page.close();
            webView.loadDataWithBaseURL("https://appassets.androidplatform.net/assets/web/index.html", new String(html.toByteArray(), "UTF-8"), "text/html", "UTF-8", null);
        } catch (Exception ex) {
            webView.loadDataWithBaseURL("https://appassets.androidplatform.net/assets/web/index.html", "<meta charset='utf-8'><body style='background:#050a14;color:white;font-family:sans-serif'>CryptoAITrader: asset load failed</body>", "text/html", "UTF-8", null);
        }
    }

    @Override public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }

    public final class PublicApiBridge {
        @JavascriptInterface public String get(String address) {
            HttpURLConnection connection = null;
            try {
                URI uri = new URI(address);
                String scheme = uri.getScheme();
                String host = uri.getHost();
                if (!"https".equalsIgnoreCase(scheme) || host == null ||
                    !(host.equalsIgnoreCase("api.lbkex.com") || host.equalsIgnoreCase("lbkperp.lbank.com")) ||
                    uri.getUserInfo() != null || uri.getFragment() != null ||
                    (uri.getPath() == null || !uri.getPath().startsWith("/v2/") && !uri.getPath().startsWith("/cfd/openApi/v1/pub/"))) {
                    return "{\"__error\":\"blocked_url\"}";
                }
                connection = (HttpURLConnection) new URL(address).openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(8000);
                connection.setReadTimeout(12000);
                connection.setInstanceFollowRedirects(false);
                connection.setRequestProperty("Accept", "application/json");
                connection.setRequestProperty("User-Agent", "CryptoAITrader/1.0.0 Android");
                int code = connection.getResponseCode();
                if (code < 200 || code >= 300) return "{\"__error\":\"http_" + code + "\"}";
                InputStream in = connection.getInputStream();
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                byte[] buf = new byte[8192];
                int n, total = 0;
                while ((n = in.read(buf)) != -1) {
                    total += n;
                    if (total > 8 * 1024 * 1024) return "{\"__error\":\"response_too_large\"}";
                    out.write(buf, 0, n);
                }
                in.close();
                return new String(out.toByteArray(), "UTF-8");
            } catch (Exception ex) {
                return "{\"__error\":\"network_unavailable\"}";
            } finally {
                if (connection != null) connection.disconnect();
            }
        }
    }
}
