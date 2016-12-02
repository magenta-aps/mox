package dk.magenta.mox.agent.rest;

import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.net.ConnectException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

public class RestClient {
    public URL url;
    public Logger log = Logger.getLogger(RestClient.class);

    public RestClient(URL host) throws MalformedURLException {
        this.url = new URL(host.getProtocol(), host.getHost(), host.getPort(), "/");
    }

    public RestClient(String host) throws MalformedURLException {
        this(new URL(host));
    }

    public URL getURLforPath(String path) throws MalformedURLException {
        return new URL(this.url.getProtocol(), this.url.getHost(), this.url.getPort(), path);
    }

    public String rest(String method, String path, char[] payload) throws IOException {
        return this.rest(method, path, payload, null);
    }

    public String rest(String method, String path, char[] payload, String authorization) throws IOException {
        return this.rest(method, this.getURLforPath(path), payload,
                authorization);
    }

    public String rest(String method, URL url, char[] payload, String
            authorization) throws IOException {
        InputStream inputStream = restRawResponse(method, url, payload, authorization);
        return IOUtils.toString(inputStream);
    }

    public InputStream restRawResponse(String method, String path, char[] payload) throws IOException {
        return this.restRawResponse(method, path, payload, null);
    }

    public InputStream restRawResponse(String method, String path, char[] payload, String authorization) throws IOException {
        return this.restRawResponse(method, this.getURLforPath(path), payload,
                authorization);
    }

    /**
     * Make a REST request and return the response as an InputStream
     * @param method
     * @param url
     * @param payload
     * @param authorization
     * @return
     * @throws IOException
     */
    public InputStream restRawResponse(String method, URL url, char[] payload, String
            authorization) throws IOException {
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout(30000);

        connection.setDoOutput(true);
        connection.setRequestProperty("Content-type", "application/json");
        if (authorization != null && !authorization.isEmpty()) {
            connection.setRequestProperty("Authorization", authorization.trim());
        }
        this.log.info("Sending message to REST interface: " + method + "" +
                    " " + url.toString() + " " + (payload != null ? new String(payload): ""));
        try {
            if (!("GET".equalsIgnoreCase(method))) {
                OutputStreamWriter out = new OutputStreamWriter(connection.getOutputStream());
                out.write(payload);
                out.close();
            }
            this.log.info("got response");
            return connection.getInputStream();
        } catch (ConnectException e) {
            this.log.warn("The defined REST interface (" + method + " " + connection.getURL().getHost() + ":" + connection.getURL().getPort() + connection.getURL().getPath() + ") does not answer.");
            throw e;
        } catch (IOException e) {
            this.log.warn("IOException on request to " + method + " " + url.toString() + ": " + e.getMessage());
            String response = IOUtils.toString(connection.getErrorStream());
            if (response != null) {
                this.log.warn(response);
                throw new IOException("IOException: Got error response: " +
                        response, e);
            } else {
                throw e;
            }
        }
    }
}