package com.ibm.mil.sigmund;

import android.app.ActionBar;
import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.TextView;

import com.twitter.sdk.android.Twitter;
import com.twitter.sdk.android.core.AppSession;
import com.twitter.sdk.android.core.Callback;
import com.twitter.sdk.android.core.Result;
import com.twitter.sdk.android.core.TwitterApiClient;
import com.twitter.sdk.android.core.TwitterAuthConfig;
import com.twitter.sdk.android.core.TwitterCore;
import com.twitter.sdk.android.core.TwitterException;
import com.twitter.sdk.android.core.models.Tweet;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.fabric.sdk.android.Fabric;
import retrofit.RestAdapter;
import retrofit.RetrofitError;
import retrofit.client.Response;
import retrofit.http.Body;
import retrofit.http.POST;

public class MainActivity extends Activity {

    // Note: Your consumer key and secret should be obfuscated in your source code before shipping.
    private static final String TWITTER_KEY = "1hBPHSs7Lhpxjp4XTlCqclmSu";
    private static final String TWITTER_SECRET = "Hq5acmVzD4hffXTsPEGvXthgWbgh7BXTZhG3a9WlZe6TQKYpcl";

    TextView textView;
    EditText editText;
    TwitterApiClient twitterApiClient;
    ProgressDialog progress;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TwitterAuthConfig authConfig = new TwitterAuthConfig(TWITTER_KEY, TWITTER_SECRET);
        Fabric.with(this, new Twitter(authConfig));
        setContentView(R.layout.activity_main);
        textView = (TextView) findViewById(R.id.textView);
        textView.setVisibility(View.GONE);

        setUpEditText();
        hideStatusBar();
        lonIntoTwitter();
    }

    private void setUpEditText(){
        editText = (EditText) findViewById(R.id.editText);
        final Activity activity = this;
        editText.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView textView, int i, KeyEvent keyEvent) {
                progress = new ProgressDialog(activity);
                progress.setTitle("Wait");
                progress.setMessage("Watson is getting to know you.");
                progress.show();
                parseTweets(textView.getText().toString());
                textView.setText("");
                return false;
            }
        });

        InputMethodManager imm = (InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.showSoftInput(editText, InputMethodManager.SHOW_IMPLICIT);
    }

    private void parseTweets(final String username) {
        final List<String> tweetTexts = new ArrayList<>();

        twitterApiClient.getStatusesService().userTimeline(null, username, 200, null, null, true, false, false, false, new Callback<List<Tweet>>() {
            @Override
            public void success(Result<List<Tweet>> result) {
                List<Tweet> tweets = result.data;
                for (int i = 0; i < tweets.size(); i++) {
                    tweetTexts.add(tweets.get(i).text);
                }
                getWatsonInsight(username, tweetTexts);
            }

            @Override
            public void failure(TwitterException e) {

            }
        });

    }



    private void lonIntoTwitter() {
        TwitterCore.getInstance().logInGuest(new Callback<AppSession>() {
            @Override
            public void success(Result<AppSession> result) {
                AppSession guestAppSession = result.data;
                twitterApiClient =  TwitterCore.getInstance().getApiClient(guestAppSession);

                editText.setEnabled(true);
            }

            @Override
            public void failure(TwitterException exception) {
                // unable to get an AppSession with guest auth
            }
        });
    }

    private void getWatsonInsight(final String username, List<String> tweetTexts) {
        List contentItems = new ArrayList();

        for (int i = 0; i < tweetTexts.size(); i++) {
            String tweetText = tweetTexts.get(i);
            Map<String, Object> contentItem = new HashMap<>();

            contentItem.put("id", "MYIDoserigj"+username+"esrgjes"+i);
            contentItem.put("userid", "username");
            contentItem.put("sourceid", "twitter");
            contentItem.put("contenttype","text/html");
            contentItem.put("language", "en");
            contentItem.put("content", tweetText);

            contentItems.add(contentItem);
        }


        Map<String, Object> jsonPayload = new HashMap<>();
        jsonPayload.put("contentItems", contentItems);

        RestAdapter restAdapter = new RestAdapter.Builder()
                .setEndpoint("http://sigmund-insights.mybluemix.net")
                .build();

        WatsonService watsonService = restAdapter.create(WatsonService.class);

        watsonService.sendTweetsToWatson(jsonPayload, new retrofit.Callback<Map<String, Object>>() {

            @Override
            public void success(Map<String, Object> stringObjectMap, Response response) {
                String summaryString = (String) stringObjectMap.get("response");
                textView.setText("@"+username+"\n\n"+summaryString);
                progress.dismiss();
                textView.setVisibility(View.VISIBLE);
                hideSoftKeyBoard();
            }

            @Override
            public void failure(RetrofitError error) {
                System.out.println(error);
            }
        });
    }

    public interface WatsonService {
        @POST("/")
        void sendTweetsToWatson(@Body Map<String, Object> jsonPayload, retrofit.Callback<Map<String, Object>> cb);
    }

    public void hideStatusBar(){
        View decorView = getWindow().getDecorView();
        // Hide the status bar.
        int uiOptions = View.SYSTEM_UI_FLAG_FULLSCREEN;
        decorView.setSystemUiVisibility(uiOptions);
        // Remember that you should never show the action bar if the
        // status bar is hidden, so hide that too if necessary.
        ActionBar actionBar = getActionBar();
        actionBar.hide();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private void hideSoftKeyBoard() {
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);

        if(imm.isAcceptingText()) { // verify if the soft keyboard is open
            imm.hideSoftInputFromWindow(getCurrentFocus().getWindowToken(), 0);
        }
    }
}
